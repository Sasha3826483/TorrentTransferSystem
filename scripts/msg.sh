#!/bin/bash
# msg.sh - используется для отправки уведомлений либо в терминал, если процесс запущен из терминала, либо удаленно, если процесс запущен из systemd

if [ "$1" -eq 0 ]; then
    echo -e "$2"
else
    echo "$2" >$PATH_TO_PRJ/scripts/externMsg
fi
