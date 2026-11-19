#!/usr/bin/env bash
set -euo pipefail

LISTFILE="$HOME/.config/rofi/scripts/list.txt"
MENUTITLE="Neovim"
EDITLABEL="✎ Редактировать список"

# Создаем директорию и файл, если их нет
mkdir -p "$(dirname "$LISTFILE")"
touch "$LISTFILE"

# Читаем строки, убирая комментарии, пустые строки и крайние пробелы (без падения при пустом файле)
mapfile -t entries < <(awk '
  /^[[:space:]]*(#|$)/ { next }
  { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print }
' "$LISTFILE")

entries+=("$EDITLABEL")

# Показываем меню
choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "$MENUTITLE" -theme-str 'window {width: 60ch;}' || true)
[ -z "${choice:-}" ] && exit 0

# Пункт «Редактировать список»
if [ "$choice" = "$EDITLABEL" ]; then
  setsid -f wezterm start -- nvim -- "$LISTFILE" >/dev/null 2>&1
  exit 0
fi

# Раскрыть ~ в путь
case "$choice" in
  "~/"*|"~") choice="${choice/#\~/$HOME}" ;;
esac

# Открыть выбор в wezterm + nvim
setsid -f wezterm start -- nvim -- "$choice" >/dev/null 2>&1
