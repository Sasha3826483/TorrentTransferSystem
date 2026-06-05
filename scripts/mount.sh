#!/bin/bash
# mount.sh - монтирование подключенного диска

if findmnt -v "$MOUNT_POINT" &>>"$LOG_FILE"; then
    msg "\nATT: storage device is already mounted\n"
    exit 0
else
    if sudo mount -vo loop "$PATH_TO_PRJ"/debug/vdisk.img \
        "$MOUNT_POINT" &>>"$LOG_FILE"; then
        msg "\nOK: SEXessful mounting\n"
        exit 0
    else
        msg "\nERROR: mounting failed (system.log)\n"
        exit 1
    fi
fi
