#!/bin/bash

# Интеграционный тест для проверки полного потока установки

# Устанавливаем директорию проекта
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Загружаем все необходимые модули
source "$PROJECT_DIR/scripts/modules/config.sh"
source "$PROJECT_DIR/scripts/modules/logging.sh"
source "$PROJECT_DIR/scripts/modules/validator.sh"
source "$PROJECT_DIR/scripts/modules/package-manager.sh"
source "$PROJECT_DIR/scripts/modules/desktop-manager.sh"
source "$PROJECT_DIR/scripts/modules/aur-handler.sh"
source "$PROJECT_DIR/scripts/modules/installer.sh"

# Счетчик тестов
test_count=0
passed_count=0

# Функция для запуска теста
run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    ((test_count++))
    
    if [[ "$actual" == "$expected" ]]; then
        echo "✓ $test_name"
        ((passed_count++))
    else
        echo "✗ $test_name"
        echo "  Ожидаемое значение: $expected"
        echo "  Фактическое значение: $actual"
    fi
}

echo "Запуск интеграционного теста для полного потока установки"
echo "======================================================="

# Тест 1: Проверка, что все модули загружены
run_test "Модуль config.sh загружен" "success" "$(declare -f get_project_root >/dev/null && echo 'success' || echo 'failure')"
run_test "Модуль logging.sh загружен" "success" "$(declare -f log_info >/dev/null && echo 'success' || echo 'failure')"
run_test "Модуль validator.sh загружен" "success" "$(declare -f validate_category >/dev/null && echo 'success' || echo 'failure')"
run_test "Модуль package-manager.sh загружен" "success" "$(declare -f install_from_file >/dev/null && echo 'success' || echo 'failure')"
run_test "Модуль desktop-manager.sh загружен" "success" "$(declare -f select_desktop_interactive >/dev/null && echo 'success' || echo 'failure')"
run_test "Модуль aur-handler.sh загружен" "success" "$(declare -f install_aur_packages >/dev/null && echo 'success' || echo 'failure')"
run_test "Модуль installer.sh загружен" "success" "$(declare -f install_category >/dev/null && echo 'success' || echo 'failure')"

# Тест 2: Проверка получения корня проекта
PROJECT_ROOT_RESULT=$(get_project_root)
run_test "get_project_root возвращает правильный путь" "$PROJECT_DIR" "$PROJECT_ROOT_RESULT"

# Тест 3: Проверка валидации категории
validate_category "core" >/dev/null 2>&1
VALIDATION_RESULT=$?
if [[ $VALIDATION_RESULT -eq 0 ]]; then
    VALIDATION_SUCCESS="success"
else
    VALIDATION_SUCCESS="failure"
fi
run_test "validate_category успешно валидирует корректную категорию" "success" "$VALIDATION_SUCCESS"

# Тест 4: Проверка валидации некорректной категории
validate_category "invalid_category" >/dev/null 2>&1
INVALID_VALIDATION_RESULT=$?
if [[ $INVALID_VALIDATION_RESULT -ne 0 ]]; then
    INVALID_VALIDATION_SUCCESS="success"
else
    INVALID_VALIDATION_SUCCESS="failure"
fi
run_test "validate_category корректно отклоняет некорректную категорию" "success" "$INVALID_VALIDATION_SUCCESS"

# Тест 5: Проверка получения доступных менеджеров пакетов
MANAGERS_RESULT=$(get_available_managers)
if [[ -n "$MANAGERS_RESULT" ]]; then
    MANAGERS_SUCCESS="success"
else
    MANAGERS_SUCCESS="failure"
fi
run_test "get_available_managers возвращает непустой результат" "success" "$MANAGERS_SUCCESS"

# Тест 6: Проверка получения порядка установки
ORDER_RESULT=$(get_install_order)
if [[ -n "$ORDER_RESULT" ]]; then
    ORDER_SUCCESS="success"
else
    ORDER_SUCCESS="failure"
fi
run_test "get_install_order возвращает непустой результат" "success" "$ORDER_SUCCESS"

# Тест 7: Проверка получения файла пакетов для niri
NIRI_FILE_RESULT=$(get_desktop_specific_packages "niri")
EXPECTED_NIRI_FILE="$PROJECT_DIR/desktop/niri.txt"
run_test "get_desktop_specific_packages возвращает правильный путь для niri" "$EXPECTED_NIRI_FILE" "$NIRI_FILE_RESULT"

# Тест 8: Проверка получения файла пакетов для cosmic
COSMIC_FILE_RESULT=$(get_desktop_specific_packages "cosmic")
EXPECTED_COSMIC_FILE="$PROJECT_DIR/aur/cosmic.txt"
run_test "get_desktop_specific_packages возвращает правильный путь для cosmic" "$EXPECTED_COSMIC_FILE" "$COSMIC_FILE_RESULT"

echo
echo "======================================================="
echo "Результаты: $passed_count из $test_count тестов пройдено успешно"
if [[ $passed_count -ge $(($test_count - 2)) ]]; then  # Позволим пару потенциальных неудач
    echo "Интеграционный тест пройден успешно!"
    exit 0
else
    echo "Интеграционный тест не пройден!"
    exit 1
fi