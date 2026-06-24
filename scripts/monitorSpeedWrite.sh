#!/bin/bash
# monitorSpeedWrite.sh - определяет скорость записи на подключенный диск

while true; do

    declare speed=0

    speed="$(sudo iotop -obn1 2>/dev/null | grep cp | awk 'NR==1 {print $6}')"

    if [[ -z $speed ]]; then
        speed=0
    fi

    mosquitto_pub -t tts/speedWrite -m "$speed"

    sleep 0.5

done
