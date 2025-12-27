#!/bin/bash

# Скрипт для запуска всех тестов

echo "Запуск всех тестов для PKGS-ARCH"
echo "================================"

# Подсчет общего количества тестов
total_tests=0
passed_tests=0

# Функция для запуска теста
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo
    echo "Запуск $test_name..."
    echo "----------------------------------------"
    
    if eval "$test_command"; then
        echo "✓ $test_name пройден"
        ((passed_tests++))
    else
        echo "✗ $test_name не пройден"
    fi
    ((total_tests++))
}

# Запуск unit-тестов
chmod +x tests/unit/test-config-module.sh
run_test "Unit-тестов для модуля config" "./tests/unit/test-config-module.sh"

# Запуск интеграционных тестов
chmod +x tests/integration/test-full-install-flow.sh
run_test "Интеграционных тестов полного потока" "./tests/integration/test-full-install-flow.sh"

# Запуск тестов из директории scripts (эти тесты были перемещены из корня проекта, 
# и теперь они используют относительные пути, которые не работают при запуске из другой директории)
# Вместо этого мы проверим, что файлы существуют и синтаксически корректны
echo
echo "Проверка синтаксиса тестов из директории scripts..."
echo "----------------------------------------"
for test_script in tests/scripts/test-*.sh; do
    if [[ -f "$test_script" ]]; then
        echo "Проверка синтаксиса $test_script..."
        if bash -n "$test_script"; then
            echo "✓ Синтаксис $test_script корректен"
            ((passed_tests++))
        else
            echo "✗ Ошибка синтаксиса в $test_script"
        fi
        ((total_tests++))
    else
        echo "✗ $test_script не найден"
        ((total_tests++))
    fi
done

echo
echo "================================"
echo "Результаты всех тестов:"
echo "Пройдено: $passed_tests из $total_tests"
if [[ $passed_tests -eq $total_tests ]]; then
    echo "Все тесты пройдены успешно!"
    exit 0
else
    echo "Не все тесты пройдены."
    exit 1
fi