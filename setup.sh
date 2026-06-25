#!/usr/bin/env bash
#
# このリポジトリ (.claude) を <project>/.claude として配置したあと、
# プロジェクトルートで以下を実行すると git / slack の MCP サーバが使えるようになります:
#
#     bash .claude/setup.sh
#
# やっていること:
#   - mcp/servers.json の内容を <project>/.mcp.json に配置（既存ならマージ）
#   - .mcp.json は Claude Code がプロジェクトルートで読む共有 MCP 設定ファイル
#
# 前提:
#   - git MCP  : uv (uvx) が必要         https://docs.astral.sh/uv/
#   - slack MCP: node/npx が必要 + 環境変数 SLACK_BOT_TOKEN / SLACK_TEAM_ID
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../.claude
PROJECT_ROOT="$(dirname "$HERE")"
SRC="$HERE/mcp/servers.json"
DEST="$PROJECT_ROOT/.mcp.json"

if [ ! -f "$SRC" ]; then
  echo "✗ テンプレートが見つかりません: $SRC" >&2
  exit 1
fi

if [ -f "$DEST" ]; then
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    # jq の * は再帰マージ。既存サーバを残したまま git/slack を追加する
    jq -s '.[0] * .[1]' "$DEST" "$SRC" > "$tmp" && mv "$tmp" "$DEST"
    echo "✓ 既存の $DEST に git/slack サーバをマージしました"
  else
    echo "⚠ $DEST が既に存在し、jq が無いため自動マージできません。" >&2
    echo "  $SRC の mcpServers を手動で $DEST にマージしてください。" >&2
    exit 1
  fi
else
  cp "$SRC" "$DEST"
  echo "✓ $DEST を作成しました"
fi

cat <<'NOTE'

次の手順:
  1. slack 用に環境変数を設定:
       export SLACK_BOT_TOKEN=xoxb-xxxx
       export SLACK_TEAM_ID=T0xxxx
  2. git 用に uv をインストール (未導入なら): https://docs.astral.sh/uv/
  3. プロジェクトルートで `claude` を起動し、表示される MCP サーバの承認を許可する
     (確認: `claude mcp list`)
NOTE
