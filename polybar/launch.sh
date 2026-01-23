#!/bin/bash

# Убиваем все запущенные экземпляры polybar
killall -q polybar

# Ждём, пока они завершатся
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.2; done

# Запускаем polybar (название бара должно совпадать с тем, что в config.ini)
polybar main &
