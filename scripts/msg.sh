#!/bin/bash
# msg.sh - используется для отправки уведомлений либо в терминал, если процесс запущен из терминала, либо удаленно, если процесс запущен из systemd

declare -r PATH_TO_PRJ="/home/user/torrent-throw-system/"

if [ -t 0 ]; then
    echo "$1"
else
    echo "$1" >$PATH_TO_PRJ/scripts/externMsg
fi
