#!/bin/bash

# ==============================
# Couleurs
# ==============================
NORMAL="\033[0m"
HIGHLIGHT="\033[1;37;44m"    # blanc gras sur fond bleu
TEXT="\033[0;33m"            # or sombre
TITLE="\033[1;35m"           # violet clair subtil
BORDER="\033[0;35m"          # violet profond

# ==============================
# Menu principal
# ==============================
main_options=("Installer les outils" "Lancer un provisionnement" "Aide" "Supprimer un provisionnement" "Quitter")
selected_main=0  # sélection du menu principal

# ==============================
# FONCTIONS PLACEHOLDER
# ==============================

install_tools() {
    case "$1" in
        "Mac (brew)") 
            echo "[TODO] Installer outils pour Mac avec Brew"
            ;;
        "Mac (no brew)") 
            echo "[TODO] Installer outils pour Mac sans Brew"
            ;;
        "Linux Ubuntu") 
            echo "[TODO] Installer outils pour Linux Ubuntu"
            ;;
        "Linux CentOS") 
            echo "[TODO] Installer outils pour Linux CentOS"
            ;;
    esac
}

launch_provision() {
    case "$1" in
        "Local") 
            echo "[TODO] Lancer provisionnement local"
            ;;
        "Cloud") 
            echo "[TODO] Lancer provisionnement cloud"
            ;;
    esac
}

delete_provision() {
    case "$1" in
        "Local") 
            echo "[TODO] Supprimer provisionnement local"
            ;;
        "Cloud") 
            echo "[TODO] Supprimer provisionnement cloud"
            ;;
    esac
}

# ==============================
# Fonction pour afficher un menu
# ==============================
draw_menu() {
    local menu_title="$1"
    shift
    local menu_options=("$@")
    local selected=$selected_main  # utiliser la variable globale pour le menu principal
    clear
    width=60

    # Bord haut
    printf "${BORDER}"
    printf "╔"; printf '═%.0s' $(seq 1 $width); printf "╗\n"

    # Titre centré
    padding=$(( (width - ${#menu_title}) / 2 ))
    printf "║"; printf ' %.0s' $(seq 1 $padding)
    printf "${TITLE}%s${BORDER}" "$menu_title"
    printf ' %.0s' $(seq 1 $((width - padding - ${#menu_title})))
    printf "║\n"

    # Séparateur
    printf "╠"; printf '═%.0s' $(seq 1 $width); printf "╣\n"

    # Options
    for i in "${!menu_options[@]}"; do
        opt="${menu_options[$i]}"
        if [ $i -eq $selected ]; then
            printf "║ ${HIGHLIGHT}%-*s${NORMAL}${BORDER} ║\n" $((width-2)) "$opt"
        else
            printf "║ ${TEXT}%-*s${NORMAL}${BORDER} ║\n" $((width-2)) "$opt"
        fi
    done

    # Bord bas
    printf "╚"; printf '═%.0s' $(seq 1 $width); printf "╝\n${NORMAL}"
    echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour quitter"
}

# ==============================
# Fonction sous-menu générique
# ==============================
submenu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    while true; do
        clear
        width=60
        # Affichage du sous-menu
        printf "${BORDER}╔"; printf '═%.0s' $(seq 1 $width); printf "╗\n"
        padding=$(( (width - ${#title}) / 2 ))
        printf "║"; printf ' %.0s' $(seq 1 $padding)
        printf "${TITLE}%s${BORDER}" "$title"
        printf ' %.0s' $(seq 1 $((width - padding - ${#title}))); printf "║\n"
        printf "╠"; printf '═%.0s' $(seq 1 $width); printf "╣\n"
        for i in "${!options[@]}"; do
            opt="${options[$i]}"
            if [ $i -eq $selected ]; then
                printf "║ ${HIGHLIGHT}%-*s${NORMAL}${BORDER} ║\n" $((width-2)) "$opt"
            else
                printf "║ ${TEXT}%-*s${NORMAL}${BORDER} ║\n" $((width-2)) "$opt"
            fi
        done
        printf "╚"; printf '═%.0s' $(seq 1 $width); printf "╝\n${NORMAL}"
        echo -e "\n  ↑ ↓ pour naviguer, Entrée pour valider, q pour revenir"

        # Lecture des touches
        read -rsn1 key
        case "$key" in
            $'\x1b') read -rsn2 key2
                      case "$key2" in
                          "[A") ((selected--)); [ $selected -lt 0 ] && selected=$((${#options[@]}-1)) ;;
                          "[B") ((selected++)); [ $selected -ge ${#options[@]} ] && selected=0 ;;
                      esac ;;
            "") 
                if [ "${options[$selected]}" == "Retour" ]; then return; fi
                clear
                echo -e "${TITLE}>>> ${title} : ${options[$selected]}${NORMAL}\n"
                
                # Redirige vers la fonction adaptée
                case "$title" in
                    "Installer les outils") install_tools "${options[$selected]}" ;;
                    "Provisionnement") launch_provision "${options[$selected]}" ;;
                    "Supprimer un provisionnement") delete_provision "${options[$selected]}" ;;
                esac

                echo -e "\nAppuie sur une touche pour revenir..."
                read -rsn1 ;;
            q) return ;;
        esac
    done
}

# ==============================
# Boucle principale
# ==============================
while true; do
    draw_menu "HIFADHI ONE-CLICK-PROVISIONNING" "${main_options[@]}"
    read -rsn1 key
    case "$key" in
        $'\x1b') read -rsn2 key2
                  case "$key2" in
                      "[A") ((selected_main--)); [ $selected_main -lt 0 ] && selected_main=$((${#main_options[@]}-1)) ;;
                      "[B") ((selected_main++)); [ $selected_main -ge ${#main_options[@]} ] && selected_main=0 ;;
                  esac ;;
        "")
            case "${main_options[$selected_main]}" in
                "Installer les outils") submenu "Installer les outils" "Mac (brew)" "Mac (no brew)" "Linux Ubuntu" "Linux CentOS" "Retour" ;;
                "Lancer un provisionnement") submenu "Provisionnement" "Local" "Cloud" "Retour" ;;
                "Supprimer un provisionnement") submenu "Supprimer un provisionnement" "Local" "Cloud" "Retour" ;;
                "Aide")
                    clear
                    echo -e "${TITLE}=== AIDE ===${NORMAL}\n"
                    echo -e "${TEXT}1. Installer les outils: choisir ton OS pour installer les prerequisites"
                    echo -e "2. Lancer un provisionnement: local ou cloud selon ton besoin"
                    echo -e "3. Supprimer un provisionnement: retirer un environnement local ou cloud"
                    echo -e "4. Quitter: fermer le menu${NORMAL}\n"
                    echo -e "Appuie sur une touche pour revenir au menu..."
                    read -rsn1
                    ;;
                "Quitter") clear; echo -e "${TEXT}Sortie. À bientôt !${NORMAL}"; exit 0 ;;
            esac ;;
        q) clear; echo -e "${TEXT}Sortie. À bientôt !${NORMAL}"; exit 0 ;;
    esac
done
