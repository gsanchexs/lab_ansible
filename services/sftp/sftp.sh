SCRIPT para a criação do sftp:
 
#!/bin/bash
 
# Define users and their directories
declare -A USERS
USERS[sftpuser1]="/storage-dados/sftpuser1/upload"
USERS[sftpuser2]="/storage-dados/sftpuser2/upload"
 
# Group for SFTP users
SFTP_GROUP="sftpgroup"
 
# Create SFTP group if it doesn't exist
if ! getent group "$SFTP_GROUP" >/dev/null; then
   sudo groupadd "$SFTP_GROUP"
   echo "Grupo $SFTP_GROUP criado."
fi
 
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
       echo "Usuário $USER criado e adicionado ao grupo $SFTP_GROUP."
   fi
 
   # Create user directories
   PARENT_DIR=$(dirname "$USER_DIR")
   sudo mkdir -p "$USER_DIR"
 
   # Set ownership and permissions
   sudo chown root:root "$PARENT_DIR"
   sudo chmod 755 "$PARENT_DIR"
   sudo chown "$USER":"$SFTP_GROUP" "$USER_DIR"
   sudo chmod 755 "$USER_DIR"
 
   echo "Diretório $USER_DIR configurado para o usuário $USER."
done
 
# Configure SSHD for each user
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak"
 
# Backup SSHD config
if [ ! -f "$BACKUP_CONFIG" ]; then
   sudo cp "$SSHD_CONFIG" "$BACKUP_CONFIG"
   echo "Backup do arquivo $SSHD_CONFIG realizado."
fi
 
# Add SSHD config for each user
for USER in "${!USERS[@]}"; do
   USER_DIR="${USERS[$USER]}"
   PARENT_DIR=$(dirname "$USER_DIR")
 
   # Check if config already exists
   if ! grep -q "Match User $USER" "$SSHD_CONFIG"; then
       echo "Configurando SSH para o usuário $USER..."
       echo -e "\nMatch User $USER\n    ChrootDirectory $PARENT_DIR\n    ForceCo                                                                                                                                                             mmand internal-sftp\n    PermitTunnel no\n    AllowAgentForwarding no\n    Allow                                                                                                                                                             TcpForwarding no\n    X11Forwarding no" | sudo tee -a "$SSHD_CONFIG" > /dev/null
   fi
done
 
# Restart SSHD to apply changes
sudo systemctl restart sshd
echo "Configuração do SFTP concluída e SSH reiniciado."