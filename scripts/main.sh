#!/bin/bash
# main.sh - скрипт-оркестратор: монтирует диск, копирует данные и размонтирует диск

# Объявляем "глобальные" переменные
declare -xr PATH_TO_PRJ="$(git rev-parse --show-toplevel)"
declare -xr PATH_TO_PRJ_SCRIPT="$PATH_TO_PRJ/scripts"
declare -xr LOG_FILE="$PATH_TO_PRJ/scripts/system.log"
declare -xr MOUNT_POINT="/mnt/ext-nvme"
declare -xr TERM_MODE=$(test -t 0 && echo 0 || echo 1) # 0 = работа в терминале; 1 = без терминала
declare -xi MSG_MODE=
declare -xr PATH_SOURCE="/mnt/int-nvme/data-transmission-daemon/complete/"
# declare -xr PATH_DESTIN="$PATH_TO_PRJ/scripts/testDirOutputMnt/"
declare -xr PATH_DESTIN="/mnt/ext-nvme/"
declare -xr UUID_SSD="DE8497A484977E29" # UUID подключаемого диска

declare modeNum=0

# Три режима отправки сообщений:
#   0) Сообщения в терминале + уведомления по сети
#   1) Только сообщения в терминале
#   2) Только сообщения по сети

if (("$TERM_MODE" == 0)); then
    echo -e "Включить уведомления(y/n)?"
    read -rp "Ввод: " answ
    while true; do
        case "$answ" in
        "y")
            MSG_MODE=0
            break
            ;;
        "n")
            MSG_MODE=1
            break
            ;;
        *)
            echo -e "ERROR: неправильный формат ввода. Введите y или n"
            read -rp "Ввод: " answ
            ;;
        esac
    done
else
    MSG_MODE=2
fi

function log {
    echo -e "\n" >>"$LOG_FILE"
    echo -e "$1" >>"$LOG_FILE"
}

function msg {
    case "$MSG_MODE" in
    0)
        echo -e "\n$1"
        if [[ "$1" =~ \[[0-9]+/[0-9]+\] ]]; then
            mosquitto_pub \
                -h localhost \
                -p 1883 \
                -t "tts/msg" \
                -m "$1"
            sleep 2
        fi
        ;;
    1)
        echo -e "\n$1"
        ;;
    2)
        mosquitto_pub \
            -h localhost \
            -p 1883 \
            -t "tts/msg" \
            -m "$1"
        sleep 2
        ;;
    esac
}

# Два режима ввода:
#   1) Ввод в окне терминала, если система запущена из терминала (даже
#       если включены сообщения через MQTT-брокера)
#   2) Ввод через MQTT-брокера, если система запущена через systemd

function input {
    local inp=
    if (("$TERM_MODE" == 0)); then
        read -rp "$1" inp
    else
        inp="$(mosquitto_sub -t "tts/reply" -C 1)" # --timeout 30  - не работает
        # if [[ $? -ne 0 ]]; then
        #     inp=3
        # fi
    fi
    echo "$inp"
}

export -f msg
export -f input
export -f log

# Фиксируем дату запуска
echo -e "----------------------------------------------------" >>"$LOG_FILE"
echo "Дата: $(date)" >>"$LOG_FILE"

log "PROC: mount.sh =>"
"$PATH_TO_PRJ_SCRIPT"/mount.sh || exit 1

while true; do
    msg "INPUT: Выберите действие:
    0) Копирование;
    1) Удаление;
    2) Выход"
    modeNum="$(input "Ввод: ")"

    case "$modeNum" in
    0)
        log "PROC: copy.sh =>"
        "$PATH_TO_PRJ_SCRIPT"/copy.sh

        case $? in
        0)
            log "OK_COPY => PROC: umount.sh =>"
            break
            ;;
        99)
            log "CANCEL_COPY =>"
            continue
            ;;
        *)
            log "ERROR_COPY => PROC: umount.sh =>"
            break
            ;;
        esac
        ;;
    1)
        log "PROC: delete.sh =>"
        "$PATH_TO_PRJ_SCRIPT"/delete.sh

        case $? in
        0)
            log "OK_DELETE"
            continue
            ;;
        99)
            log "CANCEL_DELETE =>"
            continue
            ;;
        *)
            log "ERROR_DELETE => PROC: umount.sh =>"
            break
            ;;
        esac
        ;;
    2)
        log "EXIT => PROC: umount.sh"
        break
        ;;
    *)
        msg "ATT: Неверный ввод"
        ;;
    esac
done

"$PATH_TO_PRJ_SCRIPT"/umount.sh
exit $?
