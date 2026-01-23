#!/usr/bin/env bash
set -euo pipefail

LISTFILE="$HOME/.config/rofi/scripts/list.txt"
MENUTITLE="GVim"
EDITLABEL="⚙️ Редактировать список"

mkdir -p "$(dirname "$LISTFILE")"
if [ ! -f "$LISTFILE" ]; then
  cat > "$LISTFILE" <<'EOF'
# Список файлов/проектов для gVim.
# По одной записи на строку. Можно использовать ~ для $HOME.
# Примеры:
~/notes/todo.md
~/code/project/README.md
EOF
fi

# Собираем пункты: игнорируем пустые строки и комментарии
mapfile -t entries < <(grep -v '^\s*#' "$LISTFILE" | sed '/^\s*$/d')
entries+=("$EDITLABEL")

# Показываем меню
choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "$MENUTITLE" -width 60 || true)
[ -z "${choice:-}" ] && exit 0

# Пункт «Редактировать список»
if [ "$choice" = "$EDITLABEL" ]; then
  setsid -f gvim -- "$LISTFILE" >/dev/null 2>&1
  exit 0
fi

# Раскрыть ~ в путь
case "$choice" in
  "~/"*|"~")
    choice="${choice/#\~/$HOME}"
    ;;
esac

# Открыть выбор в gvim
setsid -f gvim -- "$choice" >/dev/null 2>&1
