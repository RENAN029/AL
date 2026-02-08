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

admin_installer() {
    while true; do
        clear
        echo "=== Admin ==="
        echo "1)  Flatpak e Flathub"
        echo "2)  Nala"
        echo "3)  Pacstall"
        echo "4)  Snapd"
        echo "5)  UFW"
        echo "6)  Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) flatpak_flathub_installer ;;
            2) nala_installer ;;
            3) pacstall_installer ;;
            4) snapd_installer ;;
            5) ufw_installer ;;
            6) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

apparmor_installer() {
    local state_file="$STATE_DIR/apparmor"
    local pkg_apparmor="apparmor apparmor-utils"

    if [ -f "$state_file" ] || dpkg -s apparmor &>/dev/null; then
        if confirm "AppArmor detectado. Desinstalar?"; then
            echo "Desinstalando AppArmor..."
            sudo systemctl stop apparmor 2>/dev/null || true
            sudo systemctl disable apparmor 2>/dev/null || true
            dpkg -s apparmor &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_apparmor || true
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            sudo apt update
            sudo apt install -y $pkg_apparmor
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado. Reinicie para aplicar."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="libfuse2"

    if [ -f "$state_file" ] || dpkg -s libfuse2 &>/dev/null; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            dpkg -s libfuse2 &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_fuse || true
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
    local state_file="$STATE_DIR/compactacao"
    local pkg_compactacao="tar p7zip-full unrar unzip gzip lrzip xz-utils zip lzop"

    if [ -f "$state_file" ] || dpkg -s p7zip-full &>/dev/null; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            dpkg -s p7zip-full &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_compactacao || true
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

    if [ -f "$state_file" ] || dpkg -s aria2 &>/dev/null; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            dpkg -s aria2 &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_aria2 || true
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

curl_installer() {
    local state_file="$STATE_DIR/curl"
    local pkg_curl="curl"

    if [ -f "$state_file" ] || dpkg -s curl &>/dev/null; then
        if confirm "curl detectado. Desinstalar?"; then
            echo "Desinstalando curl..."
            dpkg -s curl &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_curl || true
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

    if [ -f "$state_file" ] || dpkg -s gnome-shell &>/dev/null; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            dpkg -s gnome-shell &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_gnome || true
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

    if [ -f "$state_file" ] || dpkg -s plasma-desktop &>/dev/null; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            dpkg -s plasma-desktop &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_plasma || true
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
    local key_url="https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb"
    local key_file="/tmp/deb-multimedia-keyring.deb"
    local sources_file="/etc/apt/sources.list.d/dmo.sources"

    if [ -f "$state_file" ] || [ -f "$sources_file" ]; then
        if confirm "DebMultimedia detectado. Desinstalar?"; then
            echo "Desinstalando DebMultimedia..."
            sudo rm -f "$sources_file"
            sudo rm -f /usr/share/keyrings/deb-multimedia-keyring.pgp
            sudo apt update
            cleanup_files "$state_file"
            echo "DebMultimedia desinstalado."
        fi
    else
        if confirm "Instalar repositório DebMultimedia?"; then
            echo "Instalando DebMultimedia..."
            curl -L -o "$key_file" "$key_url"
            sudo dpkg -i "$key_file"
            echo "Types: deb
URIs: https://www.deb-multimedia.org
Suites: $(lsb_release -cs)
Components: main non-free
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp
Enabled: yes" | sudo tee "$sources_file"
            sudo apt update
            touch "$state_file"
            echo "DebMultimedia instalado."
        fi
    fi
}

devs_installer() {
    while true; do
        clear
        echo "=== Devs ==="
        echo "1)  Fish e Fisher"
        echo "2)  Mise"
        echo "3)  NeoVim"
        echo "4)  LazyVim"
        echo "5)  Podman"
        echo "6)  Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) fish_fisher_installer ;;
            2) mise_installer ;;
            3) neovim_installer ;;
            4) lazyvim_installer ;;
            5) podman_installer ;;
            6) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

drivers_installer() {
    while true; do
        clear
        echo "=== Drivers ==="
        echo "1)  NVIDIA Proprietário"
        echo "2)  Shader Booster"
        echo "3)  Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) nvidia_proprietary_installer ;;
            2) shader_booster_installer ;;
            3) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

educacao_installer() {
    while true; do
        clear
        echo "=== Educação ==="
        echo "1)  Repositórios Contrib e Non-Free"
        echo "2)  XDG Base"
        echo "3)  Pacotes Base Pessoais"
        echo "4)  Pacotes de Mídia"
        echo "5)  yt-dlp"
        echo "6)  AppImage FUSE"
        echo "7)  aria2"
        echo "8)  curl"
        echo "9)  AppArmor"
        echo "10) Gamemode"
        echo "11) Fwupd"
        echo "12) Compactação"
        echo "13) Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) repos_contrib_nonfree_installer ;;
            2) xdg_base_installer ;;
            3) pessoal_base_installer ;;
            4) pessoal_media_installer ;;
            5) yt_dlp_installer ;;
            6) appimage_fuse_installer ;;
            7) aria2_installer ;;
            8) curl_installer ;;
            9) apparmor_installer ;;
            10) gamemode_installer ;;
            11) fwupd_installer ;;
            12) archiving_compression_installer ;;
            13) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
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

    if [ -f "$fish_state" ] || dpkg -s fish &>/dev/null; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ]; then
                cleanup_files "$fisher_state"
            fi
            dpkg -s fish &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_fish || true
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

    if [ -f "$fisher_state" ]; then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            cleanup_files "$fisher_state"
            echo "Fisher desinstalado."
        fi
    elif confirm "Instalar Fisher (plugin manager)?"; then
        echo "Instalando Fisher..."
        if command -v fish >/dev/null 2>&1; then
            fish -c "curl -sL https://git.io/fisher | source; fisher install jorgebucaran/fisher" 2>/dev/null || true
            touch "$fisher_state"
            echo "Fisher instalado."
        else
            echo "Fish Shell não está instalado. Instale primeiro."
        fi
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"

    if [ -f "$flatpak_state" ] || dpkg -s flatpak &>/dev/null; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            dpkg -s flatpak &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_flatpak || true
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        sudo apt update
        sudo apt install -y $pkg_flatpak
        
        if dpkg -s gnome-shell &>/dev/null; then
            sudo apt install -y gnome-software-plugin-flatpak
        elif dpkg -s plasma-desktop &>/dev/null; then
            sudo apt install -y plasma-discover-backend-flatpak
        fi
        
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

    if [ -f "$state_file" ] || dpkg -s fwupd &>/dev/null; then
        if confirm "Fwupd detectado. Desinstalar?"; then
            echo "Desinstalando Fwupd..."
            dpkg -s fwupd &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_fwupd || true
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

    if [ -f "$state_file" ] || dpkg -s gamemode &>/dev/null; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            dpkg -s gamemode &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_gamemode || true
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

games_installer() {
    while true; do
        clear
        echo "=== Games ==="
        echo "1)  Steam"
        echo "2)  Faugus Launcher"
        echo "3)  Fjord Launcher"
        echo "4)  Gamemode"
        echo "5)  Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) steam_installer ;;
            2) faugus_launcher_installer ;;
            3) unmojang_installer ;;
            4) gamemode_installer ;;
            5) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
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

    if [ -f "$state_file" ]; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            cleanup_files "$state_file" "$HOME/.local/share/bash-completion/completions/mise" \
                "/usr/local/share/zsh/site-functions/_mise" \
                "$HOME/.config/fish/completions/mise.fish"
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            if [ -f "$HOME/.bashrc" ]; then
                curl https://mise.run/bash | sh
                mkdir -p ~/.local/share/bash-completion/
                mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
            fi
            if [ -f "$HOME/.zshrc" ]; then
                curl https://mise.run/zsh | sh
                mkdir -p /usr/local/share/zsh/site-functions
                mise completion zsh > /usr/local/share/zsh/site-functions/_mise
            fi
            if [ -f "$HOME/.config/fish/config.fish" ]; then
                curl https://mise.run/fish | sh
                mkdir -p ~/.config/fish/completions
                mise completion fish > ~/.config/fish/completions/mise.fish
            fi
            mise use -g usage
            touch "$state_file"
            echo "Mise instalado."
        fi
    fi
}

nala_installer() {
    local state_file="$STATE_DIR/nala"
    local pkg_nala="nala"

    if [ -f "$state_file" ] || dpkg -s nala &>/dev/null; then
        if confirm "Nala detectado. Desinstalar?"; then
            echo "Desinstalando Nala..."
            dpkg -s nala &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_nala || true
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

    if [ -f "$state_file" ] || dpkg -s neovim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            dpkg -s neovim &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_neovim || true
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

nvidia_proprietary_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"
    local key_url="https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb"
    local key_file="/tmp/cuda-keyring.deb"
    local pref_file="/etc/apt/preferences.d/nvidia-repo"

    if [ -f "$state_file" ] || [ -f "/etc/apt/sources.list.d/cuda.list" ]; then
        if confirm "NVIDIA Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando NVIDIA Proprietário..."
            sudo apt remove --purge --auto-remove -y nvidia-driver-* cuda-drivers cuda-toolkit || true
            sudo rm -f /etc/apt/sources.list.d/cuda.list /etc/apt/preferences.d/nvidia-repo
            sudo apt update
            cleanup_files "$state_file"
            echo "NVIDIA Proprietário desinstalado."
        fi
    else
        echo "Instalando NVIDIA Proprietário..."
        sudo apt update
        sudo apt install -y --no-install-recommends dkms libdw-dev clang lld llvm build-essential linux-headers-$(uname -r) pipewire-audio-client-libraries
        
        curl -L -o "$key_file" "$key_url"
        sudo dpkg -i "$key_file"
        
        echo "Package: *  
Pin: origin https://developer.download.nvidia.com  
Pin-Priority: 900" | sudo tee "$pref_file"
        
        sudo apt update
        sudo apt install -y nvidia-open
        sudo update-initramfs -u
        sudo update-grub
        touch "$state_file"
        echo "NVIDIA Proprietário instalado. Reinicie para aplicar."
    fi
}

pacstall_installer() {
    local state_file="$STATE_DIR/pacstall"

    if [ -f "$state_file" ] || command -v pacstall &>/dev/null; then
        if confirm "Pacstall detectado. Desinstalar?"; then
            echo "Desinstalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://git.io/Jc9bH)" -o /dev/null --uninstall
            cleanup_files "$state_file"
            echo "Pacstall desinstalado."
        fi
    else
        if confirm "Instalar Pacstall?"; then
            echo "Instalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://git.io/Jc9bH)"
            touch "$state_file"
            echo "Pacstall instalado."
        fi
    fi
}

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra fonts-noto-cjk-extra fonts-jetbrains-mono"

    if [ -f "$state_file" ] || dpkg -s fonts-jetbrains-mono &>/dev/null; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            dpkg -s fonts-jetbrains-mono &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_base || true
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

    if [ -f "$state_file" ] || dpkg -s gstreamer1.0-alsa &>/dev/null; then
        if confirm "Pacotes de Mídia detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Mídia..."
            dpkg -s gstreamer1.0-alsa &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_media || true
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

    if [ -f "$state_file" ] || dpkg -s podman &>/dev/null; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            dpkg -s podman &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_podman || true
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

repos_contrib_nonfree_installer() {
    local state_file="$STATE_DIR/contrib_nonfree"
    local sources_file="/etc/apt/sources.list"

    if [ -f "$state_file" ] || grep -q "contrib non-free non-free-firmware" "$sources_file"; then
        if confirm "Repositórios Contrib/Non-Free detectados. Remover?"; then
            echo "Removendo repositórios Contrib/Non-Free..."
            sudo sed -i 's/ contrib non-free non-free-firmware//g' "$sources_file"
            sudo apt update
            cleanup_files "$state_file"
            echo "Repositórios removidos."
        fi
    else
        if confirm "Adicionar repositórios Contrib e Non-Free?"; then
            echo "Adicionando repositórios Contrib e Non-Free..."
            sudo sed -i '/^deb.*main$/s/$/ contrib non-free non-free-firmware/' "$sources_file"
            sudo sed -i '/^deb-src.*main$/s/$/ contrib non-free non-free-firmware/' "$sources_file"
            sudo apt update
            touch "$state_file"
            echo "Repositórios adicionados."
        fi
    fi
}

shader_booster_installer() {
    local state_file="$STATE_DIR/shader_booster"
    local boost_file="$HOME/.booster"

    if [ -f "$state_file" ] || [ -f "$boost_file" ]; then
        if confirm "Shader Booster detectado. Desinstalar?"; then
            for shell_file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
                [ -f "$shell_file" ] && sed -i '/# Shader Booster patches/,/# End Shader Booster/d' "$shell_file"
            done
            cleanup_files "$state_file" "$boost_file"
        fi
    else
        if confirm "Instalar Shader Booster?"; then
            local has_nvidia=$(lspci | grep -i 'nvidia')
            local has_mesa=$(lspci | grep -Ei '(vga|3d)' | grep -vi nvidia)
            local patch_applied=0
            local dest_file=""

            for file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
                [ -f "$file" ] && dest_file="$file" && break
            done
            [ -z "$dest_file" ] && dest_file="$HOME/.bash_profile" && touch "$dest_file"

            echo -e "\n# Shader Booster patches" >> "$dest_file"
            [ -n "$has_nvidia" ] && curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-nvidia >> "$dest_file" && patch_applied=1
            [ -n "$has_mesa" ] && curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-mesa >> "$dest_file" && patch_applied=1
            echo "# End Shader Booster" >> "$dest_file"

            [ $patch_applied -eq 1 ] && echo "1" > "$boost_file" && touch "$state_file"
        fi
    fi
}

snapd_installer() {
    local state_file="$STATE_DIR/snapd"
    local pkg_snapd="snapd"

    if [ -f "$state_file" ] || dpkg -s snapd &>/dev/null; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket 2>/dev/null || true
            sudo systemctl disable snapd.socket 2>/dev/null || true
            dpkg -s snapd &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_snapd || true
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

    if [ -f "$state_file" ] || command -v starship &>/dev/null; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
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

    if [ -f "$state_file" ] || dpkg -s ufw &>/dev/null; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            systemctl is-active --quiet ufw 2>/dev/null && sudo systemctl stop ufw || true
            systemctl is-enabled --quiet ufw 2>/dev/null && sudo systemctl disable ufw || true
            dpkg -s ufw &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_ufw || true
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw /usr/bin/ufw /usr/sbin/ufw 2>/dev/null || true
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

web_installer() {
    while true; do
        clear
        echo "=== Web ==="
        echo "1)  Zen Browser"
        echo "2)  Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) zen_browser_installer ;;
            2) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

xdg_base_installer() {
    local state_file="$STATE_DIR/xdg_base"
    local pkg_xdg="xdg-user-dirs xdg-utils"

    if [ -f "$state_file" ] || dpkg -s xdg-user-dirs &>/dev/null; then
        if confirm "XDG Base detectado. Desinstalar?"; then
            echo "Desinstalando XDG Base..."
            dpkg -s xdg-user-dirs &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_xdg || true
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

    if [ -f "$state_file" ] || dpkg -s yt-dlp &>/dev/null; then
        if confirm "yt-dlp detectado. Desinstalar?"; then
            echo "Desinstalando yt-dlp..."
            dpkg -s yt-dlp &>/dev/null && sudo apt remove --purge --auto-remove -y $pkg_ytdlp || true
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

main_menu() {
    while true; do
        clear
        echo "=== Debian Scripts ==="
        echo "1)  Admin"
        echo "2)  Devs"
        echo "3)  Drivers"
        echo "4)  Educação"
        echo "5)  Games"
        echo "6)  Web"
        echo "7)  Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) admin_installer ;;
            2) devs_installer ;;
            3) drivers_installer ;;
            4) educacao_installer ;;
            5) games_installer ;;
            6) web_installer ;;
            7) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
