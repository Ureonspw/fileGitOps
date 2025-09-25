#!/bin/bash

# Script de lancement global pour le provisionnement cloud
# Point d'entrée principal pour tous les environnements

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleurs
print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    CLOUD PROVISIONING                       ║"
    echo "║                   Ansible Automation                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

# Vérifier les prérequis
check_prerequisites() {
    print_info "Vérification des prérequis..."
    
    # Vérifier Ansible
    if ! command -v ansible &> /dev/null; then
        print_warning "Ansible n'est pas installé."
        print_info "Installation d'Ansible..."
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install ansible
            else
                print_error "Homebrew n'est pas installé. Veuillez installer Ansible manuellement."
                print_info "Visitez : https://docs.ansible.com/ansible/latest/installation_guide/"
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y ansible
            elif command -v yum &> /dev/null; then
                sudo yum install -y ansible
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y ansible
            else
                print_error "Gestionnaire de paquets non supporté."
                print_info "Veuillez installer Ansible manuellement."
                print_info "Visitez : https://docs.ansible.com/ansible/latest/installation_guide/"
                exit 1
            fi
        else
            print_error "Système d'exploitation non supporté."
            exit 1
        fi
    else
        print_success "Ansible est installé : $(ansible --version | head -n 1)"
    fi
    
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -f "configure.sh" ]]; then
        print_error "Script de configuration non trouvé."
        print_info "Veuillez exécuter ce script depuis le dossier cloud/"
        exit 1
    fi
    
    print_success "Tous les prérequis sont satisfaits !"
}

# Afficher les informations sur les environnements
show_environments() {
    echo
    print_info "Environnements disponibles :"
    echo
    echo -e "${GREEN}1) Ubuntu Dev${NC}"
    echo "   • K3s (Kubernetes léger)"
    echo "   • ArgoCD (GitOps)"
    echo "   • Coder (Environnements de développement)"
    echo "   • Podman (Conteneurs)"
    echo
    echo -e "${GREEN}2) Rocky Dev${NC}"
    echo "   • K3s (Kubernetes léger)"
    echo "   • ArgoCD (GitOps)"
    echo "   • Coder (Environnements de développement)"
    echo "   • Podman (Conteneurs)"
    echo
    echo -e "${GREEN}3) Dockgit${NC}"
    echo "   • Forgejo (Git self-hosted)"
    echo "   • Harbor (Registry de conteneurs)"
    echo "   • Podman (Conteneurs)"
    echo
}

# Menu principal
show_menu() {
    echo
    print_info "Que souhaitez-vous faire ?"
    echo
    echo "1) Provisionner un environnement"
    echo "2) Voir les informations des environnements"
    echo "3) Voir l'aide"
    echo "4) Quitter"
    echo
}

# Afficher l'aide
show_help() {
    echo
    print_info "=== AIDE ==="
    echo
    echo "Ce script vous permet de provisionner automatiquement des environnements"
    echo "de développement cloud en utilisant Ansible."
    echo
    echo "Méthodes d'utilisation :"
    echo
    echo "1) Mode interactif (recommandé) :"
    echo "   ./launch.sh"
    echo
    echo "2) Provisionnement direct :"
    echo "   ./launch.sh ubuntu-dev"
    echo "   ./launch.sh rocky-dev"
    echo "   ./launch.sh dockgit"
    echo
    echo "3) Scripts spécifiques :"
    echo "   ./ubuntu-dev/scripts/provision.sh"
    echo "   ./rocky-dev/scripts/provision.sh"
    echo "   ./dockgit/scripts/provision.sh"
    echo
    echo "Méthodes d'authentification supportées :"
    echo "• Mot de passe SSH/sudo"
    echo "• Clé SSH privée"
    echo
    echo "Pour plus d'informations, consultez le README.md"
    echo
}

# Script principal
main() {
    print_banner
    
    # Vérifier les prérequis
    check_prerequisites
    
    # Si un argument est fourni, provisionner directement
    if [[ $# -eq 1 ]]; then
        case $1 in
            "ubuntu-dev"|"rocky-dev"|"dockgit")
                print_info "Provisionnement direct de : $1"
                ./configure.sh "$1"
                ;;
            "-h"|"--help")
                show_help
                ;;
            *)
                print_error "Environnement invalide : $1"
                print_info "Environnements disponibles : ubuntu-dev, rocky-dev, dockgit"
                exit 1
                ;;
        esac
        return
    fi
    
    # Mode interactif
    while true; do
        show_menu
        read -p "Votre choix (1-4) : " choice
        
        case $choice in
            1)
                ./configure.sh
                ;;
            2)
                show_environments
                ;;
            3)
                show_help
                ;;
            4)
                print_info "Au revoir !"
                exit 0
                ;;
            *)
                print_error "Choix invalide. Veuillez choisir entre 1 et 4."
                ;;
        esac
        
        echo
        read -p "Appuyez sur Entrée pour continuer..."
    done
}

# Exécuter le script principal
main "$@"
