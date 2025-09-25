#!/bin/bash

# Script de configuration pour le provisionnement cloud avec Ansible
# Supporte Ubuntu Dev, Rocky Dev et Dockgit avec authentification par mot de passe ou clé SSH

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleurs
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

# Fonction pour valider un fichier de clé SSH
validate_ssh_key() {
    local key_path=$1
    if [[ -f "$key_path" && -r "$key_path" ]]; then
        # Vérifier que c'est bien une clé privée SSH
        if head -n 1 "$key_path" | grep -q "BEGIN.*PRIVATE KEY"; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Fonction pour créer l'inventaire Ansible
create_inventory() {
    local env_type=$1
    local ip=$2
    local user=$3
    local auth_method=$4
    local password_or_key=$5
    
    # Déterminer le chemin vers l'inventaire selon le répertoire courant
    if [[ -d "cloud" ]]; then
        local inventory_file="cloud/${env_type}/ansible/inventory.ini"
    else
        local inventory_file="${env_type}/ansible/inventory.ini"
    fi
    
    print_info "Création de l'inventaire Ansible pour $env_type..."
    
    # Convertir les tirets en underscores pour les noms de groupes Ansible
    local group_name=$(echo "$env_type" | sed 's/-/_/g')
    
    cat > "$inventory_file" << EOF
[${group_name}]
${ip} ansible_user=${user} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

    # Ajouter la méthode d'authentification
    if [[ "$auth_method" == "password" ]]; then
        cat >> "$inventory_file" << EOF

[${group_name}:vars]
ansible_ssh_pass=${password_or_key}
ansible_become_pass=${password_or_key}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
    elif [[ "$auth_method" == "key" ]]; then
        cat >> "$inventory_file" << EOF

[${group_name}:vars]
ansible_ssh_private_key_file=${password_or_key}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
    fi
    
    print_success "Inventaire créé : $inventory_file"
}

# Fonction pour exécuter le playbook
run_playbook() {
    local env_type=$1
    # Déterminer le chemin vers le playbook selon le répertoire courant
    if [[ -d "cloud" ]]; then
        local playbook_dir="cloud/${env_type}/ansible"
    else
        local playbook_dir="${env_type}/ansible"
    fi
    
    print_info "Exécution du playbook Ansible pour $env_type..."
    
    cd "$playbook_dir"
    
    # Vérifier que Ansible est installé
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible n'est pas installé. Veuillez l'installer d'abord."
        print_info "Installation d'Ansible..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install ansible
            else
                print_error "Homebrew n'est pas installé. Veuillez installer Ansible manuellement."
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
                print_error "Gestionnaire de paquets non supporté. Veuillez installer Ansible manuellement."
                exit 1
            fi
        else
            print_error "Système d'exploitation non supporté."
            exit 1
        fi
    fi
    
    # Exécuter le playbook
    if ansible-playbook -i inventory.ini playbook.yml -v; then
        print_success "Playbook exécuté avec succès pour $env_type !"
    else
        print_error "Erreur lors de l'exécution du playbook pour $env_type"
        exit 1
    fi
    
    cd - > /dev/null
}

# Fonction principale pour configurer un environnement
configure_environment() {
    local env_type=$1
    
    print_info "Configuration de l'environnement : $env_type"
    echo
    
    # Demander l'adresse IP
    while true; do
        read -p "Adresse IP du serveur : " ip
        if validate_ip "$ip"; then
            break
        else
            print_error "Adresse IP invalide. Veuillez entrer une adresse IP valide."
        fi
    done
    
    # Demander l'utilisateur
    read -p "Nom d'utilisateur pour la connexion SSH : " user
    if [[ -z "$user" ]]; then
        print_error "Le nom d'utilisateur ne peut pas être vide."
        exit 1
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
                    exit 1
                fi
                password_or_key="$password"
                break
                ;;
            2)
                auth_method="key"
                echo
                while true; do
                    read -p "Chemin vers la clé SSH privée : " key_path
                    if validate_ssh_key "$key_path"; then
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
    print_info "Résumé de la configuration :"
    echo "  Type d'environnement : $env_type"
    echo "  Adresse IP : $ip"
    echo "  Utilisateur : $user"
    echo "  Méthode d'authentification : $auth_method"
    if [[ "$auth_method" == "key" ]]; then
        echo "  Clé SSH : $password_or_key"
    fi
    echo
    
    read -p "Confirmer la configuration ? (y/N) : " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_warning "Configuration annulée."
        return 1
    fi
    
    # Créer l'inventaire et exécuter le playbook
    create_inventory "$env_type" "$ip" "$user" "$auth_method" "$password_or_key"
    run_playbook "$env_type"
}

# Menu principal
show_menu() {
    echo
    print_info "=== Configuration Cloud avec Ansible ==="
    echo
    echo "Choisissez l'environnement à provisionner :"
    echo "1) Ubuntu Dev (K3s + ArgoCD + Coder + Podman)"
    echo "2) Rocky Dev (K3s + ArgoCD + Coder + Podman)"
    echo "3) Dockgit (Forgejo + Harbor + Podman)"
    echo "4) Quitter"
    echo
}

# Script principal
main() {
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -d "cloud" && ! -f "configure.sh" ]]; then
        print_error "Le dossier 'cloud' n'existe pas. Veuillez exécuter ce script depuis la racine du projet ou depuis le dossier cloud/."
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Votre choix (1-4) : " choice
        
        case $choice in
            1)
                configure_environment "ubuntu-dev"
                ;;
            2)
                configure_environment "rocky-dev"
                ;;
            3)
                configure_environment "dockgit"
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

# Vérifier les arguments de ligne de commande
if [[ $# -eq 0 ]]; then
    main
else
    case $1 in
        "ubuntu-dev"|"rocky-dev"|"dockgit")
            configure_environment "$1"
            ;;
        "-h"|"--help")
            echo "Usage: $0 [ubuntu-dev|rocky-dev|dockgit]"
            echo
            echo "Options:"
            echo "  ubuntu-dev    Provisionner un environnement Ubuntu Dev"
            echo "  rocky-dev     Provisionner un environnement Rocky Dev"
            echo "  dockgit       Provisionner un environnement Dockgit"
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
fi
