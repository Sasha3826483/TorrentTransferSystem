#!/bin/bash
# umount.sh - размонтирование подключенного диска

declare -r PATH_TO_PRJ="/home/user/torrent-throw-system/"
declare -r LOG_FILE="$PATH_TO_PRJ/scripts/system.log"
declare -r MOUNT_POINT="/mnt/testDisk"

if ! findmnt "$MOUNT_POINT" 2>>$LOG_FILE; then
    $PATH_TO_PRJ/scripts/msg.sh \
        "ATT: storage device is already unmounted"
    exit 0
else
    if sudo unmount "$MOUNT_POINT" 2>>"$LOG_FILE"; then
        $PATH_TO_PRJ/scripts/msg.sh \
            "OK: SEXessful unmounting"
        exit 0
    else
        $PATH_TO_PRJ/scripts/msg.sh \
            "ERROR: unmounting failed (system.log)"
        exit 1
    fi
fi
