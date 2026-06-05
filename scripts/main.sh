#!/bin/bash
# main.sh - скрипт-оркестратор: монтирует диск, копирует данные и размонтирует диск

# Объявляем "глабальные" переменные
declare -xr PATH_TO_PRJ="$(git rev-parse --show-toplevel)"
declare -xr LOG_FILE="$PATH_TO_PRJ/scripts/system.log"
declare -xr MOUNT_POINT="/mnt/testDisk"
declare -xri MSG_MODE="$([ -t 0 ])"
declare -xr PATH_SOURCE="$PATH_TO_PRJ/scripts/testDirInput/"
declare -xr PATH_DESTIN="$PATH_TO_PRJ/scripts/testDirOutput"

function log {
    echo -e "\n" >>$LOG_FILE
    echo -e "$1" >>$LOG_FILE
}

function msg {
    $PATH_TO_PRJ/scripts/msg.sh $MSG_MODE "$1"
    return
}

function mount {
    $PATH_TO_PRJ/scripts/mount.sh
    return
}

function copy {
    $PATH_TO_PRJ/scripts/copy.sh
    return
}

function umount {
    $PATH_TO_PRJ/scripts/umount.sh
    return
}

export -f msg

# Фиксируем дату запуска
echo -e "----------------------------------------------------" >>$LOG_FILE
echo "Дата: $(date)" >>$LOG_FILE

log "mount.sh =>"
mount

log "copy.sh =>"
copy

log "umount.sh =>"
umount
