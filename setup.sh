#!/usr/bin/env bash
#
# プロジェクト全体（このリポジトリを使う人 全員）で使う共有セットアップ。
#
# 使い方:
#   このリポジトリを <project>/.claude として配置し、プロジェクトルートで実行:
#       bash .claude/setup.sh
#
# 役割:
#   - sync_mcp()       : MCP サーバ設定を <project>/.mcp.json に同期 (mcp/servers.json が正)
#   - install_tools()  : 全員で使うツール/パッケージのインストール
#   - apply_settings() : その他の共有設定の適用
#
# 何度でも実行可能。設定や MCP を更新したら再実行すれば最新状態に sync される。
#
# ■ 新しく「全員で使えるようにしたい」ものが出たら、ここに追記する:
#     - MCP サーバ        -> mcp/servers.json を編集（sync_mcp が自動で同期）
#     - インストールが要る -> install_tools() に冪等なコマンドを追記
#     - その他の設定       -> apply_settings() に追記
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../.claude
PROJECT_ROOT="$(dirname "$HERE")"

# --- MCP サーバ設定を <project>/.mcp.json に同期 ------------------------------
sync_mcp() {
  local src="$HERE/mcp/servers.json"
  local dest="$PROJECT_ROOT/.mcp.json"
  [ -f "$src" ] || { echo "✗ $src がありません" >&2; return 1; }

  if [ -f "$dest" ]; then
    if command -v jq >/dev/null 2>&1; then
      local tmp; tmp="$(mktemp)"
      # jq の * は再帰マージ。利用者の他サーバを残したまま git/slack を上書き同期する
      jq -s '.[0] * .[1]' "$dest" "$src" > "$tmp" && mv "$tmp" "$dest"
      echo "✓ MCP: 既存の .mcp.json に同期しました"
    else
      echo "⚠ MCP: .mcp.json が既存で jq が無いため自動同期できません。" >&2
      echo "       $src の mcpServers を手動で $dest にマージしてください。" >&2
    fi
  else
    cp "$src" "$dest"
    echo "✓ MCP: .mcp.json を作成しました"
  fi
}

# --- 全員に入れたいツール/パッケージのインストール ---------------------------
# 冪等に書くこと（再実行で壊れないように）。例:
#   command -v uv  >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
#   npm ls -g some-cli >/dev/null 2>&1 || npm i -g some-cli
install_tools() {
  : # 今はなし
}

# --- その他の共有設定の適用 ---------------------------------------------------
apply_settings() {
  : # 今はなし
}

sync_mcp
install_tools
apply_settings

cat <<'NOTE'

次の手順:
  1. slack 用に環境変数を設定:
       export SLACK_BOT_TOKEN=xoxb-xxxx
       export SLACK_TEAM_ID=T0xxxx
  2. git 用に uv をインストール (未導入なら): https://docs.astral.sh/uv/
  3. プロジェクトルートで `claude` を起動し、表示される MCP サーバの承認を許可する
     (確認: `claude mcp list`)
NOTE
