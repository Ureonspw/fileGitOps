#!/bin/bash
set -e

echo "=== Mise à jour et installation des prérequis ==="
sudo apt-get -y update
sudo apt-get -y install software-properties-common curl wget apt-transport-https gnupg lsb-release expect

echo "=== Installation Podman / Buildah ==="
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee /etc/apt/sources.list.d/libcontainers.list
curl -fsSL "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key" | sudo apt-key add -
sudo apt-get -y update
sudo apt-get -y install -y buildah podman runc

echo "=== Configuration containers.conf ==="
sudo mkdir -p /etc/containers
cat << 'EOF' | sudo tee /etc/containers/containers.conf
[engine]
cgroup_manager = "cgroupfs"
runtime = "runc"
EOF
sudo cp /etc/containers/containers.conf /usr/share/containers/containers.conf

echo "=== Installation de K3s ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig=$HOME/local-cluster.config --write-kubeconfig-mode=644" sh -

echo "=== Vérification du service K3s ==="
if systemctl is-active --quiet k3s; then
  echo "✅ K3s est actif"
else
  echo "❌ K3s n’a pas démarré correctement"
  exit 1
fi

export KUBECONFIG=$HOME/local-cluster.config

echo "=== Création du namespace ArgoCD ==="
sudo kubectl create ns argocd || true

echo "=== Installation d’ArgoCD ==="
wget -q https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -O install.yaml
sudo kubectl apply -n argocd -f install.yaml

echo "=== Attente que les pods ArgoCD soient prêts ==="
sudo kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s || true

echo "=== Installation de Helm ==="
curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Installation de Coder ==="
curl -fsSL https://coder.com/install.sh | sh

echo "=== Configuration kubeconfig root ==="
sudo mkdir -p /root/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /root/.kube/config

echo "=== Récupération IP de la VM ==="
VM_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.168\.' | head -n 1)
VM_IP=${VM_IP:-127.0.0.1}

echo "=== Récupération du mot de passe ArgoCD ==="
ARGOCD_PWD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)






# === Lancer coder server en background sous vagrant ===
# sudo rm -f /home/vagrant/coder.log /home/vagrant/coder.pid

sudo -u vagrant bash -c "nohup coder server > /home/vagrant/coder.log 2>&1 & echo \$! > /home/vagrant/coder.pid"
SERVER_PID=$(cat /home/vagrant/coder.pid)
echo "Coder server lancé avec PID $SERVER_PID"

# === Attente que le lien soit disponible ===
echo "⏳ Attente du lien Coder..."
for i in {1..30}; do
  LINK=$(grep -o "https://[a-z0-9]\+\.pit-1\.try\.coder\.app" /home/vagrant/coder.log | head -n 1 || true)
  if [ -n "$LINK" ]; then
    break
  fi
  sleep 2
done

if [ -z "$LINK" ]; then
  echo "❌ Impossible de récupérer le lien Coder"
  kill -SIGINT $SERVER_PID
  exit 1
fi

echo "Lien trouvé : $LINK"

# === Script expect temporaire pour créer le premier utilisateur ===
cat << 'EOF' > /home/vagrant/coder-init.exp
#!/usr/bin/expect -f

set timeout -1
set link [lindex $argv 0]
set username "vagrant"
set name "admin"
set email "admin@gmail.com"
set password "SuperPassw0rd!"

spawn coder login $link
expect "Would you like to create the first user? (yes/no)" { send "yes\r" }
expect "What  username" { send "$username\r" }
expect "What  name" { send "$name\r" }
expect "What's your  email" { send "$email\r" }
expect "Enter a  password" { send "$password\r" }
expect "Confirm  password" { send "$password\r" }
expect "Start a trial of Enterprise? (yes/no)" { send "no\r" }
interact
EOF

chmod +x /home/vagrant/coder-init.exp

# === Exécuter l'automatisation ===
sudo -u vagrant /home/vagrant/coder-init.exp $LINK
rm -f /home/vagrant/coder-init.exp

# === Arrêter le serveur (comme Ctrl+C) ===
kill -SIGINT $SERVER_PID
echo "Coder server arrêté proprement."











echo "=============================================="
echo " 🌍 Accédez à ArgoCD :"
echo ""
echo " 👤 Username : admin"
echo " 🔑 Password : $ARGOCD_PWD"
echo " Lien : http://$VM_IP:8090"
echo ""
echo " Lancez la commande suivante pour exposer ArgoCD :"
echo "   sudo kubectl port-forward --address 0.0.0.0 svc/argocd-server 8090:80 -n argocd"
echo "lancer code server : coder server"
echo " lancer coder server en arriere plan :"
echo " sudo -u vagrant bash -c "nohup coder server > /home/vagrant/coder.log 2>&1 & echo \$! > /home/vagrant/coder.pid"
echo "=============================================="

echo "✅ Installation complète terminée avec succès"
