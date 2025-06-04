#!/bin/bash
DEST_DIR="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}/"
cd "$DEST_DIR"
function unpack() {
    FILENAME=$1
    7z x $FILENAME || unrar x $FILENAME
}
export -f unpack
find . -name '*.rar' -exec bash -c 'unpack "$@"' bash {}  \;
