#!/bin/bash

# Модуль управления рабочими столами

# Проверяем, что другие модули загружены
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || { 
        source "$SCRIPT_DIR/modules/config.sh"
        source "$SCRIPT_DIR/modules/package-manager.sh"
    }
fi

# Функция интерактивного выбора рабочего стола
select_desktop_interactive() {
    log_info "Выберите среду рабочего стола для установки:"
    echo "1) niri (установит пакеты из desktop/niri.txt, исключит cosmic пакеты из AUR)"
    echo "2) cosmic (установит пакеты из aur/cosmic.txt, исключит niri пакеты из установки)"
    echo "3) обе среды"
    echo "4) пропустить установку специфичных пакетов сред"
    echo ""
    echo "Подробное описание каждого выбора:"
    echo "  1. 'niri': Установит пакеты из файла desktop/niri.txt, которые подходят для среды Niri."
    echo "     При этом будут исключены пакеты COSMIC из установки AUR пакетов, чтобы избежать конфликта."
    echo "     Эта опция рекомендуется, если вы планируете использовать среду Niri в качестве основной."
    echo ""
    echo "  2. 'cosmic': Установит пакеты из файла aur/cosmic.txt, которые подходят для среды COSMIC."
    echo "     При этом будут исключены пакеты Niri из установки, чтобы избежать конфликта."
    echo "     Эта опция рекомендуется, если вы планируете использовать среду COSMIC в качестве основной."
    echo ""
    echo "  3. 'обе среды': Установит пакеты для обеих сред без исключений."
    echo "     Выберите эту опцию, если вы хотите иметь обе среды на вашей системе."
    echo "     Имейте в виду, что могут возникнуть конфликты между пакетами двух сред."
    echo ""
    echo "  4. 'пропустить установку': Не установит специфичные пакеты ни для одной из сред."
    echo "     Выберите эту опцию, если вы не хотите устанавливать специфичные пакеты"
    echo "     для Niri или Cosmic, или если вы планируете использовать другую среду."
    echo ""
    echo "Что делать дальше:"
    echo "  - Введите цифру от 1 до 4 и нажмите Enter для выбора опции"
    echo "  - После выбора установка продолжится с учетом вашего решения"
    echo ""
    read -p "Введите номер (1-4): [1-niri, 2-cosmic, 3-обе среды, 4-пропустить]: " choice
    
    case $choice in
        1)
            echo "niri"
            ;;
        2)
            echo "cosmic"
            ;;
        3)
            echo "both"
            ;;
        4|*)
            echo "none"
            ;;
    esac
}

# Функция исключения конфликтующих пакетов
exclude_conflicting_packages() {
    local packages_file="$1"
    local exclude_file="$2"
    local output_file="$3"
    
    if [[ -f "$packages_file" && -f "$exclude_file" ]]; then
        while IFS= read -r package; do
            if ! grep -Fxq "$package" "$exclude_file" 2>/dev/null; then
                echo "$package" >> "$output_file"
            fi
        done < "$packages_file"
    fi
}

# Функция получения специфичных пакетов для рабочего стола
get_desktop_specific_packages() {
    local desktop="$1"
    local project_root=$(get_project_root)
    
    case $desktop in
        "niri")
            echo "$project_root/desktop/niri.txt"
            ;;
        "cosmic")
            echo "$project_root/aur/cosmic.txt"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Функция применения конфигурации рабочего стола
apply_desktop_configuration() {
    local desktop="$1"
    local install_only_missing="${2:-false}"
    local package_manager="${3:-pacman}"
    
    case $desktop in
        "niri")
            log_info "Установка пакетов для среды Niri..."
            install_from_file "desktop/niri.txt" "pacman" "$install_only_missing"
            ;;
        "cosmic")
            log_info "Установка пакетов для среды COSMIC..."
            
            # Проверяем, установлен ли AUR helper
            if command -v yay &> /dev/null; then
                install_from_file "aur/cosmic.txt" "yay" "$install_only_missing"
            elif command -v paru &> /dev/null; then
                install_from_file "aur/cosmic.txt" "paru" "$install_only_missing"
            else
                log_error "Ни один AUR helper (yay, paru) не установлен для установки пакетов COSMIC"
                return 1
            fi
            ;;
        "both")
            apply_desktop_configuration "niri" "$install_only_missing" "$package_manager"
            apply_desktop_configuration "cosmic" "$install_only_missing" "$package_manager"
            ;;
    esac
}