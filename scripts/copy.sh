#!/bin/bash
# copy.sh - скрипт для копирования файлов.

declare -r availableSpace=$(df --output=avail -B1 $PATH_DESTIN | tail -n1)
declare -r usedSpace=$(df --output=used -B1 $PATH_DESTIN | tail -n1)

declare -a selectedFiles=()
declare -a selectedIndexes=()
declare -i modeNum=0
declare availableSpaceHuman=0

function copyFiles {
    local exitStatus
    local -r total="$#"
    local current=0
    local torrentId=0
    local monitorCopyPid=0

    for file in "${@}"; do
        ((current++))
        msg "PROC: копирование файла [$current/$total] $(basename "$file") - $(du -h "$file" | cut -f 1)"

        mosquitto_pub -t tts/copyProcNumFile -m "[$current/$total]"
        mosquitto_pub -t tts/copyProcFileSize -m "$(du -h "$file" | cut -f 1)"

        if (($TERM_MODE != 0)); then
            $PATH_TO_PRJ_SCRIPT/monitorCopy.sh "$(basename "$file")" &>>$LOG_FILE &
            monitorCopyPid=$!
        fi

        # Копируем разными способами:
        #   1) rsync для информативного мониторинга во время копирования
        #   2) cp для работы скрипта monitorSize.sh (см обсидиан или README, хз
        #       не записал еще никуда)
        if (($TERM_MODE == 0)); then
            sudo rsync -avhr \
                --progress \
                --log-file "$LOG_FILE" \
                "$file" \
                "$PATH_DESTIN"
        else
            cp -rp "$file" "$PATH_DESTIN" &>>"$LOG_FILE"
        fi

        exitStatus=$?

        # Убиваем мониторинг процесса копирования текущего файла
        if (($TERM_MODE != 0)); then
            kill "$monitorCopyPid" 2>/dev/null
            mosquitto_pub -t tts/copyProcPerc -m "0"
            mosquitto_pub -t tts/copyProcFileName -m "nothing"
            mosquitto_pub -t tts/copyProcSpeedWrite -m "0"
            mosquitto_pub -t tts/copyProcFileSize -m "0 gb"
        fi

        if (($exitStatus == 0)); then
            msg "OK: файл [$current/$total] $(basename "$file") скопирован"
            torrentId=$(transmission-remote -l |
                grep "$(basename "$file")" | awk '{print $1}')
            transmission-remote -t $torrentId --remove-and-delete
        else
            msg "ERROR: ошибка при копировании [$current/$total] $(basename "$file")"
            break
        fi
    done

    mosquitto_pub -t tts/copyProcNumFile -m "[0/0]"

    case "$exitStatus" in
    0)
        # msg "OK: Все файлы успешно скопированы"
        ;;
    20)
        msg "ATT: Отмена копирования (crl-c)"
        ;;
    23)
        msg "ERROR: Часть файлов не скопировлась (см лог)"
        ;;
    11)
        msg "ERROR: Ошибка чтения/записи (см лог)"
        ;;
    *)
        msg "ERROR: Неизвестная ошибка копирования файлов (см лог)"
        ;;
    esac
    return $exitStatus
}

function checkAvailCopy {
    local requiredSpace=0 # сколько места занимают выбранные для копирования файлы
    local requiredSpaceHuman=0
    local size=0

    for file in "$@"; do
        size=$(du -sb "$file" | cut -f 1)
        ((requiredSpace += size))
    done

    if ((availableSpace >= requiredSpace)); then
        return 0
    else
        if [[ $(($requiredSpace - $availableSpace)) -le $usedSpace ]]; then
            msg "ATT: Недостаточно места на диске. Необходимо удалить $(echo "scale=2; ($requiredSpace - $availableSpace) / 1073741824" | bc -l) ГБ текущих файлов"
        else
            requiredSpaceHuman="$(echo "scale=1; ($requiredSpace / 1073741824)" | bc -l)"
            msg "ATT: Невозможно скопировать все файлы. Размер всех файлов $requiredSpaceHuman ГБ"
        fi
        return 1
    fi
}

mapfile -t files < <(find "$PATH_SOURCE" -maxdepth 1)

# Удаляем первый элемент (сам каталог) и переиндексируем массив
unset 'files[0]'
files=("${files[@]}")

if ((${#files[@]} == 0)); then
    log "Нет файлов для копирования"
    msg "ATT: Нет файлов для копирования"
    exit 99
else
    for i in "${!files[@]}"; do
        fileList+="   $(
            printf "%d) %s %s" \
                "$((i + 1))" \
                "$(basename "${files[$i]}")" \
                "$(du -h "${files[$i]}" | cut -f 1)"
        );
"
    done
    fileList+="   *) TOTAL $(du -sh "$PATH_SOURCE" | cut -f 1)"
fi

while true; do
    availableSpaceHuman=$(df --output=avail -h $PATH_DESTIN | tail -n1)

    if (($TERM_MODE == 0)); then
        msg "MSG: Доступные для копирования файлы:
$fileList

MSG: Доступно $availableSpaceHuman

INPUT: Выберите действие:
    0) Скопировать все файлы;
    1) Выбрать файлы;
    2) Назад"
    else
        msg "MSG: Доступные для копирования файлы:
$fileList

MSG: Доступно $availableSpaceHuman"
    fi

    modeNum=$(input "Ввод: ")

    case $modeNum in
    0)
        selectedFiles=("${files[@]}")

        if ! checkAvailCopy "${selectedFiles[@]}"; then
            log "Недостаточно места на диске"
            modeNum=3
            continue
        fi

        copyFiles "${selectedFiles[@]}"
        exit $?
        ;;
    1)
        msg "MSG: Доступные файлы:
$fileList

MSG: Доступно $availableSpaceHuman

INPUT: Введите номера файлов (через пробел, 0 - отмена): "
        selectedIndexes=($(input "Ввод: "))

        while true; do
            selectedFiles=()
            valid=true
            for index in "${selectedIndexes[@]}"; do
                if ((index >= 1 && index <= ${#files[@]})); then
                    selectedFiles+=("${files[$((index - 1))]}")
                elif ((index == 0)); then
                    if [[ "$index" =~ ^[0-9]+$ ]]; then
                        modeNum=3
                        continue 3
                    else
                        msg "ATT: Неверный ввод (не является числом): $index"
                        valid=false
                        break
                    fi
                else
                    msg "ATT: Неверный ввод (недопустимое число): $index"
                    valid=false
                    break
                fi
            done
            $valid && break
            msg "INPUT: Введите номера файлов (через пробел, 0 - отмена): "
            selectedIndexes=($(input "Ввод: "))
        done

        if ! checkAvailCopy "${selectedFiles[@]}"; then
            log "Недостаточно места на диске"
            modeNum=3
            continue
        fi

        copyFiles "${selectedFiles[@]}"
        exit $?
        ;;
    2)
        exit 99
        ;;
    *)
        msg "ATT: Неверный ввод"
        ;;
    esac
done
