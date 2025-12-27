#!/bin/bash

# Скрипт для тестирования использования основного скрипта установки

echo "Тестирование использования скрипта установки PKGS-ARCH"
echo "====================================================="

# Устанавливаем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "Тестирование основного скрипта установки..."

# Проверяем существование скрипта
if [[ ! -f "$SCRIPT_DIR/install.sh" ]]; then
    echo "   ✗ Основной скрипт установки не найден"
    exit 1
fi

echo "   ✓ Основной скрипт установки существует"

# Проверяем права на выполнение
if [[ -x "$SCRIPT_DIR/install.sh" ]]; then
    echo "   ✓ Скрипт установки имеет права на выполнение"
else
    echo "   ! Скрипт установки не имеет прав на выполнение, пытаемся установить..."
    chmod +x "$SCRIPT_DIR/install.sh"
    if [[ $? -eq 0 ]]; then
        echo "   ✓ Права на выполнение установлены"
    else
        echo "   ✗ Не удалось установить права на выполнение"
        exit 1
    fi
fi

echo
echo "Тестирование синтаксиса скрипта..."
if bash -n "$SCRIPT_DIR/install.sh"; then
    echo "   ✓ Синтаксис скрипта корректен"
else
    echo "   ✗ Ошибка синтаксиса в скрипте"
    exit 1
fi

echo
echo "Тестирование парсинга аргументов (без выполнения установки)..."

# Проверяем, что скрипт может быть загружен без ошибок
echo "1. Тестирование загрузки модулей..."
if bash -c "source $SCRIPT_DIR/modules/config.sh && source $SCRIPT_DIR/modules/logging.sh && source $SCRIPT_DIR/modules/validator.sh && source $SCRIPT_DIR/modules/package-manager.sh && source $SCRIPT_DIR/modules/desktop-manager.sh && source $SCRIPT_DIR/modules/aur-handler.sh && source $SCRIPT_DIR/modules/installer.sh && source $SCRIPT_DIR/helpers/arg-parser.sh"; then
    echo "   ✓ Все модули успешно загружаются"
else
    echo "   ✗ Ошибка при загрузке модулей"
    exit 1
fi

echo
echo "2. Тестирование функции парсинга аргументов..."
# Создаем временный скрипт для тестирования парсера
TEST_PARSER_SCRIPT=$(mktemp)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat > "$TEST_PARSER_SCRIPT" << EOF
#!/bin/bash
SCRIPT_DIR="$PROJECT_ROOT_DIR/scripts"
source "\$SCRIPT_DIR/modules/config.sh"
source "\$SCRIPT_DIR/modules/logging.sh"
source "\$SCRIPT_DIR/helpers/arg-parser.sh"

# Сохраняем оригинальные аргументы для тестирования
set -- "test_category" "--missing-only" "--log-file" "/tmp/test.log"

parse_arguments "\$@"

echo "CATEGORY: \$PKGS_ARCH_CATEGORY"
echo "MISSING_ONLY: \$PKGS_ARCH_MISSING_ONLY"
echo "LOG_FILE: \$PKGS_ARCH_LOG_FILE"
EOF

chmod +x "$TEST_PARSER_SCRIPT"
PARSER_OUTPUT=$(bash "$TEST_PARSER_SCRIPT")
echo "$PARSER_OUTPUT"

if [[ "$PARSER_OUTPUT" == *"CATEGORY: test_category"* && "$PARSER_OUTPUT" == *"MISSING_ONLY: true"* && "$PARSER_OUTPUT" == *"LOG_FILE: /tmp/test.log"* ]]; then
    echo "   ✓ Парсер аргументов работает корректно"
else
    echo "   ✗ Парсер аргументов работает некорректно"
    rm "$TEST_PARSER_SCRIPT"
    exit 1
fi

rm "$TEST_PARSER_SCRIPT"

echo
echo "3. Тестирование основных функций из скрипта установки..."
# Создаем тестовый скрипт для проверки основных функций
TEST_INSTALLER_SCRIPT=$(mktemp)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat > "$TEST_INSTALLER_SCRIPT" << EOF
#!/bin/bash
SCRIPT_DIR="$PROJECT_ROOT_DIR/scripts"
source "\$SCRIPT_DIR/modules/config.sh"
source "\$SCRIPT_DIR/modules/logging.sh"
source "\$SCRIPT_DIR/modules/validator.sh"
source "\$SCRIPT_DIR/modules/package-manager.sh"
source "\$SCRIPT_DIR/modules/desktop-manager.sh"
source "\$SCRIPT_DIR/modules/aur-handler.sh"
source "\$SCRIPT_DIR/modules/installer.sh"

# Тестируем основные функции
echo "PROJECT_ROOT: \$(get_project_root)"
echo "INSTALL_ORDER: \$(get_install_order)"

# Проверяем валидацию категории
if validate_category "core"; then
    echo "VALID_CATEGORY: core is valid"
else
    echo "VALID_CATEGORY: core is invalid"
fi

if ! validate_category "invalid"; then
    echo "INVALID_CATEGORY: invalid is correctly rejected"
else
    echo "INVALID_CATEGORY: invalid is not rejected"
fi
EOF

chmod +x "$TEST_INSTALLER_SCRIPT"
INSTALLER_OUTPUT=$(bash "$TEST_INSTALLER_SCRIPT")
echo "$INSTALLER_OUTPUT"
rm "$TEST_INSTALLER_SCRIPT"

echo
echo "====================================================="
echo "Тестирование использования скрипта установки завершено!"
echo "====================================================="

echo
echo "Доступные команды для запуска (не запускаются в тесте):"
echo "  ./scripts/install.sh                           # Показать справку"
echo "  ./scripts/install.sh all                       # Установить все пакеты"
echo "  ./scripts/install.sh core                      # Установить базовые пакеты"
echo " ./scripts/install.sh aur                       # Установить AUR пакеты"
echo "  ./scripts/install.sh --missing-only            # Установить только отсутствующие"
echo "  ./scripts/install.sh core --log-file /tmp/install.log  # Установить с логированием"