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

cleanup_de_packages() {
    local de_type="$1"
    
    case $de_type in
        gnome)
            echo "Removendo pacotes desnecessários do GNOME..."
            sudo rpm-ostree override remove firefox gnome-photos gnome-contacts gnome-maps gnome-weather gnome-calendar totem rhythmbox || true
            ;;
        plasma)
            echo "Removendo pacotes desnecessários do KDE Plasma..."
            sudo rpm-ostree override remove firefox kate konversation kwrite dragon elisa-player juk k3b krdc krfb ktorrent || true
            ;;
        cosmic)
            echo "Removendo pacotes desnecessários do COSMIC..."
            sudo rpm-ostree override remove firefox || true
            ;;
    esac
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
    
    if [ -f "$state_file" ] || rpm-ostree status | grep -q "cosmic" 2>/dev/null; then
        if confirm "COSMIC Desktop detectado. Desinstalar?"; then
            echo "Revertendo para imagem anterior..."
            sudo rpm-ostree rollback
            cleanup_files "$state_file"
            echo "COSMIC removido. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar COSMIC Desktop? (rebase para ublue/cosmic)"; then
            echo "Instalando COSMIC Desktop..."
            sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/cosmic:latest
            cleanup_de_packages "cosmic"
            touch "$state_file"
            echo "COSMIC instalado. Reinicie para aplicar."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local current_image=$(rpm-ostree status --json | grep -o '"deploy-pending":\?"checksum": "[^"]*"')
    
    if [ -f "$state_file" ] || echo "$current_image" | grep -q "gnome" 2>/dev/null; then
        if confirm "GNOME Desktop detectado. Desinstalar?"; then
            echo "Revertendo para imagem anterior..."
            sudo rpm-ostree rollback
            cleanup_files "$state_file"
            echo "GNOME removido. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar GNOME Desktop? (rebase para ublue/gnome)"; then
            echo "Instalando GNOME Desktop..."
            sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/gnome:latest
            cleanup_de_packages "gnome"
            touch "$state_file"
            echo "GNOME instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local current_image=$(rpm-ostree status --json | grep -o '"deploy-pending":\?"checksum": "[^"]*"')
    
    if [ -f "$state_file" ] || echo "$current_image" | grep -q "kinoite" 2>/dev/null || echo "$current_image" | grep -q "plasma" 2>/dev/null; then
        if confirm "Plasma Desktop detectado. Desinstalar?"; then
            echo "Revertendo para imagem anterior..."
            sudo rpm-ostree rollback
            cleanup_files "$state_file"
            echo "Plasma removido. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Plasma Desktop? (rebase para ublue/kinoite)"; then
            echo "Instalando Plasma Desktop..."
            sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/kinoite:latest
            cleanup_de_packages "plasma"
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
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
            sudo flatpak override io.github.Faugus.faugus-launcher --filesystem=~/.var/app/com.valvesoftware.Steam/.steam/steam/userdata/
            sudo flatpak override com.valvesoftware.Steam --talk-name=org.freedesktop.Flatpak
            sudo flatpak override com.valvesoftware.Steam --filesystem=~/.var/app/io.github.Faugus.faugus-launcher/config/faugus-launcher/
            touch "$state_file"
            echo "Faugus Launcher instalado."
        fi
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"

    if ! command -v flatpak &>/dev/null; then
        if confirm "Instalar Flatpak?"; then
            echo "Instalando Flatpak..."
            sudo rpm-ostree install flatpak
            touch "$flatpak_state"
            echo "Flatpak instalado. Reinicie para aplicar."
        fi
    else
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            sudo rpm-ostree uninstall flatpak
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado. Reinicie para aplicar."
        fi
    fi

    if command -v flatpak &>/dev/null; then
        if [ -f "$flathub_state" ] || flatpak remote-list | grep -q flathub 2>/dev/null; then
            if confirm "Flathub detectado. Remover?"; then
                echo "Removendo Flathub..."
                flatpak remote-delete flathub 2>/dev/null || true
                cleanup_files "$flathub_state"
                echo "Flathub removido."
            fi
        elif confirm "Adicionar repositório Flathub?"; then
            echo "Adicionando Flathub..."
            flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            touch "$flathub_state"
            echo "Flathub adicionado."
        fi
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

    if [ -f "$state_file" ] || rpm-ostree status | grep -q "akmod-nvidia" 2>/dev/null; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            sudo rpm-ostree uninstall akmod-nvidia xorg-x11-drv-nvidia-cuda || true
            sudo sed -i '/nvidia-drm.modeset=1/d' /etc/default/grub 2>/dev/null || true
            sudo sed -i '/rd.driver.blacklist=nouveau/d' /etc/default/grub 2>/dev/null || true
            sudo sed -i '/modprobe.blacklist=nouveau/d' /etc/default/grub 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Nvidia Proprietário?"; then
            echo "Instalando Nvidia Proprietário..."
            
            if sudo mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
                echo "SecureBoot detectado. Configurando chaves..."
                sudo rpm-ostree install kmodgenca akmods
                sudo kmodgenca
                sudo mokutil --import /etc/pki/akmods/certs/public_key.der
            fi
            
            sudo rpm-ostree install akmod-nvidia xorg-x11-drv-nvidia-cuda
            sudo rpm-ostree kargs \
                --append=rd.driver.blacklist=nouveau \
                --append=modprobe.blacklist=nouveau \
                --append=nvidia-drm.modeset=1
            
            touch "$state_file"
            echo "Nvidia Proprietário instalado. Reinicie para aplicar."
        fi
    fi
}

ostree_autoupd_installer() {
    local state_file="$STATE_DIR/ostree_autoupd"

    if [ -f "$state_file" ] || grep -q "^AutomaticUpdatePolicy=" /etc/rpm-ostreed.conf 2>/dev/null; then
        if confirm "Atualizações automáticas detectadas. Desativar?"; then
            sudo cp /etc/rpm-ostreed.conf /etc/rpm-ostreed.conf.bak
            sudo sed -i 's/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=none/' /etc/rpm-ostreed.conf
            sudo systemctl disable rpm-ostreed-automatic.timer --now
            cleanup_files "$state_file"
            echo "Atualizações automáticas desativadas."
        fi
    else
        if confirm "Ativar atualizações automáticas?"; then
            sudo cp /etc/rpm-ostreed.conf /etc/rpm-ostreed.conf.bak
            if grep -q "^AutomaticUpdatePolicy=" /etc/rpm-ostreed.conf; then
                sudo sed -i 's/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf
            else
                sudo awk '/^\[Daemon\]/ {print; print "AutomaticUpdatePolicy=stage"; next} {print}' /etc/rpm-ostreed.conf | sudo tee /etc/rpm-ostreed.conf > /dev/null
            fi
            sudo systemctl enable rpm-ostreed-automatic.timer --now
            touch "$state_file"
            echo "Atualizações automáticas ativadas."
        fi
    fi
}

rpm_fusion_installer() {
    local state_file="$STATE_DIR/rpm_fusion"
    local fedora_version=$(rpm -E %fedora)

    if [ -f "$state_file" ] || rpm -q rpmfusion-free-release &>/dev/null 2>/dev/null; then
        if confirm "RPM Fusion detectado. Desinstalar?"; then
            sudo rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release || true
            sudo rpm -e rpmfusion-free-release rpmfusion-nonfree-release 2>/dev/null || true
            cleanup_files "$state_file"
            echo "RPM Fusion desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar RPM Fusion?"; then
            echo "Instalando RPM Fusion..."
            sudo rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm
            touch "$state_file"
            echo "RPM Fusion instalado. Reinicie para aplicar."
        fi
    fi
}

terra_installer() {
    local state_file="$STATE_DIR/terra"

    if [ -f "$state_file" ] || [ -f /etc/yum.repos.d/terra.repo ]; then
        if confirm "Terra repository detectado. Desinstalar?"; then
            sudo rpm-ostree uninstall terra-release || true
            sudo rm -f /etc/yum.repos.d/terra.repo
            cleanup_files "$state_file"
            echo "Terra repository desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Terra repository?"; then
            echo "Instalando Terra repository..."
            curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo | sudo tee /etc/yum.repos.d/terra.repo
            sudo rpm-ostree install terra-release
            touch "$state_file"
            echo "Terra repository instalado. Reinicie para aplicar."
        fi
    fi
}

xpadneo_installer() {
    local state_file="$STATE_DIR/xpadneo"

    if [ -f "$state_file" ] || [ -d "/usr/src/xpadneo"* ] 2>/dev/null; then
        if confirm "Xpadneo detectado. Desinstalar?"; then
            echo "Desinstalando Xpadneo..."
            if [ -d "/usr/src/xpadneo"* ]; then
                cd /tmp
                git clone https://github.com/atar-axis/xpadneo.git || true
                cd xpadneo
                sudo ./uninstall.sh || true
                cd ..
                rm -rf xpadneo
            fi
            sudo rpm-ostree uninstall dkms bluez bluez-tools kernel-devel kernel-headers || true
            cleanup_files "$state_file"
            echo "Xpadneo desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Xpadneo?"; then
            echo "Instalando Xpadneo..."
            sudo rpm-ostree install dkms make bluez bluez-tools kernel-devel kernel-headers
            
            cd $HOME
            git clone https://github.com/atar-axis/xpadneo.git
            cd xpadneo
            sudo ./install.sh
            cd ..
            rm -rf xpadneo
            
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
        echo "1)  RPM Fusion"
        echo "2)  Terra Repository"
        echo "3)  Nvidia Proprietary"
        echo "4)  Xpadneo"
        echo "5)  Faugus Launcher"
        echo "6)  Zen Browser"
        echo "7)  Flatpak/Flathub"
        echo "8)  Homebrew"
        echo "9)  GNOME Desktop (rebase)"
        echo "10) KDE Plasma Desktop (rebase)"
        echo "11) COSMIC Desktop (rebase)"
        echo "12) CachyOS Configs"
        echo "13) OSTree Auto Updates"
        echo "0)  Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) rpm_fusion_installer ;;
            2) terra_installer ;;
            3) nvidia_proprietary_installer ;;
            4) xpadneo_installer ;;
            5) faugus_launcher_installer ;;
            6) zen_browser_installer ;;
            7) flatpak_flathub_installer ;;
            8) homebrew_installer ;;
            9) de_gnome_installer ;;
            10) de_plasma_installer ;;
            11) de_cosmic_installer ;;
            12) cachyconfs_installer ;;
            13) ostree_autoupd_installer ;;
            0) exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
