#!/bin/sh
set -e

CHECK_FILE="${CHECK_FILE:-/var/data/.setup_complete}"
EXPECTED_CONTENT="${EXPECTED_CONTENT:-copula-console-v0.2.13.tgz}"
ARCHIVES="${ARCHIVES:-}"

if [ -f "$CHECK_FILE" ]; then
  CURRENT_CONTENT=$(cat "$CHECK_FILE")
  if [ "$CURRENT_CONTENT" = "$EXPECTED_CONTENT" ]; then
    echo "✅ Проверка успешна. Установка уже выполнена."
    exit 0
  else
    echo "⚠️ Содержимое не совпадает. Перезапуск установки..."
  fi
else
  echo "⚠️ Файл проверки отсутствует. Запуск установки..."
fi

if ! command -v wget >/dev/null 2>&1; then
  echo "❌ Ошибка: wget не установлен." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "❌ Ошибка: tar не установлен." >&2
  exit 1
fi

for item in $ARCHIVES; do
  url=$(echo "$item" | cut -d':' -f1)
  dir=$(echo "$item" | cut -d':' -f2)

  if [ -z "$url" ] || [ -z "$dir" ]; then
    echo "❌ Некорректный формат архива: $item"
    continue
  fi

  echo "📥 Загрузка архива: $url → $dir"

  mkdir -p "$dir"

  tempfile="/tmp/archive_$(date +%s).tar.gz"
  wget -q -O "$tempfile" "$url" || {
    echo "❌ Ошибка загрузки архива: $url"
    exit 1
  }

  tar -xzf "$tempfile" -C "$dir" || {
    echo "❌ Ошибка распаковки архива: $tempfile"
    exit 1
  }

  rm -f "$tempfile"
done

echo "$EXPECTED_CONTENT" > "$CHECK_FILE"
echo "✅ Установка успешно завершена. Метка создана: $CHECK_FILE"
exit 0
