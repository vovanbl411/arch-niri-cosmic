#!/bin/bash

# Модуль парсинга аргументов командной строки

# Проверяем, что logging.sh загружен
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || source "$SCRIPT_DIR/modules/config.sh"
fi

# Функция для парсинга аргументов командной строки
parse_arguments() {
    local category=""
    local missing_only=false
    local log_file=""
    
    if [ $# -eq 0 ]; then
        log_info "Использование: $0 <категория> [опции]"
        log_info "Доступные категории: core, desktop, niri, cosmic (пакеты из AUR), development, fonts-themes, hardware, virtualization, aur, all, all_with_aur"
        log_info "Доступные опции:"
        log_info "  --missing-only: Установить только отсутствующие пакеты"
        log_info "  --log-file <путь>: Записывать лог в указанный файл"
        log_info "Для установки системных пакетов запустите с sudo: sudo $0 <категория> [опции]"
        log_info "Для установки AUR пакетов запустите без sudo: $0 aur [опции]"
        log_info "Для установки всех пакетов с AUR: sudo $0 all_with_aur [опции]"
        exit 0
    fi
    
    # Получаем категорию из аргумента
    category=$1
    shift
    
    # Проверяем дополнительные опции
    while [[ $# -gt 0 ]]; do
        case $1 in
            --missing-only)
                missing_only=true
                shift
                ;;
            --log-file)
                if [[ -n "$2" && "$2" != -* ]]; then
                    log_file="$2"
                    shift 2
                else
                    log_error "Опция --log-file требует аргумент"
                    exit 1
                fi
                ;;
            *)
                log_error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
    
    # Возвращаем результаты через глобальные переменные
    PKGS_ARCH_CATEGORY="$category"
    PKGS_ARCH_MISSING_ONLY="$missing_only"
    PKGS_ARCH_LOG_FILE="$log_file"
    
    export PKGS_ARCH_CATEGORY PKGS_ARCH_MISSING_ONLY PKGS_ARCH_LOG_FILE
}