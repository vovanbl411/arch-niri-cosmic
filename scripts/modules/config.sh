#!/bin/bash

# Модуль конфигурации проекта PKGS-ARCH

# Определяем директорию скрипта и сохраняем корень проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Глобальные переменные проекта
readonly PKGS_ARCH_VERSION="1.0.0"
PKGS_ARCH_LOG_FILE=""

# Массив для хранения путей к временным файлам
declare -a TEMP_FILES=()

# Функция для получения корня проекта
get_project_root() {
    echo "$PROJECT_ROOT"
}

# Функция для получения директории скрипта
get_script_dir() {
    echo "$SCRIPT_DIR"
}

# Функция для добавления временного файла в список для очистки
add_temp_file() {
    TEMP_FILES+=("$1")
}

# Функция для получения списка временных файлов
get_temp_files() {
    echo "${TEMP_FILES[@]}"
}

# Функция для установки файла лога
set_log_file() {
    PKGS_ARCH_LOG_FILE="$1"
}

# Функция для получения файла лога
get_log_file() {
    echo "$PKGS_ARCH_LOG_FILE"
}