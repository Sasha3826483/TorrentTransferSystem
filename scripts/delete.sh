#!/bin/bash
# delete.sh - скрипт для удаления файлов с подключенного диска:
#   1) Полностью
#   2) Частично

declare -a selectedFiles=()
declare -a selectedIndexes=()
declare availableSpaceHuman=0

function deleteFiles {
    local exitStatus=0
    for file in "$@"; do
        rm -rf "$file" &>>$LOG_FILE
        if (($? != 0)); then
            msg "ERROR: Ошибка удаления файла $(basename "$file") (см лог)"
            exitStatus=1
        fi
    done
    case "$exitStatus" in
    0)
        availableSpaceHuman=$(df --output=avail -h $PATH_DESTIN | tail -n1)
        msg "OK: Выбранные файлы удалены. Доступно: $availableSpaceHuman"
        ;;
    *)
        msg "ERROR: Прошизошла ошибка во время удаления файлов (см лог)"
        ;;
    esac
    return $exitStatus
}

mapfile -t files < <(find "$PATH_DESTIN" -maxdepth 1)

# Удаляем первый элемент (сам каталог) и переиндексируем массив
unset 'files[0]'
files=("${files[@]}")

if ((${#files[@]} == 0)); then
    log "Нет файлов для удаления"
    msg "ATT: Нет файлов для удаления. Отмена удаления"
    exit 99
else
    for i in "${!files[@]}"; do
        fileList+="    $(
            printf "%d) %s %s" \
                "$((i + 1))" \
                "$(basename \
                    "${files[$i]}")" \
                "$(du -h "${files[$i]}" | cut -f 1)"
        )
"
    done
    fileList+="   *) TOTAL $(du -sh $PATH_DESTIN | cut -f 1)"
fi

while true; do

    availableSpaceHuman=$(df --output=avail -h $PATH_DESTIN | tail -n1)

    if (($TERM_MODE == 0)); then
        msg "MSG: Доступные для удаления файлы:
$fileList

MSG: Свободно места на диске: $availableSpaceHuman

INPUT: Выберите действие:
    0) Удалить все файлы;
    1) Выбрать файлы;
    2) Отмена"
    else
        msg "MSG: Доступные для удаления файлы:
$fileList

MSG: Свободно места на диске: $availableSpaceHuman"
    fi

    modeNum=$(input "Ввод: ")

    case "$modeNum" in
    0)
        deleteFiles "${files[@]}"
        exit $?
        ;;
    1)
        msg "MSG: Доступные файлы:
$fileList

MSG: Свободно места на диске: $availableSpaceHuman

INPUT: Введите номера файлов (через пробел, 0 - отмена):"

        selectedIndexes=($(input))

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
            msg "INPUT: Введите номера файлов (через пробел, 0 - отмена):"
            selectedIndexes=($(input "Ввод: "))
        done
        deleteFiles "${selectedFiles[@]}"
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
