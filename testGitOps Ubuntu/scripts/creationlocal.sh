#!/bin/bash
set -e

# Déterminer le chemin du dossier courant (scripts/)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VAGRANT_DIR="$SCRIPT_DIR/../vagrant"

# Créer le dossier vagrant
mkdir -p "$VAGRANT_DIR"

# Créer le Vagrantfile
cat > "$VAGRANT_DIR/Vagrantfile" <<'EOT'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.define "dev-server" do |dev|
    dev.vm.hostname = "dev-server"

    dev.vm.network "private_network", ip: "192.168.33.10"
    # dev.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    # Ports forwardés (optionnels)
    dev.vm.network "forwarded_port", guest: 8080, host: 8080
    dev.vm.network "forwarded_port", guest: 8090, host: 8090

    dev.vm.synced_folder ".", "/vagrant"

    dev.vm.provider "virtualbox" do |vb|
      vb.memory = 6144
      vb.cpus = 2
    end

    dev.vm.provision "shell", path: "../scripts/provision_dev.sh"
  end
end
EOT

# Aller dans le dossier vagrant et démarrer la VM
cd "$VAGRANT_DIR"
vagrant up
