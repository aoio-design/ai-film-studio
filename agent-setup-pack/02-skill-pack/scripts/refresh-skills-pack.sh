#!/usr/bin/env bash
# =============================================================================
# refresh-skills-pack.sh — bring this skills pack up to the copy inside the image
# =============================================================================
# WHY THIS EXISTS
#
#   The studio and this pack are seeded onto the machine's own volume ONCE, at
#   first boot: 10-seed-config copies /seed/studio into place only when the
#   target is absent, so a restart never touches your work. That protection is
#   exactly why a pack update baked into a NEWER image cannot reach a machine
#   that is already installed — pulling the newer image does nothing by itself.
#
#   This script closes that gap, and it works offline, because the newer image is
#   already on disk:
#
#       /seed/studio/agent-setup-pack   ->   <your studio>/agent-setup-pack
#
#   New and changed files are copied. EVERY file that gets replaced is backed up
#   first, including any version you had edited, so nothing is lost. Nothing is
#   ever deleted, and files you added yourself are never touched. The output
#   names what changed, so the owner always sees what moved.
#
# USAGE
#   refresh-skills-pack.sh [--dry-run] [--studio] [--seed DIR] [--pack DIR]
#
#   (no flags)   refresh the skills pack only — the safe, normal case
#   --dry-run    report exactly what would change; change nothing
#   --studio     ALSO refresh the studio app code (app.py, templates/, static/,
#                scripts/, requirements.txt, start.sh, …). The studio needs a
#                restart afterwards, and if requirements.txt changed the venv
#                needs rebuilding — both are reported, never done silently.
#
# EXIT CODES
#   0  already current, or refreshed
#   1  could not run (no seed, no pack)
#   2  --dry-run and there is something to refresh
# =============================================================================

set -euo pipefail

DRY_RUN=0
WITH_STUDIO=0
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The script lives at <studio>/agent-setup-pack/02-skill-pack/scripts/, so paths
# are derived from the script itself rather than hard-coded: a buyer who moves
# the studio keeps a working script. Env overrides exist for odd layouts.
# Paths are resolved AFTER the options are parsed (see below): --pack has to be
# honoured before anything is derived from it, or the script can compare against —
# and write into — a completely different pack.
SEED_DIR="${SEED_DIR:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --studio)  WITH_STUDIO=1 ;;
    --seed)    SEED_DIR="${2:?--seed needs a directory}"; shift ;;
    --pack)    PACK_DIR="${2:?--pack needs a directory}"; shift ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done

# --- resolve the paths now that the options are known -------------------------
# Not before: deriving them from the script's own location first would ignore
# --pack and compare against whatever pack happens to sit next to the script.
if [ -z "${PACK_DIR:-}" ]; then
  PACK_DIR="$(cd "$SELF/../.." && pwd)"
fi
if [ ! -d "$PACK_DIR" ]; then
  echo "FAIL: no skills pack directory at $PACK_DIR"
  exit 1
fi
PACK_DIR="$(cd "$PACK_DIR" && pwd)"
STUDIO_DIR="${STUDIO_DIR:-$(cd "$PACK_DIR/.." && pwd)}"
if [ -z "${SEED_DIR:-}" ]; then
  SEED_DIR=/seed/studio
fi

if [ ! -d "$SEED_DIR" ]; then
  echo "FAIL: no image seed at $SEED_DIR — is this running inside the image?"
  exit 1
fi
SEED_PACK="$SEED_DIR/agent-setup-pack"
if [ ! -d "$SEED_PACK" ]; then
  echo "FAIL: the image seed has no agent-setup-pack at $SEED_PACK"
  exit 1
fi
if [ ! -d "$PACK_DIR" ]; then
  echo "FAIL: no skills pack at $PACK_DIR"
  exit 1
fi

# The one failure that could overwrite something real is comparing against the
# wrong tree, so refuse unless the target is actually a studio.
if [ ! -f "$STUDIO_DIR/app.py" ]; then
  echo "FAIL: $STUDIO_DIR does not look like a studio (no app.py there)."
  echo "      Pass --pack <path to agent-setup-pack> explicitly."
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$STUDIO_DIR/.pack-backups/$STAMP"

marker() {  # marker FILE -> prints one line describing the pack's ref
  local f="$1"
  if [ -f "$f" ]; then
    grep -m1 '^ref=' "$f" 2>/dev/null || echo "ref=unknown"
  else
    echo "ref=not recorded (installed before versions were)"
  fi
}

hash_of() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }

say() { printf '%s\n' "$*"; }

say "skills pack refresh"
say "  image copy (source): $(marker "$SEED_PACK/PACK-VERSION")"
say "                      $SEED_PACK"
say "  installed  (target): $(marker "$PACK_DIR/PACK-VERSION")"
say "                      $PACK_DIR"
if [ "$DRY_RUN" = 1 ]; then
  say "  mode: DRY RUN — nothing will be written"
fi
if [ "$WITH_STUDIO" = 1 ]; then
  say "  scope: the whole studio repo (app code included)"
fi

new=0
updated=0
same=0
failed=0
NEW_LIST=""
UPD_LIST=""

# Bookkeeping is not content: PACK-VERSION is rewritten by this script, and
# .git / backup directories are never compared.
while IFS= read -r -d '' src; do
  rel="${src#"$SEED_DIR"/}"
  if [ "$WITH_STUDIO" = 0 ]; then
    case "$rel" in
      agent-setup-pack/*) ;;
      *) continue ;;
    esac
  fi
  dst="$STUDIO_DIR/$rel"
  if [ ! -e "$dst" ]; then
    new=$((new + 1))
    NEW_LIST="$NEW_LIST$rel
"
    if [ "$DRY_RUN" = 0 ]; then
      mkdir -p "$(dirname "$dst")"
      if ! cp -p "$src" "$dst"; then
        failed=$((failed + 1)); say "  FAILED to copy $rel"
      fi
    fi
  elif [ "$(hash_of "$src")" != "$(hash_of "$dst")" ]; then
    updated=$((updated + 1))
    UPD_LIST="$UPD_LIST$rel
"
    if [ "$DRY_RUN" = 0 ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      if cp -p "$dst" "$BACKUP_DIR/$rel" && cp -p "$src" "$dst"; then
        :  # backed up, then replaced
      else
        failed=$((failed + 1)); say "  FAILED on $rel"
      fi
    fi
  else
    same=$((same + 1))
  fi
done < <(find "$SEED_DIR" -type f \
           ! -path '*/.git/*' ! -path '*/.pack-backups/*' \
           ! -name PACK-VERSION ! -name '.git' -print0 2>/dev/null)

# Record where this machine now stands, so the next run can tell.
if [ "$DRY_RUN" = 0 ] && [ -f "$SEED_PACK/PACK-VERSION" ]; then
  cp -p "$SEED_PACK/PACK-VERSION" "$PACK_DIR/PACK-VERSION" 2>/dev/null || true
fi

list_capped() {  # heading, newline-separated list
  local heading="$1" list="$2" n=0 line
  [ -z "$list" ] && return 0
  say "  $heading"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    n=$((n + 1))
    if [ "$n" -le 12 ]; then say "    $line"; fi
  done <<EOF
$list
EOF
  if [ "$n" -gt 12 ]; then say "    … and $((n - 12)) more"; fi
  return 0
}

say ""
say "  new files:       $new"
say "  updated files:   $updated"
say "  already current: $same"
if [ "$failed" -gt 0 ]; then
  say "  FAILED:          $failed  (see the lines above)"
fi

list_capped "new:" "$NEW_LIST"
list_capped "updated:" "$UPD_LIST"

if [ "$updated" -gt 0 ] && [ "$DRY_RUN" = 0 ]; then
  say "  every replaced file was backed up first, so any version you had —"
  say "  including your own edits — is still there:"
  say "    $BACKUP_DIR"
fi

if [ "$new" -gt 0 ] || [ "$updated" -gt 0 ]; then
  if [ "$DRY_RUN" = 1 ]; then
    say ""
    say "Dry run: nothing was changed. Re-run without --dry-run to apply."
    exit 2
  fi
  say ""
  say "Done. Skills are read when a session starts, so the next session already"
  say "has the updated pack — no restart needed."
fi

if [ "$WITH_STUDIO" = 1 ] && [ "$failed" -eq 0 ]; then
  say ""
  say "Because the studio app was included:"
  say "  1. restart the studio so the new code is running:"
  say "       pkill -f 'app/app[.]py'; nohup ./start.sh >/dev/null 2>&1 &"
  say "  2. if requirements.txt was among the updated files, rebuild the venv"
  say "     before that restart (report it, do not guess):"
  say "       ./.venv/bin/pip install -r requirements.txt"
fi

say ""
say "Report this to the owner in plain language: what changed, what was kept,"
say "and where the backup is. If nothing changed, say that in one line."
exit 0
