#!/bin/bash
set -e
# 
# ███╗   ██╗ ██████╗ ██╗███╗   ██╗██╗  ██╗
# ████╗  ██║██╔════╝ ██║████╗  ██║╚██╗██╔╝
# ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║ ╚███╔╝ 
# ██║╚██╗██║██║   ██║██║██║╚██╗██║ ██╔██╗ 
# ██║ ╚████║╚██████╔╝██║██║ ╚████║██╔╝ ██╗
# ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
#                                      v1.0
## Verifica se usuário é root (dps altero para ver se ele está só no grupo sudo talvez)
if [ "$(id -u)" -ne 0 ]; then
  echo "Roda como root, por favor." >&2
  exit 1
fi
# Input do DNS do cliente para seguir
read -p "Digite o DNS do cliente (ex: exemplo.com): " client_dns
# Instala o Nginx (se já não estiver instalado)
if ! command -v nginx &> /dev/null; then
  echo "Instalando Nginx..."
  apt-get install -y nginx
fi
# Cria o arquivo de configuração do Nginx para o DNS no padrão [DNS].conf
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
# Instala o Certbot (se não vier na instalação do nginx) e obtém o certificado SSL
if ! command -v certbot &> /dev/null; then
  echo "Instalando Certbot..."
  apt-get install -y certbot python3-certbot-nginx
fi
read -p "Digite o e-mail do operador: (Não usar o grupo suporte@open...): " owner_email 
echo "===== Obtendo certificado SSL para $client_dns ====="
certbot certonly --nginx -d "$client_dns" --non-interactive --agree-tos --email "$owner_email" --no-eff-email
# Atualiza o arquivo .conf para forçar HTTPS (remove comentários do bloco 443)
echo "===== Configurando redirecionamento HTTPS ====="
sed -i 's/#/ /g' "$CONF_FILE"
# Configura client_max_body_size (ex: 3GB ajustar conforme necessidade do cliente)
echo "Ajustando client_max_body_size para 3000MB..."
if ! grep -q "client_max_body_size" "$CONF_FILE"; then
  sed -i '/server_name/a \    client_max_body_size 3000M;' "$CONF_FILE"
else
  sed -i 's/client_max_body_size .*/client_max_body_size 3000M;/g' "$CONF_FILE"
fi
echo "===== Reiniciando Nginx ====="
nginx -t && nginx -s reload
echo "Certificado configurado e instalado para: https://$client_dns"