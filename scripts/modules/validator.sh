#!/bin/bash

# Модуль проверки и валидации

# Проверяем, что logging.sh загружен
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || { 
        source "$SCRIPT_DIR/modules/config.sh"
        source "$SCRIPT_DIR/helpers/arg-parser.sh"
    }
fi

# Функция проверки прав суперпользователя для установки системных пакетов
check_sudo() {
    local category=${1:-$PKGS_ARCH_CATEGORY}
    
    # Исключаем специальные категории, которые должны запускаться от обычного пользователя
    if [[ "$category" != "aur" && "$category" != "aur_with_desktop_choice" && "$category" != "cosmic_aur_packages" ]]; then
        if [[ "$EUID" -ne 0 ]]; then
            log_error "Для установки системных пакетов требуется запуск с правами суперпользователя"
            log_info "Используйте: sudo ./scripts/install.sh или запустите скрипт от root"
            exit 1
        fi
    fi
}

# Функция валидации существования файла
validate_file_exists() {
    local file_path="$1"
    
    # Если файл не существует по относительному пути, проверяем полный путь в PROJECT_ROOT
    if [[ ! -f "$file_path" ]]; then
        local full_path="$(get_project_root)/$file_path"
        if [[ -f "$full_path" ]]; then
            echo "$full_path"
            return 0
        else
            log_warning "Файл $file_path не найден"
            return 1
        fi
    fi
    
    echo "$file_path"
    return 0
}

# Функция валидации доступности менеджера пакетов
validate_package_manager() {
    local manager="$1"
    
    case "$manager" in
        "pacman")
            if ! command -v pacman &> /dev/null; then
                log_error "pacman не установлен"
                return 1
            fi
            ;;
        "yay"|"paru")
            if ! command -v "$manager" &> /dev/null; then
                log_error "$manager не установлен"
                return 1
            fi
            ;;
        *)
            log_error "Неизвестный менеджер пакетов: $manager"
            return 1
            ;;
    esac
    
    return 0
}

# Функция валидации категории
validate_category() {
    local category="$1"
    local valid_categories=("core" "desktop" "niri" "cosmic" "development" "fonts-themes" "hardware" "virtualization" "aur" "all" "all_with_aur" "aur_with_desktop_choice" "cosmic_aur_packages")
    
    for valid_cat in "${valid_categories[@]}"; do
        if [[ "$category" == "$valid_cat" ]]; then
            return 0
        fi
    done
    
    log_error "Неизвестная категория: $category"
    log_info "Доступные категории: ${valid_categories[*]}"
    return 1
}