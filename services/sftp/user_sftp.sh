#!/bin/bash

# Define users and their directories
declare -A USERS
#USERS[ftpuser1]="/storage-dados/ftpuser1/upload"
#USERS[ftpuser2]="/storage-dados/ftpuser2/upload"
USERS[ftpuser3]="/storage-dados/ftpuser3/upload"
#USERS[sftpuser4]="/storage-dados/sftpuser4/upload"
#USERS[ftpuser5]="/storage-dados/ftpuser5/upload"
#USERS[ftpuser6]="/storage-dados/ftpuser6/upload"


# Group for FTP users
SFTP_GROUP="sftpgroup"

# Install sshd if not installed
#if ! dpkg -l | grep -q sshd; then
#    echo "Instalando sshd..."
#    sudo apt update && sudo apt install -y sshd
#fi

# Create FTP group if it doesn't exist
#if ! getent group "$SFTP_GROUP" >/dev/null; then
#   sudo groupadd "$SFTP_GROUP"
#   echo "Grupo $SFTP_GROUP criado."
#fi

# Create base directory
BASE_DIR="/storage-dados"
sudo mkdir -p "$BASE_DIR"
sudo chown root:root "$BASE_DIR"
sudo chmod 755 "$BASE_DIR"

# Loop through each user and create directories, set permissions
for USER in "${!USERS[@]}"; do
   USER_DIR="${USERS[$USER]}"

   # Create user if they don't exist
   if ! id -u "$USER" >/dev/null 2>&1; then
       sudo adduser --disabled-password --gecos "" "$USER"
       sudo usermod -aG "$SFTP_GROUP" "$USER"
       echo "$USER:senha123" | sudo chpasswd   # senha default, troque depois
       echo "Usuário $USER criado e adicionado ao grupo $SFTP_GROUP."
   fi

   # Create user directories
   sudo mkdir -p "$USER_DIR"

   # Set ownership and permissions
   sudo chown "$USER":"$SFTP_GROUP" "$USER_DIR"
   sudo chmod 755 "$USER_DIR"

   echo "Diretório $USER_DIR configurado para o usuário $USER."
done

# Backup sshd.conf
#SSHD_CONFIG="/etc/sshd.conf"
#BACKUP_CONFIG="/etc/sshd.conf.bak"
#
#if [ ! -f "$BACKUP_CONFIG" ]; then
#   sudo cp "$SSHD_CONFIG" "$BACKUP_CONFIG"
#   echo "Backup do arquivo $SSHD_CONFIG realizado."
#fi

# Configurações básicas de segurança no sshd
#sudo bash -c "cat > $SSHD_CONFIG <<EOF
#listen=YES
#anonymous_enable=NO
#local_enable=YES
#write_enable=YES
#chroot_local_user=YES
#allow_writeable_chroot=YES
#local_umask=022
#pasv_enable=YES
#pasv_min_port=30000
#pasv_max_port=30100
#user_sub_token=\$USER
#local_root=/storage-dados/\$USER
#userlist_enable=YES
#userlist_file=/etc/sshd.userlist
#userlist_deny=NO
#EOF"
#
# Cria lista de usuários permitidos
for USER in "${!USERS[@]}"; do
   echo "$USER" | sudo tee -a /etc/sshd.userlist > /dev/null
done

# Reinicia serviço
sudo systemctl restart sshd
echo "Configuração do FTP concluída e sshd reiniciado."