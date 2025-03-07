#!/usr/bin/env bash

cd "$(realpath "$(dirname "$0")")"/.. || exit
if [ "$(date -u '+%H')" = "00" ] && [ "$(date -u '+%M')" = "00" ]; then
    cp "$MYAOOGLE/data/sub.txt" "$MYAOOGLE/data/share/log/sub$(date -u '+%Y%m%d').txt"
    echo "" > "$MYAOOGLE/data/sub.txt"
    hash=$(ipfs add -r --nocopy -Q "$MYAOOGLE/data/share/log")
    ipfspub $hash
fi
if [ "$(date -u '+%M')" = "00" ] || [ "$(date -u '+%M')" = "30" ]; then
 execution_time=$( { time : > /dev/null 2>&1; } 2>&1 )
 real_time=$(echo "$execution_time" | grep real | awk '{print $2}')
 ipfspub "Ok! Halfhour execution time: $real_time"
fi
