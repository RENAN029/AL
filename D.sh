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

deb_multimedia_installer() {
    local state_file="$STATE_DIR/deb_multimedia"
    local keyring_file="deb-multimedia-keyring_2024.9.1_all.deb"
    
    if [ -f "$state_file" ] || [ -f "/etc/apt/sources.list.d/dmo.sources" ]; then
        if confirm "DebMultimedia detectado. Desinstalar?"; then
            echo "Desinstalando DebMultimedia..."
            sudo rm -f /etc/apt/sources.list.d/dmo.sources
            cleanup_files "$state_file" "$HOME/$keyring_file"
            echo "DebMultimedia desinstalado."
        fi
    else
        if confirm "Instalar repositório DebMultimedia?"; then
            echo "Instalando DebMultimedia..."
            curl -L https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb -o "$HOME/$keyring_file"
            sudo dpkg -i "$HOME/$keyring_file"
            echo "Types: deb" | sudo tee /etc/apt/sources.list.d/dmo.sources
            echo "URIs: https://www.deb-multimedia.org" | sudo tee -a /etc/apt/sources.list.d/dmo.sources
            echo "Suites: $(lsb_release -cs)" | sudo tee -a /etc/apt/sources.list.d/dmo.sources
            echo "Components: main non-free" | sudo tee -a /etc/apt/sources.list.d/dmo.sources
            echo "Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp" | sudo tee -a /etc/apt/sources.list.d/dmo.sources
            echo "Enabled: yes" | sudo tee -a /etc/apt/sources.list.d/dmo.sources
            touch "$state_file"
            echo "DebMultimedia instalado."
        fi
    fi
}

nonfree_repos_installer() {
    local state_file="$STATE_DIR/nonfree_repos"
    
    if [ -f "$state_file" ]; then
        if confirm "Repositórios NON-FREE detectados. Desinstalar?"; then
            echo "Removendo repositórios NON-FREE..."
            sudo sed -i '/non-free\|non-free-firmware\|contrib/d' /etc/apt/sources.list
            cleanup_files "$state_file"
            echo "Repositórios NON-FREE removidos."
        fi
    else
        if confirm "Ativar repositórios CONTRIB, NON-FREE e NON-FREE-FIRMWARE?"; then
            echo "Ativando repositórios NON-FREE..."
            sudo sed -i "s/ main/ main contrib non-free non-free-firmware/" /etc/apt/sources.list
            touch "$state_file"
            echo "Repositórios NON-FREE ativados."
        fi
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"
    local pkg_gnome_plugin="gnome-software-plugin-flatpak"
    local pkg_kde_plugin="plasma-discover-backend-flatpak"
    
    if [ -f "$flatpak_state" ] || dpkg -l flatpak 2>/dev/null | grep -q ^ii; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            sudo apt purge --auto-remove -y $pkg_flatpak $pkg_gnome_plugin $pkg_kde_plugin
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        sudo apt update
        sudo apt install -y $pkg_flatpak
        
        if [ -x "$(command -v gnome-shell)" ]; then
            sudo apt install -y $pkg_gnome_plugin
        elif [ -x "$(command -v plasmashell)" ]; then
            sudo apt install -y $pkg_kde_plugin
        fi
        
        touch "$flatpak_state"
        echo "Flatpak instalado."
    fi
    
    if [ -f "$flathub_state" ] || flatpak remote-list 2>/dev/null | grep -q flathub; then
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

fish_fisher_installer() {
    local fish_state="$STATE_DIR/fish"
    local fisher_state="$STATE_DIR/fisher"
    local pkg_fish="fish"
    
    if [ -f "$fish_state" ] || dpkg -l fish 2>/dev/null | grep -q ^ii; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ]; then
                cleanup_files "$fisher_state"
            fi
            sudo apt purge --auto-remove -y $pkg_fish
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$fish_state" "$HOME/.config/fish"
            echo "Fish Shell desinstalado."
        fi
    elif confirm "Instalar Fish Shell?"; then
        echo "Instalando Fish Shell..."
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
            curl -sL https://git.io/fisher | source
            fish -c "fisher install jorgebucaran/fisher" 2>/dev/null || true
            touch "$fisher_state"
            echo "Fisher instalado."
        else
            echo "Fish Shell não encontrado. Instale o Fish primeiro."
        fi
    fi
}

mise_installer() {
    local state_file="$STATE_DIR/mise"
    
    if [ -f "$state_file" ] || command -v mise >/dev/null 2>&1; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            cleanup_files "$state_file" "$HOME/.mise"
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            if [ -f "$HOME/.bashrc" ]; then
                curl https://mise.run/bash | sh
                mise use -g usage
                mkdir -p ~/.local/share/bash-completion/
                mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
            fi
            if [ -f "$HOME/.zshrc" ] && ! command -v rpm-ostree &>/dev/null; then
                curl https://mise.run/zsh | sh
                mise use -g usage
                mkdir -p /usr/local/share/zsh/site-functions
                mise completion zsh > /usr/local/share/zsh/site-functions/_mise
            fi
            if [ -f "$HOME/.config/fish/config.fish" ]; then
                curl https://mise.run/fish | sh
                mise use -g usage
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
    
    if [ -f "$state_file" ] || dpkg -l nala 2>/dev/null | grep -q ^ii; then
        if confirm "Nala detectado. Desinstalar?"; then
            echo "Desinstalando Nala..."
            sudo apt purge --auto-remove -y $pkg_nala
            cleanup_files "$state_file"
            echo "Nala desinstalado."
        fi
    else
        if confirm "Instalar Nala?"; then
            echo "Instalando Nala..."
            sudo apt install -y $pkg_nala
            touch "$state_file"
            echo "Nala instalado."
        fi
    fi
}

nvidia_proprietary_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"
    
    if [ -f "$state_file" ] || dpkg -l nvidia-driver 2>/dev/null | grep -q ^ii; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            sudo apt purge --auto-remove -y "*nvidia*" "*cuda*"
            cleanup_files "$state_file" "$HOME/cuda-keyring_*.deb"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        if confirm "Instalar Nvidia Proprietário?"; then
            echo "Instalando Nvidia Proprietário..."
            curl -L https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb -o "$HOME/cuda-keyring_1.1-1_all.deb"
            sudo dpkg -i "$HOME/cuda-keyring_1.1-1_all.deb"
            sudo apt update
            sudo apt install -y cuda-drivers
            sudo update-initramfs -u
            sudo update-grub
            touch "$state_file"
            echo "Nvidia Proprietário instalado. Reinicie para aplicar."
        fi
    fi
}

pacstall_installer() {
    local state_file="$STATE_DIR/pacstall"
    
    if [ -f "$state_file" ] || command -v pacstall >/dev/null 2>&1; then
        if confirm "Pacstall detectado. Desinstalar?"; then
            echo "Desinstalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://pacstall.dev/q/uninstall)"
            cleanup_files "$state_file"
            echo "Pacstall desinstalado."
        fi
    else
        if confirm "Instalar Pacstall?"; then
            echo "Instalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"
            touch "$state_file"
            echo "Pacstall instalado."
        fi
    fi
}

starship_installer() {
    local state_file="$STATE_DIR/starship"
    local pkg_starship="starship"
    
    if [ -f "$state_file" ] || dpkg -l starship 2>/dev/null | grep -q ^ii; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            sudo apt purge --auto-remove -y $pkg_starship
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            sudo apt install -y $pkg_starship
            [ -f ~/.bashrc ] && grep -q "starship init" ~/.bashrc || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bashrc
            [ -f ~/.zshrc ] && grep -q "starship init" ~/.zshrc || echo -e "\neval \"\$(starship init zsh)\"" >> ~/.zshrc
            command -v fish &>/dev/null && mkdir -p ~/.config/fish && if [ -f ~/.config/fish/config.fish ]; then grep -q "starship init fish" ~/.config/fish/config.fish || echo -e "\nstarship init fish | source" >> ~/.config/fish/config.fish; else echo -e "starship init fish | source" >> ~/.config/fish/config.fish; fi
            touch "$state_file"
            echo "Starship instalado."
        fi
    fi
}

unmojang_installer() {
    local state_file="$STATE_DIR/unmojang"
    local pkg_fjord="org.unmojang.FjordLauncher"
    
    if [ -f "$state_file" ] || flatpak list --app 2>/dev/null | grep -q org.unmojang.FjordLauncher; then
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

apparmor_installer() {
    local state_file="$STATE_DIR/apparmor"
    local pkg_apparmor="apparmor"
    
    if [ -f "$state_file" ] || dpkg -l apparmor 2>/dev/null | grep -q ^ii; then
        if confirm "AppArmor detectado. Desinstalar?"; then
            echo "Desinstalando AppArmor..."
            sudo systemctl stop apparmor 2>/dev/null || true
            sudo systemctl disable apparmor 2>/dev/null || true
            sudo rm -f /etc/default/grub.d/99-apparmor.cfg 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            sudo apt purge --auto-remove -y $pkg_apparmor
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            sudo apt install -y $pkg_apparmor
            sudo mkdir -p /etc/default/grub.d
            echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} apparmor=1 security=apparmor"' | sudo tee /etc/default/grub.d/99-apparmor.cfg
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado. Reinicie para aplicar."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="libfuse2"
    
    if [ -f "$state_file" ] || dpkg -l libfuse2 2>/dev/null | grep -q ^ii; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            sudo apt purge --auto-remove -y $pkg_fuse
            cleanup_files "$state_file"
            echo "FUSE para AppImage desinstalado."
        fi
    else
        if confirm "Instalar FUSE para AppImage?"; then
            echo "Instalando FUSE para AppImage..."
            sudo apt install -y $pkg_fuse
            touch "$state_file"
            echo "FUSE para AppImage instalado."
        fi
    fi
}

archiving_compression_installer() {
    local state_file="$STATE_DIR/pessoal_compactacao"
    local pkg_compactacao="tar p7zip-full unrar unzip gzip lrzip xz-utils zip lzop"
    
    if [ -f "$state_file" ] || dpkg -l p7zip-full 2>/dev/null | grep -q ^ii; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            sudo apt purge --auto-remove -y $pkg_compactacao
            cleanup_files "$state_file"
            echo "Pacotes de Compactação desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Compactação?"; then
            echo "Instalando Pacotes de Compactação..."
            sudo apt install -y $pkg_compactacao
            touch "$state_file"
            echo "Pacotes de Compactação instalados."
        fi
    fi
}

aria2_installer() {
    local state_file="$STATE_DIR/aria2"
    local pkg_aria2="aria2"
    
    if [ -f "$state_file" ] || dpkg -l aria2 2>/dev/null | grep -q ^ii; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            sudo apt purge --auto-remove -y $pkg_aria2
            cleanup_files "$state_file"
            echo "aria2 desinstalado."
        fi
    else
        if confirm "Instalar aria2?"; then
            echo "Instalando aria2..."
            sudo apt install -y $pkg_aria2
            touch "$state_file"
            echo "aria2 instalado."
        fi
    fi
}

curl_installer() {
    local state_file="$STATE_DIR/curl"
    local pkg_curl="curl"
    
    if [ -f "$state_file" ] || dpkg -l curl 2>/dev/null | grep -q ^ii; then
        if confirm "curl detectado. Desinstalar?"; then
            echo "Desinstalando curl..."
            sudo apt purge --auto-remove -y $pkg_curl
            cleanup_files "$state_file"
            echo "curl desinstalado."
        fi
    else
        if confirm "Instalar curl?"; then
            echo "Instalando curl..."
            sudo apt install -y $pkg_curl
            touch "$state_file"
            echo "curl instalado."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-shell gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds gdm3"
    
    if [ -f "$state_file" ] || dpkg -l gnome-shell 2>/dev/null | grep -q ^ii; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            sudo apt purge --auto-remove -y $pkg_gnome
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            sudo apt install -y $pkg_gnome
            sudo systemctl enable gdm
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="plasma-desktop konsole dolphin kdeconnect partitionmanager ark sddm"
    
    if [ -f "$state_file" ] || dpkg -l plasma-desktop 2>/dev/null | grep -q ^ii; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            sudo apt purge --auto-remove -y $pkg_plasma
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            sudo apt install -y $pkg_plasma
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

faugus_launcher_installer() {
    local state_file="$STATE_DIR/faugus_launcher"
    local pkg_faugus="io.github.Faugus.faugus-launcher"
    
    if [ -f "$state_file" ] || flatpak list --app 2>/dev/null | grep -q io.github.Faugus.faugus-launcher; then
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

fwupd_installer() {
    local state_file="$STATE_DIR/fwupd"
    local pkg_fwupd="fwupd"
    
    if [ -f "$state_file" ] || dpkg -l fwupd 2>/dev/null | grep -q ^ii; then
        if confirm "Fwupd detectado. Desinstalar?"; then
            echo "Desinstalando Fwupd..."
            sudo apt purge --auto-remove -y $pkg_fwupd
            cleanup_files "$state_file"
            echo "Fwupd desinstalado."
        fi
    else
        if confirm "Instalar Fwupd?"; then
            echo "Instalando Fwupd..."
            sudo apt install -y $pkg_fwupd
            touch "$state_file"
            echo "Fwupd instalado."
        fi
    fi
}

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode"
    
    if [ -f "$state_file" ] || dpkg -l gamemode 2>/dev/null | grep -q ^ii; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            sudo apt purge --auto-remove -y $pkg_gamemode
            cleanup_files "$state_file"
            echo "Gamemode desinstalado."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
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

neovim_installer() {
    local state_file="$STATE_DIR/nvim"
    local pkg_neovim="neovim"
    
    if [ -f "$state_file" ] || dpkg -l neovim 2>/dev/null | grep -q ^ii; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            sudo apt purge --auto-remove -y $pkg_neovim
            cleanup_files "$state_file"
            echo "NeoVim desinstalado."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            sudo apt install -y $pkg_neovim
            touch "$state_file"
            echo "NeoVim instalado."
        fi
    fi
}

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-jetbrains-mono"
    
    if [ -f "$state_file" ] || dpkg -l fonts-jetbrains-mono 2>/dev/null | grep -q ^ii; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            sudo apt purge --auto-remove -y $pkg_base
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados."
        fi
    else
        if confirm "Instalar Pacotes Base?"; then
            echo "Instalando Pacotes Base..."
            sudo apt install -y $pkg_base
            touch "$state_file"
            echo "Pacotes Base instalados."
        fi
    fi
}

pessoal_media_installer() {
    local state_file="$STATE_DIR/pessoal_media"
    local pkg_media="ffmpeg gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-alsa"
    
    if [ -f "$state_file" ] || dpkg -l ffmpeg 2>/dev/null | grep -q ^ii; then
        if confirm "Pacotes de Mídia detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Mídia..."
            sudo apt purge --auto-remove -y $pkg_media
            cleanup_files "$state_file"
            echo "Pacotes de Mídia desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Mídia?"; then
            echo "Instalando Pacotes de Mídia..."
            sudo apt install -y $pkg_media
            touch "$state_file"
            echo "Pacotes de Mídia instalados."
        fi
    fi
}

podman_installer() {
    local state_file="$STATE_DIR/podman"
    local pkg_podman="podman podman-compose"
    
    if [ -f "$state_file" ] || dpkg -l podman 2>/dev/null | grep -q ^ii; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            sudo apt purge --auto-remove -y $pkg_podman
            cleanup_files "$state_file"
            echo "Podman desinstalado."
        fi
    else
        if confirm "Instalar Podman?"; then
            echo "Instalando Podman..."
            sudo apt install -y $pkg_podman
            touch "$state_file"
            echo "Podman instalado."
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
        fi
    fi
}

snapd_installer() {
    local state_file="$STATE_DIR/snapd"
    local pkg_snapd="snapd"
    
    if [ -f "$state_file" ] || dpkg -l snapd 2>/dev/null | grep -q ^ii; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket 2>/dev/null || true
            sudo systemctl disable snapd.socket 2>/dev/null || true
            sudo apt purge --auto-remove -y $pkg_snapd
            cleanup_files "$state_file"
            echo "Snapd desinstalado."
        fi
    else
        if confirm "Instalar Snapd?"; then
            echo "Instalando Snapd..."
            sudo apt install -y $pkg_snapd
            sudo systemctl enable --now snapd.socket
            touch "$state_file"
            echo "Snapd instalado."
        fi
    fi
}

steam_installer() {
    local state_file="$STATE_DIR/steam"
    local pkg_steam="com.valvesoftware.Steam"
    
    if [ -f "$state_file" ] || flatpak list --app 2>/dev/null | grep -q com.valvesoftware.Steam; then
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
    
    if [ -f "$state_file" ] || dpkg -l ufw 2>/dev/null | grep -q ^ii; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            systemctl is-active --quiet ufw 2>/dev/null && sudo systemctl stop ufw || true
            systemctl is-enabled --quiet ufw 2>/dev/null && sudo systemctl disable ufw || true
            sudo apt purge --auto-remove -y $pkg_ufw
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw /usr/bin/ufw /usr/sbin/ufw 2>/dev/null || true
            cleanup_files "$state_file"
            echo "UFW desinstalado."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
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

xdg_base_installer() {
    local state_file="$STATE_DIR/xdg_base"
    local pkg_xdg="xdg-user-dirs xdg-utils"
    
    if [ -f "$state_file" ] || dpkg -l xdg-user-dirs 2>/dev/null | grep -q ^ii; then
        if confirm "XDG Base detectado. Desinstalar?"; then
            echo "Desinstalando XDG Base..."
            sudo apt purge --auto-remove -y $pkg_xdg
            cleanup_files "$state_file"
            echo "XDG Base desinstalado."
        fi
    else
        if confirm "Instalar XDG Base?"; then
            echo "Instalando XDG Base..."
            sudo apt install -y $pkg_xdg
            touch "$state_file"
            echo "XDG Base instalado."
        fi
    fi
}

yt_dlp_installer() {
    local state_file="$STATE_DIR/yt_dlp"
    local pkg_ytdlp="yt-dlp"
    
    if [ -f "$state_file" ] || dpkg -l yt-dlp 2>/dev/null | grep -q ^ii; then
        if confirm "yt-dlp detectado. Desinstalar?"; then
            echo "Desinstalando yt-dlp..."
            sudo apt purge --auto-remove -y $pkg_ytdlp
            cleanup_files "$state_file"
            echo "yt-dlp desinstalado."
        fi
    else
        if confirm "Instalar yt-dlp?"; then
            echo "Instalando yt-dlp..."
            sudo apt install -y $pkg_ytdlp
            touch "$state_file"
            echo "yt-dlp instalado."
        fi
    fi
}

zen_browser_installer() {
    local state_file="$STATE_DIR/zen_browser"
    local pkg_zen="app.zen_browser.zen"
    
    if [ -f "$state_file" ] || flatpak list --app 2>/dev/null | grep -q app.zen_browser.zen; then
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
        echo "1)  Repositórios e Sistema Base"
        echo "2)  Shells e Terminais"
        echo "3)  Gerenciadores de Pacotes"
        echo "4)  Drivers e Sistema"
        echo "5)  Utilitários"
        echo "6)  Desktop Environments"
        echo "7)  Flatpaks"
        echo "8)  Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1)
                clear
                echo "=== Repositórios e Sistema Base ==="
                deb_multimedia_installer
                nonfree_repos_installer
                flatpak_flathub_installer
                ufw_installer
                xdg_base_installer
                ;;
            2)
                clear
                echo "=== Shells e Terminais ==="
                fish_fisher_installer
                mise_installer
                starship_installer
                nala_installer
                ;;
            3)
                clear
                echo "=== Gerenciadores de Pacotes ==="
                pacstall_installer
                snapd_installer
                ;;
            4)
                clear
                echo "=== Drivers e Sistema ==="
                nvidia_proprietary_dkms_installer
                apparmor_installer
                gamemode_installer
                fwupd_installer
                shader_booster_installer
                ;;
            5)
                clear
                echo "=== Utilitários ==="
                pessoal_base_installer
                pessoal_media_installer
                yt_dlp_installer
                curl_installer
                appimage_fuse_installer
                aria2_installer
                archiving_compression_installer
                podman_installer
                neovim_installer
                lazyvim_installer
                ;;
            6)
                clear
                echo "=== Desktop Environments ==="
                de_gnome_installer
                de_plasma_installer
                ;;
            7)
                clear
                echo "=== Flatpaks ==="
                unmojang_installer
                faugus_launcher_installer
                steam_installer
                zen_browser_installer
                ;;
            8) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
