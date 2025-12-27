#!/bin/bash

# Основной модуль установки пакетов

# Проверяем, что другие модули загружены
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || {
        source "$SCRIPT_DIR/modules/config.sh"
        source "$SCRIPT_DIR/modules/package-manager.sh"
        source "$SCRIPT_DIR/modules/validator.sh"
        source "$SCRIPT_DIR/modules/desktop-manager.sh"
        source "$SCRIPT_DIR/modules/aur-handler.sh"
    }
fi

# Функция установки пакетов по категории
install_category() {
    local category="$1"
    local install_only_missing="${2:-false}"
    local selected_desktop="${3:-""}"
    
    # Если это AUR и выбранная среда пуста, проверяем переменную окружения
    if [[ "$category" == "aur" && -z "$selected_desktop" && -n "$DESKTOP_CHOICE_FILE" && -f "$DESKTOP_CHOICE_FILE" ]]; then
        selected_desktop=$(cat "$DESKTOP_CHOICE_FILE")
    fi
    
    case $category in
        "core")
            log_info "Установка базовых системных пакетов..."
            install_from_file "core/system.txt" "pacman" "$install_only_missing"
            install_from_file "core/base.txt" "pacman" "$install_only_missing"
            install_from_file "core/network.txt" "pacman" "$install_only_missing"
            ;;
        "desktop")
            log_info "Установка пакетов рабочего стола..."
            install_from_file "desktop/apps.txt" "pacman" "$install_only_missing"
            install_from_file "desktop/audio-video.txt" "pacman" "$install_only_missing"
            install_from_file "desktop/greeter.txt" "pacman" "$install_only_missing"
            ;;
        "niri")
            log_info "Установка пакетов для среды Niri..."
            install_from_file "desktop/niri.txt" "pacman" "$install_only_missing"
            ;;
        "cosmic")
            log_info "Установка пакетов для среды COSMIC..."
            
            # Проверяем, запущен ли скрипт от root и если да, переключаемся на обычного пользователя для AUR
            if [[ "$EUID" -eq 0 ]]; then
                log_info "Обнаружен запуск от root, переключаемся на обычного пользователя для установки AUR пакетов COSMIC..."
                local original_user=$(logname 2>/dev/null || whoami)
                if [[ -n "$original_user" && "$original_user" != "root" ]]; then
                    # Определяем абсолютный путь к основному скрипту
                    local script_absolute_path="$(get_project_root)/scripts/install.sh"
                    
                    # Выполняем установку AUR пакетов от имени обычного пользователя
                    if command -v sudo &> /dev/null; then
                        if [[ "$install_only_missing" == true ]]; then
                            sudo -u "$original_user" env "PROJECT_ROOT=$(get_project_root)" "$script_absolute_path" cosmic_aur_packages --missing-only
                        else
                            sudo -u "$original_user" env "PROJECT_ROOT=$(get_project_root)" "$script_absolute_path" cosmic_aur_packages
                        fi
                    else
                        if [[ "$install_only_missing" == true ]]; then
                            exec su "$original_user" -c "PROJECT_ROOT='$(get_project_root)' '$script_absolute_path' cosmic_aur_packages --missing-only"
                        else
                            exec su "$original_user" -c "PROJECT_ROOT='$(get_project_root)' '$script_absolute_path' cosmic_aur_packages"
                        fi
                    fi
                    return 0
                else
                    log_error "Не удалось определить оригинального пользователя для установки AUR пакетов"
                    exit 1
                fi
            fi
            
            # Если не запущен от root, выполняем установку напрямую
            if command -v yay &> /dev/null; then
                install_from_file "aur/cosmic.txt" "yay" "$install_only_missing"
            elif command -v paru &> /dev/null; then
                install_from_file "aur/cosmic.txt" "paru" "$install_only_missing"
            else
                log_error "Ни один AUR helper (yay, paru) не установлен для установки пакетов COSMIC"
                exit 1
            fi
            ;;
        "development")
            log_info "Установка пакетов для разработки..."
            install_from_file "development/utils.txt" "pacman" "$install_only_missing"
            ;;
        "fonts-themes")
            log_info "Установка шрифтов и тем..."
            install_from_file "fonts-themes/fonts.txt" "pacman" "$install_only_missing"
            ;;
        "hardware")
            log_info "Установка драйверов..."
            install_from_file "hardware/drivers.txt" "pacman" "$install_only_missing"
            ;;
        "virtualization")
            log_info "Установка пакетов виртуализации..."
            install_from_file "virtualization/virt.txt" "pacman" "$install_only_missing"
            ;;
        "aur")
            install_aur_packages "$install_only_missing" "$selected_desktop"
            ;;
        "all")
            log_info "Установка всех пакетов..."
            # Устанавливаем в логическом порядке
            install_category "core" "$install_only_missing" "$selected_desktop"
            install_category "hardware" "$install_only_missing" "$selected_desktop"
            install_category "virtualization" "$install_only_missing" "$selected_desktop"
            install_category "development" "$install_only_missing" "$selected_desktop"
            install_category "fonts-themes" "$install_only_missing" "$selected_desktop"
            install_category "desktop" "$install_only_missing" "$selected_desktop"
            
            # Запрашиваем у пользователя, какую среду рабочего стола установить
            local desktop_choice=""
            if [[ "$install_only_missing" == false ]]; then
                desktop_choice=$(select_desktop_interactive)
            else
                # Если устанавливаем только отсутствующие, просто уведомляем пользователя
                log_info "При установке только отсутствующих пакетов, среды рабочего стола нужно выбирать отдельно"
            fi
            
            # Установка специфичных пакетов для рабочего стола
            if [[ "$desktop_choice" != "none" && "$desktop_choice" != "4" ]]; then
                case $desktop_choice in
                    "niri")
                        install_category "niri" "$install_only_missing" "niri"
                        ;;
                    "cosmic")
                        install_category "cosmic" "$install_only_missing" "cosmic"
                        ;;
                    "both")
                        install_category "niri" "$install_only_missing" "both"
                        install_category "cosmic" "$install_only_missing" "both"
                        ;;
                esac
            fi
            
            # Установка AUR пакетов (включая cosmic, если требуется)
            install_category "aur" "$install_only_missing" "$desktop_choice"
            ;;
        "aur_with_desktop_choice")
            handle_aur_installation_with_desktop_choice "$install_only_missing" "$selected_desktop"
            ;;
        "cosmic_aur_packages")
            install_cosmic_aur_packages "$install_only_missing"
            ;;
        *)
            log_error "Неизвестная категория: $category"
            log_info "Доступные категории: core, desktop, niri, cosmic (пакеты из AUR), development, fonts-themes, hardware, virtualization, aur, all, all_with_aur, aur_with_desktop_choice, cosmic_aur_packages"
            exit 1
            ;;
    esac
}

# Функция установки всех пакетов
install_all() {
    local install_only_missing="${1:-false}"
    local desktop_choice="${2:-""}"
    
    install_category "all" "$install_only_missing" "$desktop_choice"
}

# Функция получения порядка установки категорий
get_install_order() {
    echo "core hardware virtualization development fonts-themes desktop"
}