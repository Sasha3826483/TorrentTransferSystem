#!/bin/bash
# main.sh - скрипт-оркестратор: монтирует диск, копирует данные и размонтирует диск

declare -r PATH_TO_PRJ="/home/user/torrent-throw-system/"
declare -r LOG_FILE="$PATH_TO_PRJ/scripts/system.log"

echo "Дата: $(date)" >>$LOG_FILE

$PATH_TO_PRJ/scripts/mount.sh

# $PATH_TO_PRJ/scripts/umount.sh

echo -e "\n" >>$LOG_FILE
