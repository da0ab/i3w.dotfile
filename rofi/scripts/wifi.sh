#!/bin/bash

# Получаем список сетей
NETWORKS=$(nmcli --terse --fields SSID,SIGNAL,SECURITY device wifi list | grep -v '^--')

# Получаем все сохраненные WiFi соединения и создаем маппинг SSID -> Имя соединения
declare -A CONN_NAMES
while IFS=: read -r CONN_LINE; do
    # Разбираем строку: Имя:Тип:UUID:Устройство...
    CONN_NAME=$(echo "$CONN_LINE" | cut -d: -f1)
    CONN_TYPE=$(echo "$CONN_LINE" | cut -d: -f2)

    if [[ "$CONN_TYPE" == *"wireless"* ]] || [[ "$CONN_TYPE" == *"wifi"* ]] || [[ "$CONN_TYPE" == "802-11-wireless" ]]; then
        # Получаем SSID для этого соединения
        SSID_FULL=$(nmcli --terse --fields 802-11-wireless.ssid connection show "$CONN_NAME" 2>/dev/null)
        if [ -n "$SSID_FULL" ]; then
            # Извлекаем SSID из строки "802-11-wireless.ssid:SSID_NAME"
            SSID=$(echo "$SSID_FULL" | cut -d: -f2-)
            CONN_NAMES["$SSID"]="$CONN_NAME"
        fi
    fi
done < <(nmcli --terse connection show)

# Получаем текущее активное соединение
ACTIVE_CONN=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

# Создаем меню
MENU="↻ Пересканировать\n"
MENU+="↑ Включить WiFi\n"
MENU+="↓ Выключить WiFi\n"
MENU+="⚙ Настройки\n"
MENU+="──────────────\n"

# Добавляем сети
while IFS=: read -r SSID SIGNAL SECURITY; do
    [ -z "$SSID" ] && continue
    [ "$SSID" = "--" ] && continue

    # Определяем отображаемое имя
    if [ -n "${CONN_NAMES[$SSID]}" ]; then
        DISPLAY_NAME="${CONN_NAMES[$SSID]}"
        SAVED_ICON=" 💾"
    else
        DISPLAY_NAME="$SSID"
        SAVED_ICON=""
    fi

    # Проверяем, активно ли это соединение
    ACTIVE_ICON="  "
    if [ -n "$ACTIVE_CONN" ]; then
        if [ "${CONN_NAMES[$SSID]}" = "$ACTIVE_CONN" ]; then
            ACTIVE_ICON="✓ "
        fi
    fi

    # Иконка сигнала
    if [ "$SIGNAL" -gt 75 ]; then
        BAR="▇▇▇▇"
    elif [ "$SIGNAL" -gt 50 ]; then
        BAR="▇▇▇ "
    elif [ "$SIGNAL" -gt 25 ]; then
        BAR="▇▇  "
    else
        BAR="▇   "
    fi

    # Иконка защиты
    if [ "$SECURITY" = "--" ]; then
        LOCK="🔓"
    else
        LOCK="🔒"
    fi

    # Добавляем в меню
    MENU+="${ACTIVE_ICON}${BAR} ${SIGNAL}% ${LOCK} ${DISPLAY_NAME}${SAVED_ICON}\n"
done <<< "$NETWORKS"

# Показываем меню
CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "WiFi" -i -theme-str '
    window {
        width: 800px;
    }')

# Обработка выбора
case "$CHOICE" in
    "↻ Пересканировать")
        nmcli device wifi rescan
        notify-send "WiFi" "Сети пересканированы" -t 1500
        ;;
    "↑ Включить WiFi")
        nmcli radio wifi on
        notify-send "WiFi" "WiFi включен" -t 1500
        ;;
    "↓ Выключить WiFi")
        nmcli radio wifi off
        notify-send "WiFi" "WiFi выключен" -t 1500
        ;;
    "⚙ Настройки")
        nm-connection-editor &
        ;;
    *)
        # Если выбрана сеть
        if echo "$CHOICE" | grep -q "%"; then
            # Извлекаем имя (после иконок и процентов)
            SELECTED=$(echo "$CHOICE" | sed -E 's/^[✓ ]?▇+ [0-9]+% 🔒?🔓? //' | sed 's/ 💾$//')

            if [ -n "$SELECTED" ]; then
                # Проверяем, является ли это именем соединения
                IS_CONN_NAME=false
                for ssid in "${!CONN_NAMES[@]}"; do
                    if [ "${CONN_NAMES[$ssid]}" = "$SELECTED" ]; then
                        # Это имя соединения - подключаемся по нему
                        nmcli connection up "$SELECTED"
                        notify-send "WiFi" "Подключение: $SELECTED" -t 1500
                        IS_CONN_NAME=true
                        break
                    fi
                done

                if [ "$IS_CONN_NAME" = false ]; then
                    # Это SSID (или имя соединения которого нет в массиве)
                    # Пробуем подключиться
                    if ! nmcli device wifi connect "$SELECTED" 2>/dev/null; then
                        # Запрашиваем пароль если нужно
                        PASSWORD=$(rofi -dmenu -password -p "Пароль для $SELECTED:")
                        if [ -n "$PASSWORD" ]; then
                            nmcli device wifi connect "$SELECTED" password "$PASSWORD"
                        fi
                    else
                        notify-send "WiFi" "Подключено к $SELECTED" -t 1500
                    fi
                fi
            fi
        fi
        ;;
esac
