#!/bin/bash
# mount.sh - монтирование подключенного диска
# заметка1: при запуске из systemd findmnt не находит смонтированный диск, но это не важно, потому что в такой ситуации он и так не может быть смонтирован заранее

if findmnt -v UUID="$UUID_SSD" &>>"$LOG_FILE"; then
    msg "ATT: подключенный диск уже смонтирован"
    exit 0
else
    sudo mount -v \
        UUID="$UUID_SSD" \
        $MOUNT_POINT \
        &>>"$LOG_FILE"

    if [[ $? -eq 0 ]]; then
        msg "OK: SEXessful mounting"
        exit 0
    else
        msg "ERROR: ошибка монтирования дика (см лог)"
        exit 1
    fi
fi
