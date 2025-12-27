#!/bin/bash

# Финализация установки для базового дистрибутива

# Проверяем, что config.sh загружен
if [[ ! -v PROJECT_ROOT ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$SCRIPT_DIR/modules/config.sh"
fi

# Функция очистки временных файлов
cleanup_temp_files() {
    log_info "Очистка временных файлов..."
    # Удаляем временные файлы, созданные в процессе установки
    # rm -rf /tmp/pkgs-arch-*
}

# Функция обновления загрузчика
update_bootloader() {
    log_info "Обновление загрузчика..."
    # Здесь можно добавить обновление GRUB или другого загрузчика
    # grub-mkconfig -o /boot/grub/grub.cfg
}

# Функция подготовки системы к первому запуску
prepare_first_boot() {
    log_info "Подготовка системы к первому запуску..."
    # Здесь можно добавить подготовку к первому запуску
    # Например, установку флага необходимости первого запуска
}

# Основная функция финализации
finalize_installation() {
    log_info "Финализация установки..."
    
    cleanup_temp_files
    update_bootloader
    prepare_first_boot
    
    log_info "Установка завершена успешно!"
    log_info "Рекомендуется перезагрузить систему."
}