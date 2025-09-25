#!/bin/bash

# Script de provisionnement rapide pour Rocky Dev
# Utilise le script de configuration principal

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [[ ! -f "../../configure.sh" ]]; then
    echo "Erreur: Script de configuration non trouvé. Veuillez exécuter depuis le dossier cloud/rocky-dev/scripts/"
    exit 1
fi

print_info "=== Provisionnement Rocky Dev ==="
print_info "Ce script va configurer un environnement Rocky Linux avec :"
print_info "- K3s (Kubernetes léger)"
print_info "- ArgoCD (GitOps)"
print_info "- Coder (Environnements de développement)"
print_info "- Podman (Conteneurs)"
echo

# Exécuter le script de configuration principal
cd ../..
chmod +x configure.sh
./configure.sh rocky-dev

print_success "Provisionnement Rocky Dev terminé !"
