#!/bin/bash
set -e

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

# Formata a partição em ext4
echo "Formatando a partição $PARTITION em ext4..."
mkfs.ext4 -L "$LABEL" "$PARTITION"

# Cria o diretório de montagem
MOUNT_POINT="/$LABEL"
mkdir -p "$MOUNT_POINT"

# Monta a partição
echo "Montando a partição $PARTITION em $MOUNT_POINT..."
mount "$PARTITION" "$MOUNT_POINT"

# Adiciona a entrada no /etc/fstab
echo "Adicionando a partição ao /etc/fstab..."
UUID=$(blkid -s UUID -o value "$PARTITION")
if grep -q "$UUID" /etc/fstab; then
    echo "A partição já está configurada no /etc/fstab."
else
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
    echo "Partição adicionada ao /etc/fstab com sucesso."
fi

# Confirma a montagem
echo "Verificando a montagem..."
mount -a
if mountpoint -q "$MOUNT_POINT"; then
    echo "A partição foi montada com sucesso em $MOUNT_POINT."
else
    echo "Erro ao montar a partição. Verifique o arquivo /etc/fstab."
    exit 1
fi

echo "Disco montado."