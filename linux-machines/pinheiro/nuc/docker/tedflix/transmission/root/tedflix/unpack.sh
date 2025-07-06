#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DEST_DIR="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}"
[[ -d $DEST_DIR ]] || { echo "Dir not found: $DEST_DIR" >&2; exit 1; }
cd -- "$DEST_DIR"

echo "=== $(date '+%F %T') extracting ${TR_TORRENT_NAME}"

unpack() {
    local f="$1"
    echo "→ $f"
    if ! 7z x -aoa -y -- "$f"; then
        local rc=$?
        (( rc > 1 )) && { echo "7z rc=$rc, swapping to unrar…" >&2; unrar x -o+ -idq -- "$f"; }
    fi
}
export -f unpack

# --- multi-part first volumes ---
find . -type f -iname '*.part0*1.rar' -print0 |
  sort -zu |
  xargs -0 -n1 bash -c 'unpack "$1"' _

# --- standalone archives (no .part*, no .r00) ---
find . -type f -iname '*.rar' ! -iname '*.part*' ! -regex '.*\.r[0-9][0-9]$' -print0 |
  sort -zu |
  xargs -0 -n1 bash -c 'unpack "$1"' _
