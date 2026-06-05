#!/bin/bash
# umount.sh - размонтирование подключенного диска

if ! findmnt "$MOUNT_POINT" &>>$LOG_FILE; then
    msg "ATT: storage device is already unmounted\n"
    exit 0
else
    if sudo umount -v "$MOUNT_POINT" &>>"$LOG_FILE"; then
        msg "OK: SEXessful unmounting\n"
        exit 0
    else
        msg "ERROR: unmounting failed (system.log)\n"
        exit 1
    fi
fi
