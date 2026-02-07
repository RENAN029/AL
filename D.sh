#!/bin/bash
set -e

[ ! -f /etc/arch-release ] && { echo "Apenas Arch Linux é suportado."; exit 1; }

STATE_DIR="$HOME/.config/arch_scripts"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gdm3 gnome-initial-setup gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"

    if [ -f "$state_file" ] || pacman -Q gnome-shell &>/dev/null; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            pacman -Qq gnome-shell &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gnome || true
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            sudo pacman -S --noconfirm $pkg_gnome
            sudo systemctl enable gdm
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="sddm plasma-desktop konsole dolphin kdeconnect partitionmanager ark"

    if [ -f "$state_file" ] || pacman -Q plasma-meta &>/dev/null; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            pacman -Qq plasma-meta &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_plasma || true
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            sudo pacman -S --noconfirm $pkg_plasma
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

main_menu() {
    while true; do
        clear
        echo "=== Arch Scripts ==="
        echo "1) Admin"
        echo "2) Devs"
        echo "3) Drivers"
        echo "4) Educação"
        echo "5) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) admin_menu ;;
            2) devs_menu ;;
            3) drivers_menu ;;
            4) educacao_menu ;;
            5) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
