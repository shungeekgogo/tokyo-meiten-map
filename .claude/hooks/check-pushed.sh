#!/usr/bin/env bash
# Stop hook: 作業を終える前に、変更が GitHub (origin/main) に push 済みかを確認する。
# 未コミット・未 push があれば Claude に一度だけ差し戻す（別の PC で古いファイルにならないように）。

input=$(cat)
# 差し戻し後の2回目の停止では何もしない（無限ループ防止）
echo "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

BRANCH=main
[ "$(git symbolic-ref --short -q HEAD)" = "$BRANCH" ] || exit 0

dirty=$(git status --porcelain)
ahead=$(git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 0)

if [ -n "$dirty" ] || [ "$ahead" -gt 0 ]; then
  echo "GitHub に未反映の変更があります（未コミット: $(echo -n "$dirty" | grep -c .) ファイル / 未 push コミット: ${ahead} 件）。CLAUDE.md のルールに従ってコミットし、git push origin $BRANCH してから終了してください。" >&2
  exit 2
fi
exit 0
