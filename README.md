# 共有 .claude 設定

このリポジトリは、プロジェクトに `.claude/` として配置して**チーム全員で共有する** Claude Code 設定です。
中身は git 管理上 **`skills/` と MCP セットアップ関連のみ**を追跡しています（他は `.gitignore` 済み）。

## 含まれるもの

| 場所 | 内容 |
|---|---|
| `skills/` | 共有スキル |
| `mcp/servers.json` | 共有 MCP サーバ定義（git / slack） |
| `setup.sh` | 全員で使うもの（MCP・ツール・設定）をプロジェクトに適用/同期するスクリプト |

同梱スキル（`skills/`）:

| スキル | 用途 |
|---|---|
| `sync-project-setup` | インストール/設定/MCP を「全員向け」に展開する流れ（展開可否を確認 → setup.sh 等に記録 → develop へ） |
| `sync-skills` | あるディレクトリの `.claude/skills` を別プロジェクトへ同期（追加/上書き、`--mirror`、`--dry-run`） |

`setup.sh` が現状セットアップするもの:

- **git MCP** … `uvx mcp-server-git`（前提: [uv](https://docs.astral.sh/uv/)）
- **slack MCP** … `npx -y @modelcontextprotocol/server-slack`（前提: node/npx、環境変数 `SLACK_BOT_TOKEN` / `SLACK_TEAM_ID`）

## セットアップ手順

1. このリポジトリをプロジェクト直下に `.claude` として配置する

   ```bash
   git clone https://github.com/kana-tanaka/.claude.git <project>/.claude
   ```

2. プロジェクトルートでセットアップを実行する

   ```bash
   cd <project>
   bash .claude/setup.sh        # <project>/.mcp.json を作成/同期する
   ```

   > `.mcp.json` は Claude Code が**プロジェクトルート**で読む共有 MCP 設定です。
   > `.claude/` の中では読まれないため、setup.sh が親（プロジェクトルート）に配置します。

3. 前提を整える

   ```bash
   export SLACK_BOT_TOKEN=xoxb-xxxx   # slack 用
   export SLACK_TEAM_ID=T0xxxx
   # git 用に uv が未導入なら: https://docs.astral.sh/uv/
   ```

4. プロジェクトルートで `claude` を起動し、表示される MCP サーバの承認を許可する
   （確認: `claude mcp list`）

## 設定変更を同期する（sync）

MCP やツール、設定を更新したら、最新を取り込んで `setup.sh` を再実行するだけで同期されます。

```bash
git -C .claude pull
bash .claude/setup.sh
```

`setup.sh` は冪等なので何度実行しても安全です。既存の `.mcp.json` には（jq があれば）他のサーバを残したままマージします。

## 全員に展開したいものを追加するには

新しく「全員で使えるようにしたい」ものが出たら `.claude` リポジトリ側に記録します（変更は `develop` ブランチへ）。

- **MCP サーバ** → `mcp/servers.json` を編集（`setup.sh` の `sync_mcp` が自動同期）
- **インストールが要るツール** → `setup.sh` の `install_tools()` に冪等なコマンドを追記
- **その他の設定** → `setup.sh` の `apply_settings()` に追記
- **スキル** → `skills/` に追加

この流れは `sync-project-setup` スキルが補助します。
