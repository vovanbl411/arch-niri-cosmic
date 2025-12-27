#!/bin/bash

# Модуль управления пакетами

# Проверяем, что другие модули загружены
if ! declare -f log_error >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$SCRIPT_DIR/modules/logging.sh" || { 
        source "$SCRIPT_DIR/modules/config.sh"
        source "$SCRIPT_DIR/modules/validator.sh"
    }
fi

# Функция установки пакетов из файла
install_from_file() {
    local file_path="$1"
    local package_manager="$2"
    local install_only_missing="${3:-false}"
    
    # Валидируем существование файла
    local validated_file
    validated_file=$(validate_file_exists "$file_path")
    if [[ $? -ne 0 ]]; then
        return 0
    fi
    
    file_path="$validated_file"
    
    # Проверяем, что файл не пуст
    if [[ ! -s "$file_path" ]]; then
        log_warning "Файл $file_path пуст, пропускаем..."
        return 0
    fi
    
    log_info "Установка пакетов из $file_path"
    
    # Если нужно установить только отсутствующие пакеты, фильтруем их
    if [[ "$install_only_missing" == true ]]; then
        log_info "Фильтрация уже установленных пакетов..."
        local temp_file=$(mktemp)
        add_temp_file "$temp_file"
        local package_list
        package_list=$(cat "$file_path")
        
        # Определяем, какие пакеты уже установлены
        case $package_manager in
            "pacman")
                # Для pacman проверяем каждый пакет
                for pkg in $package_list; do
                    if ! pacman -Q "$pkg" &>/dev/null; then
                        echo "$pkg" >> "$temp_file"
                    fi
                done
                ;;
            "yay"|"paru")
                # Для AUR helpers проверяем через pacman и yay/paru
                for pkg in $package_list; do
                    if ! pacman -Q "$pkg" &>/dev/null; then
                        # Проверяем, возможно это AUR пакет
                        if command -v $package_manager &> /dev/null; then
                            # Простая проверка - если пакет не в pacman, добавляем в список
                            # Более точная проверка потребовала бы запроса к AUR
                            echo "$pkg" >> "$temp_file"
                        fi
                    fi
                done
                ;;
        esac
        
        # Проверяем, остались ли пакеты для установки
        if [[ ! -s "$temp_file" ]]; then
            log_info "Все пакеты из $file_path уже установлены"
            rm "$temp_file"
            return 0
        fi
        
        log_info "Найдено $(wc -l < "$temp_file") пакетов для установки"
        case $package_manager in
            "pacman")
                if ! pacman -S --needed - < "$temp_file"; then
                    log_error "Ошибка при установке пакетов из $file_path с помощью pacman"
                    log_warning "Продолжение установки других пакетов..."
                    # Не возвращаем ошибку, чтобы установка продолжалась
                fi
                ;;
            "yay"|"paru")
                # Проверяем, установлен ли AUR helper
                if command -v $package_manager &> /dev/null; then
                    if ! $package_manager -S --needed - < "$temp_file"; then
                        log_error "Ошибка при установке пакетов из $file_path с помощью $package_manager"
                        log_warning "Продолжение установки других пакетов..."
                        # Не возвращаем ошибку, чтобы установка продолжалась
                    fi
                else
                    log_warning "$package_manager не установлен, пропускаем установку из AUR"
                fi
                ;;
        esac
        
        rm "$temp_file"
    else
        # Стандартная установка без фильтрации
        case $package_manager in
            "pacman")
                if ! pacman -S --needed - < "$file_path"; then
                    log_error "Ошибка при установке пакетов из $file_path с помощью pacman"
                    log_warning "Продолжение установки других пакетов..."
                    # Не возвращаем ошибку, чтобы установка продолжалась
                fi
                ;;
            "yay"|"paru")
                # Проверяем, установлен ли AUR helper
                if command -v $package_manager &> /dev/null; then
                    if ! $package_manager -S --needed - < "$file_path"; then
                        log_error "Ошибка при установке пакетов из $file_path с помощью $package_manager"
                        log_warning "Продолжение установки других пакетов..."
                        # Не возвращаем ошибку, чтобы установка продолжалась
                    fi
                else
                    log_warning "$package_manager не установлен, пропускаем установку из AUR"
                fi
                ;;
        esac
    fi
}

# Функция установки пакетов из содержимого файла (для временных файлов)
install_from_content() {
    local content="$1"
    local package_manager="$2"
    local install_only_missing="${3:-false}"
    
    local temp_file=$(mktemp)
    add_temp_file "$temp_file"
    echo "$content" > "$temp_file"
    
    install_from_file "$temp_file" "$package_manager" "$install_only_missing"
}

# Функция проверки установки пакета
is_package_installed() {
    local package_name="$1"
    local package_manager="${2:-pacman}"
    
    case $package_manager in
        "pacman")
            pacman -Q "$package_name" &>/dev/null
            return $?
            ;;
        "yay"|"paru")
            # Проверяем сначала в pacman, затем в AUR
            if pacman -Q "$package_name" &>/dev/null; then
                return 0
            else
                # Для AUR пакетов проверяем через AUR helper
                $package_manager -Qs "$package_name" &>/dev/null
                return $?
            fi
            ;;
    esac
}

# Функция получения доступных менеджеров пакетов
get_available_managers() {
    local managers=()
    
    if command -v pacman &> /dev/null; then
        managers+=("pacman")
    fi
    
    if command -v yay &> /dev/null; then
        managers+=("yay")
    fi
    
    if command -v paru &> /dev/null; then
        managers+=("paru")
    fi
    
    echo "${managers[@]}"
}

# Функция фильтрации установленных пакетов из списка
filter_installed_packages() {
    local packages_list="$1"
    local package_manager="${2:-pacman}"
    local temp_file=$(mktemp)
    add_temp_file "$temp_file"
    
    for pkg in $packages_list; do
        if ! is_package_installed "$pkg" "$package_manager"; then
            echo "$pkg" >> "$temp_file"
        fi
    done
    
    cat "$temp_file"
}