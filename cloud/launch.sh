#!/bin/bash

# Script de lancement global pour le provisionnement cloud
# Point d'entrée principal pour tous les environnements
# Interface clavier améliorée avec navigation au clavier

set -e

# ==============================
# CONFIGURATION ET CONSTANTES
# ==============================

# Couleurs pour l'interface
readonly NORMAL="\033[0m"
readonly HIGHLIGHT="\033[1;37;44m"    # blanc gras sur fond bleu
readonly TEXT="\033[0;33m"            # or sombre
readonly TITLE="\033[1;35m"           # violet clair subtil
readonly BORDER="\033[0;35m"          # violet profond
readonly ERROR="\033[1;31m"           # rouge pour les erreurs
readonly SUCCESS="\033[1;32m"         # vert pour les succès
readonly WARNING="\033[1;93m"         # jaune pour les avertissements
readonly INFO="\033[0;34m"            # bleu pour les infos

# Configuration du menu
readonly MENU_WIDTH=60
readonly SCRIPT_NAME="CLOUD PROVISIONING - ANSIBLE AUTOMATION"

# Options des menus
readonly MAIN_OPTIONS=("Provisionner un environnement" "Voir les informations des environnements" "Voir l'aide" "Quitter")
readonly ENV_OPTIONS=("Ubuntu Dev" "Rocky Dev" "Dockgit" "Retour")

# Variables globales
selected_main=0
selected_env=0

# ==============================
# FONCTIONS D'AFFICHAGE
# ==============================

log_info() {
    echo -e "${INFO}[INFO]${NORMAL} $1"
}

log_success() {
    echo -e "${SUCCESS}[SUCCESS]${NORMAL} $1"
}

log_warning() {
    echo -e "${WARNING}[WARNING]${NORMAL} $1"
}

log_error() {
    echo -e "${ERROR}[ERROR]${NORMAL} $1"
}

wait_for_key() {
    echo -e "\n${TEXT}Appuyez sur une touche pour continuer...${NORMAL}"
    read -rsn1
}

# ==============================
# FONCTIONS D'INTERFACE
# ==============================

draw_border_top() {
    printf "${BORDER}╔"
    printf '═%.0s' $(seq 1 $MENU_WIDTH)
    printf "╗\n"
}

draw_border_bottom() {
    printf "${BORDER}╚"
    printf '═%.0s' $(seq 1 $MENU_WIDTH)
    printf "╝\n${NORMAL}"
}

draw_separator() {
    printf "${BORDER}╠"
    printf '═%.0s' $(seq 1 $MENU_WIDTH)
    printf "╣\n"
}

draw_title() {
    local title="$1"
    local padding=$(( (MENU_WIDTH - ${#title}) / 2 ))
    
    printf "${BORDER}║"
    printf ' %.0s' $(seq 1 $padding)
    printf "${TITLE}%s${BORDER}" "$title"
    printf ' %.0s' $(seq 1 $((MENU_WIDTH - padding - ${#title})))
    printf "║\n"
}

draw_option() {
    local option="$1"
    local is_selected="$2"
    
    if [ "$is_selected" = "true" ]; then
        printf "${BORDER}║${HIGHLIGHT} %-58s ${BORDER}║\n" "$option"
    else
        printf "${BORDER}║${TEXT} %-58s ${BORDER}║\n" "$option"
    fi
}

draw_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    clear
    
    draw_border_top
    draw_title "$title"
    draw_separator
    
    for i in "${!options[@]}"; do
        if [ $i -eq $selected_main ]; then
            draw_option "${options[$i]}" "true"
        else
            draw_option "${options[$i]}" "false"
        fi
    done
    
    draw_border_bottom
    echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour quitter"
}

# ==============================
# FONCTIONS DE VÉRIFICATION
# ==============================

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier Ansible
    if ! check_command ansible; then
        log_warning "Ansible n'est pas installé."
        log_info "Installation d'Ansible..."
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if check_command brew; then
                brew install ansible
            else
                log_error "Homebrew n'est pas installé. Veuillez installer Ansible manuellement."
                log_info "Visitez : https://docs.ansible.com/ansible/latest/installation_guide/"
                wait_for_key
                return 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if check_command apt-get; then
                sudo apt-get update && sudo apt-get install -y ansible
            elif check_command yum; then
                sudo yum install -y ansible
            elif check_command dnf; then
                sudo dnf install -y ansible
            else
                log_error "Gestionnaire de paquets non supporté."
                log_info "Veuillez installer Ansible manuellement."
                log_info "Visitez : https://docs.ansible.com/ansible/latest/installation_guide/"
                wait_for_key
                return 1
            fi
        else
            log_error "Système d'exploitation non supporté."
            wait_for_key
            return 1
        fi
    else
        log_success "Ansible est installé : $(ansible --version | head -n 1)"
    fi
    
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -f "configure.sh" ]]; then
        log_error "Script de configuration non trouvé."
        log_info "Veuillez exécuter ce script depuis le dossier cloud/"
        wait_for_key
        return 1
    fi
    
    log_success "Tous les prérequis sont satisfaits !"
    return 0
}

# ==============================
# FONCTIONS D'INFORMATION
# ==============================

show_environments() {
    clear
    draw_border_top
    draw_title "ENVIRONNEMENTS DISPONIBLES"
    draw_separator
    
    echo -e "${BORDER}║${TEXT} Ubuntu Dev${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • K3s (Kubernetes léger)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • ArgoCD (GitOps)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Coder (Environnements de développement)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Podman (Conteneurs)${NORMAL}"
    echo -e "${BORDER}║${NORMAL}"
    echo -e "${BORDER}║${TEXT} Rocky Dev${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • K3s (Kubernetes léger)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • ArgoCD (GitOps)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Coder (Environnements de développement)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Podman (Conteneurs)${NORMAL}"
    echo -e "${BORDER}║${NORMAL}"
    echo -e "${BORDER}║${TEXT} Dockgit${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Forgejo (Git self-hosted)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Harbor (Registry de conteneurs)${NORMAL}"
    echo -e "${BORDER}║${TEXT}   • Podman (Conteneurs)${NORMAL}"
    
    draw_border_bottom
    wait_for_key
}

show_help() {
    clear
    draw_border_top
    draw_title "AIDE - CLOUD PROVISIONING"
    draw_separator
    
    echo -e "${BORDER}║${TEXT} Ce script vous permet de provisionner automatiquement des${NORMAL}"
    echo -e "${BORDER}║${TEXT} environnements de développement cloud en utilisant Ansible.${NORMAL}"
    echo -e "${BORDER}║${NORMAL}"
    echo -e "${BORDER}║${TEXT} Méthodes d'utilisation :${NORMAL}"
    echo -e "${BORDER}║${NORMAL}"
    echo -e "${BORDER}║${TEXT} 1) Mode interactif (recommandé) :${NORMAL}"
    echo -e "${BORDER}║${TEXT}    ./launch.sh${NORMAL}"
    echo -e "${BORDER}║${NORMAL}"
    echo -e "${BORDER}║${TEXT} 2) Provisionnement direct :${NORMAL}"
    echo -e "${BORDER}║${TEXT}    ./launch.sh ubuntu-dev${NORMAL}"
    echo -e "${BORDER}║${TEXT}    ./launch.sh rocky-dev${NORMAL}"
    echo -e "${BORDER}║${TEXT}    ./launch.sh dockgit${NORMAL}"
    echo -e "${BORDER}║${NORMAL}"
    echo -e "${BORDER}║${TEXT} Méthodes d'authentification supportées :${NORMAL}"
    echo -e "${BORDER}║${TEXT} • Mot de passe SSH/sudo${NORMAL}"
    echo -e "${BORDER}║${TEXT} • Clé SSH privée${NORMAL}"
    
    draw_border_bottom
    wait_for_key
}

# ==============================
# FONCTIONS DE PROVISIONNEMENT
# ==============================

provision_environment() {
    local env_type="$1"
    
    clear
    log_info "Configuration de l'environnement : $env_type"
    echo
    
    # Lancer le script configure.sh avec l'environnement spécifique
    if ./configure.sh "$env_type"; then
        log_success "Provisionnement de $env_type terminé avec succès !"
    else
        log_error "Erreur lors du provisionnement de $env_type"
    fi
    
    wait_for_key
}

show_environment_menu() {
    selected_env=0
    
    while true; do
        clear
        draw_border_top
        draw_title "CHOISIR UN ENVIRONNEMENT"
        draw_separator
        
        for i in "${!ENV_OPTIONS[@]}"; do
            if [ $i -eq $selected_env ]; then
                draw_option "${ENV_OPTIONS[$i]}" "true"
            else
                draw_option "${ENV_OPTIONS[$i]}" "false"
            fi
        done
        
        draw_border_bottom
        echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour revenir"
        
        # Lecture des touches
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    "[A") ((selected_env--)); [ $selected_env -lt 0 ] && selected_env=$((${#ENV_OPTIONS[@]}-1)) ;;
                    "[B") ((selected_env++)); [ $selected_env -ge ${#ENV_OPTIONS[@]} ] && selected_env=0 ;;
                esac
                ;;
            "")
                case "${ENV_OPTIONS[$selected_env]}" in
                    "Ubuntu Dev")
                        provision_environment "ubuntu-dev"
                        ;;
                    "Rocky Dev")
                        provision_environment "rocky-dev"
                        ;;
                    "Dockgit")
                        provision_environment "dockgit"
                        ;;
                    "Retour")
                        return 0
                        ;;
                esac
                ;;
            q)
                return 0
                ;;
        esac
    done
}

# ==============================
# FONCTION PRINCIPALE
# ==============================

main() {
    # Vérifier les prérequis
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Si un argument est fourni, provisionner directement
    if [[ $# -eq 1 ]]; then
        case $1 in
            "ubuntu-dev"|"rocky-dev"|"dockgit")
                log_info "Provisionnement direct de : $1"
                provision_environment "$1"
                ;;
            "-h"|"--help")
                show_help
                ;;
            *)
                log_error "Environnement invalide : $1"
                log_info "Environnements disponibles : ubuntu-dev, rocky-dev, dockgit"
                exit 1
                ;;
        esac
        return
    fi
    
    # Mode interactif avec navigation clavier
    while true; do
        draw_menu "$SCRIPT_NAME" "${MAIN_OPTIONS[@]}"
        
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    "[A") ((selected_main--)); [ $selected_main -lt 0 ] && selected_main=$((${#MAIN_OPTIONS[@]}-1)) ;;
                    "[B") ((selected_main++)); [ $selected_main -ge ${#MAIN_OPTIONS[@]} ] && selected_main=0 ;;
                esac
                ;;
            "")
                case "${MAIN_OPTIONS[$selected_main]}" in
                    "Provisionner un environnement")
                        show_environment_menu
                        ;;
                    "Voir les informations des environnements")
                        show_environments
                        ;;
                    "Voir l'aide")
                        show_help
                        ;;
                    "Quitter")
                        clear
                        echo -e "${SUCCESS}Au revoir ! 👋${NORMAL}"
                        exit 0
                        ;;
                esac
                ;;
            q)
                clear
                echo -e "${SUCCESS}Au revoir ! 👋${NORMAL}"
                exit 0
                ;;
        esac
    done
}

# ==============================
# POINT D'ENTRÉE
# ==============================

# Vérifier que nous sommes dans le bon répertoire
if [[ ! -d "cloud" && ! -f "configure.sh" ]]; then
    log_error "Le dossier 'cloud' n'existe pas. Veuillez exécuter ce script depuis la racine du projet ou depuis le dossier cloud/."
    exit 1
fi

# Lancer le programme principal
main "$@"