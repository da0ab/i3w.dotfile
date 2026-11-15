#!/bin/bash

# ---------- VPN ----------
declare -A VPN_CONNS
while IFS=: read -r NAME TYPE; do
    if [[ "$TYPE" == "vpn" || "$TYPE" == "wireguard" ]]; then
        VPN_CONNS["$NAME"]=1
    fi
done < <(nmcli --terse --fields NAME,TYPE connection show)

# Активные VPN
declare -A ACTIVE_VPN
while IFS=: read -r NAME TYPE; do
    if [[ "$TYPE" == "vpn" || "$TYPE" == "wireguard" ]]; then
        ACTIVE_VPN["$NAME"]=1
    fi
done < <(nmcli --terse --fields NAME,TYPE connection show --active)

# ---------- Wi-Fi: дедуп по SSID, максимум сигнала ----------
declare -A BEST_SIGNAL
declare -A BEST_SEC
while IFS=: read -r SSID SIGNAL SECURITY; do
    [ -z "$SSID" ] && continue
    [ "$SSID" = "--" ] && continue
    if [ -z "${BEST_SIGNAL[$SSID]}" ] || [ "$SIGNAL" -gt "${BEST_SIGNAL[$SSID]}" ]; then
        BEST_SIGNAL["$SSID"]=$SIGNAL
        BEST_SEC["$SSID"]=$SECURITY
    fi
done < <(nmcli --terse --fields SSID,SIGNAL,SECURITY device wifi list)

# Сохранённые Wi-Fi соединения: SSID -> имя соединения
declare -A CONN_NAMES
while IFS=: read -r CONN_LINE; do
    CONN_NAME=$(echo "$CONN_LINE" | cut -d: -f1)
    CONN_TYPE=$(echo "$CONN_LINE" | cut -d: -f2)
    if [[ "$CONN_TYPE" == *"wireless"* ]]; then
        SSID_FULL=$(nmcli --terse --fields 802-11-wireless.ssid connection show "$CONN_NAME" 2>/dev/null)
        if [ -n "$SSID_FULL" ]; then
            SSID=$(echo "$SSID_FULL" | cut -d: -f2-)
            CONN_NAMES["$SSID"]="$CONN_NAME"
        fi
    fi
done < <(nmcli --terse connection show)

ACTIVE_CONN=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

# ---------- Меню ----------
MENU="↻ Пересканировать\n"
MENU+="↑ Включить WiFi\n"
MENU+="↓ Выключить WiFi\n"
MENU+="⚙ Настройки\n"
MENU+="──────────────\n"

# VPN-блок
if [ ${#VPN_CONNS[@]} -gt 0 ]; then
    MENU+="VPN:\n"
    for vpn in "${!VPN_CONNS[@]}"; do
        if [ -n "${ACTIVE_VPN[$vpn]}" ]; then
            MENU+="✓ 🔐 $vpn\n"
        else
            MENU+="  🔐 $vpn\n"
        fi
    done
    MENU+="──────────────\n"
fi

# Wi-Fi-блок
for SSID in "${!BEST_SIGNAL[@]}"; do
    SIGNAL=${BEST_SIGNAL[$SSID]}
    SECURITY=${BEST_SEC[$SSID]}

    if [ -n "${CONN_NAMES[$SSID]}" ]; then
        DISPLAY_NAME="${CONN_NAMES[$SSID]}"
        SAVED_ICON=" 💾"
    else
        DISPLAY_NAME="$SSID"
        SAVED_ICON=""
    fi

    ACTIVE_ICON="  "
    if [ -n "$ACTIVE_CONN" ] && [ "${CONN_NAMES[$SSID]}" = "$ACTIVE_CONN" ]; then
        ACTIVE_ICON="✓ "
    fi

    if [ "$SIGNAL" -gt 75 ]; then BAR="▇▇▇▇"
    elif [ "$SIGNAL" -gt 50 ]; then BAR="▇▇▇ "
    elif [ "$SIGNAL" -gt 25 ]; then BAR="▇▇  "
    else BAR="▇   "; fi

    if [ "$SECURITY" = "--" ]; then LOCK="🔓"; else LOCK="🔒"; fi

    MENU+="${ACTIVE_ICON}${BAR} ${SIGNAL}% ${LOCK} ${DISPLAY_NAME}${SAVED_ICON}\n"
done

CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "WiFi" -i -theme-str 'window { width: 800px; }')

# ---------- Обработка ----------
case "$CHOICE" in
    "↻ Пересканировать")
        nmcli device wifi rescan
        notify-send "WiFi" "Сети пересканированы" -t 1500 ;;
    "↑ Включить WiFi")
        nmcli radio wifi on
        notify-send "WiFi" "WiFi включен" -t 1500 ;;
    "↓ Выключить WiFi")
        nmcli radio wifi off
        notify-send "WiFi" "WiFi выключен" -t 1500 ;;
    "⚙ Настройки")
        nm-connection-editor & ;;
    "VPN:"|"──────────────")
        ;; # заголовки/разделители игнорируем
    *)
        # VPN?
        for vpn in "${!VPN_CONNS[@]}"; do
            if [ "$CHOICE" = "✓ 🔐 $vpn" ] || [ "$CHOICE" = "  🔐 $vpn" ]; then
                if [ -n "${ACTIVE_VPN[$vpn]}" ]; then
                    nmcli connection down "$vpn"
                    notify-send "VPN" "Отключено: $vpn" -t 1500
                else
                    nmcli connection up "$vpn"
                    notify-send "VPN" "Подключено: $vpn" -t 1500
                fi
                exit 0
            fi
        done

        # Wi-Fi
        if echo "$CHOICE" | grep -q "%"; then
            SELECTED=$(echo "$CHOICE" | sed -E 's/^[✓ ]?▇+ [0-9]+% [🔒🔓]? //' | sed 's/ 💾$//')
            if [ -n "$SELECTED" ]; then
                if nmcli connection show "$SELECTED" >/dev/null 2>&1; then
                    nmcli connection up "$SELECTED"
                    notify-send "WiFi" "Подключение: $SELECTED" -t 1500
                elif ! nmcli device wifi connect "$SELECTED" 2>/dev/null; then
                    PASSWORD=$(rofi -dmenu -password -p "Пароль для $SELECTED:")
                    [ -n "$PASSWORD" ] && nmcli device wifi connect "$SELECTED" password "$PASSWORD"
                else
                    notify-send "WiFi" "Подключено к $SELECTED" -t 1500
                fi
            fi
        fi
        ;;
esac
