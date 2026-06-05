#!/bin/bash
# copy.sh - скрипт для копирования файлов.
#           Два режима копирования:
#               1) Полное;
#               2) Выборочное.

declare -i modeNum=

msg "Выберите режим копирования:\n0) Отмена;\n1) Полное;\n2) Выборочное\n"
read -rp "Введите число: " modeNum

function allCopy {
    local rsync_mode=
    case $MSG_MODE in
    0)
        rsync_mode="-avh --progress --info=progress2 --stats --log-file $LOG_FILE"
        ;;
    1)
        rsync_mode="-a --quiet --stats --log-file $LOG_FILE"
        ;;
    esac
    rsync $rsync_mode "$PATH_SOURCE" "$PATH_DESTIN"
    return $?
}

while true; do
    case "$modeNum" in
    0)
        msg "Отмена копирования..."
        exit 1
        ;;
    1)
        msg "\nPROC: Полное копирование\n"
        #Проверка свободного места
        allCopy
        if [[ $? -eq 0 ]]; then
            msg "\nOK: Копирование завершено\n"
            exit 0
        else
            msg "\nERROR: Копирование завершено c ошибкой\n"
            exit 1
        fi
        ;;
    2)
        msg "Выборочное копирование"
        exit 0
        ;;
    *)
        msg "\nERROR: Введите число из указанного диапазона"
        read -rp "Введите число: " modeNum
        ;;
    esac
done
