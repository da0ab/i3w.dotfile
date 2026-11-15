#!/bin/bash

acpi_out=$(acpi -b)

if [[ -z "$acpi_out" ]]; then
    echo "Нет данных"
    exit 1
fi

status=$(echo "$acpi_out" | awk -F': |, ' '{print $2}')
percent=$(echo "$acpi_out" | awk -F', ' '{print $2}' | tr -d '% ')
time=$(echo "$acpi_out" | awk -F', ' '{print $3}' | sed 's/[^0-9:]//g')

# Цвета
green="%{F#00ff00}"
red="%{F#ff5555}"
reset="%{F-}"

if [[ "$status" == "Charging" ]]; then
    if [[ -n "$time" ]]; then
        echo "${green}Заряд: ${percent}% – $time${reset}"
    else
        echo "${green}Заряд: ${percent}%${reset}"
    fi
elif [[ "$status" == "Discharging" ]]; then
    if [[ "$percent" -lt 15 ]]; then
        if [[ -n "$time" ]]; then
            echo "${red}Критично: ${percent}% – $time${reset}"
        else
            echo "${red}Критично: ${percent}%${reset}"
        fi
    else
        if [[ -n "$time" ]]; then
            echo "Осталось: ${percent}% – $time"
        else
            echo "Осталось: ${percent}%"
        fi
    fi
elif [[ "$status" == "Full" ]]; then
    echo "Полный заряд: ${percent}%"
else
    echo "Неизвестно: ${percent}%"
fi
