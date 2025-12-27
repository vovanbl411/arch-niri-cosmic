#!/bin/bash

# Модуль логирования и вывода сообщений

# Проверяем, что config.sh загружен
if [[ ! -v PROJECT_ROOT ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/config.sh"
fi

# Цвета для вывода
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Функция для логирования в файл, если указан
log_to_file() {
    local message="$1"
    local log_file=$(get_log_file)
    
    if [[ -n "$log_file" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
    fi
}

# Функция для вывода информационных сообщений
log_info() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $message"
    log_to_file "[INFO] $message"
}

# Функция для вывода предупреждений
log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    log_to_file "[WARNING] $message"
}

# Функция для вывода ошибок
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    log_to_file "[ERROR] $message"
}