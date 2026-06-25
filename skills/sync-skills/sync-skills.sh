#!/usr/bin/env bash
#
# 別ディレクトリの .claude/skills 配下のスキルを、別プロジェクトの .claude/skills へ同期する。
#
# 使い方:
#   bash sync-skills.sh [オプション] <SOURCE> <TARGET> [スキル名...]
#
#   <SOURCE>  同期元。プロジェクトroot（.claude/skills を持つ）か、.claude/skills ディレクトリ自体。
#   <TARGET>  同期先。プロジェクトroot（無ければ .claude/skills を作成）か、.claude/skills ディレクトリ。
#   スキル名   省略時は全スキル。指定するとそのスキルのみ同期。
#
# オプション:
#   -n, --dry-run   実際にはコピーせず、何が起きるかだけ表示
#   --mirror        同期先にあって同期元に無いスキルを削除（完全ミラー）。既定は追加/上書きのみ。
#   -h, --help      このヘルプ
#
set -euo pipefail

DRY_RUN=0
MIRROR=0
POSITIONAL=()

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    --mirror)     MIRROR=1; shift ;;
    -h|--help)    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do POSITIONAL+=("$1"); shift; done ;;
    -*) echo "✗ 不明なオプション: $1" >&2; exit 2 ;;
    *)  POSITIONAL+=("$1"); shift ;;
  esac
done

if [ "${#POSITIONAL[@]}" -lt 2 ]; then
  echo "✗ SOURCE と TARGET を指定してください。 -h でヘルプ。" >&2
  exit 2
fi

SRC_ARG="${POSITIONAL[0]}"
TGT_ARG="${POSITIONAL[1]}"
NAMES=("${POSITIONAL[@]:2}")

# --- 同期元の skills ディレクトリを解決 --------------------------------------
resolve_src_skills() {
  local p="$1"
  if [ -d "$p/.claude/skills" ]; then echo "$p/.claude/skills"; return 0; fi
  if [ -d "$p/skills" ] && [ "$(basename "$p")" = ".claude" ]; then echo "$p/skills"; return 0; fi
  if [ -d "$p" ] && [ "$(basename "$p")" = "skills" ]; then echo "$p"; return 0; fi
  return 1
}

# --- 同期先の skills ディレクトリを解決（無ければ作る前提のパスを返す） ------
resolve_tgt_skills() {
  local p="$1"
  case "$(basename "$p")" in
    skills)  echo "$p" ;;
    .claude) echo "$p/skills" ;;
    *)       echo "$p/.claude/skills" ;;
  esac
}

SRC_SKILLS="$(resolve_src_skills "$SRC_ARG")" || {
  echo "✗ 同期元に .claude/skills が見つかりません: $SRC_ARG" >&2; exit 1;
}
SRC_SKILLS="$(cd "$SRC_SKILLS" && pwd)"
TGT_SKILLS="$(resolve_tgt_skills "$TGT_ARG")"

# --- 同期対象スキルの一覧 ----------------------------------------------------
if [ "${#NAMES[@]}" -eq 0 ]; then
  while IFS= read -r d; do NAMES+=("$(basename "$d")"); done \
    < <(find "$SRC_SKILLS" -mindepth 1 -maxdepth 1 -type d | sort)
fi
if [ "${#NAMES[@]}" -eq 0 ]; then
  echo "✗ 同期元にスキルがありません: $SRC_SKILLS" >&2; exit 1
fi

echo "同期元: $SRC_SKILLS"
echo "同期先: $TGT_SKILLS"
echo "対象:   ${NAMES[*]}"
[ "$DRY_RUN" -eq 1 ] && echo "(dry-run: 変更は行いません)"
echo

have_rsync=0; command -v rsync >/dev/null 2>&1 && have_rsync=1

[ "$DRY_RUN" -eq 0 ] && mkdir -p "$TGT_SKILLS"

# --- 各スキルをコピー/更新 ---------------------------------------------------
for name in "${NAMES[@]}"; do
  s="$SRC_SKILLS/$name"
  if [ ! -d "$s" ]; then
    echo "⚠ スキップ（同期元に存在しない）: $name" >&2; continue
  fi
  t="$TGT_SKILLS/$name"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "→ 同期予定: $name"; continue
  fi
  if [ "$have_rsync" -eq 1 ]; then
    rsync -a --delete "$s/" "$t/"
  else
    rm -rf "$t"; mkdir -p "$t"; cp -a "$s/." "$t/"
  fi
  echo "✓ 同期: $name"
done

# --- mirror: 同期元に無いスキルを同期先から削除 ------------------------------
if [ "$MIRROR" -eq 1 ] && [ -d "$TGT_SKILLS" ]; then
  while IFS= read -r d; do
    n="$(basename "$d")"
    if [ ! -d "$SRC_SKILLS/$n" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "→ 削除予定（mirror）: $n"
      else
        rm -rf "$d"; echo "✗ 削除（mirror）: $n"
      fi
    fi
  done < <(find "$TGT_SKILLS" -mindepth 1 -maxdepth 1 -type d | sort)
fi

echo
echo "完了。"
