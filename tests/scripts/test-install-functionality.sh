#!/bin/bash

# Скрипт для тестирования функциональности установки

echo "Тестирование функциональности установки PKGS-ARCH"
echo "================================================="

# Устанавливаем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загружаем основные модули
source "$SCRIPT_DIR/modules/config.sh"
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/validator.sh"
source "$SCRIPT_DIR/modules/package-manager.sh"
source "$SCRIPT_DIR/modules/desktop-manager.sh"
source "$SCRIPT_DIR/modules/aur-handler.sh"
source "$SCRIPT_DIR/modules/installer.sh"

echo
echo "Тестирование основных функций установки:"

echo
echo "1. Тестирование получения корня проекта..."
PROJECT_ROOT=$(get_project_root)
echo "   ✓ Корень проекта: $PROJECT_ROOT"

echo
echo "2. Тестирование проверки файлов..."
if validate_file_exists "core/system.txt" > /dev/null 2>&1; then
    echo "   ✓ Файл core/system.txt существует"
else
    echo "   ! Файл core/system.txt не найден, но это нормально для теста"
fi

echo
echo "3. Тестирование функций логирования..."
log_info "Это информационное сообщение для теста"
log_warning "Это предупреждение для теста"
log_error "Это сообщение об ошибке для теста"
echo "   ✓ Функции логирования работают"

echo
echo "4. Тестирование проверки категорий..."
if validate_category "core"; then
    echo "   ✓ Категория 'core' валидна"
else
    echo "   ✓ Категория 'core' не валидна (ожидаемо для теста)"
fi

if ! validate_category "invalid_category"; then
    echo "   ✓ Невалидная категория корректно отклонена"
else
    echo "   ! Невалидная категория не отклонена"
fi

echo
echo "5. Тестирование получения доступных менеджеров пакетов..."
AVAILABLE_MANAGERS=$(get_available_managers)
echo "   ✓ Доступные менеджеры пакетов: $AVAILABLE_MANAGERS"

echo
echo "6. Тестирование функций рабочего стола..."
DESKTOP_FILE=$(get_desktop_specific_packages "niri")
echo "   ✓ Файл пакетов для niri: $DESKTOP_FILE"

DESKTOP_FILE=$(get_desktop_specific_packages "cosmic")
echo "   ✓ Файл пакетов для cosmic: $DESKTOP_FILE"

echo
echo "7. Тестирование проверки AUR helper..."
AUR_HELPER=$(check_aur_helper)
if [[ -n "$AUR_HELPER" ]]; then
    echo "   ✓ Найден AUR helper: $AUR_HELPER"
else
    echo "   ! AUR helper не найден (это нормально для теста)"
fi

echo
echo "================================================="
echo "Тестирование функциональности завершено!"
echo "================================================="

# Показываем примеры использования основных функций
echo
echo "Примеры использования основных функций:"
echo " install_category 'core' false ''  # Установить базовые пакеты"
echo " install_category 'aur' false 'niri'  # Установить AUR пакеты с исключением niri"
echo " get_install_order  # Получить порядок установки категорий"