#!/bin/bash

# Проверка на права root
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен от имени root (через sudo)." 
   exit 1
fi

# Запрос пользовательского порта
read -p "Введите порт панели: " CUSTOM_PORT

# Проверка корректности введенного порта (только числа от 1 до 65535)
if ! [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] || [ "$CUSTOM_PORT" -lt 1 ] || [ "$CUSTOM_PORT" -gt 65535 ]; then
    echo "Ошибка: Некорректный порт. Пожалуйста, введите число от 1 до 65535."
    exit 1
fi

echo "Настройка Anti-DDoS by Vocky (Исправленная версия)"

# 1. Сброс текущих правил
ufw --force reset

# 2. Установка политики по умолчанию: 
# Запрещаем все ВХОДЯЩИЕ (кроме разрешенных ниже)
ufw default deny incoming
# РАЗРЕШАЕМ все ИСХОДЯЩИЕ (чтобы сервер и прокси могли выходить в интернет)
ufw default allow outgoing

# Список разрешенных подсетей
NETWORKS=(
    "95.85.0.0/16"
    "93.171.0.0/16"
    "185.69.0.0/16"
    "149.154.166.0/24"
    "217.174.0.0/16"
)

# 3. Цикл по сетям для открытия портов 22 и пользовательского порта
for net in "${NETWORKS[@]}"; do
    echo "Разрешаю ВХОДЯЩИЙ доступ для: $net на порты 22 и $CUSTOM_PORT"
    
    # Входящий трафик (ответы уйдут автоматически благодаря stateful-природе UFW)
    ufw allow in from "$net" to any port 22 proto tcp comment "SSH from $net"
    ufw allow in from "$net" to any port "$CUSTOM_PORT" proto tcp comment "Panel Port $CUSTOM_PORT from $net"
    
    # Если панель использует UDP (например, для VPN/WireGuard), раскомментируйте строку ниже:
    # ufw allow in from "$net" to any port "$CUSTOM_PORT" proto udp comment "Panel Port $CUSTOM_PORT from $net (UDP)"
done

# 4. Важное дополнение: Разрешаем Loopback (локальный интерфейс)
ufw allow in on lo
ufw allow out on lo

# 5. Включение UFW
echo "y" | ufw enable

clear
RED='\033[0;31m'
NC='\033[0m' # No Color (Сброс)

echo -e "${RED}"
cat << 'EOF'
    ▄  ████▄ ▄█▄    █  █▀ ▀▄    ▄ 
     █  █   █ █▀ ▀▄  █▄█      █  █  
█     █ █   █ █    ▀  █▀▄      ▀█   
 █    █ ▀████ █▄  ▄▀ █  █      █    
  █  █        ▀███▀    █    ▄▀      
   █▐                  ▀            
   ▐                                
EOF
echo -e "${NC}"
echo -e "\n\nНастройка Anti-DDoS завершена! Доступ открыт только для указанных подсетей."
