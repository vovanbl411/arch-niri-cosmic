#!/bin/bash

# Модуль утилит для работы с файлами

# Проверяем, что logging.sh загружен
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || source "$SCRIPT_DIR/modules/config.sh"
fi

# Функция для проверки существования файла
file_exists() {
    local file_path="$1"
    
    if [[ -f "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

# Функция для проверки, является ли файл пустым
file_is_empty() {
    local file_path="$1"
    
    if [[ ! -s "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

# Функция для чтения содержимого файла
read_file_content() {
    local file_path="$1"
    
    if file_exists "$file_path"; then
        cat "$file_path"
    else
        log_error "Файл $file_path не существует"
        return 1
    fi
}

# Функция для создания временного файла
create_temp_file() {
    local temp_file=$(mktemp)
    add_temp_file "$temp_file"
    echo "$temp_file"
}

# Функция для добавления содержимого в файл
append_to_file() {
    local file_path="$1"
    local content="$2"
    
    echo "$content" >> "$file_path"
}