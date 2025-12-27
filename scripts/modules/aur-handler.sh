#!/bin/bash

# Модуль работы с AUR (Arch User Repository)

# Проверяем, что другие модули загружены
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || { 
        source "$SCRIPT_DIR/modules/config.sh"
        source "$SCRIPT_DIR/modules/package-manager.sh"
        source "$SCRIPT_DIR/modules/desktop-manager.sh"
    }
fi

# Глобальная переменная для хранения выбора рабочей среды
DESKTOP_CHOICE_FILE=""

# Функция установки AUR пакетов
install_aur_packages() {
    local install_only_missing="${1:-false}"
    local selected_desktop="${2:-""}"
    
    log_info "Установка пакетов из AUR..."
    
    # Проверяем, запущен ли скрипт от root и если да, переключаемся на обычного пользователя для AUR
    if [[ "$EUID" -eq 0 ]]; then
        log_info "Обнаружен запуск от root, переключаемся на обычного пользователя для установки AUR пакетов..."
        local original_user=$(logname 2>/dev/null || whoami)
        if [[ -n "$original_user" && "$original_user" != "root" ]]; then
            # Создаем временный файл для передачи выбора рабочей среды
            local temp_choice_file=$(mktemp "/tmp/pkgs-arch-desktop-choice-XXXXXX")
            add_temp_file "$temp_choice_file"
            echo "$selected_desktop" > "$temp_choice_file"
            export DESKTOP_CHOICE_FILE="$temp_choice_file"
            
            # Определяем абсолютный путь к основному скрипту
            local script_absolute_path="$(get_project_root)/scripts/install.sh"
            
            # Выполняем установку AUR пакетов от имени обычного пользователя
            if command -v sudo &> /dev/null; then
                if [[ "$install_only_missing" == true ]]; then
                    sudo -u "$original_user" env "PROJECT_ROOT=$(get_project_root)" "DESKTOP_CHOICE_FILE=$temp_choice_file" "SELECTED_DESKTOP=$selected_desktop" "$script_absolute_path" aur_with_desktop_choice --missing-only
                else
                    sudo -u "$original_user" env "PROJECT_ROOT=$(get_project_root)" "DESKTOP_CHOICE_FILE=$temp_choice_file" "SELECTED_DESKTOP=$selected_desktop" "$script_absolute_path" aur_with_desktop_choice
                fi
            else
                if [[ "$install_only_missing" == true ]]; then
                    exec su "$original_user" -c "PROJECT_ROOT='$(get_project_root)' DESKTOP_CHOICE_FILE='$temp_choice_file' SELECTED_DESKTOP='$selected_desktop' '$script_absolute_path' aur_with_desktop_choice --missing-only"
                else
                    exec su "$original_user" -c "PROJECT_ROOT='$(get_project_root)' DESKTOP_CHOICE_FILE='$temp_choice_file' SELECTED_DESKTOP='$selected_desktop' '$script_absolute_path' aur_with_desktop_choice"
                fi
            fi
            rm -f "$temp_choice_file"
            return 0
        else
            log_error "Не удалось определить оригинального пользователя для установки AUR пакетов"
            exit 1
        fi
    fi
    
    # Если не запущен от root, выполняем установку напрямую
    if command -v yay &> /dev/null; then
        # Если выбрана среда niri, исключаем cosmic пакеты из AUR
        if [[ "$selected_desktop" == "niri" ]]; then
            log_info "Исключаем пакеты COSMIC из установки AUR (выбрана среда Niri)"
            # Создаем временный файл с фильтрованным списком
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/aur/cosmic.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "yay" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        elif [[ "$selected_desktop" == "cosmic" ]]; then
            log_info "Исключаем пакеты Niri из установки AUR (выбрана среда Cosmic)"
            # Создаем временный файл с фильтрованным списком, исключая niri пакеты
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/desktop/niri.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "yay" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        else
            # Устанавливаем все AUR пакеты
            install_from_file "aur/aur.txt" "yay" "$install_only_missing"
        fi
    elif command -v paru &> /dev/null; then
        # Та же логика для paru
        if [[ "$selected_desktop" == "niri" ]]; then
            log_info "Исключаем пакеты COSMIC из установки AUR (выбрана среда Niri)"
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/aur/cosmic.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "paru" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        elif [[ "$selected_desktop" == "cosmic" ]]; then
            log_info "Исключаем пакеты Niri из установки AUR (выбрана среда Cosmic)"
            # Создаем временный файл с фильтрованным списком, исключая niri пакеты
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/desktop/niri.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "paru" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        else
            install_from_file "aur/aur.txt" "paru" "$install_only_missing"
        fi
    else
        log_error "Ни один AUR helper (yay, paru) не установлен"
        exit 1
    fi
}

# Функция переключения на обычного пользователя
switch_to_normal_user() {
    local original_user=$(logname 2>/dev/null || whoami)
    
    if [[ -n "$original_user" && "$original_user" != "root" ]]; then
        echo "$original_user"
        return 0
    else
        log_error "Не удалось определить оригинального пользователя"
        return 1
    fi
}

# Функция проверки установленного AUR helper
check_aur_helper() {
    if command -v yay &> /dev/null; then
        echo "yay"
    elif command -v paru &> /dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

# Функция обработки установки AUR пакетов (специальная категория)
handle_aur_installation_with_desktop_choice() {
    local install_only_missing="${1:-false}"
    local selected_desktop="${2:-""}"
    
    # Если selected_desktop не передан как аргумент, пытаемся получить из переменной окружения
    if [[ -z "$selected_desktop" && -n "$SELECTED_DESKTOP" ]]; then
        selected_desktop="$SELECTED_DESKTOP"
    fi
    
    log_info "Установка AUR пакетов от обычного пользователя (выбрана среда: $selected_desktop)..."
    
    if command -v yay &> /dev/null; then
        # Если выбрана среда niri, исключаем cosmic пакеты из AUR
        if [[ "$selected_desktop" == "niri" ]]; then
            log_info "Исключаем пакеты COSMIC из установки AUR (выбрана среда Niri)"
            # Создаем временный файл с фильтрованным списком
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/aur/cosmic.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "yay" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        elif [[ "$selected_desktop" == "cosmic" ]]; then
            log_info "Исключаем пакеты Niri из установки AUR (выбрана среда Cosmic)"
            # Создаем временный файл с фильтрованным списком, исключая niri пакеты
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/desktop/niri.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "yay" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        else
            # Устанавливаем все AUR пакеты
            install_from_file "aur/aur.txt" "yay" "$install_only_missing"
        fi
    elif command -v paru &> /dev/null; then
        # Та же логика для paru
        if [[ "$selected_desktop" == "niri" ]]; then
            log_info "Исключаем пакеты COSMIC из установки AUR (выбрана среда Niri)"
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/aur/cosmic.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "paru" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        elif [[ "$selected_desktop" == "cosmic" ]]; then
            log_info "Исключаем пакеты Niri из установки AUR (выбрана среда Cosmic)"
            # Создаем временный файл с фильтрованным списком, исключая niri пакеты
            local temp_aur_file=$(mktemp)
            add_temp_file "$temp_aur_file"
            local project_root=$(get_project_root)
            if [[ -f "$project_root/aur/aur.txt" ]]; then
                exclude_conflicting_packages "$project_root/aur/aur.txt" "$project_root/desktop/niri.txt" "$temp_aur_file"
                install_from_file "$temp_aur_file" "paru" "$install_only_missing"
                rm "$temp_aur_file"
            fi
        else
            install_from_file "aur/aur.txt" "paru" "$install_only_missing"
        fi
    else
        log_error "Ни один AUR helper (yay, paru) не установлен"
        exit 1
    fi
}

# Функция установки AUR пакетов для COSMIC от обычного пользователя
install_cosmic_aur_packages() {
    local install_only_missing="${1:-false}"
    
    # Если install_only_missing не передан как аргумент, проверяем переменную окружения PKGS_ARCH_MISSING_ONLY
    if [[ "$install_only_missing" == "${1:-false}" && -n "$PKGS_ARCH_MISSING_ONLY" ]]; then
        install_only_missing="$PKGS_ARCH_MISSING_ONLY"
    fi
    
    log_info "Установка AUR пакетов для среды COSMIC от обычного пользователя..."
    if command -v yay &> /dev/null; then
        install_from_file "aur/cosmic.txt" "yay" "$install_only_missing"
    elif command -v paru &> /dev/null; then
        install_from_file "aur/cosmic.txt" "paru" "$install_only_missing"
    else
        log_error "Ни один AUR helper (yay, paru) не установлен для установки пакетов COSMIC"
        exit 1
    fi
}