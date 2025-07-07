#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob nocaseglob extglob
IFS=$'\n\t'

TORRENT_PATH="${TR_TORRENT_DIR:-}/${TR_TORRENT_NAME:-}"

unpack() {
  local f=$1
  printf '→ %s\n' "$f"
  if 7z x -aoa -y -spe -- "$f"; then
    return 0
  fi
  local rc=$?
  (( rc == 1 )) && return 0
  printf '7z failed (rc=%d); swapping to unrar...\n' "$rc" >&2
  unrar x -o+ -idq -- "$f" || true
}

archives=()

# ── harvest archives
if [[ -d $TORRENT_PATH ]]; then
  while IFS= read -r -d '' f; do
    base=$(basename -- "$f")
    lf=${base,,}
    part_no=

    # one-shot formats
    case $lf in
      *.tar|*.tar.*|*.tgz|*.tbz2|*.txz) archives+=("$f"); continue ;;
    esac

    # RAR bundle
    case $lf in
      *.part*[0-9].rar)
        part_no=${lf##*.part}; part_no=${part_no%%.rar}; part_no=${part_no##*(0)}
        [[ $part_no = 1 ]] && archives+=("$f"); continue ;;
      *.r[0-9][0-9]) continue ;;
      *.rar) archives+=("$f"); continue ;;
    esac

    # 7-Zip multi-vol
    case $lf in
      *.7z.[0-9]*) [[ $lf = *.7z.0*1 ]] && archives+=("$f"); continue ;;
      *.7z)        archives+=("$f"); continue ;;
    esac

    # ZIP circus
    case $lf in
      *.zip.[0-9]*) [[ $lf = *.zip.0*1 ]] && archives+=("$f"); continue ;;
      *.part*[0-9].zip)
        part_no=${lf##*.part}; part_no=${part_no%%.zip}; part_no=${part_no##*(0)}
        [[ $part_no = 1 ]] && archives+=("$f"); continue ;;
      *.z[0-9][0-9]) continue ;;
      *.zip) archives+=("$f"); continue ;;
    esac
  done < <(find "$TORRENT_PATH" -type f -print0)

elif [[ -f $TORRENT_PATH ]]; then
  case "${TORRENT_PATH,,}" in
    *.zip|*.rar|*.7z|*.tar|*.tar.*|*.tgz|*.tbz2|*.txz)
      archives+=("$TORRENT_PATH") ;;
  esac
fi

(( ${#archives[@]} == 0 )) && exit 0

printf '=== %s extracting %s\n' "$(date '+%F %T')" "${TR_TORRENT_NAME:-unknown}"
for f in "${archives[@]}"; do
  (
    dir=$(dirname -- "$f")
    base=$(basename -- "$f")
    cd -- "$dir" && unpack "$base"
  )
done
