#!/bin/bash

set -e

echo "=== Installation K3s (sans traefik) via script officiel ==="
curl -sfL https://get.k3s.io | sh -s - --disable traefik

echo "=== Ajout de /usr/local/bin au PATH dans .bashrc de l'utilisateur vagrant ==="
grep -qxF 'export PATH=$PATH:/usr/local/bin' /home/vagrant/.bashrc || echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /home/vagrant/.bashrc

echo "=== Création d'un lien symbolique /usr/bin/k3s pour accès global ==="
if ! command -v k3s &> /dev/null; then
  sudo ln -s /usr/local/bin/k3s /usr/bin/k3s
fi

echo "=== Redémarrage du service k3s pour appliquer les configs ==="
sudo systemctl restart k3s

echo "=== Attente que le cluster soit prêt (max 120s) ==="
timeout=120
start=$(date +%s)
while true; do
  status=$(sudo /usr/local/bin/k3s kubectl get nodes --no-headers | awk '{print $2}')
  if [[ "$status" == "Ready" ]]; then
    echo "✅ Cluster prêt"
    break
  fi
  now=$(date +%s)
  if (( now - start > timeout )); then
    echo "❌ Timeout, le cluster n'est pas prêt"
    exit 1
  fi
  sleep 5
done

echo "=== Installation terminée ==="
