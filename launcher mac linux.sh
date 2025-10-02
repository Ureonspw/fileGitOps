#!/bin/bash

# ==============================
# HIFADHI ONE-CLICK PROVISIONING
# Script de provisionnement automatisé
# ==============================

set -e  # Arrêter en cas d'erreur

# ==============================
# CONFIGURATION DU RÉPERTOIRE DE TRAVAIL
# ==============================

# S'assurer qu'on est dans le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

# Configuration du menu
readonly MENU_WIDTH=60
readonly SCRIPT_NAME="HIFADHI ONE-CLICK-PROVISIONING"

# Chemins des dossiers de provisionnement
readonly ROCKY_PATH="testGitOps Rocky"
readonly UBUNTU_PATH="testGitOps Ubuntu"
readonly SERVERREPO_PATH="serveur_DOCKGIT"

# Options des menus
readonly MAIN_OPTIONS=("Installer les outils" "Lancer un provisionnement" "Aide" "Supprimer un provisionnement" "mise sous tension" "mise hors tension" "connexion" "Quitter" )
readonly INSTALL_OPTIONS=("Mac (brew)" "Mac (sans brew)" "Linux Ubuntu" "Linux CentOS" "Retour")

# Variables globales
selected_main=0

# ==============================
# FONCTIONS DE VÉRIFICATION
# ==============================

check_provisioning_status() {
    local rocky_exists=false
    local ubuntu_exists=false
    local serverrepo_exists=false
    
    # Vérifier l'existence des dossiers vagrant ET la présence d'un Vagrantfile
    if [ -d "$ROCKY_PATH/vagrant" ] && [ -f "$ROCKY_PATH/vagrant/Vagrantfile" ]; then
        rocky_exists=true
    fi
    
    if [ -d "$UBUNTU_PATH/vagrant" ] && [ -f "$UBUNTU_PATH/vagrant/Vagrantfile" ]; then
        ubuntu_exists=true
    fi
    
    if [ -d "$SERVERREPO_PATH/vagrant" ] && [ -f "$SERVERREPO_PATH/vagrant/Vagrantfile" ]; then
        serverrepo_exists=true
    fi
    
    # Retourner les 3 valeurs séparées par :
    echo "$rocky_exists:$ubuntu_exists:$serverrepo_exists"
}


get_available_provision_options() {
    local status=$(check_provisioning_status)
    local rocky_exists=$(echo "$status" | cut -d: -f1)
    local ubuntu_exists=$(echo "$status" | cut -d: -f2)
    local serverrepo_exists=$(echo "$status" | cut -d: -f3)
    
    local options=()
    
    # Ajouter les options disponibles pour provisionnement
    if [ "$rocky_exists" = "false" ]; then
        options+=("Rocky_DEV")
    fi
    
    if [ "$ubuntu_exists" = "false" ]; then
        options+=("Ubuntu_DEV")
    fi
    
    if [ "$serverrepo_exists" = "false" ]; then
        options+=("serverRepo")
    fi
    
    options+=("Cloud" "Retour")
    
    echo "${options[@]}"
}
get_available_ssh_options() {
    local status=$(check_provisioning_status)
    local rocky_exists=$(echo "$status" | cut -d: -f1)
    local ubuntu_exists=$(echo "$status" | cut -d: -f2)
    local serverrepo_exists=$(echo "$status" | cut -d: -f3)
    
    local options=()
    
    # Ne proposer que les serveurs déjà provisionnés et en cours d'exécution
    if [ "$rocky_exists" = "true" ]; then
        local rocky_status=$(check_server_status "$ROCKY_PATH")
        if [ "$rocky_status" = "running" ]; then
            options+=("Rocky_DEV")
        fi
    fi
    
    if [ "$ubuntu_exists" = "true" ]; then
        local ubuntu_status=$(check_server_status "$UBUNTU_PATH")
        if [ "$ubuntu_status" = "running" ]; then
            options+=("Ubuntu_DEV")
        fi
    fi
    
    if [ "$serverrepo_exists" = "true" ]; then
        local serverrepo_status=$(check_server_status "$SERVERREPO_PATH")
        if [ "$serverrepo_status" = "running" ]; then
            options+=("serverRepo")
        fi
    fi
    
    options+=("Retour")
    
    echo "${options[@]}"
}

get_available_delete_options() {
    local status=$(check_provisioning_status)
    local rocky_exists=$(echo "$status" | cut -d: -f1)
    local ubuntu_exists=$(echo "$status" | cut -d: -f2)
    local serverrepo_exists=$(echo "$status" | cut -d: -f3)
    
    local options=()
    
    # Ajouter les options disponibles pour suppression
    if [ "$rocky_exists" = "true" ]; then
        options+=("Rocky_DEV")
    fi
    
    if [ "$ubuntu_exists" = "true" ]; then
        options+=("Ubuntu_DEV")
    fi
    
    if [ "$serverrepo_exists" = "true" ]; then
        options+=("serverRepo")
    fi
    
    options+=("Cloud" "Retour")
    
    echo "${options[@]}"
}
get_available_shserver_options() {
    local status=$(check_provisioning_status)
    local rocky_exists=$(echo "$status" | cut -d: -f1)
    local ubuntu_exists=$(echo "$status" | cut -d: -f2)
    local serverrepo_exists=$(echo "$status" | cut -d: -f3)
    
    local options=()
    
    # Ne proposer que les serveurs déjà provisionnés
    if [ "$rocky_exists" = "true" ]; then
        options+=("Rocky_DEV")
    fi
    
    if [ "$ubuntu_exists" = "true" ]; then
        options+=("Ubuntu_DEV")
    fi
    
    if [ "$serverrepo_exists" = "true" ]; then
        options+=("serverRepo")
    fi
    
    options+=("Retour")
    
    echo "${options[@]}"
}

get_available_shutdown_options() {
    local status=$(check_provisioning_status)
    local rocky_exists=$(echo "$status" | cut -d: -f1)
    local ubuntu_exists=$(echo "$status" | cut -d: -f2)
    local serverrepo_exists=$(echo "$status" | cut -d: -f3)
    
    local options=()
    
    # Ne proposer que les serveurs déjà provisionnés et en cours d'exécution
    if [ "$rocky_exists" = "true" ]; then
        local rocky_status=$(check_server_status "$ROCKY_PATH")
        if [ "$rocky_status" = "running" ]; then
            options+=("Rocky_DEV")
        fi
    fi
    
    if [ "$ubuntu_exists" = "true" ]; then
        local ubuntu_status=$(check_server_status "$UBUNTU_PATH")
        if [ "$ubuntu_status" = "running" ]; then
            options+=("Ubuntu_DEV")
        fi
    fi
    
    if [ "$serverrepo_exists" = "true" ]; then
        local serverrepo_status=$(check_server_status "$SERVERREPO_PATH")
        if [ "$serverrepo_status" = "running" ]; then
            options+=("serverRepo")
        fi
    fi
    
    options+=("Retour")
    
    echo "${options[@]}"
}

show_provisioning_status() {
    local status=$(check_provisioning_status)
    local rocky_exists=$(echo "$status" | cut -d: -f1)
    local ubuntu_exists=$(echo "$status" | cut -d: -f2)
    local serverrepo_exists=$(echo "$status" | cut -d: -f3)
    
    echo -e "\n${TITLE}=== ÉTAT DES PROVISIONNEMENTS ===${NORMAL}"
    
    if [ "$rocky_exists" = "true" ]; then
        echo -e "${SUCCESS}✓ Rocky Linux${NORMAL} - Provisionnement existant"
    else
        echo -e "${TEXT}○ Rocky Linux${NORMAL} - Pas de provisionnement"
    fi
    
    if [ "$ubuntu_exists" = "true" ]; then
        echo -e "${SUCCESS}✓ Ubuntu${NORMAL} - Provisionnement existant"
    else
        echo -e "${TEXT}○ Ubuntu${NORMAL} - Pas de provisionnement"
    fi
    
    if [ "$serverrepo_exists" = "true" ]; then
        echo -e "${SUCCESS}✓ serverRepo${NORMAL} - Provisionnement existant"
    else
        echo -e "${TEXT}○ serverRepo${NORMAL} - Pas de provisionnement"
    fi
    
    echo ""
}
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

log_warning() {
    echo -e "${WARNING}[WARNING]${NORMAL} $1"
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

launch_rocky_provision() {
    log_info "Lancement du provisionnement Rocky Linux..."
    
    # Vérifier si le provisionnement existe déjà
    if [ -d "$ROCKY_PATH/vagrant" ]; then
        log_warning "Un provisionnement Rocky Linux existe déjà !"
        log_info "Veuillez d'abord le supprimer avant d'en créer un nouveau."
        return 1
    fi
    
    # Vérifier les prérequis
    if ! check_command vagrant || ! check_command ansible; then
        log_error "Les outils requis ne sont pas installés"
        echo "Veuillez d'abord installer les outils via le menu principal"
        return 1
    fi
    
    # TODO: Implémenter le provisionnement complet
    # 1. Créer/copier le Vagrantfile approprié pour Rocky
    # 2. Initialiser vagrant dans le dossier
    # 3. Configurer les variables d'environnement
    # 4. Lancer vagrant up
    # 5. Appliquer les playbooks Ansible
    # 6. Vérifier l'état des services
    
    # Créer le dossier vagrant
   
    cd "$ROCKY_PATH/terraform"
    terraform init
    terraform plan
    terraform apply
    
    
    log_success "Provisionnement Rocky Linux configuré avec succès !"
    log_info "Le dossier vagrant a été créé dans: $ROCKY_PATH/vagrant"
    log_info "Vous pouvez maintenant démarrer le serveur est deja mis sous tension vous pouvez y acceder avec la fonction connexion"
}

launch_ubuntu_provision() {
    log_info "Lancement du provisionnement Ubuntu..."
    
    # Vérifier si le provisionnement existe déjà
    if [ -d "$UBUNTU_PATH/vagrant" ]; then
        log_warning "Un provisionnement Ubuntu existe déjà !"
        log_info "Veuillez d'abord le supprimer avant d'en créer un nouveau."
        return 1
    fi
    
    # Vérifier les prérequis
    if ! check_command vagrant || ! check_command ansible; then
        log_error "Les outils requis ne sont pas installés"
        echo "Veuillez d'abord installer les outils via le menu principal"
        return 1
    fi
    
    # TODO: Implémenter le provisionnement complet
    # 1. Créer/copier le Vagrantfile approprié pour Ubuntu
    # 2. Initialiser vagrant dans le dossier
    # 3. Configurer les variables d'environnement
    # 4. Lancer vagrant up
    # 5. Appliquer les playbooks Ansible
    # 6. Vérifier l'état des services
    
    cd "$UBUNTU_PATH/terraform"
    terraform init
    terraform plan
    terraform apply
    
    log_success "Provisionnement Ubuntu configuré avec succès !"
    log_info "Le dossier vagrant a été créé dans: $UBUNTU_PATH/vagrant"
    log_info "Vous pouvez maintenant démarrer le serveur est deja mis sous tension vous pouvez y acceder avec la fonction connexion"
}

launch_cloud_provision() {
    log_info "Lancement du provisionnement cloud..."
    
    # Vérifier les prérequis
    if ! check_command ansible; then
        log_error "Ansible n'est pas installé"
        log_info "Veuillez d'abord installer les outils via le menu principal"
        return 1
    fi
    
    # Vérifier que le dossier cloud existe
    if [ ! -d "cloud" ]; then
        log_error "Le dossier 'cloud' n'existe pas dans le répertoire courant"
        return 1
    fi
    
    # Vérifier que le script configure.sh existe et est exécutable
    if [ ! -f "cloud/configure.sh" ] || [ ! -x "cloud/configure.sh" ]; then
        log_error "Le script configure.sh n'existe pas ou n'est pas exécutable"
        return 1
    fi
    
    # Sauvegarder le répertoire courant
    local original_dir=$(pwd)
    
    # Changer vers le dossier cloud
    cd cloud
    
    # Lancer le script configure.sh en mode interactif
    log_info "Lancement du menu de configuration cloud..."
    log_info "Vous allez pouvoir choisir l'environnement (Ubuntu Dev, Rocky Dev, ou Dockgit)"
    log_info "et configurer la connexion (IP, utilisateur, mot de passe/clé SSH)"
    echo
    
    # Attendre que l'utilisateur appuie sur une touche
    wait_for_key
    
    if ./configure.sh; then
        log_success "Provisionnement cloud terminé avec succès !"
    else
        log_error "Erreur lors du provisionnement cloud"
        cd "$original_dir"
        return 1
    fi
    
    # Retourner au répertoire parent
    cd "$original_dir"
}



launch_serverRepo_provision() {
    log_info "Lancement du provisionnement des repositories serveur..."
    
    # Vérifier si le provisionnement existe déjà
    if [ -d "$SERVERREPO_PATH/vagrant" ]; then
        log_warning "Un provisionnement serverRepo existe déjà !"
        log_info "Veuillez d'abord le supprimer avant d'en créer un nouveau."
        return 1
    fi
    
    # Vérifier les prérequis
    if ! check_command vagrant || ! check_command ansible; then
        log_error "Les outils requis ne sont pas installés"
        echo "Veuillez d'abord installer les outils via le menu principal"
        return 1
    fi

    cd "$SERVERREPO_PATH/terraform"
    terraform init
    terraform plan
    terraform apply
    
    # TODO: Implémenter le provisionnement complet
    # 1. Créer/copier le Vagrantfile approprié pour serverRepo
    # 2. Initialiser vagrant dans le dossier
    # 3. Configurer les variables d'environnement
    # 4. Lancer vagrant up
    # 5. Appliquer les playbooks Ansible
    # 6. Vérifier l'état des services
    
    
    log_success "Provisionnement serverRepo terminé avec succès !"
    log_info "Utilisation du dossier vagrant existant: $SERVERREPO_PATH/vagrant"
    log_info "Vous pouvez maintenant démarrer le serveur est deja mis sous tension vous pouvez y acceder avec la fonction connexion"
}



launch_provision() {
    case "$1" in
        "Rocky_DEV")
            launch_rocky_provision
            ;;
        "Ubuntu_DEV")
            launch_ubuntu_provision
            ;;
        "Cloud")
            launch_cloud_provision
            ;;
        "serverRepo")
            launch_serverRepo_provision
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

delete_rocky_provision() {
    log_info "Suppression du provisionnement Rocky Linux..."
    
    if [ ! -d "$ROCKY_PATH/vagrant" ]; then
        log_error "Aucun provisionnement Rocky Linux trouvé à supprimer"
        return 1
    fi
    
    # Arrêter et détruire les VMs Vagrant si elles existent
    if [ -f "$ROCKY_PATH/vagrant/Vagrantfile" ]; then
        log_info "Arrêt et destruction des VMs Rocky Linux..."
        cd "$ROCKY_PATH/vagrant"
        
        # Vérifier si des VMs sont en cours d'exécution
        if vagrant status 2>/dev/null | grep -q "running"; then
            log_info "Arrêt des VMs en cours d'exécution..."
            vagrant halt 2>/dev/null || log_warning "Impossible d'arrêter les VMs"
        fi
        
        # Détruire les VMs
        log_info "Destruction des VMs..."
        vagrant destroy -f 2>/dev/null || log_warning "Aucune VM à détruire ou erreur lors de la destruction"
        
        # Retourner au répertoire parent
        cd - > /dev/null
    fi
    
    # Exécuter terraform destroy pour nettoyer les ressources
    if [ -d "$ROCKY_PATH/terraform" ]; then
        log_info "Nettoyage des ressources Terraform..."
        cd "$ROCKY_PATH/terraform"
        
        # Vérifier que terraform est disponible
        if command -v terraform &> /dev/null; then
            # Vérifier si des ressources existent
            if terraform state list 2>/dev/null | grep -q .; then
                log_info "Destruction des ressources Terraform..."
                terraform destroy -auto-approve 2>/dev/null || log_warning "Erreur lors de terraform destroy"
            else
                log_info "Aucune ressource Terraform à détruire"
            fi
        else
            log_warning "Terraform n'est pas disponible, impossible de nettoyer les ressources"
        fi
        
        # Retourner au répertoire parent
        cd - > /dev/null
    fi
    
    # Attendre un peu pour s'assurer que tous les processus sont terminés
    sleep 2
    
    # Supprimer le dossier vagrant avec force
    log_info "Suppression du dossier vagrant..."
    if rm -rf "$ROCKY_PATH/vagrant" 2>/dev/null; then
        log_success "Provisionnement Rocky Linux supprimé avec succès !"
    else
        log_warning "Première tentative de suppression échouée, nouvelle tentative..."
        # Essayer de supprimer les fichiers cachés individuellement
        if [ -d "$ROCKY_PATH/vagrant/.vagrant" ]; then
            rm -rf "$ROCKY_PATH/vagrant/.vagrant" 2>/dev/null
        fi
        # Nouvelle tentative de suppression complète
        if rm -rf "$ROCKY_PATH/vagrant" 2>/dev/null; then
            log_success "Provisionnement Rocky Linux supprimé avec succès !"
        else
            log_error "Erreur lors de la suppression du dossier vagrant. Vérifiez les permissions."
            return 1
        fi
    fi
}

delete_ubuntu_provision() {
    log_info "Suppression du provisionnement Ubuntu..."
    
    if [ ! -d "$UBUNTU_PATH/vagrant" ]; then
        log_error "Aucun provisionnement Ubuntu trouvé à supprimer"
        return 1
    fi
    
    # Arrêter et détruire les VMs Vagrant si elles existent
    if [ -f "$UBUNTU_PATH/vagrant/Vagrantfile" ]; then
        log_info "Arrêt et destruction des VMs Ubuntu..."
        cd "$UBUNTU_PATH/vagrant"
        
        # Vérifier si des VMs sont en cours d'exécution
        if vagrant status 2>/dev/null | grep -q "running"; then
            log_info "Arrêt des VMs en cours d'exécution..."
            vagrant halt 2>/dev/null || log_warning "Impossible d'arrêter les VMs"
        fi
        
        # Détruire les VMs
        log_info "Destruction des VMs..."
        vagrant destroy -f 2>/dev/null || log_warning "Aucune VM à détruire ou erreur lors de la destruction"
        
        # Retourner au répertoire parent
        cd - > /dev/null
    fi
    
    # Exécuter terraform destroy pour nettoyer les ressources
    if [ -d "$UBUNTU_PATH/terraform" ]; then
        log_info "Nettoyage des ressources Terraform..."
        cd "$UBUNTU_PATH/terraform"
        
        # Vérifier que terraform est disponible
        if command -v terraform &> /dev/null; then
            # Vérifier si des ressources existent
            if terraform state list 2>/dev/null | grep -q .; then
                log_info "Destruction des ressources Terraform..."
                terraform destroy -auto-approve 2>/dev/null || log_warning "Erreur lors de terraform destroy"
            else
                log_info "Aucune ressource Terraform à détruire"
            fi
        else
            log_warning "Terraform n'est pas disponible, impossible de nettoyer les ressources"
        fi
        
        # Retourner au répertoire parent
        cd - > /dev/null
    fi
    
    # Attendre un peu pour s'assurer que tous les processus sont terminés
    sleep 2
    
    # Supprimer le dossier vagrant avec force
    log_info "Suppression du dossier vagrant..."
    if rm -rf "$UBUNTU_PATH/vagrant" 2>/dev/null; then
        log_success "Provisionnement Ubuntu supprimé avec succès !"
    else
        log_warning "Première tentative de suppression échouée, nouvelle tentative..."
        # Essayer de supprimer les fichiers cachés individuellement
        if [ -d "$UBUNTU_PATH/vagrant/.vagrant" ]; then
            rm -rf "$UBUNTU_PATH/vagrant/.vagrant" 2>/dev/null
        fi
        # Nouvelle tentative de suppression complète
        if rm -rf "$UBUNTU_PATH/vagrant" 2>/dev/null; then
            log_success "Provisionnement Ubuntu supprimé avec succès !"
        else
            log_error "Erreur lors de la suppression du dossier vagrant. Vérifiez les permissions."
            return 1
        fi
    fi
}

delete_cloud_provision() {
    log_info "Suppression du provisionnement cloud..."
    
    # TODO: Implémenter la suppression cloud complète
    # 1. Vérifier l'existence des fichiers Terraform
    # 2. Lire le state pour voir les ressources créées
    # 3. Exécuter terraform destroy avec confirmation
    # 4. Nettoyer les fichiers .tfstate
    # 5. Supprimer les ressources temporaires
    # 6. Nettoyer les clés SSH générées
    
    # SIMULATION POUR TEST
    log_info "=== SIMULATION SUPPRESSION CLOUD ==="
    echo "1. Lecture de l'état Terraform..."
    sleep 1
    echo "   -> terraform state list"
    echo "2. Planification de la destruction..."
    sleep 1
    echo "   -> terraform plan -destroy"
    echo "3. Destruction des ressources cloud..."
    sleep 2
    echo "   -> terraform destroy -auto-approve"
    echo "4. Nettoyage des fichiers d'état..."
    sleep 1
    echo "5. Suppression des clés SSH temporaires..."
    log_info "=== FIN DE LA SIMULATION ==="
    
    log_success "Provisionnement cloud supprimé avec succès !"
    log_warning "Note: Ceci était une simulation. Implémentation réelle à venir."
}

delete_serverRepo_provision() {
    log_info "Suppression du provisionnement des repositories serveur..."
    
    if [ ! -d "$SERVERREPO_PATH/vagrant" ]; then
        log_error "Aucun provisionnement serverRepo trouvé à supprimer"
        return 1
    fi
    
    # Arrêter et détruire les VMs Vagrant si elles existent
    if [ -f "$SERVERREPO_PATH/vagrant/Vagrantfile" ]; then
        log_info "Arrêt et destruction des VMs serverRepo..."
        cd "$SERVERREPO_PATH/vagrant"
        
        # Vérifier si des VMs sont en cours d'exécution
        if vagrant status 2>/dev/null | grep -q "running"; then
            log_info "Arrêt des VMs en cours d'exécution..."
            vagrant halt 2>/dev/null || log_warning "Impossible d'arrêter les VMs"
        fi
        
        # Détruire les VMs
        log_info "Destruction des VMs..."
        vagrant destroy -f 2>/dev/null || log_warning "Aucune VM à détruire ou erreur lors de la destruction"
        
        # Retourner au répertoire parent
        cd - > /dev/null
    fi
    
    # Exécuter terraform destroy pour nettoyer les ressources
    if [ -d "$SERVERREPO_PATH/terraform" ]; then
        log_info "Nettoyage des ressources Terraform..."
        cd "$SERVERREPO_PATH/terraform"
        
        # Vérifier que terraform est disponible
        if command -v terraform &> /dev/null; then
            # Vérifier si des ressources existent
            if terraform state list 2>/dev/null | grep -q .; then
                log_info "Destruction des ressources Terraform..."
                terraform destroy -auto-approve 2>/dev/null || log_warning "Erreur lors de terraform destroy"
            else
                log_info "Aucune ressource Terraform à détruire"
            fi
        else
            log_warning "Terraform n'est pas disponible, impossible de nettoyer les ressources"
        fi
        
        # Retourner au répertoire parent
        cd - > /dev/null
    fi
    
    # Attendre un peu pour s'assurer que tous les processus sont terminés
    sleep 2
    
    # Supprimer le dossier vagrant avec force
    log_info "Suppression du dossier vagrant..."
    if rm -rf "$SERVERREPO_PATH/vagrant" 2>/dev/null; then
        log_success "Provisionnement serverRepo supprimé avec succès !"
    else
        log_warning "Première tentative de suppression échouée, nouvelle tentative..."
        # Essayer de supprimer les fichiers cachés individuellement
        if [ -d "$SERVERREPO_PATH/vagrant/.vagrant" ]; then
            rm -rf "$SERVERREPO_PATH/vagrant/.vagrant" 2>/dev/null
        fi
        # Nouvelle tentative de suppression complète
        if rm -rf "$SERVERREPO_PATH/vagrant" 2>/dev/null; then
            log_success "Provisionnement serverRepo supprimé avec succès !"
        else
            log_error "Erreur lors de la suppression du dossier vagrant. Vérifiez les permissions."
            return 1
        fi
    fi
}

delete_provision() {
    # Demander confirmation
    echo -e "${WARNING}⚠️  ATTENTION: Cette action est irréversible !${NORMAL}"
    echo -e "${TEXT}Voulez-vous vraiment supprimer le provisionnement $1 ? (y/N)${NORMAL}"
    read -n 1 confirm
    echo
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "Suppression annulée par l'utilisateur"
        return 0
    fi
    
    case "$1" in
        "Rocky_DEV")
            delete_rocky_provision
            ;;
        "Ubuntu_DEV")
            delete_ubuntu_provision
            ;;
        "Cloud")
            delete_cloud_provision
            ;;
        "serverRepo")
            delete_serverRepo_provision
            ;;
        *)
            log_error "Option de suppression non reconnue: $1"
            return 1
            ;;
    esac
}




check_server_status() {
    local server_path="$1"
    
    # Vérifier que le dossier vagrant existe ET qu'il contient un Vagrantfile
    if [ -d "$server_path/vagrant" ] && [ -f "$server_path/vagrant/Vagrantfile" ]; then
        # Vérifier que vagrant est disponible
        if ! command -v vagrant &> /dev/null; then
            echo "not_provisioned"
            return
        fi
        
        # Aller dans le dossier vagrant et vérifier le statut
        cd "$server_path/vagrant" 2>/dev/null || {
            echo "not_provisioned"
            return
        }
        
        # Vérifier le statut vagrant avec une approche plus robuste
        local vagrant_status_output=$(vagrant status 2>/dev/null)
        
        if echo "$vagrant_status_output" | grep -q "running"; then
            echo "running"
        elif echo "$vagrant_status_output" | grep -qE "(poweroff|saved|aborted|not created)"; then
            echo "stopped"
        else
            # Si on ne peut pas déterminer le statut, mais que le Vagrantfile existe,
            # on considère que c'est provisionné mais arrêté
            echo "stopped"
        fi
    else
        echo "not_provisioned"
    fi
}

shupserver() {
    local server_name="$1"
    local server_path=""
    
    # Déterminer le chemin du serveur
    case "$server_name" in
        "Rocky_DEV")
            server_path="$ROCKY_PATH"
            ;;
        "Ubuntu_DEV")
            server_path="$UBUNTU_PATH"
            ;;
        "serverRepo")
            server_path="$SERVERREPO_PATH"
            ;;
        *)
            log_error "Option non reconnue: $server_name"
            return 1
            ;;
    esac
    
    # Vérifier que le dossier vagrant existe
    if [ ! -d "$server_path/vagrant" ]; then
        log_error "Le provisionnement $server_name n'existe pas !"
        log_info "Veuillez d'abord créer un provisionnement via le menu principal"
        return 1
    fi
    
    # Vérifier l'état actuel du serveur
    local current_status=$(check_server_status "$server_path")
    
    if [ "$current_status" = "running" ]; then
        log_warning "Le serveur $server_name est déjà en cours d'exécution !"
        echo -e "${TEXT}Voulez-vous le redémarrer ? (y/N)${NORMAL}"
        read -n 1 restart_confirm
        echo
        
        if [ "$restart_confirm" = "y" ] || [ "$restart_confirm" = "Y" ]; then
            log_info "Arrêt du serveur $server_name..."
            cd "$server_path/vagrant" && vagrant halt
            if [ $? -ne 0 ]; then
                log_error "Échec de l'arrêt du serveur $server_name"
                return 1
            fi
            sleep 2
        else
            log_info "Démarrage annulé"
            return 0
        fi
    fi
    
    # Démarrer le serveur
    log_info "Démarrage du serveur $server_name..."
    cd "$server_path/vagrant" || {
        log_error "Impossible d'accéder au dossier $server_path/vagrant"
        return 1
    }
    
    # Vérifier que Vagrant est disponible
    if ! command -v vagrant &> /dev/null; then
        log_error "Vagrant n'est pas installé ou pas dans le PATH"
        return 1
    fi
    
    # Lancer vagrant up
    vagrant up
    local vagrant_exit_code=$?
    
    if [ $vagrant_exit_code -eq 0 ]; then
        log_success "Serveur $server_name démarré avec succès !"
        
        # Afficher les informations de connexion
        echo -e "\n${TITLE}=== INFORMATIONS DE CONNEXION ===${NORMAL}"
        vagrant ssh-config
        
        # Afficher l'adresse IP si disponible
        local ip_info=$(vagrant ssh -c "ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1" 2>/dev/null)
        if [ -n "$ip_info" ]; then
            echo -e "\n${SUCCESS}Adresse IP du serveur:${NORMAL}"
            echo "$ip_info"
        fi
    else
        log_error "Échec du démarrage du serveur $server_name"
        log_info "Vérifiez les logs avec: cd $server_path/vagrant && vagrant status"
        return 1
    fi
}

# ==============================
# FONCTIONS DE MISE HORS TENSION
# ==============================

shutdown_server() {
    local server_name="$1"
    local server_path=""
    
    # Déterminer le chemin du serveur
    case "$server_name" in
        "Rocky_DEV")
            server_path="$ROCKY_PATH"
            ;;
        "Ubuntu_DEV")
            server_path="$UBUNTU_PATH"
            ;;
        "serverRepo")
            server_path="$SERVERREPO_PATH"
            ;;
        *)
            log_error "Option non reconnue: $server_name"
            return 1
            ;;
    esac
    
    # Vérifier que le dossier vagrant existe
    if [ ! -d "$server_path/vagrant" ]; then
        log_error "Le provisionnement $server_name n'existe pas !"
        log_info "Veuillez d'abord créer un provisionnement via le menu principal"
        return 1
    fi
    
    # Vérifier l'état actuel du serveur
    local current_status=$(check_server_status "$server_path")
    
    if [ "$current_status" = "not_provisioned" ]; then
        log_error "Le serveur $server_name n'est pas provisionné !"
        return 1
    elif [ "$current_status" = "stopped" ]; then
        log_warning "Le serveur $server_name est déjà arrêté !"
        return 0
    fi
    
    # Demander confirmation avant l'arrêt
    echo -e "${WARNING}⚠️  ATTENTION: Vous allez arrêter le serveur $server_name !${NORMAL}"
    echo -e "${TEXT}Voulez-vous vraiment arrêter le serveur ? (y/N)${NORMAL}"
    read -n 1 confirm
    echo
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "Arrêt annulé par l'utilisateur"
        return 0
    fi
    
    # Arrêter le serveur
    log_info "Arrêt du serveur $server_name..."
    cd "$server_path/vagrant" || {
        log_error "Impossible d'accéder au dossier $server_path/vagrant"
        return 1
    }
    
    # Vérifier que Vagrant est disponible
    if ! command -v vagrant &> /dev/null; then
        log_error "Vagrant n'est pas installé ou pas dans le PATH"
        return 1
    fi
    
    # Lancer vagrant halt
    vagrant halt
    local vagrant_exit_code=$?
    
    if [ $vagrant_exit_code -eq 0 ]; then
        log_success "Serveur $server_name arrêté avec succès !"
        
        # Vérifier l'état final
        local final_status=$(check_server_status "$server_path")
        if [ "$final_status" = "stopped" ]; then
            log_success "État confirmé : Serveur $server_name arrêté"
        elif [ "$final_status" = "not_provisioned" ]; then
            log_warning "Attention : Le provisionnement semble avoir été supprimé"
        else
            log_info "État actuel : $final_status"
        fi
    else
        log_error "Échec de l'arrêt du serveur $server_name"
        log_info "Vérifiez les logs avec: cd $server_path/vagrant && vagrant status"
        return 1
    fi
}

# ==============================
# FONCTIONS DE CONNEXION SSH
# ==============================

connect_ssh() {
    local server_name="$1"
    local server_path=""
    
    # Déterminer le chemin du serveur
    case "$server_name" in
        "Rocky_DEV")
            server_path="$ROCKY_PATH"
            ;;
        "Ubuntu_DEV")
            server_path="$UBUNTU_PATH"
            ;;
        "serverRepo")
            server_path="$SERVERREPO_PATH"
            ;;
        *)
            log_error "Option non reconnue: $server_name"
            return 1
            ;;
    esac
    
    # Vérifier que le dossier vagrant existe
    if [ ! -d "$server_path/vagrant" ]; then
        log_error "Le provisionnement $server_name n'existe pas !"
        log_info "Veuillez d'abord créer un provisionnement via le menu principal"
        return 1
    fi
    
    # Vérifier l'état du serveur
    local current_status=$(check_server_status "$server_path")
    
    if [ "$current_status" = "not_provisioned" ]; then
        log_error "Le serveur $server_name n'est pas provisionné !"
        return 1
    elif [ "$current_status" = "stopped" ]; then
        log_warning "Le serveur $server_name est arrêté !"
        echo -e "${TEXT}Voulez-vous le démarrer maintenant ? (y/N)${NORMAL}"
        read -n 1 start_confirm
        echo
        
        if [ "$start_confirm" = "y" ] || [ "$start_confirm" = "Y" ]; then
            log_info "Démarrage du serveur $server_name..."
            shupserver "$server_name"
            if [ $? -ne 0 ]; then
                log_error "Impossible de démarrer le serveur $server_name"
                return 1
            fi
        else
            log_info "Connexion annulée"
            return 0
        fi
    fi
    
    # Se connecter au serveur
    log_info "Connexion au serveur $server_name..."
    cd "$server_path/vagrant" || {
        log_error "Impossible d'accéder au dossier $server_path/vagrant"
        return 1
    }
    
    # Vérifier que Vagrant est disponible
    if ! command -v vagrant &> /dev/null; then
        log_error "Vagrant n'est pas installé ou pas dans le PATH"
        return 1
    fi
    
    # Afficher les informations de connexion avant de se connecter
    echo -e "\n${TITLE}=== INFORMATIONS DE CONNEXION ===${NORMAL}"
    vagrant ssh-config
    
    echo -e "\n${SUCCESS}Connexion au serveur $server_name...${NORMAL}"
    echo -e "${TEXT}Pour quitter la session SSH, tapez 'exit'${NORMAL}\n"
    
    # Se connecter via SSH
    vagrant ssh
    local ssh_exit_code=$?
    
    if [ $ssh_exit_code -eq 0 ]; then
        log_success "Déconnexion du serveur $server_name réussie"
    else
        log_warning "Session SSH terminée avec le code: $ssh_exit_code"
    fi
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

dynamic_submenu() {
    local title="$1"
    local menu_type="$2"  # "provision" ou "delete"
    
    # Obtenir les options dynamiquement
    local options_array
    if [ "$menu_type" = "provision" ]; then
        options_array=($(get_available_provision_options))
    elif [ "$menu_type" = "delete" ]; then
        options_array=($(get_available_delete_options))
    elif [ "$title" = "Installer les outils" ]; then
        options_array=("${INSTALL_OPTIONS[@]}")
    elif [ "$menu_type" = "shserver" ]; then
        options_array=($(get_available_shserver_options))
    elif [ "$menu_type" = "ssh" ]; then
        options_array=($(get_available_ssh_options))
    elif [ "$menu_type" = "shutdown" ]; then
        options_array=($(get_available_shutdown_options))
    else
        log_error "Type de menu non reconnu: $menu_type"
        return 1
    fi
    
    # Vérifier s'il y a des options disponibles (autres que "Retour")
    local has_options=false
    for option in "${options_array[@]}"; do
        if [ "$option" != "Retour" ] && [ "$option" != "Cloud" ]; then
            has_options=true
            break
        fi
    done
    
    local selected=0
    
    while true; do
        clear
        
        # Afficher le statut des provisionnements
        if [ "$menu_type" = "provision" ] || [ "$menu_type" = "delete" ]; then
            show_provisioning_status
        fi
        
        draw_border_top
        draw_title "$title"
        draw_separator
        
        # Afficher un message si aucune option n'est disponible
        if [ "$has_options" = "false" ] && ([ "$menu_type" = "provision" ] || [ "$menu_type" = "delete" ] || [ "$menu_type" = "shutdown" ] || [ "$menu_type" = "ssh" ]); then
            if [ "$menu_type" = "provision" ]; then
                draw_option "Aucun provisionnement local disponible" "false"
                draw_option "(Des provisionnements existent déjà)" "false"
            elif [ "$menu_type" = "delete" ]; then
                draw_option "Aucun provisionnement à supprimer" "false"
            elif [ "$menu_type" = "shutdown" ]; then
                draw_option "Aucun serveur en cours d'exécution" "false"
                draw_option "(Aucun serveur à arrêter)" "false"
            elif [ "$menu_type" = "ssh" ]; then
                draw_option "Aucun serveur en cours d'exécution" "false"
                draw_option "(Aucun serveur pour la connexion)" "false"
            fi
            draw_separator
        fi
        
        for i in "${!options_array[@]}"; do
            local is_selected="false"
            [ $i -eq $selected ] && is_selected="true"
            draw_option "${options_array[$i]}" "$is_selected"
        done
        
        draw_border_bottom
        echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour revenir"
        
        # Lecture des touches
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    "[A") ((selected--)); [ $selected -lt 0 ] && selected=$((${#options_array[@]}-1)) ;;
                    "[B") ((selected++)); [ $selected -ge ${#options_array[@]} ] && selected=0 ;;
                esac
                ;;
            "")
                if [ "${options_array[$selected]}" == "Retour" ]; then
                    return 0
                fi
                
                # Ignorer les options non-fonctionnelles
                if [ "${options_array[$selected]}" == "Aucun provisionnement local disponible" ] || \
                   [ "${options_array[$selected]}" == "(Des provisionnements existent déjà)" ] || \
                   [ "${options_array[$selected]}" == "Aucun provisionnement à supprimer" ] || \
                   [ "${options_array[$selected]}" == "Aucun serveur en cours d'exécution" ] || \
                   [ "${options_array[$selected]}" == "(Aucun serveur à arrêter)" ] || \
                   [ "${options_array[$selected]}" == "(Aucun serveur pour la connexion)" ]; then
                    continue
                fi
                
                clear
                echo -e "${TITLE}>>> ${title} : ${options_array[$selected]}${NORMAL}\n"
                
                # Exécuter l'action appropriée
                case "$title" in
                    "Installer les outils")
                        install_tools "${options_array[$selected]}"
                        ;;
                    "Provisionnement")
                        launch_provision "${options_array[$selected]}"
                        ;;
                    "Supprimer un provisionnement")
                        delete_provision "${options_array[$selected]}"
                        ;;
                    "Mise sous tension des serveurs")
                        shupserver "${options_array[$selected]}"
                        ;;
                    "Connexion a un serveur")
                        connect_ssh "${options_array[$selected]}"
                        ;;
                    "Mise hors tension des serveurs")
                        shutdown_server "${options_array[$selected]}"
                        ;;
                esac
                
                wait_for_key
                
                # Recalculer les options après l'action
                if [ "$menu_type" = "provision" ]; then
                    options_array=($(get_available_provision_options))
                elif [ "$menu_type" = "delete" ]; then
                    options_array=($(get_available_delete_options))
                elif [ "$menu_type" = "shutdown" ]; then
                    options_array=($(get_available_shutdown_options))
                elif [ "$menu_type" = "ssh" ]; then
                    options_array=($(get_available_ssh_options))
                elif [ "$menu_type" = "shserver" ]; then
                    options_array=($(get_available_shserver_options))
                fi
                
                # Vérifier à nouveau s'il y a des options
                has_options=false
                for option in "${options_array[@]}"; do
                    if [ "$option" != "Retour" ] && [ "$option" != "Cloud" ]; then
                        has_options=true
                        break
                    fi
                done
                
                # Réinitialiser la sélection
                selected=0
                ;;
            q)
                return 0
                ;;
        esac
    done
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
                    "Mise sous tension des serveurs")
                        shupserver "${options[$selected]}"
                        ;;
                    "Connexion a un serveur")
                        connect_ssh "${options[$selected]}"
                        ;;
                    "Mise hors tension des serveurs")
                        shutdown_server "${options[$selected]}"
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
    
    # Afficher le statut actuel
    show_provisioning_status
    
    echo -e "${TEXT}Options disponibles :${NORMAL}"
    echo -e "1. ${HIGHLIGHT}Installer les outils${NORMAL} - Installe Terraform, Ansible et Vagrant"
    echo -e "   selon votre système d'exploitation"
    echo -e "2. ${HIGHLIGHT}Lancer un provisionnement${NORMAL} - Déploie un environnement"
    echo -e "   local (Rocky/Ubuntu) ou cloud (Terraform)"
    echo -e "   ${TEXT}Note: Seuls les provisionnements non-existants sont proposés${NORMAL}"
    echo -e "3. ${HIGHLIGHT}Supprimer un provisionnement${NORMAL} - Détruit un environnement"
    echo -e "   existant pour libérer les ressources"
    echo -e "   ${TEXT}Note: Seuls les provisionnements existants sont proposés${NORMAL}"
    echo -e "4. ${HIGHLIGHT}Mise sous tension${NORMAL} - Démarre un serveur provisionné"
    echo -e "   ${TEXT}Note: Seuls les serveurs provisionnés sont proposés${NORMAL}"
    echo -e "5. ${HIGHLIGHT}Mise hors tension${NORMAL} - Arrête un serveur en cours d'exécution"
    echo -e "   ${TEXT}Note: Seuls les serveurs en cours d'exécution sont proposés${NORMAL}"
    echo -e "6. ${HIGHLIGHT}Connexion${NORMAL} - Se connecte en SSH à un serveur"
    echo -e "   ${TEXT}Note: Seuls les serveurs en cours d'exécution sont proposés${NORMAL}"
    echo -e "7. ${HIGHLIGHT}Aide${NORMAL} - Affiche cette aide"
    echo -e "8. ${HIGHLIGHT}Quitter${NORMAL} - Ferme le programme"
    echo -e "\n${TEXT}Navigation :${NORMAL}"
    echo -e "- Utilisez les flèches ↑ ↓ pour naviguer"
    echo -e "- Appuyez sur Entrée pour valider"
    echo -e "- Appuyez sur 'q' pour revenir ou quitter"
    echo -e "\n${TEXT}Détection automatique :${NORMAL}"
    echo -e "- Le script détecte automatiquement les dossiers 'vagrant' existants"
    echo -e "- Rocky Linux: ${ROCKY_PATH}/vagrant"
    echo -e "- Ubuntu: ${UBUNTU_PATH}/vagrant"
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
                        dynamic_submenu "Installer les outils" "install"
                        ;;
                    "Lancer un provisionnement")
                        dynamic_submenu "Provisionnement" "provision"
                        ;;
                    "Supprimer un provisionnement")
                        dynamic_submenu "Supprimer un provisionnement" "delete"
                        ;;
                    "Aide")
                        show_help
                        ;;
                    "Quitter")
                        clear
                        echo -e "${SUCCESS}Au revoir ! 👋${NORMAL}"
                        exit 0
                        ;;
                    "mise sous tension")
                        dynamic_submenu "Mise sous tension des serveurs" "shserver"
                        ;;
                    "mise hors tension")
                        dynamic_submenu "Mise hors tension des serveurs" "shutdown"
                        ;;
                    "connexion")
                        dynamic_submenu "Connexion a un serveur" "ssh"
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