#!/bin/bash

# ==============================
# HIFADHI ONE-CLICK PROVISIONING
# Script de provisionnement automatisé
# ==============================

set -e  # Arrêter en cas d'erreur

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

# Configuration du menu
readonly MENU_WIDTH=60
readonly SCRIPT_NAME="HIFADHI ONE-CLICK-PROVISIONING"

# Options des menus
readonly MAIN_OPTIONS=("Installer les outils" "Lancer un provisionnement" "Aide" "Supprimer un provisionnement" "Quitter")
readonly INSTALL_OPTIONS=("Mac (brew)" "Mac (sans brew)" "Linux Ubuntu" "Linux CentOS" "Retour")
readonly PROVISION_OPTIONS=("Local" "Cloud" "Retour")

# Variables globales
selected_main=0

# ==============================
# FONCTIONS UTILITAIRES
# ==============================

log_info() {
    echo -e "${TEXT}[INFO]${NORMAL} $1"
}

log_success() {
    echo -e "${SUCCESS}[SUCCESS]${NORMAL} $1"
}

log_error() {
    echo -e "${ERROR}[ERROR]${NORMAL} $1" >&2
}

wait_for_key() {
    echo -e "\nAppuie sur une touche pour continuer..."
    read -rsn1
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 est installé et accessible"
        return 0
    else
        log_error "$1 n'est pas trouvé dans le PATH"
        return 1
    fi
}

download_vagrant_boxes() {
    log_info "Téléchargement des images Vagrant..."
    echo "Téléchargement des images de Rocky Linux et Ubuntu..."
    echo "Assurez-vous d'être connecté à Internet et que VirtualBox est installé"
    
    # Vérifier que Vagrant est disponible
    if ! command -v vagrant &> /dev/null; then
        log_error "Vagrant n'est pas installé ou pas dans le PATH"
        return 1
    fi
    
    # Télécharger Rocky Linux 9
    log_info "Téléchargement de Rocky Linux 9..."
    if vagrant box add rockylinux/9 --provider virtualbox 2>/dev/null || vagrant box list | grep -q "rockylinux/9"; then
        log_success "Image Rocky Linux 9 disponible"
    else
        log_error "Échec du téléchargement de Rocky Linux 9"
    fi
    
    # Télécharger Ubuntu Jammy (22.04)
    log_info "Téléchargement d'Ubuntu 22.04 LTS..."
    if vagrant box add ubuntu/jammy64 --provider virtualbox 2>/dev/null || vagrant box list | grep -q "ubuntu/jammy64"; then
        log_success "Image Ubuntu 22.04 disponible"
    else
        log_error "Échec du téléchargement d'Ubuntu 22.04"
    fi
    
    log_success "Téléchargement des images Vagrant terminé"
}

# ==============================
# FONCTIONS D'INSTALLATION
# ==============================

install_mac_brew() {
    log_info "Installation des outils via Homebrew..."
    
    # Vérifier si Homebrew est installé
    if ! command -v brew &> /dev/null; then
        log_info "Installation de Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            log_error "Échec de l'installation de Homebrew"
            return 1
        }
    fi
    
    # Installation des outils
    log_info "Installation de Terraform, Ansible et Vagrant..."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    brew install ansible
    brew install hashicorp/tap/hashicorp-vagrant
    
    # Vérification
    check_command terraform
    check_command ansible
    check_command vagrant
    
    # Téléchargement des images Vagrant
    download_vagrant_boxes
    
    log_success "Installation terminée avec succès !"
}

install_mac_no_brew() {
    log_info "Installation manuelle pour Mac (sans Homebrew)..."
    
    # Installation d'Ansible via pip
    if command -v python3 &> /dev/null; then
        log_info "Installation d'Ansible via pip..."
        python3 -m pip install --user ansible
    else
        log_error "Python3 est requis pour cette installation"
        return 1
    fi
    
    # Instructions pour Terraform et Vagrant
    echo -e "${TEXT}Pour Terraform et Vagrant, téléchargez manuellement depuis :${NORMAL}"
    echo "- Terraform: https://www.terraform.io/downloads.html"
    echo "- Vagrant: https://www.vagrantup.com/downloads"
    
    log_info "Ajoutez les binaires à votre PATH après téléchargement"
    
    # Téléchargement des images Vagrant si Vagrant est disponible
    if command -v vagrant &> /dev/null; then
        download_vagrant_boxes
    else
        echo -e "${TEXT}Note: Installez Vagrant puis relancez ce script pour télécharger les images${NORMAL}"
    fi
}

install_ubuntu() {
    log_info "Installation des outils pour Ubuntu..."
    
    # Mise à jour des paquets
    sudo apt-get update
    
    # Installation d'Ansible
    log_info "Installation d'Ansible..."
    sudo apt install software-properties-common -y
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible -y
    
    # Installation de Terraform
    log_info "Installation de Terraform..."
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    sudo apt update
    sudo apt-get install terraform -y
    
    # Installation de Vagrant
    log_info "Installation de Vagrant..."
    sudo apt install vagrant -y
    
    # Vérification
    check_command terraform
    check_command ansible
    check_command vagrant
    
    # Téléchargement des images Vagrant
    download_vagrant_boxes
    
    log_success "Installation terminée avec succès !"
}

install_centos() {
    log_info "Installation des outils pour CentOS/RHEL..."
    
    # Installation d'EPEL et Ansible
    log_info "Installation d'Ansible..."
    sudo dnf install epel-release -y
    sudo dnf install ansible -y
    
    # Installation de Terraform et Vagrant
    log_info "Installation de Terraform et Vagrant..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum install -y terraform vagrant
    
    # Vérification
    check_command terraform
    check_command ansible
    check_command vagrant
    
    # Téléchargement des images Vagrant
    download_vagrant_boxes
    
    log_success "Installation terminée avec succès !"
}

install_tools() {
    case "$1" in
        "Mac (brew)")
            install_mac_brew
            ;;
        "Mac (sans brew)")
            install_mac_no_brew
            ;;
        "Linux Ubuntu")
            install_ubuntu
            ;;
        "Linux CentOS")
            install_centos
            ;;
        *)
            log_error "Option d'installation non reconnue: $1"
            return 1
            ;;
    esac
}

# ==============================
# FONCTIONS DE PROVISIONNEMENT
# ==============================

launch_local_provision() {
    log_info "Lancement du provisionnement local..."
    
    # Vérifier les prérequis
    if ! check_command terraform || ! check_command ansible; then
        log_error "Les outils requis ne sont pas installés"
        echo "Veuillez d'abord installer les outils via le menu principal"
        return 1
    fi
    
    # TODO: Implémenter la logique de provisionnement local
    echo "Configuration Vagrant en cours..."
    echo "Application des playbooks Ansible..."
    
    log_info "Provisionnement local en cours de développement..."
}

launch_cloud_provision() {
    log_info "Lancement du provisionnement cloud..."
    
    # Vérifier les prérequis
    if ! check_command terraform; then
        log_error "Terraform n'est pas installé"
        return 1
    fi
    
    # TODO: Implémenter la logique de provisionnement cloud
    echo "Initialisation de Terraform..."
    echo "Création des ressources cloud..."
    
    log_info "Provisionnement cloud en cours de développement..."
}

launch_provision() {
    case "$1" in
        "Local")
            launch_local_provision
            ;;
        "Cloud")
            launch_cloud_provision
            ;;
        *)
            log_error "Option de provisionnement non reconnue: $1"
            return 1
            ;;
    esac
}

# ==============================
# FONCTIONS DE SUPPRESSION
# ==============================

delete_local_provision() {
    log_info "Suppression du provisionnement local..."
    
    # TODO: Implémenter la logique de suppression locale
    echo "Destruction des VMs Vagrant..."
    echo "Nettoyage des fichiers temporaires..."
    
    log_info "Suppression locale en cours de développement..."
}

delete_cloud_provision() {
    log_info "Suppression du provisionnement cloud..."
    
    # TODO: Implémenter la logique de suppression cloud
    echo "Destruction des ressources Terraform..."
    echo "Nettoyage des états distants..."
    
    log_info "Suppression cloud en cours de développement..."
}

delete_provision() {
    case "$1" in
        "Local")
            delete_local_provision
            ;;
        "Cloud")
            delete_cloud_provision
            ;;
        *)
            log_error "Option de suppression non reconnue: $1"
            return 1
            ;;
    esac
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
        printf "${BORDER}║ ${HIGHLIGHT}%-*s${NORMAL}${BORDER} ║\n" $((MENU_WIDTH-2)) "$option"
    else
        printf "${BORDER}║ ${TEXT}%-*s${NORMAL}${BORDER} ║\n" $((MENU_WIDTH-2)) "$option"
    fi
}

draw_menu() {
    local menu_title="$1"
    shift
    local menu_options=("$@")
    
    clear
    
    draw_border_top
    draw_title "$menu_title"
    draw_separator
    
    for i in "${!menu_options[@]}"; do
        local is_selected="false"
        [ $i -eq $selected_main ] && is_selected="true"
        draw_option "${menu_options[$i]}" "$is_selected"
    done
    
    draw_border_bottom
    echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour quitter"
}

submenu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    
    while true; do
        clear
        
        draw_border_top
        draw_title "$title"
        draw_separator
        
        for i in "${!options[@]}"; do
            local is_selected="false"
            [ $i -eq $selected ] && is_selected="true"
            draw_option "${options[$i]}" "$is_selected"
        done
        
        draw_border_bottom
        echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour revenir"
        
        # Lecture des touches
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    "[A") ((selected--)); [ $selected -lt 0 ] && selected=$((${#options[@]}-1)) ;;
                    "[B") ((selected++)); [ $selected -ge ${#options[@]} ] && selected=0 ;;
                esac
                ;;
            "")
                if [ "${options[$selected]}" == "Retour" ]; then
                    return 0
                fi
                
                clear
                echo -e "${TITLE}>>> ${title} : ${options[$selected]}${NORMAL}\n"
                
                # Exécuter l'action appropriée
                case "$title" in
                    "Installer les outils")
                        install_tools "${options[$selected]}"
                        ;;
                    "Provisionnement")
                        launch_provision "${options[$selected]}"
                        ;;
                    "Supprimer un provisionnement")
                        delete_provision "${options[$selected]}"
                        ;;
                esac
                
                wait_for_key
                ;;
            q)
                return 0
                ;;
        esac
    done
}

show_help() {
    clear
    echo -e "${TITLE}=== AIDE ===${NORMAL}\n"
    echo -e "${TEXT}Ce script permet de gérer facilement le provisionnement d'environnements.${NORMAL}\n"
    echo -e "${TEXT}Options disponibles :${NORMAL}"
    echo -e "1. ${HIGHLIGHT}Installer les outils${NORMAL} - Installe Terraform, Ansible et Vagrant"
    echo -e "   selon votre système d'exploitation"
    echo -e "2. ${HIGHLIGHT}Lancer un provisionnement${NORMAL} - Déploie un environnement"
    echo -e "   local (Vagrant) ou cloud (Terraform)"
    echo -e "3. ${HIGHLIGHT}Supprimer un provisionnement${NORMAL} - Détruit un environnement"
    echo -e "   existant pour libérer les ressources"
    echo -e "4. ${HIGHLIGHT}Aide${NORMAL} - Affiche cette aide"
    echo -e "5. ${HIGHLIGHT}Quitter${NORMAL} - Ferme le programme"
    echo -e "\n${TEXT}Navigation :${NORMAL}"
    echo -e "- Utilisez les flèches ↑ ↓ pour naviguer"
    echo -e "- Appuyez sur Entrée pour valider"
    echo -e "- Appuyez sur 'q' pour revenir ou quitter"
    wait_for_key
}

# ==============================
# FONCTION PRINCIPALE
# ==============================

main() {
    # Vérifier que nous sommes dans un terminal
    if [ ! -t 0 ]; then
        echo "Ce script doit être exécuté dans un terminal interactif"
        exit 1
    fi
    
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
                    "Installer les outils")
                        submenu "Installer les outils" "${INSTALL_OPTIONS[@]}"
                        ;;
                    "Lancer un provisionnement")
                        submenu "Provisionnement" "${PROVISION_OPTIONS[@]}"
                        ;;
                    "Supprimer un provisionnement")
                        submenu "Supprimer un provisionnement" "${PROVISION_OPTIONS[@]}"
                        ;;
                    "Aide")
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

# Vérifier les dépendances de base
if ! command -v curl &> /dev/null; then
    log_error "curl est requis mais n'est pas installé"
    exit 1
fi

# Lancer le programme principal
main "$@"