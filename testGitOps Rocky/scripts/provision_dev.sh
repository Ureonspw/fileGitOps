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

echo "=== Récupération IP de la VM ==="
# Récupère toutes les IP (sauf 127.x et 10.x)
VM_IP=$(hostname -I | tr ' ' '\n' | grep -v '^127\.' | grep -v '^10\.' | head -n 1)

# Si aucune IP trouvée, fallback sur 127.0.0.1
VM_IP=${VM_IP:-127.0.0.1}

echo "[INFO] IP détectée : $VM_IP"

ARGOCD_PWD=$(sudo k3s kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "=== Installation de Coder ==="
curl -fsSL https://coder.com/install.sh | sh




cat << 'EOF' > lancement.sh


#!/bin/bash

# === Dossier de destination ===
DEST_DIR="/home/vagrant/scripts"
mkdir -p "$DEST_DIR"
chown vagrant:vagrant "$DEST_DIR"
chmod 755 "$DEST_DIR"

# === Générer le fichier template_Account dans le dossier ===

LOG_DIR="/home/vagrant/scripts"

echo "=== Lancer Coder server en arrière-plan ==="
sudo -u vagrant bash -c "nohup coder server > $LOG_DIR/coder.log 2>&1 & echo \$! > $LOG_DIR/coder.pid"

# Vérifier que le PID a été écrit
if [ ! -f "$LOG_DIR/coder.pid" ]; then
  echo "❌ Erreur: Impossible de créer le fichier PID"
  exit 1
fi

SERVER_PID=$(cat $LOG_DIR/coder.pid)
if [ -z "$SERVER_PID" ]; then
  echo "❌ Erreur: PID vide"
  exit 1
fi

echo "Coder server lancé avec PID $SERVER_PID"

# === Attente que le lien soit disponible ===
echo "⏳ Attente du lien Coder..."
for i in {1..30}; do
  LINK=$(grep -o "https://[a-z0-9]\+\.pit-1\.try\.coder\.app" $LOG_DIR/coder.log | head -n 1 || true)
  if [ -n "$LINK" ]; then
    break
  fi
  sleep 2
done

if [ -z "$LINK" ]; then
  echo "❌ Impossible de récupérer le lien Coder"
  kill -INT $SERVER_PID
  exit 1
fi

echo "Lien trouvé : $LINK"

# === Lancer Coder login en interactif (tu remplis manuellement) ===
sudo -u vagrant coder login $LINK

# === Une fois terminé, on continue ===
echo "✅ Utilisateur créé avec succès."

systemctl --user enable --now podman.socket

mkdir podmantemplate
cat << 'EOF_MAIN' > podmantemplate/main.tf


terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  username = data.coder_workspace_owner.me.name
}

variable "docker_socket" {
  default     = "unix:///run/user/1000/podman/podman.sock"
  description = "(Optional) Podman/Docker socket URI"
  type        = string
}

provider "docker" {
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    # Prépare le home utilisateur au premier démarrage
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi
  EOT

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }


  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }

  metadata {
    display_name = "Swap Usage (Host)"
    key          = "7_swap_host"
    script       = <<EOT
      free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024.0/1024.0/1024.0, $2/1024.0/1024.0/1024.0) }'
    EOT
    interval     = 10
    timeout      = 1
  }
}

module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"
  version = "~> 1.0"

  agent_id = coder_agent.main.id
  order    = 1
}

module "jetbrains_gateway" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/jetbrains-gateway/coder"

  jetbrains_ides = ["IU", "PS", "WS", "PY", "CL", "GO", "RM", "RD", "RR"]
  default        = "IU"
  folder         = "/home/coder"

  version    = "~> 1.0"
  agent_id   = coder_agent.main.id
  agent_name = "main"
  order      = 2
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "codercom/enterprise-base:ubuntu"

  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name

  entrypoint = [
    "sh", "-c",
    replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.containers.internal")
  ]

  env = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  host {
    host = "host.containers.internal"
    ip   = "host-gateway"
  }

  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

EOF_MAIN

cat << 'EOF_README' > podmantemplate/README.md

---
display_name: CODE_SERVER_PODMAN
description: le template de base avec les container podman
icon: ../../../site/static/emojis/1f4e6.png
maintainer_github: coder
verified: true
tags: []
---

# A minimal Scaffolding for a Coder Template

c'est mon template que j'ai creer de base avec podman et codeserver. Il creeras ton workspace avec un container podman et un codeserver.

EOF_README

cd podmantemplate

coder template push -y  





# === Arrêter le serveur (comme Ctrl+C) ===
kill -INT $SERVER_PID



echo "✅ Le script template_Account a été généré dans $DEST_DIR"
echo "👉 Les logs et PID seront aussi stockés dans $DEST_DIR"

EOF

chmod +x lancement.sh

# === Création du script veruser.sh ===
cat << 'EOF' > veruser.sh
#!/bin/bash

echo "=== Détection automatique de l'utilisateur avec UID 1000 ==="
USER_UID1000=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USER_UID1000" ]; then
  echo "❌ Erreur: Aucun utilisateur avec UID 1000 trouvé"
  exit 1
fi
echo "✅ Utilisateur détecté: $USER_UID1000 (UID 1000)"

echo "=== Modification du script lancement.sh ==="
if [ ! -f "lancement.sh" ]; then
  echo "❌ Erreur: Le fichier lancement.sh n'existe pas"
  exit 1
fi

# Sauvegarde du fichier original
cp lancement.sh lancement.sh.backup
echo "✅ Sauvegarde créée: lancement.sh.backup"

# Remplacement de toutes les occurrences de "vagrant" par l'utilisateur détecté
sed -i "s/vagrant/$USER_UID1000/g" lancement.sh

echo "✅ Script lancement.sh modifié avec l'utilisateur: $USER_UID1000"
echo "🚀 Vous pouvez maintenant lancer: ./lancement.sh"

EOF

chmod +x veruser.sh

# === Création du script pONCoder.sh ===
cat << 'EOF' > pONCoder.sh
#!/bin/bash

# === Script pour lancer Coder en arrière-plan ===

# Détection automatique de l'utilisateur avec UID 1000
USER_UID1000=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USER_UID1000" ]; then
  echo "❌ Erreur: Aucun utilisateur avec UID 1000 trouvé"
  exit 1
fi

LOG_DIR="/home/$USER_UID1000/scripts"
mkdir -p "$LOG_DIR"

# Vérifier si Coder est déjà en cours d'exécution
if [ -f "$LOG_DIR/coder.pid" ]; then
  PID=$(cat "$LOG_DIR/coder.pid")
  if ps -p $PID > /dev/null 2>&1; then
    echo "⚠️  Coder est déjà en cours d'exécution avec le PID $PID"
    echo "💡 Utilisez ./pOFFCoder.sh pour l'arrêter d'abord"
    exit 1
  else
    echo "🧹 Nettoyage du fichier PID obsolète"
    rm -f "$LOG_DIR/coder.pid"
  fi
fi

echo "🚀 Lancement de Coder server en arrière-plan..."
sudo -u $USER_UID1000 bash -c "nohup coder server > $LOG_DIR/coder.log 2>&1 & echo \$! > $LOG_DIR/coder.pid"

# Vérifier que le PID a été écrit
if [ ! -f "$LOG_DIR/coder.pid" ]; then
  echo "❌ Erreur: Impossible de créer le fichier PID"
  exit 1
fi

SERVER_PID=$(cat "$LOG_DIR/coder.pid")
if [ -z "$SERVER_PID" ]; then
  echo "❌ Erreur: PID vide"
  exit 1
fi

echo "✅ Coder server lancé avec succès !"
echo "📋 PID: $SERVER_PID"
echo "📁 Logs: $LOG_DIR/coder.log"
echo "💡 Utilisez ./pOFFCoder.sh pour l'arrêter"

# Attendre un peu pour voir si le serveur démarre correctement
sleep 3
if ps -p $SERVER_PID > /dev/null 2>&1; then
  echo "🎉 Coder server fonctionne correctement !"
  
  # === Attente que le lien soit disponible ===
  echo "⏳ Attente du lien Coder..."
  for i in {1..30}; do
    LINK=$(grep -o "https://[a-z0-9]\+\.pit-1\.try\.coder\.app" $LOG_DIR/coder.log | head -n 1 || true)
    if [ -n "$LINK" ]; then
      break
    fi
    sleep 2
  done
  
  if [ -n "$LINK" ]; then
    echo "🔗 Lien Coder disponible : $LINK"
    echo "💡 Vous pouvez maintenant vous connecter à Coder !"
  else
    echo "⚠️  Impossible de récupérer le lien Coder automatiquement"
    echo "📋 Vérifiez les logs: cat $LOG_DIR/coder.log"
  fi
else
  echo "❌ Erreur: Coder server s'est arrêté prématurément"
  echo "📋 Vérifiez les logs: cat $LOG_DIR/coder.log"
  exit 1
fi
EOF

chmod +x pONCoder.sh

# === Création du script pOFFCoder.sh ===
cat << 'EOF' > pOFFCoder.sh
#!/bin/bash

# === Script pour arrêter Coder ===

# Détection automatique de l'utilisateur avec UID 1000
USER_UID1000=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USER_UID1000" ]; then
  echo "❌ Erreur: Aucun utilisateur avec UID 1000 trouvé"
  exit 1
fi

LOG_DIR="/home/$USER_UID1000/scripts"
PID_FILE="$LOG_DIR/coder.pid"

# Vérifier si le fichier PID existe
if [ ! -f "$PID_FILE" ]; then
  echo "⚠️  Aucun fichier PID trouvé. Coder n'est peut-être pas en cours d'exécution."
  echo "💡 Utilisez ./pONCoder.sh pour le lancer"
  exit 1
fi

PID=$(cat "$PID_FILE")
if [ -z "$PID" ]; then
  echo "❌ Erreur: Fichier PID vide"
  rm -f "$PID_FILE"
  exit 1
fi

# Vérifier si le processus existe
if ! ps -p $PID > /dev/null 2>&1; then
  echo "⚠️  Le processus avec PID $PID n'existe plus"
  echo "🧹 Nettoyage du fichier PID obsolète"
  rm -f "$PID_FILE"
  exit 1
fi

echo "🛑 Arrêt de Coder server (PID: $PID)..."

# Tenter un arrêt propre avec SIGTERM
kill -TERM $PID

# Attendre jusqu'à 10 secondes pour un arrêt propre
for i in {1..10}; do
  if ! ps -p $PID > /dev/null 2>&1; then
    echo "✅ Coder server arrêté proprement"
    rm -f "$PID_FILE"
    exit 0
  fi
  echo "⏳ Attente de l'arrêt... ($i/10)"
  sleep 1
done

# Si le processus ne s'arrête pas, forcer avec SIGKILL
echo "⚠️  Arrêt forcé avec SIGKILL..."
kill -KILL $PID

# Vérifier que le processus est bien arrêté
if ! ps -p $PID > /dev/null 2>&1; then
  echo "✅ Coder server arrêté avec succès"
  rm -f "$PID_FILE"
else
  echo "❌ Erreur: Impossible d'arrêter Coder server"
  exit 1
fi
EOF

chmod +x pOFFCoder.sh

# === Création du script pONArgoCD.sh ===
cat << 'EOF' > pONArgoCD.sh
#!/bin/bash

# === Script pour lancer ArgoCD port-forward en arrière-plan ===

# Détection automatique de l'utilisateur avec UID 1000
USER_UID1000=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USER_UID1000" ]; then
  echo "❌ Erreur: Aucun utilisateur avec UID 1000 trouvé"
  exit 1
fi

LOG_DIR="/home/$USER_UID1000/scripts"
mkdir -p "$LOG_DIR"

# Vérifier si ArgoCD port-forward est déjà en cours d'exécution
if [ -f "$LOG_DIR/argocd.pid" ]; then
  PID=$(cat "$LOG_DIR/argocd.pid")
  if ps -p $PID > /dev/null 2>&1; then
    echo "⚠️  ArgoCD port-forward est déjà en cours d'exécution avec le PID $PID"
    echo "💡 Utilisez ./pOFFArgoCD.sh pour l'arrêter d'abord"
    exit 1
  else
    echo "🧹 Nettoyage du fichier PID obsolète"
    rm -f "$LOG_DIR/argocd.pid"
  fi
fi

# Vérifier que k3s est disponible
if ! command -v k3s &> /dev/null; then
  echo "❌ Erreur: k3s n'est pas installé ou pas dans le PATH"
  exit 1
fi

# Vérifier que le namespace argocd existe
if ! sudo k3s kubectl get namespace argocd &> /dev/null; then
  echo "❌ Erreur: Le namespace 'argocd' n'existe pas"
  echo "💡 Assurez-vous qu'ArgoCD est installé"
  exit 1
fi

echo "🚀 Lancement d'ArgoCD port-forward en arrière-plan..."
sudo k3s kubectl port-forward --address 0.0.0.0 service/argocd-server 8090:80 -n argocd > "$LOG_DIR/argocd.log" 2>&1 &
echo $! > "$LOG_DIR/argocd.pid"

# Vérifier que le PID a été écrit
if [ ! -f "$LOG_DIR/argocd.pid" ]; then
  echo "❌ Erreur: Impossible de créer le fichier PID"
  exit 1
fi

ARGOCD_PID=$(cat "$LOG_DIR/argocd.pid")
if [ -z "$ARGOCD_PID" ]; then
  echo "❌ Erreur: PID vide"
  exit 1
fi

echo "✅ ArgoCD port-forward lancé avec succès !"
echo "📋 PID: $ARGOCD_PID"
echo "📁 Logs: $LOG_DIR/argocd.log"
echo "🌐 ArgoCD accessible sur: http://$(hostname -I | awk '{print $1}'):8090"
echo "💡 Utilisez ./pOFFArgoCD.sh pour l'arrêter"

# Attendre un peu pour voir si le port-forward démarre correctement
sleep 3
if ps -p $ARGOCD_PID > /dev/null 2>&1; then
  echo "🎉 ArgoCD port-forward fonctionne correctement !"
else
  echo "❌ Erreur: ArgoCD port-forward s'est arrêté prématurément"
  echo "📋 Vérifiez les logs: cat $LOG_DIR/argocd.log"
  exit 1
fi
EOF

chmod +x pONArgoCD.sh

# === Création du script pOFFArgoCD.sh ===
cat << 'EOF' > pOFFArgoCD.sh
#!/bin/bash

# === Script pour arrêter ArgoCD port-forward ===

# Détection automatique de l'utilisateur avec UID 1000
USER_UID1000=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USER_UID1000" ]; then
  echo "❌ Erreur: Aucun utilisateur avec UID 1000 trouvé"
  exit 1
fi

LOG_DIR="/home/$USER_UID1000/scripts"
PID_FILE="$LOG_DIR/argocd.pid"

# Vérifier si le fichier PID existe
if [ ! -f "$PID_FILE" ]; then
  echo "⚠️  Aucun fichier PID trouvé. ArgoCD port-forward n'est peut-être pas en cours d'exécution."
  echo "💡 Utilisez ./pONArgoCD.sh pour le lancer"
  exit 1
fi

PID=$(cat "$PID_FILE")
if [ -z "$PID" ]; then
  echo "❌ Erreur: Fichier PID vide"
  rm -f "$PID_FILE"
  exit 1
fi

# Vérifier si le processus existe
if ! ps -p $PID > /dev/null 2>&1; then
  echo "⚠️  Le processus avec PID $PID n'existe plus"
  echo "🧹 Nettoyage du fichier PID obsolète"
  rm -f "$PID_FILE"
  exit 1
fi

echo "🛑 Arrêt d'ArgoCD port-forward (PID: $PID)..."

# Tenter un arrêt propre avec SIGTERM
kill -TERM $PID

# Attendre jusqu'à 10 secondes pour un arrêt propre
for i in {1..10}; do
  if ! ps -p $PID > /dev/null 2>&1; then
    echo "✅ ArgoCD port-forward arrêté proprement"
    rm -f "$PID_FILE"
    exit 0
  fi
  echo "⏳ Attente de l'arrêt... ($i/10)"
  sleep 1
done

# Si le processus ne s'arrête pas, forcer avec SIGKILL
echo "⚠️  Arrêt forcé avec SIGKILL..."
kill -KILL $PID

# Vérifier que le processus est bien arrêté
if ! ps -p $PID > /dev/null 2>&1; then
  echo "✅ ArgoCD port-forward arrêté avec succès"
  rm -f "$PID_FILE"
else
  echo "❌ Erreur: Impossible d'arrêter ArgoCD port-forward"
  exit 1
fi
EOF

chmod +x pOFFArgoCD.sh





















echo "=============================================="
echo " 🌍 Accedez a ArgoCD  :"
echo ""
echo " 👤 Username : admin"
echo " 🔑 Password : $ARGOCD_PWD"
echo " lien vers le service : http://$VM_IP:8090"
echo " comment lancer le service :  sudo k3s kubectl port-forward --address 0.0.0.0 service/argocd-server 8090:80 -n argocd "
echo "pour creer une nouvelle app a traver argo via le cli (exemple foncctionnel): sudo k3s kubectl apply -f https://raw.githubusercontent.com/Ureonspw/testimgnigx/main/k8s/application.yaml -n argocd"
echo " lancer code server : coder server"
echo " lancer coder server en arrière-plan :"
echo "   sudo -u vagrant bash -c \"nohup coder server > /home/vagrant/coder.log 2>&1 & echo \$! > /home/vagrant/coder.pid\""
echo " 🔧 Pour adapter le script à votre utilisateur : ./veruser.sh"
echo " 🚀 Pour créer le template : ./lancement.sh"
echo " 🌐 Pour lancer ArgoCD port-forward en arrière-plan : ./pONArgoCD.sh"
echo " ⏹️  Pour arrêter ArgoCD port-forward : ./pOFFArgoCD.sh"
echo " ▶️  Pour lancer Coder en arrière-plan : ./pONCoder.sh"
echo " ⏹️  Pour arrêter Coder : ./pOFFCoder.sh"
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
