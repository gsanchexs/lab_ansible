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


docker run -d -p 1521:1521 -e ORACLE_PASSWORD=<your password> gvenzl/oracle-free