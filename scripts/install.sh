#!/bin/bash

# Скрипт для автоматической установки пакетов из списков проекта PKGS-ARCH
# Использование: ./scripts/install.sh [категория]

set -e  # Выход при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав суперпользователя для установки системных пакетов
check_sudo() {
    if [ "$EUID" -ne 0 ] && [ "$1" != "aur" ]; then
        print_error "Для установки системных пакетов требуется запуск с правами суперпользователя"
        print_message "Используйте: sudo ./scripts/install.sh или запустите скрипт от root"
        exit 1
    fi
}

# Функция установки пакетов из файла
install_from_file() {
    local file_path=$1
    local package_manager=$2
    
    if [ ! -f "$file_path" ]; then
        print_warning "Файл $file_path не найден, пропускаем..."
        return 0
    fi
    
    if [ ! -s "$file_path" ]; then
        print_warning "Файл $file_path пуст, пропускаем..."
        return 0
    fi
    
    print_message "Установка пакетов из $file_path"
    
    case $package_manager in
        "pacman")
            pacman -S --needed - < "$file_path"
            ;;
        "yay"|"paru")
            # Проверяем, установлен ли AUR helper
            if command -v $package_manager &> /dev/null; then
                $package_manager -S --needed - < "$file_path"
            else
                print_warning "$package_manager не установлен, пропускаем установку из AUR"
            fi
            ;;
    esac
}

# Основная функция установки
install_packages() {
    local category=$1
    
    case $category in
        "core")
            print_message "Установка базовых системных пакетов..."
            install_from_file "core/system.txt" "pacman"
            install_from_file "core/base.txt" "pacman"
            install_from_file "core/network.txt" "pacman"
            ;;
        "desktop")
            print_message "Установка пакетов рабочего стола..."
            install_from_file "desktop/apps.txt" "pacman"
            install_from_file "desktop/audio-video.txt" "pacman"
            install_from_file "desktop/greeter.txt" "pacman"
            ;;
        "niri")
            print_message "Установка пакетов для среды Niri..."
            install_from_file "desktop/niri.txt" "pacman"
            ;;
        "cosmic")
            print_message "Установка пакетов для среды COSMIC..."
            # Проверяем, какой AUR helper установлен
            if command -v yay &> /dev/null; then
                install_from_file "aur/cosmic.txt" "yay"
            elif command -v paru &> /dev/null; then
                install_from_file "aur/cosmic.txt" "paru"
            else
                print_error "Ни один AUR helper (yay, paru) не установлен для установки пакетов COSMIC"
                exit 1
            fi
            ;;
        "development")
            print_message "Установка пакетов для разработки..."
            install_from_file "development/utils.txt" "pacman"
            ;;
        "fonts-themes")
            print_message "Установка шрифтов и тем..."
            install_from_file "fonts-themes/fonts.txt" "pacman"
            ;;
        "hardware")
            print_message "Установка драйверов..."
            install_from_file "hardware/drivers.txt" "pacman"
            ;;
        "virtualization")
            print_message "Установка пакетов виртуализации..."
            install_from_file "virtualization/virt.txt" "pacman"
            ;;
        "aur")
            print_message "Установка пакетов из AUR..."
            # Проверяем, какой AUR helper установлен
            if command -v yay &> /dev/null; then
                install_from_file "aur/aur.txt" "yay"
            elif command -v paru &> /dev/null; then
                install_from_file "aur/aur.txt" "paru"
            else
                print_error "Ни один AUR helper (yay, paru) не установлен"
                exit 1
            fi
            ;;
        "all")
            print_message "Установка всех пакетов..."
            # Устанавливаем в логическом порядке
            install_packages "core"
            install_packages "hardware"
            install_packages "virtualization"
            install_packages "desktop"
            # Установка niri или cosmic по выбору пользователя:
            # install_packages "niri"  # Для среды Niri (все пакеты в одном файле)
            # install_packages "cosmic"  # Для среды COSMIC (пакеты из AUR)
            install_packages "development"
            install_packages "fonts-themes"
            # Установка AUR пакетов (включая cosmic, если требуется)
            # install_packages "aur"  # Установка пакетов из AUR, включая COSMIC
            ;;
        *)
            print_error "Неизвестная категория: $category"
            print_message "Доступные категории: core, desktop, niri, cosmic (пакеты из AUR), development, fonts-themes, hardware, virtualization, aur, all"
            exit 1
            ;;
    esac
}

# Проверка аргументов командной строки
if [ $# -eq 0 ]; then
    print_message "Использование: $0 <категория>"
    print_message "Доступные категории: core, desktop, niri, cosmic (пакеты из AUR), development, fonts-themes, hardware, virtualization, aur, all"
    print_message "Для установки системных пакетов запустите с sudo: sudo $0 <категория>"
    print_message "Для установки AUR пакетов запустите без sudo: $0 aur"
    exit 0
fi

# Получаем категорию из аргумента
CATEGORY=$1

# Для AUR не нужен sudo, для остальных - нужен
if [ "$CATEGORY" != "aur" ]; then
    check_sudo
fi

# Выполняем установку
install_packages "$CATEGORY"

print_message "Установка завершена!"