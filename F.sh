#!/bin/bash
set -e

[ ! -f /etc/fedora-release ] && [ ! -f /etc/ostree ] && { echo "Apenas Fedora Atomic é suportado."; exit 1; }

STATE_DIR="$HOME/.config/fedora_atomic_scripts"
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

cachyconfs_installer() {
    local state_file="$STATE_DIR/cachyconfs"

    if [ -f "$state_file" ] || [ -f "/usr/lib/sysctl.d/99-cachyos-settings.conf" ]; then
        if confirm "CachyOS Configs detectado. Desinstalar?"; then
            sudo rm -f /usr/lib/sysctl.d/99-cachyos-settings.conf
            sudo sysctl --system
            cleanup_files "$state_file"
        fi
    else
        if confirm "Instalar CachyOS Configs?"; then
            sudo mkdir -p /usr/lib/sysctl.d
            curl -s https://raw.githubusercontent.com/CachyOS/CachyOS-Settings/main/sysctl/99-cachyos-settings.conf | sudo tee /usr/lib/sysctl.d/99-cachyos-settings.conf > /dev/null
            sudo sysctl --system
            touch "$state_file"
        fi
    fi
}

de_cosmic_installer() {
    local state_file="$STATE_DIR/de_cosmic"

    if [ -f "$state_file" ] || rpm-ostree status 2>/dev/null | grep -q "cosmic-atomic"; then
        if confirm "COSMIC detectado. Rebase para Fedora Atomic padrão?"; then
            local fedora_version=$(rpm -E %fedora)
            local arch=$(uname -m)
            sudo rpm-ostree rebase fedora:fedora/${fedora_version}/${arch}/silverblue
            cleanup_files "$state_file"
            echo "Rebase para imagem padrão concluído. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar COSMIC (rebase para fedora cosmic-atomic)?"; then
            local fedora_version=$(rpm -E %fedora)
            local arch=$(uname -m)
            sudo rpm-ostree rebase fedora:fedora/${fedora_version}/${arch}/cosmic-atomic
            touch "$state_file"
            echo "Rebase para COSMIC concluído. Reinicie para aplicar."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"

    if [ -f "$state_file" ] || rpm-ostree status 2>/dev/null | grep -q "silverblue"; then
        if confirm "GNOME detectado. Desinstalar?"; then
            echo "GNOME é o ambiente padrão. Remova manualmente ou faça rebase para outra imagem."
        fi
    else
        if confirm "Instalar GNOME (rebase para fedora silverblue)?"; then
            local fedora_version=$(rpm -E %fedora)
            local arch=$(uname -m)
            sudo rpm-ostree rebase fedora:fedora/${fedora_version}/${arch}/silverblue
            touch "$state_file"
            echo "Rebase para GNOME concluído. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"

    if [ -f "$state_file" ] || rpm-ostree status 2>/dev/null | grep -q "kinoite"; then
        if confirm "KDE Plasma detectado. Rebase para Fedora Atomic padrão?"; then
            local fedora_version=$(rpm -E %fedora)
            local arch=$(uname -m)
            sudo rpm-ostree rebase fedora:fedora/${fedora_version}/${arch}/silverblue
            cleanup_files "$state_file"
            echo "Rebase para imagem padrão concluído. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar KDE Plasma (rebase para fedora kinoite)?"; then
            local fedora_version=$(rpm -E %fedora)
            local arch=$(uname -m)
            sudo rpm-ostree rebase fedora:fedora/${fedora_version}/${arch}/kinoite
            touch "$state_file"
            echo "Rebase para Kinoite concluído. Reinicie para aplicar."
        fi
    fi
}

faugus_launcher_installer() {
    local state_file="$STATE_DIR/faugus_launcher"
    local pkg_faugus="io.github.Faugus.faugus-launcher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.Faugus.faugus-launcher 2>/dev/null; then
        if confirm "Faugus Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Faugus Launcher..."
            flatpak uninstall --user -y $pkg_faugus 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Faugus Launcher desinstalado."
        fi
    else
        if confirm "Instalar Faugus Launcher?"; then
            echo "Instalando Faugus Launcher..."
            flatpak install --user --noninteractive flathub $pkg_faugus
            flatpak override --user io.github.Faugus.faugus-launcher --filesystem=~/.var/app/com.valvesoftware.Steam/.steam/steam/userdata/
            flatpak override --user com.valvesoftware.Steam --talk-name=org.freedesktop.Flatpak
            flatpak override --user com.valvesoftware.Steam --filesystem=~/.var/app/io.github.Faugus.faugus-launcher/config/faugus-launcher/
            touch "$state_file"
            echo "Faugus Launcher instalado."
        fi
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"

    if [ -f "$flatpak_state" ] || command -v flatpak &>/dev/null; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Flatpak é parte do sistema. Remova manualmente se necessário."
        fi
    fi

    if [ -f "$flathub_state" ] || flatpak remote-list --user 2>/dev/null | grep -q flathub; then
        if confirm "Flathub detectado. Remover?"; then
            echo "Removendo Flathub..."
            flatpak remote-delete --user flathub 2>/dev/null || true
            cleanup_files "$flathub_state"
            echo "Flathub removido."
        fi
    elif confirm "Adicionar repositório Flathub?"; then
        echo "Adicionando Flathub..."
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        touch "$flathub_state"
        echo "Flathub adicionado."
    fi
}

homebrew_installer() {
    local state_file="$STATE_DIR/homebrew"

    if [ -f "$state_file" ] || command -v brew &>/dev/null; then
        if confirm "Brew detectado. Desinstalar?"; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
            sed -i '/brew shellenv/d' ~/.bashrc
            [ -f ~/.zshrc ] && sed -i '/brew shellenv/d' ~/.zshrc
            [ -f ~/.config/fish/config.fish ] && sed -i '/fish_add_path.*linuxbrew/d' ~/.config/fish/config.fish
            cleanup_files "$state_file"
            rm -rf /home/$USER/.linuxbrew /home/$USER/.local/share/Homebrew /home/$USER/.cache/Homebrew
        fi
    else
        if confirm "Instalar Brew?"; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            [ -f /home/linuxbrew/.linuxbrew/bin/brew ] && BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew" || BREW_PATH="$HOME/.linuxbrew/bin/brew"
            echo "eval \"\$($BREW_PATH shellenv)\"" >> ~/.bashrc
            [ -f ~/.zshrc ] && echo "eval \"\$($BREW_PATH shellenv)\"" >> ~/.zshrc
            [ -f ~/.config/fish/config.fish ] && echo "fish_add_path $(dirname $BREW_PATH)" >> ~/.config/fish/config.fish
            eval "$($BREW_PATH shellenv)"
            touch "$state_file"
        fi
    fi
}

nvidia_proprietary_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"

    if [ -f "$state_file" ] || rpm -q akmod-nvidia &>/dev/null; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            sudo rpm-ostree uninstall akmod-nvidia xorg-x11-drv-nvidia-cuda 2>/dev/null || true
            sudo rm -f /etc/modprobe.d/blacklist-nouveau-nova.conf
            sudo rpm-ostree kargs --delete=rd.driver.blacklist=nova_core --delete=modprobe.blacklist=nova_core --delete=rd.driver.blacklist=nouveau --delete=modprobe.blacklist=nouveau --delete=nvidia-drm.modeset=1
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Nvidia Proprietário?"; then
            echo "Instalando Nvidia Proprietário..."
            
            if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release &>/dev/null; then
                rpmfusion_installer
            fi
            
            if sudo mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
                sudo rpm-ostree install akmods rpmdevtools
                sudo kmodgenca
                sudo mokutil --import /etc/pki/akmods/certs/public_key.der
                cd $HOME
                git clone https://github.com/CheariX/silverblue-akmods-keys
                cd silverblue-akmods-keys
                sudo bash setup.sh
                sudo rpm-ostree install -yA akmods-keys-*.noarch.rpm
                cd ..
                rm -rf silverblue-akmods-keys
            fi
            
            sudo rpm-ostree install akmod-nvidia xorg-x11-drv-nvidia-cuda
            sudo tee /etc/modprobe.d/blacklist-nouveau-nova.conf <<EOF
blacklist nouveau
blacklist nova_core
EOF
            sudo rpm-ostree kargs --append=rd.driver.blacklist=nova_core --append=modprobe.blacklist=nova_core --append=rd.driver.blacklist=nouveau --append=modprobe.blacklist=nouveau --append=nvidia-drm.modeset=1
            touch "$state_file"
            echo "Nvidia Proprietário instalado. Reinicie para aplicar."
        fi
    fi
}

ostree_autoupd_installer() {
    local state_file="$STATE_DIR/ostree_autoupd"
    local AUTOPOLICY="stage"

    if [ -f "$state_file" ] || systemctl is-enabled rpm-ostreed-automatic.timer &>/dev/null; then
        if confirm "Auto-updates detectados. Desativar?"; then
            sudo systemctl disable rpm-ostreed-automatic.timer --now
            if [ -f /etc/rpm-ostreed.conf.bak ]; then
                sudo mv /etc/rpm-ostreed.conf.bak /etc/rpm-ostreed.conf
            else
                sudo sed -i 's/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=none/' /etc/rpm-ostreed.conf
            fi
            sudo systemctl restart rpm-ostreed
            cleanup_files "$state_file"
            echo "Auto-updates desativados."
        fi
    else
        if confirm "Ativar auto-updates?"; then
            sudo cp /etc/rpm-ostreed.conf /etc/rpm-ostreed.conf.bak
            if grep -q "^AutomaticUpdatePolicy=" /etc/rpm-ostreed.conf; then
                sudo sed -i "s/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=${AUTOPOLICY}/" /etc/rpm-ostreed.conf
            else
                sudo awk -v policy="$AUTOPOLICY" '
                /^\[Daemon\]/ {
                    print
                    print "AutomaticUpdatePolicy=" policy
                    next
                }
                { print }
                ' /etc/rpm-ostreed.conf | sudo tee /etc/rpm-ostreed.conf > /dev/null
            fi
            sudo systemctl enable rpm-ostreed-automatic.timer --now
            sudo systemctl restart rpm-ostreed
            touch "$state_file"
            echo "Auto-updates ativados com política: $AUTOPOLICY"
        fi
    fi
}

rpmfusion_installer() {
    local state_file="$STATE_DIR/rpmfusion"

    if [ -f "$state_file" ] || rpm -q rpmfusion-free-release &>/dev/null; then
        if confirm "RPM Fusion detectado. Remover?"; then
            sudo rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release 2>/dev/null || true
            cleanup_files "$state_file"
            echo "RPM Fusion removido."
        fi
    else
        if confirm "Instalar RPM Fusion?"; then
            local fedora_version=$(rpm -E %fedora)
            sudo rpm-ostree install \
                https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm \
                https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm
            touch "$state_file"
            echo "RPM Fusion instalado."
        fi
    fi
}

terra_installer() {
    local state_file="$STATE_DIR/terra"

    if [ -f "$state_file" ] || [ -f /etc/yum.repos.d/terra.repo ]; then
        if confirm "Terra repository detectado. Remover?"; then
            sudo rm -f /etc/yum.repos.d/terra.repo
            sudo rpm-ostree uninstall terra-release 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Terra repository removido."
        fi
    else
        if confirm "Instalar Terra repository?"; then
            curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo | sudo tee /etc/yum.repos.d/terra.repo
            sudo rpm-ostree install -y terra-release
            touch "$state_file"
            echo "Terra repository instalado."
        fi
    fi
}

xpadneo_installer() {
    local state_file="$STATE_DIR/xpadneo"

    if [ -f "$state_file" ] || rpm -q xpadneo &>/dev/null; then
        if confirm "Xpadneo detectado. Desinstalar?"; then
            echo "Desinstalando Xpadneo..."
            sudo rpm-ostree uninstall xpadneo 2>/dev/null || true
            sudo rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:shdwchn10:xpadneo.repo
            cleanup_files "$state_file"
            echo "Xpadneo desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Xpadneo?"; then
            echo "Instalando Xpadneo..."
            local fedora_version=$(rpm -E %fedora)
            sudo curl -L -o /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:shdwchn10:xpadneo.repo \
                https://copr.fedorainfracloud.org/coprs/shdwchn10/xpadneo/repo/fedora-${fedora_version}/shdwchn10-xpadneo-fedora-${fedora_version}.repo
            sudo rpm-ostree install xpadneo
            touch "$state_file"
            echo "Xpadneo instalado. Reinicie para aplicar."
        fi
    fi
}

zen_browser_installer() {
    local state_file="$STATE_DIR/zen_browser"
    local pkg_zen="app.zen_browser.zen"

    if [ -f "$state_file" ] || flatpak list --app | grep -q app.zen_browser.zen 2>/dev/null; then
        if confirm "Zen Browser detectado. Desinstalar?"; then
            echo "Desinstalando Zen Browser..."
            flatpak uninstall --user -y $pkg_zen 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Zen Browser desinstalado."
        fi
    else
        if confirm "Instalar Zen Browser?"; then
            echo "Instalando Zen Browser..."
            flatpak install --or-update --user --noninteractive flathub $pkg_zen
            touch "$state_file"
            echo "Zen Browser instalado."
        fi
    fi
}

main_menu() {
    while true; do
        clear
        echo "=== Fedora Atomic Scripts ==="
        echo "1) RPM Fusion"
        echo "2) Terra Repository"
        echo "3) Ostree Auto-updates"
        echo "4) CachyOS Configs"
        echo "5) Xpadneo (Xbox Controller) - COPR"
        echo "6) Faugus Launcher"
        echo "7) Zen Browser"
        echo "8) Flatpak/Flathub"
        echo "9) Homebrew"
        echo "10) Nvidia Proprietary"
        echo "11) COSMIC Desktop (Fedora Cosmic-Atomic)"
        echo "12) GNOME Desktop (Silverblue)"
        echo "13) KDE Plasma Desktop (Kinoite)"
        echo "0) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) rpmfusion_installer ;;
            2) terra_installer ;;
            3) ostree_autoupd_installer ;;
            4) cachyconfs_installer ;;
            5) xpadneo_installer ;;
            6) faugus_launcher_installer ;;
            7) zen_browser_installer ;;
            8) flatpak_flathub_installer ;;
            9) homebrew_installer ;;
            10) nvidia_proprietary_installer ;;
            11) de_cosmic_installer ;;
            12) de_gnome_installer ;;
            13) de_plasma_installer ;;
            0) exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
