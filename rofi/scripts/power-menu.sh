#!/bin/bash

# Простой power-меню с rofi

chosen=$(echo -e "⏻ Shutdown\n Reboot\n Logout\n Lock\n Cancel" | rofi -dmenu -i -p "Power Menu" -i -theme-str '
    window {
        width: 800px;
    }
    listview {
        lines: 5;
    }
')
case "$chosen" in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Logout")
        i3-msg exit
        ;;
    " Lock")
        i3lock
        ;;
    " Cancel")
        exit 0
        ;;
esac
