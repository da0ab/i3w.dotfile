#!/usr/bin/env bash
set -euo pipefail

# ---------- 1. Установка зависимостей (Debian/Ubuntu) ----------
echo ">>> Установка i3, polybar, rofi, feh и вспомогательных инструментов..."
sudo apt update
sudo apt install -y i3 polybar rofi feh picom git curl

# ---------- 2. Клонирование вашего репозитория конфигурации ----------
REPO_URL="https://github.com/da0ab/i3w.dotfile.git"
TMP_DIR=$(mktemp -d)
echo ">>> Клонирование $REPO_URL ..."
git clone --depth 1 "$REPO_URL" "$TMP_DIR"

# ---------- 3. Резервное копирование старых конфигураций (если существуют) ----------
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
for dir in i3 polybar rofi i3status; do
    if [ -d "$HOME/.config/$dir" ]; then
        echo ">>> Резервное копирование существующего $dir в $BACKUP_DIR ..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
    fi
done

# ---------- 4. Копирование конфигураций ----------
echo ">>> Копирование конфигураций из репозитория..."
mkdir -p "$HOME/.config"
# В репозитории могут быть каталоги i3, polybar, rofi, копируем их напрямую
for dir in i3 polybar rofi; do
    if [ -d "$TMP_DIR/$dir" ]; then
        cp -r "$TMP_DIR/$dir" "$HOME/.config/"
    fi
done

# Если в репозитории есть скрипты, добавляем права на выполнение (на случай если есть .sh файлы)
find "$HOME/.config/i3" "$HOME/.config/polybar" "$HOME/.config/rofi" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# ---------- 5. Очистка ----------
rm -rf "$TMP_DIR"

echo ">>> Готово. Конфигурации скопированы в ~/.config/"
echo ">>> Перезайдите в сессию или выполните i3-msg restart (если i3 уже запущен)."
