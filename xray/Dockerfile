FROM teddysun/xray:latest

# Устанавливаем необходимые пакеты один раз при сборке
RUN apk add --no-cache iptables iproute2

# Копируем скрипт и даем права на выполнение
COPY setup_tproxy.sh /setup_tproxy.sh
RUN chmod +x /setup_tproxy.sh

ENTRYPOINT ["/bin/sh", "/setup_tproxy.sh"]
