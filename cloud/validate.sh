#!/bin/bash

# Script de validation de la configuration cloud
# Vérifie que tous les fichiers nécessaires sont présents et valides

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

# Compteurs
total_checks=0
passed_checks=0
failed_checks=0
warning_checks=0

# Fonction pour vérifier un fichier
check_file() {
    local file_path=$1
    local description=$2
    local required=${3:-true}
    
    total_checks=$((total_checks + 1))
    
    if [[ -f "$file_path" ]]; then
        if [[ -r "$file_path" ]]; then
            print_success "✓ $description : $file_path"
            passed_checks=$((passed_checks + 1))
        else
            print_error "✗ $description : $file_path (non lisible)"
            failed_checks=$((failed_checks + 1))
        fi
    else
        if [[ "$required" == "true" ]]; then
            print_error "✗ $description : $file_path (manquant)"
            failed_checks=$((failed_checks + 1))
        else
            print_warning "⚠ $description : $file_path (optionnel, manquant)"
            warning_checks=$((warning_checks + 1))
        fi
    fi
}

# Fonction pour vérifier un répertoire
check_directory() {
    local dir_path=$1
    local description=$2
    local required=${3:-true}
    
    total_checks=$((total_checks + 1))
    
    if [[ -d "$dir_path" ]]; then
        if [[ -r "$dir_path" ]]; then
            print_success "✓ $description : $dir_path"
            passed_checks=$((passed_checks + 1))
        else
            print_error "✗ $description : $dir_path (non accessible)"
            failed_checks=$((failed_checks + 1))
        fi
    else
        if [[ "$required" == "true" ]]; then
            print_error "✗ $description : $dir_path (manquant)"
            failed_checks=$((failed_checks + 1))
        else
            print_warning "⚠ $description : $dir_path (optionnel, manquant)"
            warning_checks=$((warning_checks + 1))
        fi
    fi
}

# Fonction pour vérifier qu'un script est exécutable
check_executable() {
    local file_path=$1
    local description=$2
    
    total_checks=$((total_checks + 1))
    
    if [[ -f "$file_path" && -x "$file_path" ]]; then
        print_success "✓ $description : $file_path (exécutable)"
        passed_checks=$((passed_checks + 1))
    elif [[ -f "$file_path" ]]; then
        print_warning "⚠ $description : $file_path (non exécutable)"
        warning_checks=$((warning_checks + 1))
    else
        print_error "✗ $description : $file_path (manquant)"
        failed_checks=$((failed_checks + 1))
    fi
}

# Fonction pour vérifier la syntaxe YAML
check_yaml_syntax() {
    local file_path=$1
    local description=$2
    
    total_checks=$((total_checks + 1))
    
    if [[ -f "$file_path" ]]; then
        if command -v python3 &> /dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$file_path'))" 2>/dev/null; then
                print_success "✓ $description : $file_path (syntaxe YAML valide)"
                passed_checks=$((passed_checks + 1))
            else
                print_error "✗ $description : $file_path (syntaxe YAML invalide)"
                failed_checks=$((failed_checks + 1))
            fi
        else
            print_warning "⚠ $description : $file_path (Python3 non disponible pour validation YAML)"
            warning_checks=$((warning_checks + 1))
        fi
    else
        print_error "✗ $description : $file_path (manquant)"
        failed_checks=$((failed_checks + 1))
    fi
}

# Fonction pour vérifier la syntaxe Ansible
check_ansible_syntax() {
    local file_path=$1
    local description=$2
    
    total_checks=$((total_checks + 1))
    
    if [[ -f "$file_path" ]]; then
        if command -v ansible-playbook &> /dev/null; then
            if ansible-playbook --syntax-check "$file_path" > /dev/null 2>&1; then
                print_success "✓ $description : $file_path (syntaxe Ansible valide)"
                passed_checks=$((passed_checks + 1))
            else
                print_error "✗ $description : $file_path (syntaxe Ansible invalide)"
                failed_checks=$((failed_checks + 1))
            fi
        else
            print_warning "⚠ $description : $file_path (Ansible non disponible pour validation)"
            warning_checks=$((warning_checks + 1))
        fi
    else
        print_error "✗ $description : $file_path (manquant)"
        failed_checks=$((failed_checks + 1))
    fi
}

# Fonction pour vérifier un environnement spécifique
check_environment() {
    local env_name=$1
    local env_dir="cloud/${env_name}"
    
    print_info "=== Vérification de l'environnement : $env_name ==="
    
    # Vérifier la structure des dossiers
    check_directory "${env_dir}" "Dossier principal $env_name"
    check_directory "${env_dir}/ansible" "Dossier ansible pour $env_name"
    check_directory "${env_dir}/scripts" "Dossier scripts pour $env_name"
    check_directory "${env_dir}/config" "Dossier config pour $env_name"
    
    # Vérifier les fichiers principaux
    check_file "${env_dir}/ansible/playbook.yml" "Playbook Ansible pour $env_name"
    check_file "${env_dir}/config/example_inventory.ini" "Exemple d'inventaire pour $env_name"
    check_executable "${env_dir}/scripts/provision.sh" "Script de provisionnement pour $env_name"
    
    # Vérifier la syntaxe des fichiers
    check_ansible_syntax "${env_dir}/ansible/playbook.yml" "Syntaxe du playbook $env_name"
    
    echo
}

# Fonction pour vérifier les outils système
check_system_tools() {
    print_info "=== Vérification des outils système ==="
    
    # Vérifier Ansible
    total_checks=$((total_checks + 1))
    if command -v ansible &> /dev/null; then
        print_success "✓ Ansible : $(ansible --version | head -n 1)"
        passed_checks=$((passed_checks + 1))
    else
        print_error "✗ Ansible : Non installé"
        failed_checks=$((failed_checks + 1))
    fi
    
    # Vérifier ansible-playbook
    total_checks=$((total_checks + 1))
    if command -v ansible-playbook &> /dev/null; then
        print_success "✓ ansible-playbook : Disponible"
        passed_checks=$((passed_checks + 1))
    else
        print_error "✗ ansible-playbook : Non disponible"
        failed_checks=$((failed_checks + 1))
    fi
    
    # Vérifier les collections Ansible
    total_checks=$((total_checks + 1))
    if ansible-galaxy collection list | grep -q "kubernetes.core"; then
        print_success "✓ Collection kubernetes.core : Installée"
        passed_checks=$((passed_checks + 1))
    else
        print_warning "⚠ Collection kubernetes.core : Non installée"
        warning_checks=$((warning_checks + 1))
    fi
    
    total_checks=$((total_checks + 1))
    if ansible-galaxy collection list | grep -q "community.general"; then
        print_success "✓ Collection community.general : Installée"
        passed_checks=$((passed_checks + 1))
    else
        print_warning "⚠ Collection community.general : Non installée"
        warning_checks=$((warning_checks + 1))
    fi
    
    echo
}

# Fonction pour afficher le résumé
show_summary() {
    echo
    print_info "=== RÉSUMÉ DE LA VALIDATION ==="
    echo
    echo "Total des vérifications : $total_checks"
    echo -e "✓ Vérifications réussies : ${GREEN}$passed_checks${NC}"
    echo -e "⚠ Avertissements : ${YELLOW}$warning_checks${NC}"
    echo -e "✗ Échecs : ${RED}$failed_checks${NC}"
    echo
    
    if [[ $failed_checks -eq 0 ]]; then
        if [[ $warning_checks -eq 0 ]]; then
            print_success "Toutes les vérifications sont passées avec succès !"
            print_info "La configuration est prête pour le provisionnement."
        else
            print_success "Configuration valide avec quelques avertissements."
            print_info "Vous pouvez procéder au provisionnement."
        fi
    else
        print_error "Des erreurs ont été détectées."
        print_info "Veuillez corriger les erreurs avant de procéder au provisionnement."
        exit 1
    fi
}

# Script principal
main() {
    print_info "=== Validation de la Configuration Cloud ==="
    echo
    
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -d "cloud" ]]; then
        print_error "Le dossier 'cloud' n'existe pas."
        print_info "Veuillez exécuter ce script depuis la racine du projet."
        exit 1
    fi
    
    # Vérifier les fichiers globaux
    print_info "=== Vérification des fichiers globaux ==="
    check_executable "cloud/configure.sh" "Script de configuration principal"
    check_executable "cloud/launch.sh" "Script de lancement principal"
    check_executable "cloud/test_connection.sh" "Script de test de connectivité"
    check_executable "cloud/cleanup.sh" "Script de nettoyage"
    check_executable "cloud/install_dependencies.sh" "Script d'installation des dépendances"
    check_file "cloud/README.md" "Documentation principale"
    check_file "cloud/config.yml" "Configuration globale"
    check_file "cloud/ansible.cfg" "Configuration Ansible"
    check_file "cloud/requirements.txt" "Fichier des dépendances"
    check_file "cloud/environment.example" "Exemple de variables d'environnement"
    
    # Vérifier la syntaxe des fichiers de configuration
    check_yaml_syntax "cloud/config.yml" "Syntaxe de la configuration globale"
    
    echo
    
    # Vérifier chaque environnement
    check_environment "ubuntu-dev"
    check_environment "rocky-dev"
    check_environment "dockgit"
    
    # Vérifier les outils système
    check_system_tools
    
    # Afficher le résumé
    show_summary
}

# Exécuter le script principal
main "$@"
