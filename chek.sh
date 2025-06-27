#!/bin/sh
set -e

# Переменные окружения
CHECK_FILE="${CHECK_FILE:-/workspace/static/ver.txt}"
EXPECTED_CONTENT="${EXPECTED_CONTENT:-copula-console-v0.2.13.tgz}"
ARCHIVES="${ARCHIVES:-}"

# Проверяем, была ли уже выполнена установка
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

# Проверяем наличие необходимых утилит
if ! command -v wget >/dev/null 2>&1; then
  echo "❌ Ошибка: wget не установлен." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "❌ Ошибка: tar не установлен." >&2
  exit 1
fi

# Обрабатываем список архивов
IFS=' ' read -r -a archive_list <<< "$ARCHIVES"
for item in "${archive_list[@]}"; do
  IFS=':' read -r url dir <<< "$item"

  if [ -z "$url" ] || [ -z "$dir" ]; then
    echo "❌ Некорректный формат архива: $item"
    continue
  fi

  echo "📥 Загрузка архива: $url → $dir"

  # Создаём целевую папку
  mkdir -p "$dir"

  # Имя временного файла
  tempfile="/tmp/archive_$(date +%s).tar.gz"

  # Скачиваем архив
  wget -q -O "$tempfile" "$url" || {
    echo "❌ Ошибка загрузки архива: $url"
    exit 1
  }

  # Распаковываем архив
  tar -xzf "$tempfile" -C "$dir" || {
    echo "❌ Ошибка распаковки архива: $tempfile"
    exit 1
  }

  # Удаляем временный файл
  rm -f "$tempfile"
done

# Создаём файл с меткой версии
echo "$EXPECTED_CONTENT" > "$CHECK_FILE"
echo "✅ Установка успешно завершена. Метка создана: $CHECK_FILE"
exit 0
