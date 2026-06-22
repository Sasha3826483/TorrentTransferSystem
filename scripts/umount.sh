#!/bin/bash
# umount.sh - размонтирование подключенного диска

sudo umount -v UUID="$UUID_SSD" &>>"$LOG_FILE"

if [[ $? -eq 0 ]]; then
    msg "OK: диск отключен"
    exit 0
else
    msg "ERROR: ошибка отключения диска (см лог)"
    exit 1
fi
