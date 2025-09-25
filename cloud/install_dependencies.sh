#!/bin/bash

# Script d'installation des dépendances pour le provisionnement cloud
# Installe automatiquement Ansible et les outils nécessaires

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

# Fonction pour détecter le système d'exploitation
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    echo "ubuntu"
                    ;;
                centos|rhel|rocky|almalinux)
                    echo "centos"
                    ;;
                fedora)
                    echo "fedora"
                    ;;
                *)
                    echo "linux"
                    ;;
            esac
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# Fonction pour installer sur macOS
install_macos() {
    print_info "Installation des dépendances sur macOS..."
    
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew n'est pas installé."
        print_info "Veuillez installer Homebrew d'abord :"
        print_info "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # Installer Ansible
    if ! command -v ansible &> /dev/null; then
        print_info "Installation d'Ansible..."
        brew install ansible
    else
        print_success "Ansible est déjà installé : $(ansible --version | head -n 1)"
    fi
    
    # Installer sshpass
    if ! command -v sshpass &> /dev/null; then
        print_info "Installation de sshpass..."
        brew install hudochenkov/sshpass/sshpass
    else
        print_success "sshpass est déjà installé"
    fi
    
    # Installer netcat
    if ! command -v nc &> /dev/null; then
        print_info "Installation de netcat..."
        brew install netcat
    else
        print_success "netcat est déjà installé"
    fi
}

# Fonction pour installer sur Ubuntu/Debian
install_ubuntu() {
    print_info "Installation des dépendances sur Ubuntu/Debian..."
    
    # Mettre à jour les paquets
    print_info "Mise à jour des paquets..."
    sudo apt-get update
    
    # Installer Ansible
    if ! command -v ansible &> /dev/null; then
        print_info "Installation d'Ansible..."
        sudo apt-get install -y ansible
    else
        print_success "Ansible est déjà installé : $(ansible --version | head -n 1)"
    fi
    
    # Installer sshpass
    if ! command -v sshpass &> /dev/null; then
        print_info "Installation de sshpass..."
        sudo apt-get install -y sshpass
    else
        print_success "sshpass est déjà installé"
    fi
    
    # Installer netcat
    if ! command -v nc &> /dev/null; then
        print_info "Installation de netcat..."
        sudo apt-get install -y netcat-openbsd
    else
        print_success "netcat est déjà installé"
    fi
}

# Fonction pour installer sur CentOS/RHEL/Rocky
install_centos() {
    print_info "Installation des dépendances sur CentOS/RHEL/Rocky..."
    
    # Installer EPEL si nécessaire
    if ! rpm -q epel-release &> /dev/null; then
        print_info "Installation d'EPEL..."
        sudo yum install -y epel-release
    fi
    
    # Installer Ansible
    if ! command -v ansible &> /dev/null; then
        print_info "Installation d'Ansible..."
        sudo yum install -y ansible
    else
        print_success "Ansible est déjà installé : $(ansible --version | head -n 1)"
    fi
    
    # Installer sshpass
    if ! command -v sshpass &> /dev/null; then
        print_info "Installation de sshpass..."
        sudo yum install -y sshpass
    else
        print_success "sshpass est déjà installé"
    fi
    
    # Installer netcat
    if ! command -v nc &> /dev/null; then
        print_info "Installation de netcat..."
        sudo yum install -y nc
    else
        print_success "netcat est déjà installé"
    fi
}

# Fonction pour installer sur Fedora
install_fedora() {
    print_info "Installation des dépendances sur Fedora..."
    
    # Installer Ansible
    if ! command -v ansible &> /dev/null; then
        print_info "Installation d'Ansible..."
        sudo dnf install -y ansible
    else
        print_success "Ansible est déjà installé : $(ansible --version | head -n 1)"
    fi
    
    # Installer sshpass
    if ! command -v sshpass &> /dev/null; then
        print_info "Installation de sshpass..."
        sudo dnf install -y sshpass
    else
        print_success "sshpass est déjà installé"
    fi
    
    # Installer netcat
    if ! command -v nc &> /dev/null; then
        print_info "Installation de netcat..."
        sudo dnf install -y nc
    else
        print_success "netcat est déjà installé"
    fi
}

# Fonction pour installer les collections Ansible
install_ansible_collections() {
    print_info "Installation des collections Ansible nécessaires..."
    
    # Installer kubernetes.core
    if ! ansible-galaxy collection list | grep -q "kubernetes.core"; then
        print_info "Installation de la collection kubernetes.core..."
        ansible-galaxy collection install kubernetes.core
    else
        print_success "Collection kubernetes.core déjà installée"
    fi
    
    # Installer community.general
    if ! ansible-galaxy collection list | grep -q "community.general"; then
        print_info "Installation de la collection community.general..."
        ansible-galaxy collection install community.general
    else
        print_success "Collection community.general déjà installée"
    fi
}

# Fonction pour vérifier l'installation
verify_installation() {
    print_info "Vérification de l'installation..."
    
    local all_good=true
    
    # Vérifier Ansible
    if command -v ansible &> /dev/null; then
        print_success "✓ Ansible : $(ansible --version | head -n 1)"
    else
        print_error "✗ Ansible : Non installé"
        all_good=false
    fi
    
    # Vérifier sshpass
    if command -v sshpass &> /dev/null; then
        print_success "✓ sshpass : Installé"
    else
        print_warning "⚠ sshpass : Non installé (optionnel pour l'authentification par mot de passe)"
    fi
    
    # Vérifier netcat
    if command -v nc &> /dev/null; then
        print_success "✓ netcat : Installé"
    else
        print_warning "⚠ netcat : Non installé (optionnel pour les tests de connectivité)"
    fi
    
    # Vérifier les collections Ansible
    if ansible-galaxy collection list | grep -q "kubernetes.core"; then
        print_success "✓ Collection kubernetes.core : Installée"
    else
        print_error "✗ Collection kubernetes.core : Non installée"
        all_good=false
    fi
    
    if ansible-galaxy collection list | grep -q "community.general"; then
        print_success "✓ Collection community.general : Installée"
    else
        print_error "✗ Collection community.general : Non installée"
        all_good=false
    fi
    
    if $all_good; then
        print_success "Toutes les dépendances principales sont installées !"
        print_info "Vous pouvez maintenant utiliser les scripts de provisionnement."
    else
        print_error "Certaines dépendances sont manquantes."
        print_info "Veuillez réexécuter ce script ou installer manuellement les dépendances manquantes."
        exit 1
    fi
}

# Script principal
main() {
    print_info "=== Installation des Dépendances ==="
    echo
    
    # Détecter le système d'exploitation
    local os=$(detect_os)
    print_info "Système d'exploitation détecté : $os"
    
    # Installer selon le système
    case $os in
        "macos")
            install_macos
            ;;
        "ubuntu")
            install_ubuntu
            ;;
        "centos")
            install_centos
            ;;
        "fedora")
            install_fedora
            ;;
        *)
            print_error "Système d'exploitation non supporté : $os"
            print_info "Veuillez installer manuellement :"
            print_info "  - Ansible"
            print_info "  - sshpass (optionnel)"
            print_info "  - netcat (optionnel)"
            exit 1
            ;;
    esac
    
    # Installer les collections Ansible
    install_ansible_collections
    
    # Vérifier l'installation
    verify_installation
    
    print_success "Installation terminée avec succès !"
}

# Exécuter le script principal
main "$@"
