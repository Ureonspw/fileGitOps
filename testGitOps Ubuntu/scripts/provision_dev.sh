#!/bin/bash
set -e

echo "=== Mise à jour et installation des prérequis ==="
sudo apt-get -y update
sudo apt-get -y install -y software-properties-common curl wget apt-transport-https gnupg lsb-release

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

echo "=============================================="
echo " 🌍 Accédez à ArgoCD :"
echo ""
echo " 👤 Username : admin"
echo " 🔑 Password : $ARGOCD_PWD"
echo " Lien : http://$VM_IP:8090"
echo ""
echo " Lancez la commande suivante pour exposer ArgoCD :"
echo "   sudo kubectl port-forward --address 0.0.0.0 svc/argocd-server 8090:80 -n argocd"
echo "=============================================="

echo "✅ Installation complète terminée avec succès"
