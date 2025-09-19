#!/bin/bash
set -e
sudo su 
echo "=== Installation des outils de base ==="
sudo dnf -y install dnf-plugins-core curl buildah podman runc wget

echo "=== Configuration containers.conf ==="
sudo mkdir -p /etc/containers
cat << 'EOF' | sudo tee /etc/containers/containers.conf
[engine]
cgroup_manager = "cgroupfs"
runtime = "runc"
EOF
sudo cp /etc/containers/containers.conf /usr/share/containers/containers.conf


sudo tee /etc/containers/systemd/forgejo.network > /dev/null << 'EOF'
[Network]
NetworkName=forgejo
EOF


sudo tee /etc/containers/systemd/postgres-data.volume > /dev/null << 'EOF'
[Volume]
VolumeName=postgres-data
EOF

sudo tee /etc/containers/systemd/forgejo-data.volume > /dev/null << 'EOF'
[Volume]
VolumeName=forgejo-data
EOF



sudo tee /etc/containers/systemd/postgres.container > /dev/null << 'EOF'
[Container]
ContainerName=postgres
Environment=POSTGRES_DB=forgejo
Environment=POSTGRES_USER=forgejo
Environment=POSTGRES_PASSWORD=ForgejoSecurePass2024!
Image=docker.io/library/postgres:15
Network=forgejo.network
Volume=postgres-data:/var/lib/postgresql/data

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF



sudo tee /etc/containers/systemd/forgejo.container > /dev/null << 'EOF'
[Container]
ContainerName=forgejo
Environment=USER_UID=1000
Environment=USER_GID=1000
Image=codeberg.org/forgejo/forgejo:11
Network=forgejo.network
PublishPort=3001:3000
PublishPort=222:22
Volume=forgejo-data:/data

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF



sudo systemctl daemon-reload



echo "=== Démarrage des services d'installation des containers de forgejo==="
sudo systemctl start postgres
sudo systemctl start forgejo





echo "=== Récupération IP de la VM ==="
VM_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.168\.' | head -n 1)
VM_IP=${VM_IP:-127.0.0.1}
echo "[INFO] IP détectée : $VM_IP"

HARBOR_DIR=/opt/harbor
CERT_DIR=/etc/harbor/certs
HARBOR_VERSION="v2.11.0"
HARBOR_PASSWORD="Harbor12345"

echo "[INFO] Installation des dépendances..."
sudo dnf install -y wget curl tar dnf-plugins-core openssl podman

# Installer Docker CE et plugin Compose
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker

echo "[INFO] Téléchargement de Harbor..."
cd /tmp
wget https://github.com/goharbor/harbor/releases/download/$HARBOR_VERSION/harbor-online-installer-$HARBOR_VERSION.tgz
tar xvf harbor-online-installer-$HARBOR_VERSION.tgz
sudo mv harbor $HARBOR_DIR
cd $HARBOR_DIR
sudo cp harbor.yml.tmpl harbor.yml

echo "[INFO] Génération des certificats SSL avec SAN..."
sudo mkdir -p $CERT_DIR

cat > /tmp/harbor-openssl.cnf <<EOF
[req]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no

[req_distinguished_name]
C  = CI
ST = Abidjan
L  = Abidjan
O  = HarborLab
CN = $VM_IP

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = $VM_IP
EOF

openssl req -x509 -nodes -days 365 \
 -keyout $CERT_DIR/harbor.key \
 -out $CERT_DIR/harbor.crt \
 -config /tmp/harbor-openssl.cnf -extensions v3_req

echo "[INFO] Configuration de harbor.yml..."
sudo sed -i "s/hostname:.*/hostname: $VM_IP/" harbor.yml
sudo sed -i "s#harbor_admin_password:.*#harbor_admin_password: $HARBOR_PASSWORD#" harbor.yml
sudo sed -i "s#certificate:.*#certificate: $CERT_DIR/harbor.crt#" harbor.yml
sudo sed -i "s#private_key:.*#private_key: $CERT_DIR/harbor.key#" harbor.yml

echo "[INFO] Installation de Harbor..."
sudo ./install.sh

echo "[INFO] Configuration Podman pour le certificat..."
sudo mkdir -p /etc/containers/certs.d/$VM_IP
sudo cp $CERT_DIR/harbor.crt /etc/containers/certs.d/$VM_IP/ca.crt



echo "======================================================="
echo " Harbor est installé avec succès !"
echo " Accès web : https://$VM_IP"
echo " Login : admin / $HARBOR_PASSWORD"
echo " forgejo est installé avec succès !"
echo " Accès web : http://$VM_IP:3001"

echo "======================================================="






echo "✅ Installation complète d'ArgoCD avec K3s"
