#!/bin/sh
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [PROXY_SETUP] $1"; }

log "Очистка старых правил iptables..."
iptables -t nat -F
iptables -t nat -X

log "Создание цепочки перехвата XRAY..."
iptables -t nat -N XRAY

# === ЛОКАЛЬНЫЙ ТРАФИК ПРОПУСКАЕМ ===
iptables -t nat -A XRAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A XRAY -d 10.0.0.0/8 -j RETURN
iptables -t nat -A XRAY -d 172.16.0.0/12 -j RETURN
iptables -t nat -A XRAY -d 192.168.0.0/16 -j RETURN

# === DNS (UDP + TCP 53) → Xray DNS inbound ===
iptables -t nat -A XRAY -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A XRAY -p tcp --dport 53 -j REDIRECT --to-ports 53

# === Весь остальной TCP → transparent proxy ===
iptables -t nat -A XRAY -p tcp -j REDIRECT --to-ports 12345

# === Применяем к OUTPUT (исключая сам Xray) ===
iptables -t nat -A OUTPUT -p tcp -m mark ! --mark 255 -j XRAY
iptables -t nat -A OUTPUT -p udp --dport 53 -m mark ! --mark 255 -j XRAY

# === Принудительно ставим resolv.conf на Xray (127.0.0.1:53) ===
log "Настройка /etc/resolv.conf на Xray DNS..."
cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
options ndots:0 timeout:1 attempts:3
EOF

log "Правила iptables применены. Запуск Xray..."
exec /usr/bin/xray -config /etc/xray/config.json
