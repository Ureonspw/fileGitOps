

#!/bin/bash
set -e
  sudo su 

  sudo apt-get -y update
  sudo apt-get -y install software-properties-common curl
  
  # Dépôt officiel Podman/Buildah
  echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee /etc/apt/sources.list.d/libcontainers.list
  curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key" | sudo apt-key add -
  
  sudo apt-get -y update
  sudo apt-get -y install buildah podman runc curl wget
  
  # Configurer le runtime dans containers.conf
  sudo mkdir -p /etc/containers
  cat << 'EOF' | sudo tee /etc/containers/containers.conf
[engine]
cgroup_manager = "cgroupfs"
runtime = "runc"
EOF

  # Remplacer la config globale aussi
sudo cp /etc/containers/containers.conf /usr/share/containers/containers.conf
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=" - write-kubeconfig=$HOME/local-cluster.config - write-kubeconfig-mode=644" sh -
systemctl status k3s
export KUBECONFIG=$HOME/local-cluster.config
sudo kubectl create ns argocd
wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -O install.yaml
sudo kubectl apply -n argocd -f install.yaml
sudo kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
sudo kubectl get all -n argocd

# echo "=== Exposition du service ArgoCD en NodePort ==="
# sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# # Récupérer IP de la VM
# VM_IP=$(hostname -I | awk '{print $1}')

# # Récupérer les NodePorts (HTTP et HTTPS si dispo)
# HTTP_PORT=$(sudo kubectl get svc argocd-server -n argocd -o jsonpath="{.spec.ports[?(@.port==80)].nodePort}")
# HTTPS_PORT=$(sudo kubectl get svc argocd-server -n argocd -o jsonpath="{.spec.ports[?(@.port==443)].nodePort}")

# Récupérer le mot de passe admin ArgoCD
ARGOCD_PWD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# Affichage clair
# nohup sudo kubectl port-forward --address 0.0.0.0 service/argocd-server 8090:80 -n argocd > /tmp/argocd-portforward.log 2>&1 &

echo "=============================================="
echo " 🌍 Accedez a ArgoCD  :"
echo ""
echo " 👤 Username : admin"
echo " 🔑 Password : $ARGOCD_PWD"
echo " lien vers le service : http://192.168.33.10:8090"
echo " comment lancer :  sudo kubectl port-forward --address 0.0.0.0 service/argocd-server 8090:80 -n argocd "
echo "=============================================="






#  sudo kubectl port-forward --address 0.0.0.0 svc/argocd-server 8080:80 -n argocd

















# echo "=== Installation de K3s (Flannel par défaut actif) ==="
# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=" - write-kubeconfig=$HOME/local-cluster.config - write-kubeconfig-mode=644" sh -

# echo "=== Vérification du service K3s ==="
# sudo systemctl status k3s

# echo "=== Mise à jour du PATH pour vagrant ==="
# grep -qxF 'export PATH=$PATH:/usr/local/bin' /home/vagrant/.bashrc || echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /home/vagrant/.bashrc

# echo "=== Lien symbolique de k3s dans /usr/bin ==="
# sudo ln -sf /usr/local/bin/k3s /usr/bin/k3s

# echo "=== Attente que le cluster K3s ait au moins 1 nœud ==="
# for i in {1..30}; do
#   nodes=$(/usr/local/bin/k3s kubectl get nodes --no-headers 2>/dev/null | wc -l)
#   if [[ $nodes -ge 1 ]]; then
#     echo "✅ Nœud détecté"
#     break
#   fi
#   echo "⏳ Aucun nœud détecté, nouvelle tentative..."
#   sleep 5
# done

# echo "=== Attente que tous les nœuds soient Ready (max 120s) ==="
# if ! /usr/local/bin/k3s kubectl wait --for=condition=Ready node --all --timeout=120s; then
#   echo "❌ Timeout: Cluster non prêt"
#   /usr/local/bin/k3s kubectl get nodes -o wide
#   exit 1
# fi
# echo "✅ Cluster prêt"

# echo "=== Création du namespace argocd ==="
# /usr/local/bin/k3s kubectl create ns argocd

# echo "=== Installation d'ArgoCD ==="
# wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -O install.yaml
# /usr/local/bin/k3s kubectl apply -n argocd -f install.yaml


# echo "=== Attente que les pods ArgoCD soient prêts (max 300s) ==="
# if ! /usr/local/bin/k3s kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s; then
#   echo "❌ Timeout: certains pods ArgoCD ne sont pas prêts"
#   /usr/local/bin/k3s kubectl get pods -n argocd -o wide
#   exit 1
# fi
# echo "✅ Tous les pods ArgoCD sont prêts"

# echo "=== Récupération du mot de passe admin ArgoCD ==="
# /usr/local/bin/k3s kubectl -n argocd get secret argocd-initial-admin-secret \
#   -o jsonpath="{.data.password}" | base64 -d
# echo

# echo "=== Installation CLI ArgoCD ==="
# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

# echo "=== État final des pods ArgoCD ==="
# /usr/local/bin/k3s kubectl get pods -n argocd -o wide


echo "✅ Installation complète d'ArgoCD avec K3s"
