---
name: sync-project-setup
description: Use when the user installs a tool/package, adds or changes an MCP server or Claude setting, or asks to make something usable "project-wide" / "for everyone" in this shared .claude repo. First confirms whether to share it with ALL repo users; if yes, records it so others sync by re-running setup.sh (MCP -> mcp/servers.json, installs -> setup.sh install_tools(), settings -> setup.sh apply_settings()), updates README, and commits to the develop branch.
---

# Sync project setup

This `.claude/` directory is a **shared config repo** (`kana-tanaka/.claude`) that teammates
place into their own projects. Anything meant for "everyone" must be recorded here so others
get it by re-running `setup.sh`.

## When to use

Trigger this whenever, in this workspace, the user:

- installs a tool/package and it might be needed by others,
- adds or changes an **MCP server** or a Claude setting,
- says things like「プロジェクト全体で使えるように」「全員が使えるように」.

## Steps

1. **Confirm sharing first.** Ask the user (AskUserQuestion) whether this should be available
   to **all** users of the repo, or kept local to this machine only.
   - If local only → do it locally and stop. Do not touch the repo.

2. **Record it so `setup.sh` re-run = sync.** Pick the right place:
   - **MCP server** → edit `.claude/mcp/servers.json` (synced to `<project>/.mcp.json` by `sync_mcp`).
   - **Tool/package install** → add an **idempotent** command to `install_tools()` in `.claude/setup.sh`
     (e.g. `command -v X >/dev/null || <install>`).
   - **Other Claude setting** → add to `apply_settings()` in `.claude/setup.sh`, or commit the
     relevant settings file.

3. **Update `.claude/README.md`** if the user-facing setup/prerequisites changed.

4. **Commit to the `develop` branch and push** (this repo uses `develop`).

## Notes

- `.mcp.json` is read from the **project root**, not from inside `.claude/`; that is why
  `setup.sh` writes to the parent directory.
- Keep `setup.sh` idempotent so re-running it simply syncs to the latest state.
- Never commit secrets. Reference them via env vars (e.g. `${SLACK_BOT_TOKEN}`).
