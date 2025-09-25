#!/bin/bash

# Test rapide pour rocky-dev
echo "Test de configuration rocky-dev"

# Créer l'inventaire directement
cat > rocky-dev/ansible/inventory.ini << EOF
[rocky_dev]
192.168.1.17 ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[rocky_dev:vars]
ansible_ssh_pass=Ureon@1234
ansible_become_pass=Ureon@1234
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

echo "Inventaire créé, test du playbook..."

cd rocky-dev/ansible
ansible-playbook -i inventory.ini playbook.yml --check
