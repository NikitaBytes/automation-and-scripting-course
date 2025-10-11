FROM python:3.12-slim

# Установка cron и зависимостей
RUN apt-get update && apt-get install -y cron ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/lab03

# Копируем скрипты
COPY currency_exchange_rate.py /opt/lab03/
COPY weekly_usd.sh /opt/lab03/
COPY cronjob /opt/lab03/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /opt/lab03/weekly_usd.sh && \
    pip install --no-cache-dir requests && \
    touch /var/log/cron.log && chmod 666 /var/log/cron.log

ENV API_KEY=my_secret_key_123_scripting \
    LAB02_BASE_URL=http://host.docker.internal:8080/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]