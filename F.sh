Quero que vc altere e adapte esse script para funcionar no fedora atomico. Os ambientes desktop devem ser usados os rebuilds por nao ter como instalar o ambiente desktop em si em um fedora atomico, entao 
ao selecionar um de ele deve rebuildar para aquele de selecionado, a nao ser que ja esteja no de selecionado. Por conta disso, vc tambem deve remover manualmente os pacotes que nao sao necessarios pelo usuario 
para um ambiente mais limpo, (ex: firefox, gnome-photos, kate). Os unicos pacotes que devem ficar sao os apresentados no script para arch.

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

de_cosmic_installer() {
    local state_file="$STATE_DIR/de_cosmic"
    local pkg_cosmic="cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers"

    if [ -f "$state_file" ] || pacman -Q cosmic-session &>/dev/null; then
        if confirm "Cosmic detectado. Desinstalar?"; then
            echo "Desinstalando Cosmic..."
            sudo systemctl disable cosmic-greeter 2>/dev/null || true
            pacman -Qq cosmic-session &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cosmic || true
            cleanup_files "$state_file"
            echo "Cosmic desinstalado."
        fi
    else
        if confirm "Instalar Cosmic?"; then
            echo "Instalando Cosmic..."
            sudo pacman -S --noconfirm $pkg_cosmic
            sudo systemctl enable cosmic-greeter
            touch "$state_file"
            echo "Cosmic instalado. Reinicie para aplicar."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-initial-setup gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"

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
    local pkg_plasma="plasma-meta konsole dolphin kdeconnect partitionmanager ark"

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
        echo "1) "
        echo "2) "
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) ;;
            2) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
