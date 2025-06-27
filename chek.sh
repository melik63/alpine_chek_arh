#!/bin/sh
set -e

# === Настройки по умолчанию ===
CHECK_FILE="${CHECK_FILE:-/workspace/static/ver.txt}"
EXPECTED_CONTENT="${EXPECTED_CONTENT:-copula-console-v0.2.13.tgz}"

# Формат: "url1:dir1:strip1;url2:dir2:strip2;..."
ARCHIVES="${ARCHIVES:-repo.int.sifox.ru/cpaas/web-ui/copula-console/copula-console-v0.2.13.tgz:/workspace/static/console/:3}"

# ==============================
# Проверка наличия файла метки
# ==============================
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

# ==============================
# Проверка необходимых утилит
# ==============================
if ! command -v wget >/dev/null 2>&1; then
  echo "❌ Ошибка: wget не установлен." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "❌ Ошибка: tar не установлен." >&2
  exit 1
fi

mkdir -p "$(dirname "$CHECK_FILE")"

# ==============================
# Обработка архивов
# ==============================
for item in $(echo "$ARCHIVES" | tr ';' ' '); do
  url=$(echo "$item" | cut -d':' -f1)
  dir=$(echo "$item" | cut -d':' -f2)
  strip=$(echo "$item" | cut -d':' -f3)

  if [ -z "$url" ] || [ -z "$dir" ] || [ -z "$strip" ]; then
    echo "❌ Некорректный формат архива: $item"
    continue
  fi

  echo "📥 Загрузка архива: $url → $dir (strip: $strip)"

  mkdir -p "$dir"

  tempfile="/tmp/archive_$(date +%s).tar.gz"
  wget -q -O "$tempfile" "$url" || {
    echo "❌ Ошибка загрузки архива: $url"
    exit 1
  }

  tar -xzf "$tempfile" -C "$dir" --strip-components="$strip" || {
    echo "❌ Ошибка распаковки архива: $tempfile"
    exit 1
  }

  rm -f "$tempfile"
done

# ==============================
# Запись метки завершения установки
# ==============================
echo "$EXPECTED_CONTENT" > "$CHECK_FILE"
echo "✅ Установка успешно завершена. Метка создана: $CHECK_FILE"
exit 0
