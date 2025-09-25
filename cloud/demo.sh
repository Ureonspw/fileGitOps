#!/bin/bash

# Script de démonstration des fonctionnalités cloud
# Montre toutes les capacités du système de provisionnement

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    DÉMONSTRATION CLOUD                       ║"
    echo "║                   Système de Provisionnement                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
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

# Fonction pour attendre l'utilisateur
wait_for_user() {
    echo
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction pour afficher la structure des dossiers
show_structure() {
    print_section "Structure des Dossiers"
    
    echo "📁 Structure du projet cloud :"
    echo
    tree cloud/ 2>/dev/null || find cloud/ -type f -name "*.sh" -o -name "*.yml" -o -name "*.ini" -o -name "*.md" | sort
    echo
    print_info "Total des fichiers créés : $(find cloud/ -type f | wc -l)"
}

# Fonction pour montrer les environnements disponibles
show_environments() {
    print_section "Environnements Disponibles"
    
    echo "🎯 Environnements supportés :"
    echo
    echo -e "${GREEN}1. Ubuntu Dev${NC}"
    echo "   • K3s (Kubernetes léger)"
    echo "   • ArgoCD (GitOps)"
    echo "   • Coder (Environnements de développement)"
    echo "   • Podman (Conteneurs)"
    echo "   • Scripts : provision_dev.sh → playbook.yml"
    echo
    
    echo -e "${GREEN}2. Rocky Dev${NC}"
    echo "   • K3s (Kubernetes léger)"
    echo "   • ArgoCD (GitOps)"
    echo "   • Coder (Environnements de développement)"
    echo "   • Podman (Conteneurs)"
    echo "   • Scripts : provision_dev.sh → playbook.yml"
    echo
    
    echo -e "${GREEN}3. Dockgit${NC}"
    echo "   • Forgejo (Git self-hosted)"
    echo "   • Harbor (Registry de conteneurs)"
    echo "   • Podman (Conteneurs)"
    echo "   • Scripts : provision_dev.sh → playbook.yml"
    echo
}

# Fonction pour montrer les scripts disponibles
show_scripts() {
    print_section "Scripts Disponibles"
    
    echo "🔧 Scripts principaux :"
    echo
    echo -e "${GREEN}• launch.sh${NC} - Point d'entrée principal avec menu interactif"
    echo -e "${GREEN}• configure.sh${NC} - Configuration et provisionnement"
    echo -e "${GREEN}• test_connection.sh${NC} - Test de connectivité SSH"
    echo -e "${GREEN}• validate.sh${NC} - Validation de la configuration"
    echo -e "${GREEN}• cleanup.sh${NC} - Nettoyage des fichiers temporaires"
    echo -e "${GREEN}• install_dependencies.sh${NC} - Installation des dépendances"
    echo
    echo "📋 Scripts spécifiques par environnement :"
    echo
    echo -e "${GREEN}• ubuntu-dev/scripts/provision.sh${NC}"
    echo -e "${GREEN}• rocky-dev/scripts/provision.sh${NC}"
    echo -e "${GREEN}• dockgit/scripts/provision.sh${NC}"
    echo
}

# Fonction pour montrer les méthodes d'authentification
show_authentication() {
    print_section "Méthodes d'Authentification"
    
    echo "🔐 Authentification supportée :"
    echo
    echo -e "${GREEN}1. Mot de passe SSH/sudo${NC}"
    echo "   • Saisie sécurisée du mot de passe"
    echo "   • Utilisation d'sshpass pour l'automatisation"
    echo "   • Support des privilèges sudo"
    echo
    
    echo -e "${GREEN}2. Clé SSH privée${NC}"
    echo "   • Validation du fichier de clé"
    echo "   • Vérification des permissions"
    echo "   • Support des clés RSA, ECDSA, Ed25519"
    echo
    
    echo "🛡️ Sécurité :"
    echo "   • Désactivation de la vérification des clés d'hôte"
    echo "   • Timeout configurable pour les connexions"
    echo "   • Gestion des erreurs de connexion"
    echo
}

# Fonction pour montrer les fonctionnalités Ansible
show_ansible_features() {
    print_section "Fonctionnalités Ansible"
    
    echo "⚙️ Configuration Ansible :"
    echo
    echo -e "${GREEN}• ansible.cfg${NC} - Configuration optimisée"
    echo "  - 10 processus parallèles"
    echo "  - Pipelining activé"
    echo "  - Timeout de 30 secondes"
    echo "  - Gestion des erreurs améliorée"
    echo
    
    echo -e "${GREEN}• Collections requises${NC} :"
    echo "  - kubernetes.core (pour K3s/ArgoCD)"
    echo "  - community.general (pour les tâches générales)"
    echo
    
    echo -e "${GREEN}• Playbooks optimisés${NC} :"
    echo "  - Gestion des erreurs robuste"
    echo "  - Vérifications de santé"
    echo "  - Configuration automatique"
    echo "  - Logs détaillés"
    echo
}

# Fonction pour montrer les exemples d'utilisation
show_usage_examples() {
    print_section "Exemples d'Utilisation"
    
    echo "🚀 Commandes de base :"
    echo
    echo -e "${GREEN}# Installation des dépendances${NC}"
    echo "./install_dependencies.sh"
    echo
    
    echo -e "${GREEN}# Validation de la configuration${NC}"
    echo "./validate.sh"
    echo
    
    echo -e "${GREEN}# Lancement interactif${NC}"
    echo "./launch.sh"
    echo
    
    echo -e "${GREEN}# Provisionnement direct${NC}"
    echo "./configure.sh ubuntu-dev"
    echo "./configure.sh rocky-dev"
    echo "./configure.sh dockgit"
    echo
    
    echo -e "${GREEN}# Test de connectivité${NC}"
    echo "./test_connection.sh ubuntu-dev"
    echo
    
    echo -e "${GREEN}# Nettoyage${NC}"
    echo "./cleanup.sh"
    echo
}

# Fonction pour montrer les fichiers de configuration
show_configuration() {
    print_section "Fichiers de Configuration"
    
    echo "📝 Fichiers de configuration disponibles :"
    echo
    echo -e "${GREEN}• config.yml${NC} - Configuration globale"
    echo "  - Versions des logiciels"
    echo "  - Ports par défaut"
    echo "  - Mots de passe"
    echo "  - Configuration SSL"
    echo
    
    echo -e "${GREEN}• ansible.cfg${NC} - Configuration Ansible"
    echo "  - Optimisations de performance"
    echo "  - Paramètres SSH"
    echo "  - Gestion des erreurs"
    echo
    
    echo -e "${GREEN}• environment.example${NC} - Variables d'environnement"
    echo "  - Configuration SSH"
    echo "  - Ports personnalisables"
    echo "  - Mots de passe sécurisés"
    echo
    
    echo -e "${GREEN}• requirements.txt${NC} - Dépendances"
    echo "  - Ansible et collections"
    echo "  - Outils optionnels"
    echo
}

# Fonction pour montrer les fonctionnalités avancées
show_advanced_features() {
    print_section "Fonctionnalités Avancées"
    
    echo "🔧 Fonctionnalités avancées :"
    echo
    echo -e "${GREEN}• Validation automatique${NC}"
    echo "  - Vérification de la syntaxe YAML"
    echo "  - Validation des playbooks Ansible"
    echo "  - Contrôle des permissions"
    echo
    
    echo -e "${GREEN}• Gestion des erreurs${NC}"
    echo "  - Retry automatique"
    echo "  - Logs détaillés"
    echo "  - Nettoyage en cas d'échec"
    echo
    
    echo -e "${GREEN}• Personnalisation${NC}"
    echo "  - Configuration modulaire"
    echo "  - Variables d'environnement"
    echo "  - Templates personnalisables"
    echo
    
    echo -e "${GREEN}• Monitoring${NC}"
    echo "  - Tests de connectivité"
    echo "  - Vérification des services"
    echo "  - Logs de provisionnement"
    echo
}

# Fonction pour montrer les prochaines étapes
show_next_steps() {
    print_section "Prochaines Étapes"
    
    echo "🎯 Pour commencer :"
    echo
    echo "1. ${GREEN}Installer les dépendances${NC}"
    echo "   ./install_dependencies.sh"
    echo
    
    echo "2. ${GREEN}Valider la configuration${NC}"
    echo "   ./validate.sh"
    echo
    
    echo "3. ${GREEN}Préparer votre serveur${NC}"
    echo "   - Accès SSH configuré"
    echo "   - Privilèges sudo activés"
    echo "   - Ports ouverts (22, 80, 443, 3000, 3001, 8090)"
    echo
    
    echo "4. ${GREEN}Lancer le provisionnement${NC}"
    echo "   ./launch.sh"
    echo
    
    echo "📚 Documentation complète :"
    echo "   - README.md - Guide complet"
    echo "   - QUICKSTART.md - Démarrage rapide"
    echo "   - requirements.txt - Dépendances"
    echo
}

# Script principal
main() {
    print_banner
    
    print_info "Bienvenue dans la démonstration du système de provisionnement cloud !"
    print_info "Ce script vous montre toutes les fonctionnalités disponibles."
    echo
    
    show_structure
    wait_for_user
    
    show_environments
    wait_for_user
    
    show_scripts
    wait_for_user
    
    show_authentication
    wait_for_user
    
    show_ansible_features
    wait_for_user
    
    show_usage_examples
    wait_for_user
    
    show_configuration
    wait_for_user
    
    show_advanced_features
    wait_for_user
    
    show_next_steps
    
    print_success "Démonstration terminée !"
    print_info "Vous êtes maintenant prêt à utiliser le système de provisionnement cloud."
    echo
    print_info "Pour commencer, exécutez : ./install_dependencies.sh"
}

# Exécuter le script principal
main "$@"
