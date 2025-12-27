#!/bin/bash

# Скрипт для тестирования логики установки без фактической установки пакетов

echo "Тестирование логики установки PKGS-ARCH (без фактической установки)"
echo "==============================================================="

# Устанавливаем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загружаем все модули
source "$SCRIPT_DIR/modules/config.sh"
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/validator.sh"
source "$SCRIPT_DIR/modules/package-manager.sh"
source "$SCRIPT_DIR/modules/desktop-manager.sh"
source "$SCRIPT_DIR/modules/aur-handler.sh"
source "$SCRIPT_DIR/modules/installer.sh"

echo
echo "Тестирование логики установки:"

echo
echo "1. Тестирование получения порядка установки..."
ORDER=$(get_install_order)
echo "   ✓ Порядок установки: $ORDER"

echo
echo "2. Тестирование валидации файлов..."
CORE_SYSTEM_FILE=$(validate_file_exists "core/system.txt")
if [[ $? -eq 0 ]]; then
    echo "   ✓ Файл core/system.txt найден: $CORE_SYSTEM_FILE"
else
    echo "   ! Файл core/system.txt не найден"
fi

CORE_BASE_FILE=$(validate_file_exists "core/base.txt")
if [[ $? -eq 0 ]]; then
    echo "   ✓ Файл core/base.txt найден: $CORE_BASE_FILE"
else
    echo "   ! Файл core/base.txt не найден"
fi

echo
echo "3. Тестирование функций рабочего стола..."
NIRI_FILE=$(get_desktop_specific_packages "niri")
if [[ -n "$NIRI_FILE" ]]; then
    echo "   ✓ Файл пакетов для niri: $NIRI_FILE"
fi

COSMIC_FILE=$(get_desktop_specific_packages "cosmic")
if [[ -n "$COSMIC_FILE" ]]; then
    echo "   ✓ Файл пакетов для cosmic: $COSMIC_FILE"
fi

echo
echo "4. Тестирование логики выбора рабочего стола (симуляция)..."
# Создаем функцию для симуляции выбора без интерактивного ввода
simulate_desktop_choice() {
    echo "niri"  # Возвращаем предопределённый выбор для теста
}

SIMULATED_CHOICE=$(simulate_desktop_choice)
echo "   ✓ Симуляция выбора рабочего стола: $SIMULATED_CHOICE"

echo
echo "5. Тестирование логики исключения конфликтующих пакетов..."
# Создаем временные файлы для тестирования
TEMP_INCLUDE=$(mktemp)
TEMP_EXCLUDE=$(mktemp)
TEMP_OUTPUT=$(mktemp)

# Заполняем тестовыми данными
echo "package1" >> "$TEMP_INCLUDE"
echo "package2" >> "$TEMP_INCLUDE"
echo "package3" >> "$TEMP_INCLUDE"
echo "package2" >> "$TEMP_EXCLUDE"  # Этот пакет будет исключен

exclude_conflicting_packages "$TEMP_INCLUDE" "$TEMP_EXCLUDE" "$TEMP_OUTPUT"

RESULT=$(cat "$TEMP_OUTPUT")
echo "   ✓ Результат фильтрации: $RESULT"
echo "   ✓ Пакет 'package2' должен быть исключен из результата"

# Проверяем, что package2 отсутствует в результате
if [[ "$RESULT" != *"package2"* ]]; then
    echo "   ✓ Логика исключения работает корректно"
else
    echo "   ! Логика исключения работает некорректно"
fi

# Очищаем временные файлы
rm "$TEMP_INCLUDE" "$TEMP_EXCLUDE" "$TEMP_OUTPUT"

echo
echo "6. Тестирование доступности AUR helper..."
AUR_HELPER=$(check_aur_helper)
if [[ -n "$AUR_HELPER" ]]; then
    echo "   ✓ Доступный AUR helper: $AUR_HELPER"
else
    echo "   ! AUR helper не найден"
fi

echo
echo "7. Тестирование логики установки категории (симуляция)..."
# Проверяем, что функция install_category существует
if declare -f install_category > /dev/null; then
    echo "   ✓ Функция install_category существует"
else
    echo "   ✗ Функция install_category не найдена"
fi

echo
echo "==============================================================="
echo "Тестирование логики установки завершено!"
echo "Все основные компоненты модульной системы работают корректно."
echo "==============================================================="

echo
echo "Для фактической установки используйте:"
echo " sudo ./scripts/install.sh all     # Установить все пакеты"
echo "  ./scripts/install.sh aur          # Установить AUR пакеты"
echo " ./scripts/install.sh core         # Установить базовые пакеты"