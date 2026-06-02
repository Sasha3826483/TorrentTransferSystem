#!/bin/bash
# mount.sh - монтирование подключенного диска

declare -r PATH_TO_PRJ="/home/user/torrent-throw-system/"
declare -r LOG_FILE="$PATH_TO_PRJ/scripts/system.log"
declare -r MOUNT_POINT="/mnt/testDisk"

if findmnt -v "$MOUNT_POINT" &>>$LOG_FILE; then
    $PATH_TO_PRJ/scripts/msg.sh \
        "ATT: storage device is already mounted"
    exit 0
else
    if sudo mount -vo loop $PATH_TO_PRJ/debug/vdisk.img \
        "$MOUNT_POINT" &>>"$LOG_FILE"; then
        $PATH_TO_PRJ/scripts/msg.sh \
            "OK: SEXessful mounting"
        exit 0
    else
        $PATH_TO_PRJ/scripts/msg.sh \
            "ERROR: mounting failed (system.log)"
        exit 1
    fi
fi
