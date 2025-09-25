#!/bin/bash

# Script de nettoyage pour supprimer les fichiers temporaires
# et les inventaires générés automatiquement

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour nettoyer un environnement
cleanup_environment() {
    local env_type=$1
    local env_dir="cloud/${env_type}"
    
    if [[ ! -d "$env_dir" ]]; then
        print_warning "Dossier $env_dir non trouvé, ignoré."
        return 0
    fi
    
    print_info "Nettoyage de l'environnement : $env_type"
    
    # Supprimer l'inventaire généré automatiquement
    local inventory_file="${env_dir}/ansible/inventory.ini"
    if [[ -f "$inventory_file" ]]; then
        rm -f "$inventory_file"
        print_success "Inventaire supprimé : $inventory_file"
    fi
    
    # Supprimer les fichiers temporaires Ansible
    local temp_files=(
        "${env_dir}/ansible/*.retry"
        "${env_dir}/ansible/.ansible"
        "${env_dir}/ansible/ansible.log"
    )
    
    for pattern in "${temp_files[@]}"; do
        if ls $pattern > /dev/null 2>&1; then
            rm -rf $pattern
            print_success "Fichiers temporaires supprimés : $pattern"
        fi
    done
}

# Fonction pour nettoyer tous les environnements
cleanup_all() {
    print_info "Nettoyage de tous les environnements..."
    
    local environments=("ubuntu-dev" "rocky-dev" "dockgit")
    
    for env in "${environments[@]}"; do
        cleanup_environment "$env"
    done
    
    # Nettoyer les fichiers temporaires globaux
    local global_temp_files=(
        "/tmp/ansible-ssh-*"
        "/tmp/ansible.log"
        "/tmp/harbor-openssl.cnf"
        "/tmp/install.yaml"
        "/tmp/harbor-online-installer-*.tgz"
    )
    
    for pattern in "${global_temp_files[@]}"; do
        if ls $pattern > /dev/null 2>&1; then
            rm -rf $pattern
            print_success "Fichiers temporaires globaux supprimés : $pattern"
        fi
    done
}

# Fonction pour afficher l'aide
show_help() {
    echo
    print_info "=== AIDE - Script de Nettoyage ==="
    echo
    echo "Ce script supprime les fichiers temporaires et les inventaires"
    echo "générés automatiquement par les scripts de provisionnement."
    echo
    echo "Usage :"
    echo "  $0                    # Nettoyer tous les environnements"
    echo "  $0 ubuntu-dev         # Nettoyer uniquement Ubuntu Dev"
    echo "  $0 rocky-dev          # Nettoyer uniquement Rocky Dev"
    echo "  $0 dockgit            # Nettoyer uniquement Dockgit"
    echo "  $0 --help             # Afficher cette aide"
    echo
    echo "Fichiers supprimés :"
    echo "  • Inventaires générés automatiquement (inventory.ini)"
    echo "  • Fichiers de retry Ansible (*.retry)"
    echo "  • Logs Ansible (ansible.log)"
    echo "  • Fichiers temporaires SSH (/tmp/ansible-ssh-*)"
    echo "  • Fichiers de téléchargement temporaires"
    echo
    echo "ATTENTION : Ce script ne supprime PAS les fichiers de configuration"
    echo "d'exemple (example_inventory.ini) ni les playbooks."
    echo
}

# Script principal
main() {
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -d "cloud" ]]; then
        print_error "Le dossier 'cloud' n'existe pas."
        print_info "Veuillez exécuter ce script depuis la racine du projet."
        exit 1
    fi
    
    if [[ $# -eq 0 ]]; then
        # Nettoyer tous les environnements
        cleanup_all
        print_success "Nettoyage complet terminé !"
    else
        case $1 in
            "ubuntu-dev"|"rocky-dev"|"dockgit")
                cleanup_environment "$1"
                print_success "Nettoyage de $1 terminé !"
                ;;
            "--help"|"-h")
                show_help
                ;;
            *)
                print_error "Argument invalide : $1"
                show_help
                exit 1
                ;;
        esac
    fi
}

# Exécuter le script principal
main "$@"
