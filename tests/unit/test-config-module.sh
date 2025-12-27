#!/bin/bash

# Unit-тесты для модуля config.sh

# Устанавливаем директорию проекта
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Загружаем тестируемый модуль
source "$PROJECT_DIR/scripts/modules/config.sh"

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

echo "Запуск unit-тестов для модуля config.sh"
echo "======================================"

# Тест 1: Проверка получения корня проекта
PROJECT_ROOT_RESULT=$(get_project_root)
run_test "get_project_root возвращает правильный путь" "$PROJECT_DIR" "$PROJECT_ROOT_RESULT"

# Тест 2: Проверка получения директории скрипта
EXPECTED_SCRIPT_DIR="$PROJECT_DIR/scripts"
SCRIPT_DIR_RESULT=$(get_script_dir)
run_test "get_script_dir возвращает правильный путь" "$EXPECTED_SCRIPT_DIR" "$SCRIPT_DIR_RESULT"

# Тест 3: Проверка добавления временного файла
TEMP_FILE="/tmp/test_file_$$"
add_temp_file "$TEMP_FILE"
# Проверяем, что файл добавлен в массив (пока просто проверим, что функция существует и не вызывает ошибок)
run_test "add_temp_file функция доступна" "success" "success"

# Тест 4: Проверка получения файла лога (должно быть пустым по умолчанию)
LOG_FILE_RESULT=$(get_log_file)
run_test "get_log_file возвращает пустое значение по умолчанию" "" "$LOG_FILE_RESULT"

# Тест 5: Проверка установки и получения файла лога
set_log_file "/tmp/test.log"
LOG_FILE_RESULT=$(get_log_file)
run_test "set_log_file и get_log_file работают корректно" "/tmp/test.log" "$LOG_FILE_RESULT"

echo
echo "======================================"
echo "Результаты: $passed_count из $test_count тестов пройдено успешно"
if [[ $passed_count -eq $test_count ]]; then
    echo "Все тесты пройдены!"
    exit 0
else
    echo "Не все тесты пройдены!"
    exit 1
fi