#!/bin/bash

# Скрипт для автоматической установки пакетов из списков проекта PKGS-ARCH
# Использование: ./scripts/install.sh [категория]

set -e  # Выход при ошибке

# Загружаем все необходимые модули
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
check_sudo "$CATEGORY"

# Если запрошена установка all с AUR пакетами, меняем категорию на all и устанавливаем флаг
INSTALL_AUR_WITH_ALL=false
desktop_choice=""

if [[ "$CATEGORY" == "all_with_aur" ]]; then
    ORIGINAL_CATEGORY="$CATEGORY"
    CATEGORY="all"
    INSTALL_AUR_WITH_ALL=true
    
    # Для all_with_aur также запрашиваем выбор среды рабочего стола
    if [[ "$MISSING_ONLY" == false ]]; then
        desktop_choice=$(select_desktop_interactive)
    fi
fi

# Переходим в корень проекта
cd "$(get_project_root)"

# Выполняем установку
install_category "$CATEGORY" "$MISSING_ONLY" "$desktop_choice"

# Если была запрошена установка AUR пакетов вместе с all, устанавливаем их отдельно
if [[ "$INSTALL_AUR_WITH_ALL" == true ]]; then
    log_info "Установка AUR пакетов..."
    # Для AUR нужен отдельный вызов без sudo
    if command -v sudo &> /dev/null && [[ "$EUID" -eq 0 ]]; then
        # Если мы в sudo, временно сбрасываем привилегии для установки AUR
        original_user=$(logname 2>/dev/null || whoami)
        if [[ -n "$original_user" ]]; then
            # Создаем временный файл для передачи выбора рабочей среды
            temp_choice_file=$(mktemp "/tmp/pkgs-arch-desktop-choice-XXXXXX")
            add_temp_file "$temp_choice_file"
            echo "$desktop_choice" > "$temp_choice_file"
            export DESKTOP_CHOICE_FILE="$temp_choice_file"
            
            # Определяем абсолютный путь к скрипту
            script_absolute_path="$(get_project_root)/scripts/install.sh"
            
            exec su "$original_user" -c "PROJECT_ROOT='$(get_project_root)' DESKTOP_CHOICE_FILE='$temp_choice_file' '$script_absolute_path' aur $([ "$MISSING_ONLY" = true ] && echo '--missing-only' || echo '') $([ -n "$PKGS_ARCH_LOG_FILE" ] && echo "--log-file $PKGS_ARCH_LOG_FILE" || echo '')"
        else
            log_error "Не удалось определить оригинального пользователя для установки AUR пакетов"
            log_info "Запустите установку AUR пакетов отдельно: ./scripts/install.sh aur"
        fi
    else
        install_category "aur" "$MISSING_ONLY" "$desktop_choice"
    fi
fi

# Убедимся, что последнее сообщение также попадает в лог
log_info "Установка завершена!"
log_to_file "Установка завершена успешно"

# Удаляем временный файл с выбором рабочей среды, если он был создан
if [[ -n "$DESKTOP_CHOICE_FILE" && -f "$DESKTOP_CHOICE_FILE" ]]; then
    rm -f "$DESKTOP_CHOICE_FILE"
fi