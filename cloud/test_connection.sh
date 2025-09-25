#!/bin/bash

# Script de test de connectivité pour les serveurs cibles
# Vérifie la connectivité SSH avant le provisionnement

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

# Fonction pour valider une adresse IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a ip_parts=($ip)
        for part in "${ip_parts[@]}"; do
            if [[ $part -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Fonction pour tester la connectivité SSH
test_ssh_connection() {
    local ip=$1
    local user=$2
    local auth_method=$3
    local password_or_key=$4
    
    print_info "Test de connectivité SSH vers $user@$ip..."
    
    # Test de ping
    if ping -c 1 -W 5 "$ip" > /dev/null 2>&1; then
        print_success "Ping vers $ip : OK"
    else
        print_error "Ping vers $ip : ÉCHEC"
        return 1
    fi
    
    # Test de port SSH
    if nc -z -w5 "$ip" 22 > /dev/null 2>&1; then
        print_success "Port SSH (22) sur $ip : OK"
    else
        print_error "Port SSH (22) sur $ip : ÉCHEC"
        return 1
    fi
    
    # Test de connexion SSH
    local ssh_cmd="ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    
    if [[ "$auth_method" == "password" ]]; then
        # Test avec mot de passe (nécessite sshpass)
        if command -v sshpass &> /dev/null; then
            if sshpass -p "$password_or_key" $ssh_cmd "$user@$ip" "echo 'Connexion SSH réussie'" > /dev/null 2>&1; then
                print_success "Connexion SSH avec mot de passe : OK"
            else
                print_error "Connexion SSH avec mot de passe : ÉCHEC"
                return 1
            fi
        else
            print_warning "sshpass non installé. Impossible de tester la connexion avec mot de passe."
            print_info "Pour installer sshpass :"
            print_info "  Ubuntu/Debian: sudo apt-get install sshpass"
            print_info "  CentOS/RHEL: sudo yum install sshpass"
            print_info "  macOS: brew install hudochenkov/sshpass/sshpass"
        fi
    elif [[ "$auth_method" == "key" ]]; then
        # Test avec clé SSH
        if $ssh_cmd -i "$password_or_key" "$user@$ip" "echo 'Connexion SSH réussie'" > /dev/null 2>&1; then
            print_success "Connexion SSH avec clé : OK"
        else
            print_error "Connexion SSH avec clé : ÉCHEC"
            return 1
        fi
    fi
    
    # Test des privilèges sudo
    print_info "Test des privilèges sudo..."
    if [[ "$auth_method" == "password" ]]; then
        if command -v sshpass &> /dev/null; then
            if sshpass -p "$password_or_key" $ssh_cmd "$user@$ip" "sudo -n true" > /dev/null 2>&1; then
                print_success "Privilèges sudo : OK"
            else
                print_warning "Privilèges sudo : Nécessite un mot de passe"
            fi
        fi
    elif [[ "$auth_method" == "key" ]]; then
        if $ssh_cmd -i "$password_or_key" "$user@$ip" "sudo -n true" > /dev/null 2>&1; then
            print_success "Privilèges sudo : OK"
        else
            print_warning "Privilèges sudo : Nécessite un mot de passe"
        fi
    fi
    
    return 0
}

# Fonction pour tester un environnement complet
test_environment() {
    local env_type=$1
    
    print_info "=== Test de l'environnement : $env_type ==="
    echo
    
    # Demander les informations de connexion
    while true; do
        read -p "Adresse IP du serveur : " ip
        if validate_ip "$ip"; then
            break
        else
            print_error "Adresse IP invalide. Veuillez entrer une adresse IP valide."
        fi
    done
    
    read -p "Nom d'utilisateur pour la connexion SSH : " user
    if [[ -z "$user" ]]; then
        print_error "Le nom d'utilisateur ne peut pas être vide."
        return 1
    fi
    
    # Demander la méthode d'authentification
    echo
    print_info "Méthode d'authentification :"
    echo "1) Mot de passe"
    echo "2) Clé SSH privée"
    while true; do
        read -p "Choisissez (1 ou 2) : " auth_choice
        case $auth_choice in
            1)
                auth_method="password"
                echo
                read -s -p "Mot de passe : " password
                echo
                if [[ -z "$password" ]]; then
                    print_error "Le mot de passe ne peut pas être vide."
                    return 1
                fi
                password_or_key="$password"
                break
                ;;
            2)
                auth_method="key"
                echo
                while true; do
                    read -p "Chemin vers la clé SSH privée : " key_path
                    if [[ -f "$key_path" && -r "$key_path" ]]; then
                        password_or_key="$key_path"
                        break
                    else
                        print_error "Fichier de clé SSH invalide ou inaccessible."
                    fi
                done
                break
                ;;
            *)
                print_error "Choix invalide. Veuillez choisir 1 ou 2."
                ;;
        esac
    done
    
    echo
    print_info "Début des tests de connectivité..."
    echo
    
    # Effectuer les tests
    if test_ssh_connection "$ip" "$user" "$auth_method" "$password_or_key"; then
        print_success "Tous les tests de connectivité sont passés avec succès !"
        print_info "Vous pouvez maintenant procéder au provisionnement."
        return 0
    else
        print_error "Certains tests ont échoué. Veuillez vérifier la configuration."
        return 1
    fi
}

# Menu principal
show_menu() {
    echo
    print_info "=== Test de Connectivité ==="
    echo
    echo "Choisissez l'environnement à tester :"
    echo "1) Ubuntu Dev"
    echo "2) Rocky Dev"
    echo "3) Dockgit"
    echo "4) Quitter"
    echo
}

# Script principal
main() {
    # Vérifier les outils nécessaires
    if ! command -v nc &> /dev/null; then
        print_warning "netcat (nc) n'est pas installé. Certains tests peuvent échouer."
        print_info "Pour installer netcat :"
        print_info "  Ubuntu/Debian: sudo apt-get install netcat"
        print_info "  CentOS/RHEL: sudo yum install nc"
        print_info "  macOS: brew install netcat"
    fi
    
    if [[ $# -eq 1 ]]; then
        case $1 in
            "ubuntu-dev"|"rocky-dev"|"dockgit")
                test_environment "$1"
                ;;
            "-h"|"--help")
                echo "Usage: $0 [ubuntu-dev|rocky-dev|dockgit]"
                echo
                echo "Options:"
                echo "  ubuntu-dev    Tester la connectivité pour Ubuntu Dev"
                echo "  rocky-dev     Tester la connectivité pour Rocky Dev"
                echo "  dockgit       Tester la connectivité pour Dockgit"
                echo "  -h, --help    Afficher cette aide"
                echo
                echo "Si aucun argument n'est fourni, un menu interactif sera affiché."
                ;;
            *)
                print_error "Argument invalide : $1"
                echo "Utilisez '$0 --help' pour voir les options disponibles."
                exit 1
                ;;
        esac
    else
        while true; do
            show_menu
            read -p "Votre choix (1-4) : " choice
            
            case $choice in
                1)
                    test_environment "ubuntu-dev"
                    ;;
                2)
                    test_environment "rocky-dev"
                    ;;
                3)
                    test_environment "dockgit"
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
    fi
}

# Exécuter le script principal
main "$@"
