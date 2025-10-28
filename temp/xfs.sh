#!/bin/bash
set -e
#==================================#==================================
# Scanneia pra garantir que ele reconheceu o novo disco
#==================================#==================================
echo "- - -" | tee /sys/class/scsi_host/host*/scan
echo "- - -" | tee /sys/class/scsi_disk/*/device/rescan

read -p "Qual o nome da partição desejada? (Não especificar o / ) " LABEL
read -p "Digite o dispositivo do disco (exemplo: /dev/sdX): " DISK

#if [ ! -b "$DISK" ]; then
#    echo "Dispositivo $DISK não encontrado."
#    exit 1
#fi
#
# Cria uma nova partição
#echo "Criando uma nova partição em $DISK..."
#parted -s "$DISK" mklabel gpt
#parted -s "$DISK" mkpart primary ext4 0% 100%

# Determina a partição criada
PARTITION="${DISK}"
#if [ ! -b "$PARTITION" ]; then
#    echo "Erro ao criar a partição em $DISK."
#    exit 1
#fi
 
echo "Formatando a partição $PARTITION em xfs..."
mkfs.xfs -L "$LABEL" "$PARTITION"

MOUNT_POINT="/$LABEL"
mkdir -p "$MOUNT_POINT"

echo "Montando a partição $PARTITION em $MOUNT_POINT..."
mount "$PARTITION" "$MOUNT_POINT"

echo "Adicionando a partição ao /etc/fstab..."
UUID=$(blkid -s UUID -o value "$PARTITION")
if grep -q "$UUID" /etc/fstab; then
    echo "A partição já está configurada no /etc/fstab."
else
    echo "UUID=$UUID $MOUNT_POINT xfs defaults 0 1" >> /etc/fstab
    echo "/etc/fstab com sucesso."
fi

echo "Verificando a montagem..."
systemctl daemon-reload
mount -a
if mountpoint -q "$MOUNT_POINT"; then
    echo "A partição foi montada com sucesso em $MOUNT_POINT."
else
    echo "Erro ao montar a partição. Verifique o arquivo /etc/fstab."
    exit 1
fi

echo "=============Disco montado.============="
#==================================
# Inicia a instalação do Owncloud
#==================================
sudo apt install -y net-tools vim neofetch ca-certificates curl gnupg lsb-release
curl -fsSL https://get.docker.com | sudo bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
## Instala o compose
sudo curl -L "https://github.com/docker/compose/releases/download/2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker --version

mkdir -p /data/owncloud
mkdir -p /pg/db
echo "Fim da instalação do Docker && Início da coleta de dados para subir o compose"
#==================================#==================================
# Coleta as credenciais do banco de dados
#==================================#==================================
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
#==================================#==================================
# Coleta as credenciais do administrador do OwnCloud
#==================================#==================================
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
#==================================
# Coleta informações de DNS e IP
#==================================
read -p "Digite o DNS do cliente: " clientdns
read -p "Digite o IP público do cliente: " clientip
read -p "Digite o e-mail do operador que está criando o ambiente: " owner_email
#==================================#==================================
# Cria o arquivo .env com as variáveis de ambiente
#==================================#==================================
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
cat > /data/docker-compose.yml <<EOL
version: '3.8'

services:
  db:
    image: postgres:16.8
    container_name: owncloud-db
    restart: always
    environment:
      POSTGRES_DB: ${OWNCLOUD_DB_NAME}
      POSTGRES_USER: ${OWNCLOUD_DB_USERNAME}
      POSTGRES_PASSWORD: ${OWNCLOUD_DB_PASSWORD}
    volumes:
      - /pg/db:/var/lib/postgresql/data
    expose:
      - "5432"

  owncloud:
    image: owncloud/server:10.15
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
      - LC_ALL=C.UTF-8
    ports:
      - "8080:8080"
    volumes:
      - /data/owncloud:/mnt/data
EOL
#==================================
# Inicia os containers
#==================================
cd /data
docker compose up -d
#==================================#==================================
# Configura o arquivo config.php do OwnCloud para correção da aba logout
#==================================#==================================
echo "Configurando o arquivo config.php do OwnCloud"
CONFIG_FILE="/data/owncloud/config/config.php"

sed -i "/'overwrite.cli.url'/a \\
'overwritehost' => '$clientdns',\\
'overwriteprotocol' => 'https',
" "$CONFIG_FILE"
#
echo "Deploy do OwnCloud concluído com sucesso!"
#==================================
# Config do NGINX
#==================================
if [ "$(id -u)" -ne 0 ]; then
  echo "Roda como root, por favor." >&2
  exit 1
fi
#==================================
# Input do DNS do cliente para seguir
#==================================
read -p "Digite o DNS do cliente (ex: exemplo.com): " client_dns
#==================================#==================================
# Instala o Nginx (se já não estiver instalado)
#==================================#==================================
if ! command -v nginx &> /dev/null; then
  echo "Instalando Nginx..."
  apt-get install -y nginx
fi
#==================================#==================================
# Cria o arquivo de configuração do Nginx para o DNS no padrão [DNS].conf
#==================================#==================================
CONF_FILE="/etc/nginx/conf.d/${client_dns}.conf"
echo "Criando .conf $CONF_FILE..."
cat > "$CONF_FILE" <<EOF
server {

    listen 80;
    server_name $client_dns;

    access_log /var/log/nginx/$client_dns-http-access.log;
    error_log /var/log/nginx/$client_dns-http-error.log;

    return 301 https://$client_dns;

}

server {
 
    #listen 443 ssl;
    #server_name $client_dns;

    #ssl_prefer_server_ciphers on;
    #ssl_certificate /etc/letsencrypt/live/$client_dns/fullchain.pem;
    #ssl_certificate_key /etc/letsencrypt/live/$client_dns/privkey.pem;

    access_log /var/log/nginx/$client_dns-https-access.log;
    error_log /var/log/nginx/$client_dns-https-error.log;

    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
EOF
echo "===== Reiniciando Nginx ====="
nginx -t && nginx -s reload
#==================================#==================================
# Instala o Certbot (se não vier na instalação do nginx) e obtém o certificado SSL
#==================================#==================================
if ! command -v certbot &> /dev/null; then
  echo "Instalando Certbot..."
  apt-get install -y certbot python3-certbot-nginx
fi
read -p "Digite o e-mail do operador: (Não usar o grupo suporte@open...): " owner_email 
echo "===== Obtendo certificado SSL para $client_dns ====="
certbot certonly --nginx -d "$client_dns" --non-interactive --agree-tos --email "$owner_email" --no-eff-email
#==================================#==================================
# Atualiza o arquivo .conf para forçar HTTPS (remove comentários do bloco 443)
#==================================#==================================
echo "===== Configurando redirecionamento HTTPS ====="
sed -i 's/#/ /g' "$CONF_FILE"
#==================================#==================================
# Configura client_max_body_size (ex: 300MB ajustar conforme necessidade do cliente)
#==================================#==================================
echo "Ajustando client_max_body_size para 300MB..."
if ! grep -q "client_max_body_size" "$CONF_FILE"; then
  sed -i '/server_name/a \    client_max_body_size 3000M;' "$CONF_FILE"
else
  sed -i 's/client_max_body_size .*/client_max_body_size 3000M;/g' "$CONF_FILE"
fi
echo "===== Reiniciando Nginx ====="
nginx -t && nginx -s reload
echo "Certificado configurado e instalado para: https://$client_dns"