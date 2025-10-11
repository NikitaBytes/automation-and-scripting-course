#!/bin/sh

create_log_file() {
    echo "Создаю лог-файл..."
    touch /var/log/cron.log
    chmod 666 /var/log/cron.log
}

monitor_logs() {
    echo "=== Мониторинг cron логов ==="
    tail -f /var/log/cron.log
}

run_cron() {
    echo "=== Запуск демона cron ==="
    exec cron -f
}

# Экспортируем окружение для cron
env > /etc/environment

# Настройка cronjob
install -m 0644 /opt/lab03/cronjob /etc/cron.d/lab03

create_log_file
monitor_logs &
run_cron