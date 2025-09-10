#!/bin/bash
set -e

echo "=== Mise à jour et installation des prérequis ==="
sudo apt-get -y update
sudo apt-get -y install software-properties-common curl wget apt-transport-https gnupg lsb-release expect

echo "=== Installation Podman / Buildah ==="
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




cat << 'EOF' > lancement.sh


#!/bin/bash

# === Dossier de destination ===
DEST_DIR="/home/vagrant/scripts"
mkdir -p "$DEST_DIR"

# === Générer le fichier template_Account dans le dossier ===

LOG_DIR="/home/vagrant/scripts"

echo "=== Lancer Coder server en arrière-plan ==="
sudo -u vagrant bash -c "nohup coder server > $LOG_DIR/coder.log 2>&1 & echo \$! > $LOG_DIR/coder.pid"

SERVER_PID=$(cat $LOG_DIR/coder.pid)
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
  kill -SIGINT $SERVER_PID
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
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
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
kill -SIGINT $SERVER_PID



echo "✅ Le script template_Account a été généré dans $DEST_DIR"
echo "👉 Les logs et PID seront aussi stockés dans $DEST_DIR"

EOF

chmod +x lancement.sh















echo "=============================================="
echo " 🌍 Accédez à ArgoCD :"
echo ""
echo " 👤 Username : admin"
echo " 🔑 Password : $ARGOCD_PWD"
echo " Lien : http://$VM_IP:8090"
echo ""
echo " Lancez la commande suivante pour exposer ArgoCD :"
echo "   sudo kubectl port-forward --address 0.0.0.0 svc/argocd-server 8090:80 -n argocd"
echo " lancer code server : coder server"
echo " lancer coder server en arrière-plan :"
echo "   sudo -u vagrant bash -c \"nohup coder server > /home/vagrant/coder.log 2>&1 & echo \$! > /home/vagrant/coder.pid\""
echo " 🚀 Pour créer le template : ./lancement.sh"
echo "=============================================="

echo "✅ Installation complète terminée avec succès"
