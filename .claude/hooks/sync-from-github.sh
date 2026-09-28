#!/usr/bin/env bash
# SessionStart hook: Claude Code を開いたら、まず GitHub (origin/main) の最新版と同期する。
# 標準出力はセッション冒頭の Claude へのコンテキストとして渡される。
# 失敗してもセッションは止めない（常に exit 0）。

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

BRANCH=main
current=$(git symbolic-ref --short -q HEAD)

if ! git fetch --quiet origin "$BRANCH" 2>/dev/null; then
  echo "[GitHub同期] origin に接続できず最新版を確認できませんでした（オフライン？）。作業前にユーザーへ伝え、接続後に git pull origin $BRANCH すること。"
  exit 0
fi

if [ "$current" != "$BRANCH" ]; then
  echo "[GitHub同期] 現在のブランチは '$current' です（$BRANCH ではないため自動同期はスキップ）。"
  exit 0
fi

behind=$(git rev-list --count "HEAD..origin/$BRANCH")
ahead=$(git rev-list --count "origin/$BRANCH..HEAD")
dirty=$(git status --porcelain)

if [ "$behind" -gt 0 ]; then
  if [ -n "$dirty" ]; then
    echo "[GitHub同期] GitHub に新しいコミットが ${behind} 件ありますが、この PC に未コミットの変更があるため自動更新していません。"
    echo "未コミットのファイル:"; echo "$dirty"
    echo "→ ユーザーに確認のうえ、変更をコミットしてから git pull --rebase origin $BRANCH で同期すること。"
  elif [ "$ahead" -gt 0 ]; then
    if git pull --quiet --rebase origin "$BRANCH" 2>/dev/null; then
      echo "[GitHub同期] GitHub の新しいコミット ${behind} 件を取り込み、この PC の未 push コミット ${ahead} 件をその上に載せ直しました。git push origin $BRANCH で GitHub に反映すること。"
    else
      git rebase --abort 2>/dev/null
      echo "[GitHub同期] GitHub とこの PC の両方に別々の変更があり、自動で統合できませんでした（競合）。ユーザーに状況を説明し、競合を解決してから push すること。"
    fi
  else
    before=$(git rev-parse --short HEAD)
    if git merge --quiet --ff-only "origin/$BRANCH" >/dev/null 2>&1; then
      echo "[GitHub同期] GitHub の最新版に更新しました（${before} → $(git rev-parse --short HEAD)、${behind} 件）。更新されたファイル:"
      git diff --stat "$before" HEAD | tail -n 20
    else
      echo "[GitHub同期] 自動更新に失敗しました。git status を確認すること。"
    fi
  fi
else
  msg="[GitHub同期] この PC のファイルは GitHub の最新版と同じです（$(git rev-parse --short HEAD)）。"
  [ "$ahead" -gt 0 ] && msg="$msg ただし未 push のコミットが ${ahead} 件あります → git push origin $BRANCH すること。"
  [ -n "$dirty" ] && msg="$msg 未コミットの変更があります（前回の作業の残り？）→ 内容を確認してコミット・push すること。"
  echo "$msg"
fi
exit 0
