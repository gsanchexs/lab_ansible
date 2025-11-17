#!/bin/bash
set -e

### Instala dependências básicas e Docker
sudo apt install -y net-tools vim neofetch ca-certificates curl gnupg lsb-release
curl -fsSL https://get.docker.com | sudo bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

### Instala Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker --version

### Estrutura de diretórios
sudo mkdir -p /data/owncloud
sudo mkdir -p /nvme/mariadb
sudo chown -R $USER:$USER /data /nvme

echo "=== Fim da instalação do Docker e início da configuração do ambiente ==="

### Senhas seguras
while true; do
    read -s -p "Digite a senha do banco de dados: " dbpasswd
    echo
    read -s -p "Confirme a senha do banco de dados: " dbpasswd_confirm
    echo
    if [ "$dbpasswd" == "$dbpasswd_confirm" ] && [ ${#dbpasswd} -ge 12 ]; then
        break
    else
        echo "Senhas não são iguais ou são muito curtas (min 12). Tente novamente."
    fi
done

while true; do
    read -s -p "Digite a senha do administrador do OwnCloud: " adminpasswd
    echo
    read -s -p "Confirme a senha do administrador do OwnCloud: " adminpasswd_confirm
    echo
    if [ "$adminpasswd" == "$adminpasswd_confirm" ] && [ ${#adminpasswd} -ge 12 ]; then
        break
    else
        echo "Senhas não são iguais ou são muito curtas (min 12). Tente novamente."
    fi
done

### Coleta dados de cliente
read -p "Digite o DNS do cliente: " clientdns
read -p "Digite o IP público do cliente: " clientip
read -p "Digite o e-mail do operador que está criando o ambiente: " owner_email

### Gera .env
cat > /data/.env <<EOL
OWNCLOUD_DB_TYPE=mysql
OWNCLOUD_DB_HOST=db
OWNCLOUD_DB_NAME=owncloud
OWNCLOUD_DB_USERNAME=owncloud
OWNCLOUD_DB_PASSWORD=$dbpasswd
OWNCLOUD_ADMIN_USERNAME=admin
OWNCLOUD_ADMIN_PASSWORD=$adminpasswd
OWNCLOUD_TRUSTED_DOMAINS=$clientdns,$clientip
OWNCLOUD_ALLOW_EXTERNAL_LOCAL_STORAGE=true
EOL

### docker-compose.yml
cat > /data/docker-compose.yml <<EOL
version: '3.8'

services:
  db:
    image: mariadb:11
    container_name: owncloud-db
    restart: always
    command: --transaction-isolation=READ-COMMITTED --max-connections=200 --innodb_buffer_pool_size=1G
    environment:
      MYSQL_DATABASE: \${OWNCLOUD_DB_NAME}
      MYSQL_USER: \${OWNCLOUD_DB_USERNAME}
      MYSQL_PASSWORD: \${OWNCLOUD_DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: \${OWNCLOUD_DB_PASSWORD}
    volumes:
      - /nvme/mariadb:/var/lib/mysql
    expose:
      - "3306"

  redis:
    image: redis:alpine
    container_name: owncloud-redis
    restart: always
    command: redis-server --save "" --appendonly no

  owncloud:
    image: owncloud/server:10
    container_name: owncloud
    restart: always
    depends_on:
      - db
      - redis
    env_file: /data/.env
    environment:
      - VIRTUAL_HOST=$clientdns
      - LETSENCRYPT_HOST=$clientdns
      - LETSENCRYPT_EMAIL=$owner_email
      - OWNCLOUD_DOMAIN=$clientdns
      - OWNCLOUD_REDIS_ENABLED=true
      - OWNCLOUD_REDIS_HOST=redis
    ports:
      - "8080:8080"
    volumes:
      - /app/owncloud/apps:/mnt/data/apps
      - /app/owncloud/config:/mnt/data/config
      - /app/owncloud/sessions:/mnt/data/sessions
      - /data/owncloud/files:/mnt/data/files
EOL

### Sobe o ambiente
cd /data
docker compose up -d

### Ajusta config.php
CONFIG_FILE="/data/owncloud/config/config.php"
if [ -f "$CONFIG_FILE" ]; then
  sed -i "/'overwrite.cli.url'/a 'overwritehost' => '$clientdns',\n'overwriteprotocol' => 'http'," "$CONFIG_FILE"
fi

### Aplica cache no OwnCloud
sleep 20
docker exec -it owncloud occ config:system:set memcache.local --value='\OC\Memcache\APCu'
docker exec -it owncloud occ config:system:set memcache.locking --value='\OC\Memcache\Redis'
docker exec -it owncloud occ config:system:set redis --value="{\"host\":\"redis\",\"port\":6379}" --type=json

echo "=== Deploy do OwnCloud com MariaDB + Redis concluído com sucesso! ==="
