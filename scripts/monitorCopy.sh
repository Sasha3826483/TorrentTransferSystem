#!/bin/bash
# monitorTimeCopy - вычисляет время копирования файла

declare -r fileName="$1"

declare speed=0

declare sizePoint1=0
declare sizePoint2=0
declare timeElaps=0
declare timeRemain=0
declare dSize=0

declare -r fileSizeSource=$(du -b $PATH_SOURCE/"$fileName" 2>/dev/null | cut -f1)
declare fileSizeDestin=0
declare copyProcPerc=0

function formatTime() {
    local sec=$1
    local min=0
    local rem=0

    min=$((sec / 60))
    rem=$((sec % 60))

    printf "%02d:%02d" "$min" "$rem"
}

while true; do

    # Определяем процент завершения копирования
    fileSizeDestin=$(du -b $PATH_DESTIN/"$fileName" 2>/dev/null | cut -f1)
    copyProcPerc=$(echo "scale=1; $fileSizeDestin * 100 / $fileSizeSource" | bc -l)

    # Определяем скорость копирования
    timeElaps=0.5
    sizePoint1=$(du -b $PATH_DESTIN/"$fileName" | cut -f1)
    sleep $timeElaps
    sizePoint2=$(du -b $PATH_DESTIN/"$fileName" | cut -f1)

    dSize=$((sizePoint2 - sizePoint1))
    speed=$(echo "scale=0; $dSize / $timeElaps" | bc -l)

    if ((speed > 0)); then
        timeRemain=$(((fileSizeSource - sizePoint2) / speed))
    else
        timeRemain=0
    fi

    mosquitto_pub -t tts/copyProcTimeRemain -m "$(formatTime "$timeRemain")"
    mosquitto_pub -t tts/copyProcSpeedWrite -m "$(echo "scale=0; $speed / 1024 / 1024" | bc -l)"
    mosquitto_pub -t tts/copyProcFileName -m "$fileName"
    mosquitto_pub -t tts/copyProcPerc -m "$copyProcPerc"
done
