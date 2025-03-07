#!/usr/bin/env bash

cd "$(realpath "$(dirname "$0")")"/.. || exit
if [ "$(date -u '+%H')" = "00" ] && [ "$(date -u '+%M')" = "00" ]; then
    cp "$MYAOOGLE/data/sub.txt" "$MYAOOGLE/data/share/log/sub$(date -u '+%Y%m%d').txt"
    echo "" > "$MYAOOGLE/data/sub.txt"
    hash=$(ipfs add -r --nocopy -Q "$MYAOOGLE/data/share/log")
    ipfspub $hash
fi
