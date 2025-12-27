#!/bin/bash

# Постустановочные действия для базового дистрибутива

# Проверяем, что config.sh загружен
if [[ ! -v PROJECT_ROOT ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$SCRIPT_DIR/modules/config.sh"
fi

# Функция создания пользователя
create_user() {
    local username="$1"
    local password="$2"
    
    if [[ -n "$username" ]]; then
        log_info "Создание пользователя $username..."
        # Здесь можно добавить создание пользователя
        # useradd -m -G wheel -s /bin/bash "$username"
        # echo "$username:$password" | chpasswd
    fi
}

# Функция настройки sudo
setup_sudo() {
    log_info "Настройка sudo..."
    # Здесь можно добавить настройку sudo для группы wheel
    # sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

# Функция настройки автозагрузки сервисов
setup_services() {
    log_info "Настройка автозагрузки сервисов..."
    # Здесь можно добавить включение необходимых сервисов
    # systemctl enable systemd-networkd
    # systemctl enable systemd-resolved
    # systemctl enable greetd
}

# Функция настройки безопасности
setup_security() {
    log_info "Настройка безопасности..."
    # Здесь можно добавить настройки безопасности
}

# Основная функция постустановочных действий
post_installation() {
    local username="$1"
    local password="$2"
    
    log_info "Выполнение постустановочных действий..."
    
    create_user "$username" "$password"
    setup_sudo
    setup_services
    setup_security
    
    log_info "Постустановочные действия завершены"
}