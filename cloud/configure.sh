#!/bin/bash

# Script de configuration pour le provisionnement cloud avec Ansible
# Supporte Ubuntu Dev, Rocky Dev et Dockgit avec authentification par mot de passe ou clé SSH

set -e

# Couleurs pour l'affichage (cohérentes avec le launcher principal)
readonly CLOUD_NORMAL="\033[0m"
readonly CLOUD_HIGHLIGHT="\033[1;37;44m"    # blanc gras sur fond bleu
readonly CLOUD_TEXT="\033[0;33m"            # or sombre
readonly CLOUD_TITLE="\033[1;35m"           # violet clair subtil
readonly CLOUD_BORDER="\033[0;35m"          # violet profond
readonly CLOUD_ERROR="\033[1;31m"           # rouge pour les erreurs
readonly CLOUD_SUCCESS="\033[1;32m"         # vert pour les succès
readonly CLOUD_WARNING="\033[1;93m"         # jaune pour les avertissements
readonly CLOUD_INFO="\033[0;34m"            # bleu pour les infos

# Fonction d'affichage avec couleurs (cohérentes avec le launcher principal)
print_info() {
    echo -e "${CLOUD_INFO}[INFO]${CLOUD_NORMAL} $1"
}

print_success() {
    echo -e "${CLOUD_SUCCESS}[SUCCESS]${CLOUD_NORMAL} $1"
}

print_warning() {
    echo -e "${CLOUD_WARNING}[WARNING]${CLOUD_NORMAL} $1"
}

print_error() {
    echo -e "${CLOUD_ERROR}[ERROR]${CLOUD_NORMAL} $1"
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
        return 0
    else
        print_error "Erreur lors de l'exécution du playbook pour $env_type"
        return 1
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
    
    if run_playbook "$env_type"; then
        # Afficher le message de succès et attendre
        echo
        print_success "Provisionnement de $env_type terminé avec succès !"
        echo
        print_info "Résumé du provisionnement :"
        echo "  • Environnement : $env_type"
        echo "  • Serveur : $ip"
        echo "  • Utilisateur : $user"
        echo "  • Méthode d'authentification : $auth_method"
        echo
        print_info "Vous pouvez maintenant utiliser votre environnement provisionné."
        echo
        wait_for_cloud_key
    else
        # Afficher le message d'erreur et attendre
        echo
        print_error "Le provisionnement de $env_type a échoué !"
        echo
        print_info "Vérifiez :"
        echo "  • La connectivité réseau vers $ip"
        echo "  • Les identifiants de connexion"
        echo "  • Les logs Ansible ci-dessus"
        echo
        wait_for_cloud_key
        return 1
    fi
}

# ==============================
# FONCTIONS D'INTERFACE CLOUD
# ==============================

# Configuration du menu cloud
readonly CLOUD_MENU_WIDTH=60
readonly CLOUD_SCRIPT_NAME="CLOUD PROVISIONING - ANSIBLE AUTOMATION"

# Options des menus cloud
readonly CLOUD_ENV_OPTIONS=("Ubuntu Dev" "Rocky Dev" "Dockgit" "Retour")

# Variables globales cloud
selected_cloud=0

# Couleurs déjà définies en haut du fichier

# Fonctions d'interface cloud
draw_cloud_border_top() {
    printf "${CLOUD_BORDER}╔"
    printf '═%.0s' $(seq 1 $CLOUD_MENU_WIDTH)
    printf "╗\n"
}

draw_cloud_border_bottom() {
    printf "${CLOUD_BORDER}╚"
    printf '═%.0s' $(seq 1 $CLOUD_MENU_WIDTH)
    printf "╝\n${CLOUD_NORMAL}"
}

draw_cloud_separator() {
    printf "${CLOUD_BORDER}╠"
    printf '═%.0s' $(seq 1 $CLOUD_MENU_WIDTH)
    printf "╣\n"
}

draw_cloud_title() {
    local title="$1"
    local padding=$(( (CLOUD_MENU_WIDTH - ${#title}) / 2 ))
    
    printf "${CLOUD_BORDER}║"
    printf ' %.0s' $(seq 1 $padding)
    printf "${CLOUD_TITLE}%s${CLOUD_BORDER}" "$title"
    printf ' %.0s' $(seq 1 $((CLOUD_MENU_WIDTH - padding - ${#title})))
    printf "║\n"
}

draw_cloud_option() {
    local option="$1"
    local is_selected="$2"
    
    if [ "$is_selected" = "true" ]; then
        printf "${CLOUD_BORDER}║${CLOUD_HIGHLIGHT} %-58s ${CLOUD_BORDER}║\n" "$option"
    else
        printf "${CLOUD_BORDER}║${CLOUD_TEXT} %-58s ${CLOUD_BORDER}║\n" "$option"
    fi
}

draw_cloud_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    clear
    
    draw_cloud_border_top
    draw_cloud_title "$title"
    draw_cloud_separator
    
    for i in "${!options[@]}"; do
        if [ $i -eq $selected_cloud ]; then
            draw_cloud_option "${options[$i]}" "true"
        else
            draw_cloud_option "${options[$i]}" "false"
        fi
    done
    
    draw_cloud_border_bottom
    echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour quitter"
}

wait_for_cloud_key() {
    echo -e "\n${CLOUD_TEXT}Appuyez sur une touche pour continuer...${CLOUD_NORMAL}"
    read -rsn1
}

# Script principal avec interface clavier
main() {
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -d "cloud" && ! -f "configure.sh" ]]; then
        print_error "Le dossier 'cloud' n'existe pas. Veuillez exécuter ce script depuis la racine du projet ou depuis le dossier cloud/."
        exit 1
    fi
    
    # Mode interactif avec navigation clavier
    while true; do
        draw_cloud_menu "$CLOUD_SCRIPT_NAME" "${CLOUD_ENV_OPTIONS[@]}"
        
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    "[A") ((selected_cloud--)); [ $selected_cloud -lt 0 ] && selected_cloud=$((${#CLOUD_ENV_OPTIONS[@]}-1)) ;;
                    "[B") ((selected_cloud++)); [ $selected_cloud -ge ${#CLOUD_ENV_OPTIONS[@]} ] && selected_cloud=0 ;;
                esac
                ;;
            "")
                case "${CLOUD_ENV_OPTIONS[$selected_cloud]}" in
                    "Ubuntu Dev")
                        configure_environment "ubuntu-dev"
                        ;;
                    "Rocky Dev")
                        configure_environment "rocky-dev"
                        ;;
                    "Dockgit")
                        configure_environment "dockgit"
                        ;;
                    "Retour")
                        clear
                        echo -e "${CLOUD_SUCCESS}Retour au menu principal ! 👋${CLOUD_NORMAL}"
                        exit 0
                        ;;
                esac
                ;;
            q)
                clear
                echo -e "${CLOUD_SUCCESS}Au revoir ! 👋${CLOUD_NORMAL}"
                exit 0
                ;;
        esac
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
