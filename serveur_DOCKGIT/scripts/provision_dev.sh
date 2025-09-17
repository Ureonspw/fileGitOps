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


echo "=== Installation de K3s (Flannel par défaut actif) ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=" - write-kubeconfig=$HOME/local-cluster.config - write-kubeconfig-mode=644" sh -

echo "=== Vérification du service K3s ==="
sudo systemctl status k3s

echo "=== Mise à jour du PATH pour vagrant ==="
grep -qxF 'export PATH=$PATH:/usr/local/bin' /home/vagrant/.bashrc || echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /home/vagrant/.bashrc

echo "=== Lien symbolique de k3s dans /usr/bin ==="
sudo ln -sf /usr/local/bin/k3s /usr/bin/k3s


echo "=== Attente que le cluster K3s ait au moins 1 nœud ==="
for i in {1..30}; do
  nodes=$(/usr/local/bin/k3s kubectl get nodes --no-headers 2>/dev/null | wc -l)
  if [[ $nodes -ge 1 ]]; then
    echo "✅ Nœud détecté"
    break
  fi
  echo "⏳ Aucun nœud détecté, nouvelle tentative..."
  sleep 5
done

echo "=== Attente que tous les nœuds soient Ready (max 120s) ==="
if ! /usr/local/bin/k3s kubectl wait --for=condition=Ready node --all --timeout=120s; then
  echo "❌ Timeout: Cluster non prêt"
  /usr/local/bin/k3s kubectl get nodes -o wide
  exit 1
fi
echo "✅ Cluster prêt"


echo "=== Création du namespace argocd ==="
/usr/local/bin/k3s kubectl create ns argocd

echo "=== Installation d'ArgoCD ==="
wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -O install.yaml
/usr/local/bin/k3s kubectl apply -n argocd -f install.yaml

sudo k3s kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
sudo k3s kubectl get all -n argocd


ARGOCD_PWD=$(sudo k3s kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)


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










echo "=============================================="
echo " 🌍 Accedez a ArgoCD  :"
echo ""
echo " 👤 Username : admin"
echo " 🔑 Password : $ARGOCD_PWD"
echo " lien vers le service : http://192.168.33.10:8090"
echo " comment lancer le service :  sudo k3s kubectl port-forward --address 0.0.0.0 service/argocd-server 8090:80 -n argocd "
echo "pour creer une nouvelle app a traver argo via le cli (exemple foncctionnel): sudo k3s kubectl apply -f https://raw.githubusercontent.com/Ureonspw/testimgnigx/main/k8s/application.yaml -n argocd"
echo " lancer code server : coder server"
echo " lancer coder server en arrière-plan :"
echo "   sudo -u vagrant bash -c \"nohup coder server > /home/vagrant/coder.log 2>&1 & echo \$! > /home/vagrant/coder.pid\""
echo " 🚀 Pour créer le template : ./lancement.sh"
echo "=============================================="





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
