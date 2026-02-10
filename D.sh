#!/bin/bash
set -e

[ ! -f /etc/debian_version ] && { echo "Apenas Debian é suportado."; exit 1; }

STATE_DIR="$HOME/.config/debian_scripts"
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

affinity_installer() {
    local state_file="$STATE_DIR/affinity"
    local affinity_dir="$HOME/Affinity"
    local appimage_path="$affinity_dir/Affinity.AppImage"

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "Affinity detectado. Desinstalar?"; then
            echo "Desinstalando Affinity..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            [ -d "$affinity_dir" ] && rmdir "$affinity_dir" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Affinity desinstalado."
        fi
    else
        if confirm "Instalar Affinity Photo?"; then
            echo "Instalando Affinity Photo..."
            mkdir -p "$affinity_dir"
            
            local download_url=$(curl -s https://api.github.com/repos/ryzendew/Linux-Affinity-Installer/releases/latest | grep -o '"browser_download_url": *"[^"]*"' | grep -i 'affinity.*appimage' | head -1 | cut -d'"' -f4)
            [ -z "$download_url" ] && download_url="https://github.com/ryzendew/Linux-Affinity-Installer/releases/latest/download/Affinity.AppImage"
            
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            
            touch "$state_file"
            echo "Affinity Photo instalado."
        fi
    fi
}

apparmor_installer() {
    local state_file="$STATE_DIR/apparmor"
    local pkg_apparmor="apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*apparmor "; then
        if confirm "AppArmor detectado. Desinstalar?"; then
            echo "Desinstalando AppArmor..."
            sudo systemctl stop apparmor 2>/dev/null || true
            sudo systemctl disable apparmor 2>/dev/null || true
            sudo apt remove --purge -y $pkg_apparmor
            sudo sed -i '/GRUB_CMDLINE_LINUX.*apparmor/d' /etc/default/grub
            sudo update-grub
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            sudo apt update
            sudo apt install -y $pkg_apparmor
            sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"/' /etc/default/grub
            sudo update-grub
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado. Reinicie para aplicar."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="libfuse2"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*libfuse2"; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            sudo apt remove --purge -y $pkg_fuse
            cleanup_files "$state_file"
            echo "FUSE para AppImage desinstalado."
        fi
    else
        if confirm "Instalar FUSE para AppImage?"; then
            echo "Instalando FUSE para AppImage..."
            sudo apt update
            sudo apt install -y $pkg_fuse
            touch "$state_file"
            echo "FUSE para AppImage instalado."
        fi
    fi
}

archiving_compression_installer() {
    local state_file="$STATE_DIR/pessoal_compactacao"
    local pkg_compactacao="tar p7zip-full unrar unzip gzip lrzip xz-utils zip lzop"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*p7zip-full"; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            sudo apt remove --purge -y $pkg_compactacao
            cleanup_files "$state_file"
            echo "Pacotes de Compactação desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Compactação?"; then
            echo "Instalando Pacotes de Compactação..."
            sudo apt update
            sudo apt install -y $pkg_compactacao
            touch "$state_file"
            echo "Pacotes de Compactação instalados."
        fi
    fi
}

aria2_installer() {
    local state_file="$STATE_DIR/aria2"
    local pkg_aria2="aria2"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*aria2"; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            sudo apt remove --purge -y $pkg_aria2
            cleanup_files "$state_file"
            echo "aria2 desinstalado."
        fi
    else
        if confirm "Instalar aria2?"; then
            echo "Instalando aria2..."
            sudo apt update
            sudo apt install -y $pkg_aria2
            touch "$state_file"
            echo "aria2 instalado."
        fi
    fi
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

curl_installer() {
    local state_file="$STATE_DIR/curl"
    local pkg_curl="curl"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*curl"; then
        if confirm "curl detectado. Desinstalar?"; then
            echo "Desinstalando curl..."
            sudo apt remove --purge -y $pkg_curl
            cleanup_files "$state_file"
            echo "curl desinstalado."
        fi
    else
        if confirm "Instalar curl?"; then
            echo "Instalando curl..."
            sudo apt update
            sudo apt install -y $pkg_curl
            touch "$state_file"
            echo "curl instalado."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-shell gnome-terminal gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*gnome-shell"; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            sudo apt remove --purge -y $pkg_gnome
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            sudo apt update
            sudo apt install -y $pkg_gnome
            sudo systemctl enable gdm
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="plasma-desktop konsole dolphin kdeconnect partitionmanager ark"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*plasma-desktop"; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            sudo apt remove --purge -y $pkg_plasma
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            sudo apt update
            sudo apt install -y $pkg_plasma
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

deb_multimedia_installer() {
    local state_file="$STATE_DIR/deb_multimedia"

    if [ -f "$state_file" ] || [ -f "/etc/apt/sources.list.d/dmo.list" ]; then
        if confirm "DebMultimedia detectado. Desinstalar?"; then
            echo "Desinstalando DebMultimedia..."
            sudo rm -f /etc/apt/sources.list.d/dmo.list
            sudo rm -f /usr/share/keyrings/deb-multimedia-keyring.gpg
            sudo apt update
            cleanup_files "$state_file"
            echo "DebMultimedia desinstalado."
        fi
    else
        if confirm "Instalar repositório DebMultimedia?"; then
            echo "Instalando DebMultimedia..."
            curl -L -o /tmp/deb-multimedia-keyring.deb https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb
            sudo dpkg -i /tmp/deb-multimedia-keyring.deb
            rm -f /tmp/deb-multimedia-keyring.deb
            
            echo "deb https://www.deb-multimedia.org forky main non-free" | sudo tee /etc/apt/sources.list.d/dmo.list > /dev/null
            
            sudo apt update
            touch "$state_file"
            echo "DebMultimedia instalado."
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

fish_fisher_installer() {
    local fish_state="$STATE_DIR/fish"
    local fisher_state="$STATE_DIR/fisher"
    local pkg_fish="fish"

    if [ -f "$fish_state" ] || dpkg -l | grep -q "^ii.*fish"; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ] || command -v fisher >/dev/null 2>&1; then
                rm -rf ~/.config/fish/functions/fisher.fish
                rm -rf ~/.config/fish/completions/fisher.fish
                cleanup_files "$fisher_state"
            fi
            sudo apt remove --purge -y $pkg_fish
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$fish_state" "$HOME/.config/fish"
            echo "Fish Shell desinstalado."
        fi
    elif confirm "Instalar Fish Shell?"; then
        echo "Instalando Fish Shell..."
        sudo apt update
        sudo apt install -y $pkg_fish
        sudo chsh -s "$(which fish)" "$USER"
        mkdir -p ~/.config/fish
        echo "set fish_greeting" > ~/.config/fish/config.fish
        touch "$fish_state"
        echo "Fish Shell instalado."
    fi

    if [ -f "$fisher_state" ] || command -v fisher >/dev/null 2>&1; then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            rm -rf ~/.config/fish/functions/fisher.fish
            rm -rf ~/.config/fish/completions/fisher.fish
            cleanup_files "$fisher_state"
            echo "Fisher desinstalado."
        fi
    elif confirm "Instalar Fisher (plugin manager)?"; then
        echo "Instalando Fisher..."
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish > ~/.config/fish/functions/fisher.fish
        fish -c "curl -sL https://git.io/fisher | source; fisher install jorgebucaran/fisher" 2>/dev/null || true
        touch "$fisher_state"
        echo "Fisher instalado."
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"

    if [ -f "$flatpak_state" ] || dpkg -l | grep -q "^ii.*flatpak"; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            sudo apt remove --purge -y $pkg_flatpak
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        sudo apt update
        sudo apt install -y $pkg_flatpak
        touch "$flatpak_state"
        echo "Flatpak instalado."
    fi

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
}

fwupd_installer() {
    local state_file="$STATE_DIR/fwupd"
    local pkg_fwupd="fwupd"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*fwupd"; then
        if confirm "Fwupd detectado. Desinstalar?"; then
            echo "Desinstalando Fwupd..."
            sudo apt remove --purge -y $pkg_fwupd
            cleanup_files "$state_file"
            echo "Fwupd desinstalado."
        fi
    else
        if confirm "Instalar Fwupd?"; then
            echo "Instalando Fwupd..."
            sudo apt update
            sudo apt install -y $pkg_fwupd
            touch "$state_file"
            echo "Fwupd instalado."
        fi
    fi
}

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*gamemode"; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            sudo apt remove --purge -y $pkg_gamemode
            cleanup_files "$state_file"
            echo "Gamemode desinstalado."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
            sudo apt update
            sudo apt install -y $pkg_gamemode
            touch "$state_file"
            echo "Gamemode instalado."
        fi
    fi
}

lazyvim_installer() {
    local state_file="$STATE_DIR/nvim_lazyvim"
    local nvim_dir="$HOME/.config/nvim"

    if [ -f "$state_file" ] || [ -d "$nvim_dir" ]; then
        if confirm "LazyVim detectado. Desinstalar?"; then
            echo "Desinstalando LazyVim..."
            rm -rf "$nvim_dir"
            cleanup_files "$state_file"
            echo "LazyVim desinstalado."
        fi
    else
        if confirm "Instalar LazyVim?"; then
            echo "Instalando LazyVim..."
            rm -rf "$nvim_dir"
            git clone https://github.com/LazyVim/starter "$nvim_dir"
            rm -rf "$nvim_dir/.git"
            touch "$state_file"
            echo "LazyVim instalado."
        fi
    fi
}

mise_installer() {
    local state_file="$STATE_DIR/mise"

    if [ -f "$state_file" ] || command -v mise >/dev/null 2>&1; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            rm -rf ~/.local/share/mise
            sed -i '/mise init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/mise init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/mise init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            if [ -f ~/.bashrc ]; then
                curl https://mise.run/bash | sh
                mkdir -p ~/.local/share/bash-completion/
                mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
            fi
            if [ -f ~/.zshrc ]; then
                curl https://mise.run/zsh | sh
                mkdir -p ~/.local/share/zsh/site-functions
                mise completion zsh > ~/.local/share/zsh/site-functions/_mise
            fi
            if [ -f ~/.config/fish/config.fish ]; then
                curl https://mise.run/fish | sh
                mkdir -p ~/.config/fish/completions
                mise completion fish > ~/.config/fish/completions/mise.fish
            fi
            touch "$state_file"
            echo "Mise instalado."
        fi
    fi
}

nala_installer() {
    local state_file="$STATE_DIR/nala"
    local pkg_nala="nala"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*nala"; then
        if confirm "Nala detectado. Desinstalar?"; then
            echo "Desinstalando Nala..."
            sudo apt remove --purge -y $pkg_nala
            cleanup_files "$state_file"
            echo "Nala desinstalado."
        fi
    else
        if confirm "Instalar Nala?"; then
            echo "Instalando Nala..."
            sudo apt update
            sudo apt install -y $pkg_nala
            touch "$state_file"
            echo "Nala instalado."
        fi
    fi
}

neovim_installer() {
    local state_file="$STATE_DIR/nvim"
    local pkg_neovim="neovim"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*neovim"; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            sudo apt remove --purge -y $pkg_neovim
            cleanup_files "$state_file"
            echo "NeoVim desinstalado."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            sudo apt update
            sudo apt install -y $pkg_neovim
            touch "$state_file"
            echo "NeoVim instalado."
        fi
    fi
}

nvidia_proprietary_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*nvidia-driver"; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            sudo apt remove --purge -y nvidia-driver-* cuda-drivers cuda-keyring
            sudo rm -f /etc/apt/preferences.d/nvidia-repo
            sudo rm -f /etc/apt/sources.list.d/cuda.list
            sudo apt update
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        if confirm "Instalar Nvidia Proprietário?"; then
            echo "Instalando Nvidia Proprietário..."
            sudo apt update
            sudo apt install -y ntpsec
            sudo timedatectl set-ntp true
            
            curl -L -o /tmp/cuda-keyring.deb https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
            sudo dpkg -i /tmp/cuda-keyring.deb
            rm -f /tmp/cuda-keyring.deb
            
            echo 'Package: *  
Pin: origin https://developer.download.nvidia.com  
Pin-Priority: 100' | sudo tee /etc/apt/preferences.d/nvidia-repo > /dev/null
            
            sudo apt update --allow-insecure-repositories --allow-unauthenticated
            sudo apt install -y --allow-unauthenticated cuda-drivers
            sudo update-initramfs -u
            sudo update-grub
            touch "$state_file"
            echo "Nvidia Proprietário instalado. Reinicie para aplicar."
        fi
    fi
}

ntpsec_installer() {
    local state_file="$STATE_DIR/ntpsec"
    local pkg_ntpsec="ntpsec"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*ntpsec"; then
        if confirm "NTPsec detectado. Desinstalar?"; then
            echo "Desinstalando NTPsec..."
            sudo systemctl stop ntpsec 2>/dev/null || true
            sudo systemctl disable ntpsec 2>/dev/null || true
            sudo apt remove --purge -y $pkg_ntpsec
            cleanup_files "$state_file"
            echo "NTPsec desinstalado."
        fi
    else
        if confirm "Instalar NTPsec para sincronização de horário?"; then
            echo "Instalando NTPsec..."
            sudo apt update
            sudo apt install -y $pkg_ntpsec
            sudo systemctl enable ntpsec
            sudo systemctl start ntpsec
            sudo timedatectl set-ntp true
            touch "$state_file"
            echo "NTPsec instalado e sincronização ativada."
        fi
    fi
}

oh_my_bash_installer() {
    local state_file="$STATE_DIR/oh_my_bash"

    if [ -f "$state_file" ] || [ -d "$HOME/.oh-my-bash" ]; then
        if confirm "Oh My Bash detectado. Desinstalar?"; then
            [ -d "$HOME/.oh-my-bash" ] && yes | "$HOME/.oh-my-bash"/tools/uninstall.sh
            cleanup_files "$state_file"
            echo "Oh My Bash desinstalado."
        fi
    else
        if confirm "Instalar Oh My Bash?"; then
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
            touch "$state_file"
            echo "Oh My Bash instalado."
        fi
    fi
}

pacstall_installer() {
    local state_file="$STATE_DIR/pacstall"

    if [ -f "$state_file" ] || command -v pacstall >/dev/null 2>&1; then
        if confirm "Pacstall detectado. Desinstalar?"; then
            echo "Desinstalando Pacstall..."
            bash -c "$(curl -fsSL https://pacstall.dev/q/uninstall -o -)"
            cleanup_files "$state_file"
            echo "Pacstall desinstalado."
        fi
    else
        if confirm "Instalar Pacstall?"; then
            echo "Instalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install -o -)"
            touch "$state_file"
            echo "Pacstall instalado."
        fi
    fi
}

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra fonts-jetbrains-mono fonts-bebas-neue"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*fonts-jetbrains-mono"; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            sudo apt remove --purge -y $pkg_base
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados."
        fi
    else
        if confirm "Instalar Pacotes Base?"; then
            echo "Instalando Pacotes Base..."
            sudo apt update
            sudo apt install -y $pkg_base
            touch "$state_file"
            echo "Pacotes Base instalados."
        fi
    fi
}

pessoal_media_installer() {
    local state_file="$STATE_DIR/pessoal_media"
    local pkg_media="ffmpeg gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-alsa"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*ffmpeg"; then
        if confirm "Pacotes de Mídia detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Mídia..."
            sudo apt remove --purge -y $pkg_media
            cleanup_files "$state_file"
            echo "Pacotes de Mídia desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Mídia?"; then
            echo "Instalando Pacotes de Mídia..."
            sudo apt update
            sudo apt install -y $pkg_media
            touch "$state_file"
            echo "Pacotes de Mídia instalados."
        fi
    fi
}

podman_installer() {
    local state_file="$STATE_DIR/podman"
    local pkg_podman="podman podman-compose"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*podman"; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            sudo apt remove --purge -y $pkg_podman
            cleanup_files "$state_file"
            echo "Podman desinstalado."
        fi
    else
        if confirm "Instalar Podman?"; then
            echo "Instalando Podman..."
            sudo apt update
            sudo apt install -y $pkg_podman
            touch "$state_file"
            echo "Podman instalado."
        fi
    fi
}

repos_nonfree_installer() {
    local state_file="$STATE_DIR/repos_nonfree"

    if [ -f "$state_file" ]; then
        if confirm "Repositórios non-free detectados. Desinstalar?"; then
            echo "Desinstalando repositórios non-free..."
            sudo sed -i 's/ main non-free-firmware/ main/' /etc/apt/sources.list
            sudo sed -i 's/ main non-free-firmware/ main/' /etc/apt/sources.list.d/*.list 2>/dev/null || true
            sudo apt update
            cleanup_files "$state_file"
            echo "Repositórios non-free desinstalados."
        fi
    else
        if confirm "Instalar repositórios non-free e non-free-firmware?"; then
            echo "Instalando repositórios non-free..."
            sudo sed -i 's/ main/ main non-free non-free-firmware contrib/' /etc/apt/sources.list
            sudo apt update
            touch "$state_file"
            echo "Repositórios non-free instalados."
        fi
    fi
}

shader_booster_installer() {
    local state_file="$STATE_DIR/shader_booster"
    local boost_file="$HOME/.booster"

    if [ -f "$state_file" ] || [ -f "$boost_file" ]; then
        if confirm "Shader Booster detectado. Desinstalar?"; then
            for shell_file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
                [ -f "$shell_file" ] && sed -i '/# Shader Booster patches/,/# End Shader Booster/d' "$shell_file"
            done
            cleanup_files "$state_file" "$boost_file" "$HOME/patch-nvidia" "$HOME/patch-mesa"
            echo "Shader Booster desinstalado."
        fi
    else
        if confirm "Instalar Shader Booster?"; then
            local has_nvidia=$(lspci | grep -i 'nvidia')
            local has_mesa=$(lspci | grep -Ei '(vga|3d)' | grep -vi nvidia)
            local patch_applied=0
            local dest_file=""

            for file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
                [ -f "$file" ] && dest_file="$file" && break
            done
            [ -z "$dest_file" ] && dest_file="$HOME/.bash_profile" && touch "$dest_file"

            echo -e "\n# Shader Booster patches" >> "$dest_file"
            [ -n "$has_nvidia" ] && curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-nvidia >> "$dest_file" && patch_applied=1
            [ -n "$has_mesa" ] && curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-mesa >> "$dest_file" && patch_applied=1
            echo "# End Shader Booster" >> "$dest_file"

            [ $patch_applied -eq 1 ] && echo "1" > "$boost_file" && touch "$state_file"
            echo "Shader Booster instalado."
        fi
    fi
}

snapd_installer() {
    local state_file="$STATE_DIR/snapd"
    local pkg_snapd="snapd"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*snapd"; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket 2>/dev/null || true
            sudo systemctl disable snapd.socket 2>/dev/null || true
            sudo apt remove --purge -y $pkg_snapd
            cleanup_files "$state_file"
            echo "Snapd desinstalado."
        fi
    else
        if confirm "Instalar Snapd?"; then
            echo "Instalando Snapd..."
            sudo apt update
            sudo apt install -y $pkg_snapd
            sudo systemctl enable --now snapd.socket
            touch "$state_file"
            echo "Snapd instalado."
        fi
    fi
}

starship_installer() {
    local state_file="$STATE_DIR/starship"
    local pkg_starship="starship"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*starship"; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            sudo apt remove --purge -y $pkg_starship
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            sudo apt update
            sudo apt install -y $pkg_starship
            [ -f ~/.bashrc ] && grep -q "starship init" ~/.bashrc || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bashrc
            [ -f ~/.zshrc ] && grep -q "starship init" ~/.zshrc || echo -e "\neval \"\$(starship init zsh)\"" >> ~/.zshrc
            command -v fish &>/dev/null && mkdir -p ~/.config/fish && if [ -f ~/.config/fish/config.fish ]; then grep -q "starship init fish" ~/.config/fish/config.fish || echo -e "\nstarship init fish | source" >> ~/.config/fish/config.fish; else echo -e "starship init fish | source" >> ~/.config/fish/config.fish; fi
            touch "$state_file"
            echo "Starship instalado."
        fi
    fi
}

steam_installer() {
    local state_file="$STATE_DIR/steam"
    local pkg_steam="com.valvesoftware.Steam"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.valvesoftware.Steam 2>/dev/null; then
        if confirm "Steam detectado. Desinstalar?"; then
            echo "Desinstalando Steam..."
            flatpak uninstall --user -y $pkg_steam 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Steam desinstalado."
        fi
    else
        if confirm "Instalar Steam?"; then
            echo "Instalando Steam..."
            flatpak install --or-update --user --noninteractive flathub $pkg_steam
            touch "$state_file"
            echo "Steam instalado."
        fi
    fi
}

ufw_installer() {
    local state_file="$STATE_DIR/ufw"
    local pkg_ufw="ufw"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*ufw"; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            sudo ufw --force disable
            sudo systemctl stop ufw 2>/dev/null || true
            sudo systemctl disable ufw 2>/dev/null || true
            sudo apt remove --purge -y $pkg_ufw
            cleanup_files "$state_file"
            echo "UFW desinstalado."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
            sudo apt update
            sudo apt install -y $pkg_ufw
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw allow 53317/udp
            sudo ufw allow 53317/tcp
            sudo ufw allow 1714:1764/udp
            sudo ufw allow 1714:1764/tcp
            sudo ufw allow 12135/tcp
            sudo ufw allow 42000:42001/udp
            sudo ufw allow 42000:42001/tcp
            sudo systemctl enable ufw
            sudo ufw --force enable
            sudo ufw status verbose
            touch "$state_file"
            echo "UFW instalado e configurado."
        fi
    fi
}

unmojang_installer() {
    local state_file="$STATE_DIR/unmojang"
    local pkg_fjord="org.unmojang.FjordLauncher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.unmojang.FjordLauncher 2>/dev/null; then
        if confirm "Fjord Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Fjord Launcher..."
            flatpak uninstall --user -y $pkg_fjord 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Fjord Launcher desinstalado."
        fi
    else
        if confirm "Instalar Fjord Launcher?"; then
            echo "Instalando Fjord Launcher..."
            flatpak remote-add --user --if-not-exists hero-persson https://hero-persson.github.io/unmojang-flatpak/index.flatpakrepo
            flatpak install --user --or-update --noninteractive hero-persson $pkg_fjord
            touch "$state_file"
            echo "Fjord Launcher instalado."
        fi
    fi
}

xdg_base_installer() {
    local state_file="$STATE_DIR/xdg_base"
    local pkg_xdg="xdg-user-dirs xdg-utils"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*xdg-user-dirs"; then
        if confirm "XDG Base detectado. Desinstalar?"; then
            echo "Desinstalando XDG Base..."
            sudo apt remove --purge -y $pkg_xdg
            cleanup_files "$state_file"
            echo "XDG Base desinstalado."
        fi
    else
        if confirm "Instalar XDG Base?"; then
            echo "Instalando XDG Base..."
            sudo apt update
            sudo apt install -y $pkg_xdg
            touch "$state_file"
            echo "XDG Base instalado."
        fi
    fi
}

yt_dlp_installer() {
    local state_file="$STATE_DIR/yt_dlp"
    local pkg_ytdlp="yt-dlp"

    if [ -f "$state_file" ] || dpkg -l | grep -q "^ii.*yt-dlp"; then
        if confirm "yt-dlp detectado. Desinstalar?"; then
            echo "Desinstalando yt-dlp..."
            sudo apt remove --purge -y $pkg_ytdlp
            cleanup_files "$state_file"
            echo "yt-dlp desinstalado."
        fi
    else
        if confirm "Instalar yt-dlp?"; then
            echo "Instalando yt-dlp..."
            sudo apt update
            sudo apt install -y $pkg_ytdlp
            touch "$state_file"
            echo "yt-dlp instalado."
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

zsh_ohmyzsh_installer() {
    local zsh_state="$STATE_DIR/zsh"
    local ohmyzsh_state="$STATE_DIR/ohmyzsh"
    local pkg_zsh="zsh"

    if [ -f "$zsh_state" ] || dpkg -l | grep -q "^ii.*zsh"; then
        if confirm "Zsh detectado. Desinstalar?"; then
            echo "Desinstalando Zsh..."
            if [ -f "$ohmyzsh_state" ] || [ -d "$HOME/.oh-my-zsh" ]; then
                [ -d "$HOME/.oh-my-zsh" ] && {
                    chmod +x "$HOME/.oh-my-zsh/tools/uninstall.sh"
                    yes | "$HOME/.oh-my-zsh/tools/uninstall.sh"
                }
                cleanup_files "$ohmyzsh_state"
            fi
            sudo apt remove --purge -y $pkg_zsh
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$zsh_state" "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc.backup"
            echo "Zsh desinstalado."
        fi
    elif confirm "Instalar Zsh?"; then
        echo "Instalando Zsh..."
        sudo apt update
        sudo apt install -y $pkg_zsh
        sudo chsh -s "$(which zsh)" "$USER"
        touch "$HOME/.zshrc"
        touch "$zsh_state"
        echo "Zsh instalado."
    fi
    
    if [ ! -f "$ohmyzsh_state" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
        if confirm "Instalar Oh My Zsh?"; then
            echo "Instalando Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            touch "$ohmyzsh_state"
            echo "Oh My Zsh instalado."
        fi
    elif [ -f "$ohmyzsh_state" ] || [ -d "$HOME/.oh-my-zsh" ]; then
        if confirm "Oh My Zsh detectado. Desinstalar?"; then
            echo "Desinstalando Oh My Zsh..."
            [ -d "$HOME/.oh-my-zsh" ] && {
                chmod +x "$HOME/.oh-my-zsh/tools/uninstall.sh"
                yes | "$HOME/.oh-my-zsh/tools/uninstall.sh"
            }
            cleanup_files "$ohmyzsh_state"
            echo "Oh My Zsh desinstalado."
        fi
    fi
}

zswap_installer() {
    local state_file="$STATE_DIR/zswap"

    if [ -f "$state_file" ]; then
        if confirm "ZSWAP detectado. Desinstalar?"; then
            echo "Desinstalando ZSWAP..."
            sudo sed -i '/zswap\.enabled/d' /etc/default/grub
            sudo update-grub
            cleanup_files "$state_file"
            echo "ZSWAP desinstalado."
        fi
    else
        if confirm "Ativar ZSWAP?"; then
            echo "Ativando ZSWAP..."
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& zswap.enabled=1/' /etc/default/grub
            sudo update-grub
            touch "$state_file"
            echo "ZSWAP ativado. Reinicie para aplicar."
        fi
    fi
}

main_menu() {
    while true; do
        clear
        echo "=== Debian Scripts ==="
        echo "1) Affinity Photo"
        echo "2) AppArmor"
        echo "3) AppImage FUSE"
        echo "4) Archiving/Compression"
        echo "5) aria2"
        echo "6) CachyOS Configs"
        echo "7) curl"
        echo "8) GNOME Desktop"
        echo "9) KDE Plasma Desktop"
        echo "10) DebMultimedia Repository"
        echo "11) Faugus Launcher"
        echo "12) Fish Shell + Fisher"
        echo "13) Flatpak + Flathub"
        echo "14) Fwupd"
        echo "15) Gamemode"
        echo "16) LazyVim"
        echo "17) Mise"
        echo "18) Nala"
        echo "19) NeoVim"
        echo "20) Nvidia Drivers"
        echo "21) NTPsec (Sincronização Horário)"
        echo "22) Oh My Bash"
        echo "23) Pacstall"
        echo "24) Base Packages (Fonts)"
        echo "25) Media Packages"
        echo "26) Podman"
        echo "27) Non-free Repositories"
        echo "28) Shader Booster"
        echo "29) Snapd"
        echo "30) Starship"
        echo "31) Steam"
        echo "32) UFW"
        echo "33) Unmojang (Fjord Launcher)"
        echo "34) XDG Base"
        echo "35) yt-dlp"
        echo "36) Zen Browser"
        echo "37) Zsh + Oh My Zsh"
        echo "38) ZSWAP"
        echo "39) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) affinity_installer ;;
            2) apparmor_installer ;;
            3) appimage_fuse_installer ;;
            4) archiving_compression_installer ;;
            5) aria2_installer ;;
            6) cachyconfs_installer ;;
            7) curl_installer ;;
            8) de_gnome_installer ;;
            9) de_plasma_installer ;;
            10) deb_multimedia_installer ;;
            11) faugus_launcher_installer ;;
            12) fish_fisher_installer ;;
            13) flatpak_flathub_installer ;;
            14) fwupd_installer ;;
            15) gamemode_installer ;;
            16) lazyvim_installer ;;
            17) mise_installer ;;
            18) nala_installer ;;
            19) neovim_installer ;;
            20) nvidia_proprietary_dkms_installer ;;
            21) ntpsec_installer ;;
            22) oh_my_bash_installer ;;
            23) pacstall_installer ;;
            24) pessoal_base_installer ;;
            25) pessoal_media_installer ;;
            26) podman_installer ;;
            27) repos_nonfree_installer ;;
            28) shader_booster_installer ;;
            29) snapd_installer ;;
            30) starship_installer ;;
            31) steam_installer ;;
            32) ufw_installer ;;
            33) unmojang_installer ;;
            34) xdg_base_installer ;;
            35) yt_dlp_installer ;;
            36) zen_browser_installer ;;
            37) zsh_ohmyzsh_installer ;;
            38) zswap_installer ;;
            39) exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
