#!/bin/bash

# Проверка на права root
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен от имени root (через sudo)." 
   exit 1
fi

# Запрос пользовательского порта
read -p "Введите порт панеля: " CUSTOM_PORT

# Проверка корректности введенного порта (только числа от 1 до 65535)
if ! [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] || [ "$CUSTOM_PORT" -lt 1 ] || [ "$CUSTOM_PORT" -gt 65535 ]; then
    echo "Ошибка: Некорректный порт. Пожалуйста, введите число от 1 до 65535."
    exit 1
fi

echo "Настройка Anti-DDoS by Vocky"

# 1. Сброс текущих правил (осторожно, все кастомные правила удалятся)
ufw --force reset

# 2. Установка политики по умолчанию: запретить всё (входящее и исходящее)
ufw default deny incoming
ufw default deny outgoing

# Список разрешенных подсетей
NETWORKS=(
    "95.85.0.0/16"
    "93.171.0.0/16"
    "185.69.0.0/16"
    "185.20.138.0/24"
    "149.154.166.0/24"
)

# 3. Цикл по сетям для открытия портов 22 и пользовательского порта
for net in "${NETWORKS[@]}"; do
    echo "Разрешаю доступ для: $net на порты 22 и $CUSTOM_PORT"
    
    # Входящий трафик
    ufw allow in from "$net" to any port 22 proto tcp comment "SSH from $net"
    ufw allow in from "$net" to any port "$CUSTOM_PORT" proto tcp comment "Port $CUSTOM_PORT from $net"
    
    # Исходящий трафик (ответы и запросы к этим сетям)
    ufw allow out to "$net" port 22 proto tcp comment "SSH to $net"
    ufw allow out to "$net" port "$CUSTOM_PORT" proto tcp comment "Port $CUSTOM_PORT to $net"
done

# 4. Важное дополнение: Разрешаем Loopback (локальный интерфейс)
# Без этого многие системные службы внутри сервера перестанут работать
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
echo -e "\n\nНастройка Anti-DDoS завершена!"
