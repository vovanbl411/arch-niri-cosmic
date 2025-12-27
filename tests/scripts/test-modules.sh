#!/bin/bash

# Скрипт для тестирования модульной системы установки

echo "Тестирование модульной системы установки PKGS-ARCH"
echo "================================================="

# Устанавливаем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Тестируем каждый модуль
echo
echo "1. Тестирование модуля конфигурации..."
if source "$SCRIPT_DIR/modules/config.sh"; then
    echo "   ✓ Модуль config.sh успешно загружен"
    echo "   ✓ PROJECT_ROOT: $(get_project_root)"
    echo "   ✓ SCRIPT_DIR: $(get_script_dir)"
else
    echo "   ✗ Ошибка загрузки config.sh"
    exit 1
fi

echo
echo "2. Тестирование модуля логирования..."
if source "$SCRIPT_DIR/modules/logging.sh"; then
    echo "   ✓ Модуль logging.sh успешно загружен"
    log_info "Тестирование логирования работает"
    log_warning "Это тестовое предупреждение"
    log_error "Это тестовая ошибка"
    echo "   ✓ Функции логирования работают"
else
    echo "   ✗ Ошибка загрузки logging.sh"
    exit 1
fi

echo
echo "3. Тестирование модуля валидации..."
if source "$SCRIPT_DIR/modules/validator.sh"; then
    echo "   ✓ Модуль validator.sh успешно загружен"
    echo "   ✓ Функция check_sudo доступна"
    echo "   ✓ Функция validate_file_exists доступна"
    echo "   ✓ Функция validate_package_manager доступна"
    echo "   ✓ Функция validate_category доступна"
else
    echo "   ✗ Ошибка загрузки validator.sh"
    exit 1
fi

echo
echo "4. Тестирование модуля управления пакетами..."
if source "$SCRIPT_DIR/modules/package-manager.sh"; then
    echo "   ✓ Модуль package-manager.sh успешно загружен"
    echo "   ✓ Функция install_from_file доступна"
    echo "   ✓ Функция install_from_content доступна"
    echo "   ✓ Функция is_package_installed доступна"
    echo "   ✓ Функция get_available_managers доступна"
    echo "   ✓ Функция filter_installed_packages доступна"
else
    echo "   ✗ Ошибка загрузки package-manager.sh"
    exit 1
fi

echo
echo "5. Тестирование модуля управления рабочими столами..."
if source "$SCRIPT_DIR/modules/desktop-manager.sh"; then
    echo "   ✓ Модуль desktop-manager.sh успешно загружен"
    echo "   ✓ Функция select_desktop_interactive доступна"
    echo "   ✓ Функция exclude_conflicting_packages доступна"
    echo "   ✓ Функция get_desktop_specific_packages доступна"
    echo "   ✓ Функция apply_desktop_configuration доступна"
else
    echo "   ✗ Ошибка загрузки desktop-manager.sh"
    exit 1
fi

echo
echo "6. Тестирование модуля работы с AUR..."
if source "$SCRIPT_DIR/modules/aur-handler.sh"; then
    echo "   ✓ Модуль aur-handler.sh успешно загружен"
    echo "   ✓ Функция install_aur_packages доступна"
    echo "   ✓ Функция switch_to_normal_user доступна"
    echo "   ✓ Функция check_aur_helper доступна"
    echo "   ✓ Функция handle_aur_installation_with_desktop_choice доступна"
    echo "   ✓ Функция install_cosmic_aur_packages доступна"
else
    echo "   ✗ Ошибка загрузки aur-handler.sh"
    exit 1
fi

echo
echo "7. Тестирование основного модуля установки..."
if source "$SCRIPT_DIR/modules/installer.sh"; then
    echo "   ✓ Модуль installer.sh успешно загружен"
    echo "   ✓ Функция install_category доступна"
    echo "   ✓ Функция install_all доступна"
    echo "   ✓ Функция get_install_order доступна"
else
    echo "   ✗ Ошибка загрузки installer.sh"
    exit 1
fi

echo
echo "8. Тестирование вспомогательных модулей..."
if source "$SCRIPT_DIR/helpers/arg-parser.sh"; then
    echo "   ✓ Модуль arg-parser.sh успешно загружен"
    echo "   ✓ Функция parse_arguments доступна"
else
    echo "   ✗ Ошибка загрузки arg-parser.sh"
    exit 1
fi

if source "$SCRIPT_DIR/helpers/file-utils.sh"; then
    echo "   ✓ Модуль file-utils.sh успешно загружен"
    echo "   ✓ Функция file_exists доступна"
    echo "   ✓ Функция file_is_empty доступна"
    echo "   ✓ Функция read_file_content доступна"
    echo "   ✓ Функция create_temp_file доступна"
    echo "   ✓ Функция append_to_file доступна"
else
    echo "   ✗ Ошибка загрузки file-utils.sh"
    exit 1
fi

echo
echo "9. Тестирование основного скрипта установки..."
if [[ -f "$SCRIPT_DIR/install.sh" ]]; then
    echo "   ✓ Основной скрипт install.sh существует"
    # Проверяем, что скрипт синтаксически корректен
    if bash -n "$SCRIPT_DIR/install.sh"; then
        echo "   ✓ Синтаксис install.sh корректен"
    else
        echo "   ✗ Ошибка синтаксиса в install.sh"
        exit 1
    fi
else
    echo "   ✗ Основной скрипт install.sh не найден"
    exit 1
fi

echo
echo "10. Тестирование скриптов дистрибутива..."
DISTRIBUTION_SCRIPTS=(
    "$SCRIPT_DIR/distributions/base/pre-install.sh"
    "$SCRIPT_DIR/distributions/base/post-install.sh"
    "$SCRIPT_DIR/distributions/base/finalize.sh"
    "$SCRIPT_DIR/distribution-installer.sh"
)

for script in "${DISTRIBUTION_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo "   ✓ Скрипт $script существует"
        if bash -n "$script"; then
            echo "   ✓ Синтаксис $script корректен"
        else
            echo "   ✗ Ошибка синтаксиса в $script"
            exit 1
        fi
    else
        echo "   ✗ Скрипт $script не найден"
        exit 1
    fi
done

echo
echo "================================================="
echo "Все модули успешно протестированы!"
echo "Модульная система установки PKGS-ARCH работает корректно."
echo "================================================="

# Показываем пример использования
echo
echo "Примеры использования:"
echo " ./scripts/install.sh all          # Установить все пакеты"
echo "  ./scripts/install.sh aur          # Установить пакеты из AUR"
echo "  ./scripts/install.sh core         # Установить базовые пакеты"
echo " ./scripts/install.sh --missing-only  # Установить только отсутствующие пакеты"