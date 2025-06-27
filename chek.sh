#!/bin/sh

set -e  # Выход при ошибке

# Переменные окружения
CHECK_FILE="${CHECK_FILE:-/var/data/.setup_complete}"
EXPECTED_CONTENT="${EXPECTED_CONTENT:-v1.0.0}"
ARCHIVES="${ARCHIVES:-}"  # Например: "http://a.tgz:/dir1 http://b.tgz:/dir2"

# Проверяем, был ли уже выполнен процесс
if [ -f "$CHECK_FILE" ]; then
    CURRENT_CONTENT=$(cat "$CHECK_FILE")
    if [ "$CURRENT_CONTENT" == "$EXPECTED_CONTENT" ]; then
        echo "✅ Проверка успешна. Установка уже выполнена."
        exit 0
    else
        echo "⚠️ Содержимое не совпадает. Перезапуск установки..."
    fi
else
    echo "⚠️ Файл проверки отсутствует. Запуск установки..."
fi

# Проверка наличия curl и tar
command -v curl >/dev/null 2>&1 || { echo "❌ Ошибка: curl не установлен." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "❌ Ошибка: tar не установлен." >&2; exit 1; }

# Обработка архивов
IFS=' ' read -r -a archive_list <<< "$ARCHIVES"

for item in "${archive_list[@]}"; do
    # Разделяем URL и директорию
    IFS=':' read -r url dir <<< "$item"
    
    if [ -z "$url" ] || [ -z "$dir" ]; then
        echo "❌ Некорректный формат архива: $item"
        continue
    fi

    echo "📥 Загрузка архива: $url → $dir"

    mkdir -p "$dir"

    # Скачиваем архив
    tempfile="/tmp/archive_$(date +%s).tar.gz"
    curl -s -L "$url" -o "$tempfile"

    if [ $? -ne 0 ]; then
        echo "❌ Ошибка загрузки архива: $url"
        exit 1
    fi

    # Распаковываем
    tar -xzf "$tempfile" -C "$dir"
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка распаковки архива: $tempfile"
        exit 1
    fi

    rm -f "$tempfile"
done

# Создаём файл с меткой
echo "$EXPECTED_CONTENT" > "$CHECK_FILE"

echo "✅ Установка успешно завершена. Метка создана: $CHECK_FILE"
exit 0
