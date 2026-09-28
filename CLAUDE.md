# 駅ちか名店マップ — 作業ルール

## GitHub と常に同期する（複数 PC で作業）
- 作業開始時は、まず GitHub の最新版（今のブランチの追跡先。通常は `origin/main`）とこの PC のファイルを同期する。`.claude/hooks/sync-from-github.sh`（SessionStart フック）が自動で fetch・fast-forward し、結果をセッション冒頭に表示する。未コミットの変更や競合で自動更新できなかったと表示されたら、作業に入る前にユーザーに伝えて解決する。
- 作業終了前に、すべての変更がコミット・push 済みであることを確認する（`.claude/hooks/check-pushed.sh`（Stop フック）が未反映の変更を検出すると差し戻す）。
- このアプリ（`index.html`）やドキュメントを変更したら、そのたびに確認なしでコミットして `origin/main`（https://github.com/shungeekgogo/tokyo-meiten-map、Private）に push する。
- 機能・対象駅・ジャンル・データ範囲が変わったら `README.md` も合わせて更新する。

## データの扱い
- 食べログ本体（tabelog.com）はボット認証（Cloudflare）で保護されているため突破しない。百名店リストは meiten.reiwaq.com などのまとめから確認する。
- 予算と地図上の位置は推定値。公式URLは確認できたものだけ直接リンクし、それ以外は検索リンクにする。
- 写真は著作権に配慮し、埋め込まずリンクで見せる。

## プレビュー
- `python -m http.server 8765` で起動し http://localhost:8765 を開く（`.claude/launch.json` はローカル専用で git 管理外）。
- Artifact として公開しない（Artifact の CSP では地図タイル画像が読み込めない）。
