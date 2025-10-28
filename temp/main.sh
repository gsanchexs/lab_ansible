#!/bin/bash
set -e

#   ██████╗ ██╗    ██╗███╗   ██╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗ 
#  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
#  ██║   ██║██║ █╗ ██║██╔██╗ ██║██║     ██║     ██║   ██║██║   ██║██║  ██║
#  ██║   ██║██║███╗██║██║╚██╗██║██║     ██║     ██║   ██║██║   ██║██║  ██║
#  ╚██████╔╝╚███╔███╔╝██║ ╚████║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
#   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ 
#                                                                     v1.0
### Instala algumas ferramentas pra troubleshooting
sudo apt install -y net-tools vim neofetch ca-certificates curl gnupg lsb-release
### Instala o Docker
curl -fsSL https://get.docker.com | sudo bash
sudo systemctl enable --now docker
### Adiciona o usuário atual ao grupo 'docker' (em caso do operador rodar sem root)
sudo usermod -aG docker $USER
## Instala o compose
sudo curl -L "https://github.com/docker/compose/releases/download/2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# Valida a Instalação do docker
docker --version
# Cria a estrutura de diretórios para o OwnCloud
mkdir -p /data/{db,owncloud}
echo "Fim da instalação do Docker && Início da coleta de dados para subir o compose"
# Coleta as credenciais do banco de dados
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
#credenciais do administrador do OwnCloud
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
#coleta informações de DNS e IP
read -p "Digite o DNS do cliente: " clientdns
read -p "Digite o IP público do cliente: " clientip
read -p "Digite o e-mail do operador que está criando o ambiente: " owner_email
#cria o arquivo .env com as variáveis de ambiente
echo "Criando o arquivo .env..."
cat > /data/.env <<EOL
OWNCLOUD_DB_TYPE=pgsql
OWNCLOUD_DB_HOST=db
OWNCLOUD_DB_NAME=owncloud
OWNCLOUD_DB_USERNAME=owncloud
OWNCLOUD_DB_PASSWORD=$dbpasswd
OWNCLOUD_ADMIN_USERNAME=admin
OWNCLOUD_ADMIN_PASSWORD=$adminpasswd
OWNCLOUD_TRUSTED_DOMAINS=$clientdns,$clientip
OWNCLOUD_ALLOW_EXTERNAL_LOCAL_STORAGE=true
EOL
#cria o arquivo docker-compose.yml
echo "Criando o arquivo docker-compose.yml..."
cat > /data/docker-compose.yml <<EOL
version: '3.8'

services:
  db:
    image: postgres:16
    container_name: owncloud-db
    restart: always
    environment:
      POSTGRES_DB: \${OWNCLOUD_DB_NAME}
      POSTGRES_USER: \${OWNCLOUD_DB_USERNAME}
      POSTGRES_PASSWORD: \${OWNCLOUD_DB_PASSWORD}
    volumes:
      - /data/db:/var/lib/postgresql/data
    expose:
      - "5432"

  owncloud:
    image: owncloud/server:10
    container_name: owncloud
    restart: always
    depends_on:
      - db
    env_file: /data/.env
    environment:
      - VIRTUAL_HOST=$clientdns
      - LETSENCRYPT_HOST=$clientdns
      - LETSENCRYPT_EMAIL=$owner_email
      - OWNCLOUD_DOMAIN=$clientdns
    ports:
      - "8080:8080"
    volumes:
      - /data/owncloud:/mnt/data
EOL
#start dos containers
cd /data
docker compose up -d
#configura o arquivo config.php do OwnCloud para correção da aba logout
echo "Configurando o arquivo config.php do OwnCloud..."
CONFIG_FILE="/data/owncloud/config/config.php"
sed -i "/'overwrite.cli.url'/a 'overwritehost' => '$clientdns',\n'overwriteprotocol' => 'http'," "$CONFIG_FILE"
#
echo "Deploy do OwnCloud concluído com sucesso!"