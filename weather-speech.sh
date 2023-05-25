#!/bin/bash

cd $(dirname $0)
. ../lib/smarthome
. ../lib/speech

dstpath=$root/tmp
srcfile=$dstpath/weather
dstfile=$srcfile.wav
logfile=$root/log/weather-speech.log

exec >>"$logfile" 2>&1

windDir() {
    direction=$1

    if [ $direction == 'e' ]; then
        direction='восточный'
    else if [ $direction == 'w' ]; then
        direction='западный'
    else if [ $direction == 's' ]; then
        direction='южный'
    else if [ $direction == 'n' ]; then
        direction='северный'
    else if [ $direction == 'se' ]; then
        direction='юго-восточный'
    else if [ $direction == 'ne' ]; then
        direction='северо-восточный'
    else if [ $direction == 'sw' ]; then
        direction='юго-западный'
    else if [ $direction == 'nw' ]; then
        direction='северо-западный'
    fi fi fi fi fi fi fi fi

    echo $direction
}

getText() {
    echo -n "Внимание! Прослушайте информацию о погоде. "
    h=$(/bin/date '+%H' | sed 's/^0//')

    echo "hour: $h" >&2
    date >&2
    while [ $(cat "$srcfile" | wc -l) -lt 21 ]; do
        sleep 1
    done
    date >&2
    cat "$srcfile" >&2

    if [ $h -ge 6 -a $h -le 9 ]; then
        night=$(windDir $(head -n 7 "$srcfile" | tail -n 1))
        echo -n "Ночью температура воздуха была "$(digitToWord $night)" градус"$(wordSuffix $night)". "
    fi

    temp=$(head -n 1 "$srcfile" | sed 's/\..*//')
    weather=$(head -n 2 "$srcfile" | tail -n 1)
    pressure=$(head -n 3 "$srcfile" | tail -n 1 | sed 's/\..*//')
    wind=$(head -n 4 "$srcfile" | tail -n 1 | sed 's/\..*//')
    direction=$(windDir $(head -n 5 "$srcfile" | tail -n 1))
    humidity=$(windDir $(head -n 6 "$srcfile" | tail -n 1))

    echo -n "Текущая температура воздуха "$(digitToWord $temp)" градус"$(wordSuffix $temp)" Цельсия, "
    echo -n "$weather. "
    echo -n "Атмосферное давление "$(digitToWord $pressure)" миллиметр"$(wordSuffix $pressure)" ртутного столба. "
    echo -n "Относительная влажность воздуха "$(digitToWord $humidity)" процент"$(wordSuffix $humidity)". "
    echo -n "Ветер $direction, "$(digitToWord $wind)" метр"$(wordSuffix $wind)" в секунду. "

    if [ $h -ge 6 -a $h -le 11 ]; then
        tempFrom=$(head -n 8 "$srcfile" | tail -n 1 | sed 's/\..*//')
        tempTo=$(head -n 9 "$srcfile" | tail -n 1 | sed 's/\..*//')
        weather=$(head -n 10 "$srcfile" | tail -n 1)
        press=$(head -n 11 "$srcfile" | tail -n 1 | sed 's/\..*//')
        w=$(head -n 12 "$srcfile" | tail -n 1 | sed 's/\..*//')
        wdir=$(windDir $(head -n 13 "$srcfile" | tail -n 1))
        hum=$(windDir $(head -n 14 "$srcfile" | tail -n 1))

        echo -n "Днём температура воздуха составит "$(digitToWord $tempFrom)", "$(digitToWord $tempTo)" градус"$(wordSuffix $tempTo)", $weather. "

        if [ $pressure -eq $press ]; then
            echo -n "Атмосферное давление не изменится. "
        else
            dir="увеличится"
            if [ $pressure -gt $press ]; then
                dir="уменьшится"
            fi
            echo -n "Атмосферное давление $dir до "$(digitToWord $press)" миллиметр"$(wordSuffix $press)" ртутного столба. "
        fi

        if [ $wind -ne $w ]; then
            dir="усилится"
            if [ $wind -gt -$w ]; then
                dir="ослабнет"
            fi
            echo -n "Ветер $wdir $dir до "$(digitToWord $w)" метр"$(wordSuffix $wind 1)" в секунду. "
        fi

        if [ $humidity -ne $hum ]; then
            dir="увеличится"
            if [ $humidity -gt $hum ]; then
                dir="уменьшится"
            fi
            echo -n "Влажность воздуха $dir до "$(digitToWord $hum)" процент"$(wordSuffix $hum 1)". "
        fi
    fi

    if [ $h -ge 6 -a $h -le 17 ]; then
        tempFrom=$(head -n 15 "$srcfile" | tail -n 1 | sed 's/\..*//')
        tempTo=$(head -n 16 "$srcfile" | tail -n 1 | sed 's/\..*//')
        weather=$(head -n 17 "$srcfile" | tail -n 1)
        press=$(head -n 18 "$srcfile" | tail -n 1 | sed 's/\..*//')
        w=$(head -n 19 "$srcfile" | tail -n 1 | sed 's/\..*//')
        wdir=$(windDir $(head -n 20 "$srcfile" | tail -n 1))
        hum=$(windDir $(head -n 21 "$srcfile" | tail -n 1))

        echo -n "Вечером будет $weather, "$(digitToWord $tempFrom)", "$(digitToWord $tempTo)" градус"$(wordSuffix $tempTo)". "

        if [ $pressure -ne $press ]; then
            dir="увеличится"
            if [ $pressure -gt $press ]; then
                dir="уменьшится"
            fi
            echo -n "Атмосферное давление $dir до "$(digitToWord $press)" миллиметр"$(wordSuffix $press)" ртутного столба. "
        fi

        if [ $wind -ne $w ]; then
            dir="усилится"
            if [ $wind -gt -$w ]; then
                dir="ослабнет"
            fi
            echo -n "Ветер $wdir $dir до "$(digitToWord $w)" метр"$(wordSuffix $wind 1)" в секунду. "
        fi

        if [ $humidity -ne $hum ]; then
            dir="увеличится"
            if [ $humidity -gt $hum ]; then
                dir="уменьшится"
            fi
            echo -n "Влажность воздуха $dir до "$(digitToWord $hum)" процент"$(wordSuffix $hum 1)". "
        fi
    fi

    echo
}

msg=$(getText)
echo $msg >&2

$root/bin/speech.sh "$msg" "$dstfile"
