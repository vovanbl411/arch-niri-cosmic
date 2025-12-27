#!/bin/bash

# Скрипт установки полноценного дистрибутива на базе PKGS-ARCH

set -e  # Выход при ошибке

# Загружаем все необходимые модулы
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/modules/config.sh"
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/validator.sh"
source "$SCRIPT_DIR/modules/package-manager.sh"
source "$SCRIPT_DIR/modules/desktop-manager.sh"
source "$SCRIPT_DIR/modules/aur-handler.sh"
source "$SCRIPT_DIR/modules/installer.sh"
source "$SCRIPT_DIR/helpers/arg-parser.sh"

# Функция для удаления всех временных файлов
cleanup_temp_files() {
    for temp_file in "${TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done
}

# Функция для обработки сигналов
handle_signal() {
    log_error "Получен сигнал прерывания. Завершение работы..."
    cleanup_temp_files
    exit 1
}

# Устанавливаем обработчик для сигналов прерывания
trap handle_signal SIGINT SIGTERM

# Устанавливаем обработчик для выхода из скрипта
trap cleanup_temp_files EXIT

# Функция установки дистрибутива
install_distribution() {
    local install_only_missing="${1:-false}"
    local desktop_choice="${2:-""}"
    local username="${3:-""}"
    local password="${4:-""}"
    
    log_info "Начало установки дистрибутива PKGS-ARCH..."
    
    # Загружаем скрипты для предустановочных действий
    if [[ -f "$SCRIPT_DIR/distributions/base/pre-install.sh" ]]; then
        source "$SCRIPT_DIR/distributions/base/pre-install.sh"
        pre_installation
    fi
    
    # Устанавливаем пакеты
    install_category "all" "$install_only_missing" "$desktop_choice"
    
    # Устанавливаем AUR пакеты
    install_category "aur" "$install_only_missing" "$desktop_choice"
    
    # Загружаем скрипты для постустановочных действий
    if [[ -f "$SCRIPT_DIR/distributions/base/post-install.sh" ]]; then
        source "$SCRIPT_DIR/distributions/base/post-install.sh"
        post_installation "$username" "$password"
    fi
    
    # Загружаем скрипты для финализации
    if [[ -f "$SCRIPT_DIR/distributions/base/finalize.sh" ]]; then
        source "$SCRIPT_DIR/distributions/base/finalize.sh"
        finalize_installation
    fi
    
    log_info "Установка дистрибутива PKGS-ARCH завершена!"
}

# Парсим аргументы командной строки
parse_arguments "$@"

# Извлекаем значения из глобальных переменных
CATEGORY="$PKGS_ARCH_CATEGORY"
MISSING_ONLY="$PKGS_ARCH_MISSING_ONLY"

# Устанавливаем файл лога, если указан
if [[ -n "$PKGS_ARCH_LOG_FILE" ]]; then
    set_log_file "$PKGS_ARCH_LOG_FILE"
fi

# Проверяем, нужно ли запрашивать sudo для установки
check_sudo

# Переходим в корень проекта
cd "$(get_project_root)"

# Выполняем установку дистрибутива
install_distribution "$MISSING_ONLY" "" "" ""

# Убедимся, что последнее сообщение также попадает в лог
log_info "Установка завершена!"
log_to_file "Установка дистрибутива завершена успешно"