#!/bin/bash
# monitorSize.sh - определяет процесс завершения процесса копирования в %

# function cleanup() {
#     mosquitto_pub -t tts/copyProcPerc -m "777"
# }
#
# trap cleanup TERM

# declare -r FILE_NAME=$(cat "/home/user/torrent-throw-system/scripts/fileName.txt")
declare -r FILE_NAME="$1"
declare -r INP=$(du -b /mnt/int-nvme/data-transmission-daemon/complete/"$FILE_NAME" 2>/dev/null | cut -f1)

declare out=0
declare result=0

while true; do

    out=$(du -b /mnt/ext-nvme/"$FILE_NAME" 2>/dev/null | cut -f1)

    if [[ -z $FILE_NAME ]]; then
        result=0
    else
        result=$(echo "scale=1; $out * 100 / $INP" | bc -l)
    fi

    mosquitto_pub -t tts/copyProcPerc -m "$result"

    sleep 1

done
