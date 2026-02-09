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
    
    if [ -f "$state_file" ]; then
        if confirm "Repositório DebMultimedia detectado. Remover?"; then
            echo "Removendo repositório DebMultimedia..."
            sudo rm -f /etc/apt/sources.list.d/dmo.sources /usr/share/keyrings/deb-multimedia-keyring.pgp 2>/dev/null || true
            cleanup_files "$state_file"
            echo "DebMultimedia removido."
        fi
    else
        if confirm "Adicionar repositório DebMultimedia?"; then
            echo "Adicionando DebMultimedia..."
            curl -fsSL https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb -o /tmp/deb-multimedia-keyring.deb
            sudo dpkg -i /tmp/deb-multimedia-keyring.deb
            rm -f /tmp/deb-multimedia-keyring.deb
            echo 'Types: deb
URIs: https://www.deb-multimedia.org
Suites: trixie
Components: main non-free
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp
Enabled: yes' | sudo tee /etc/apt/sources.list.d/dmo.sources >/dev/null
            apt modernize-sources 2>/dev/null || true
            touch "$state_file"
            echo "DebMultimedia adicionado."
        fi
    fi
}

nonfree_repos_installer() {
    local state_file="$STATE_DIR/nonfree_repos"
    
    if [ -f "$state_file" ]; then
        if confirm "Repositórios NON-FREE detectados. Remover?"; then
            echo "Removendo repositórios NON-FREE..."
            sudo sed -i '/non-free/d' /etc/apt/sources.list
            sudo sed -i '/contrib/d' /etc/apt/sources.list
            cleanup_files "$state_file"
            echo "Repositórios NON-FREE removidos."
        fi
    else
        if confirm "Adicionar repositórios NON-FREE, NON-FREE-FIRMWARE e CONTRIB?"; then
            echo "Adicionando repositórios NON-FREE..."
            sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
            apt modernize-sources 2>/dev/null || true
            sudo apt update
            touch "$state_file"
            echo "Repositórios NON-FREE adicionados."
        fi
    fi
}

apparmor_installer() {
    local state_file="$STATE_DIR/apparmor"
    local pkg_apparmor="apparmor apparmor-utils"
    
    if [ -f "$state_file" ] || dpkg -l apparmor &>/dev/null; then
        if confirm "AppArmor detectado. Desinstalar?"; then
            echo "Desinstalando AppArmor..."
            sudo systemctl stop apparmor 2>/dev/null || true
            sudo systemctl disable apparmor 2>/dev/null || true
            sudo apt purge -y $pkg_apparmor
            sudo apt autoremove -y
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            sudo apt install -y $pkg_apparmor
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="fuse3 libfuse2"
    
    if [ -f "$state_file" ] || dpkg -l fuse3 &>/dev/null; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            sudo apt purge -y $pkg_fuse
            sudo apt autoremove -y
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
    local state_file="$STATE_DIR/compactacao"
    local pkg_compactacao="tar p7zip-full unrar unzip gzip lrzip xz-utils zip lzop"
    
    if [ -f "$state_file" ] || dpkg -l p7zip-full &>/dev/null; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            sudo apt purge -y $pkg_compactacao
            sudo apt autoremove -y
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
    
    if [ -f "$state_file" ] || dpkg -l aria2 &>/dev/null; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            sudo apt purge -y $pkg_aria2
            sudo apt autoremove -y
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
    
    if [ -f "$state_file" ] || dpkg -l curl &>/dev/null; then
        if confirm "curl detectado. Desinstalar?"; then
            echo "Desinstalando curl..."
            sudo apt purge -y $pkg_curl
            sudo apt autoremove -y
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
    local pkg_gnome="gnome-shell gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"
    
    if [ -f "$state_file" ] || dpkg -l gnome-shell &>/dev/null; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            sudo apt purge -y $pkg_gnome
            sudo apt autoremove -y
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
    local pkg_plasma="plasma-desktop konsole dolphin kdeconnect partitionmanager ark"
    
    if [ -f "$state_file" ] || dpkg -l plasma-desktop &>/dev/null; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            sudo apt purge -y $pkg_plasma
            sudo apt autoremove -y
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
    
    if [ -f "$fish_state" ] || dpkg -l fish &>/dev/null; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ]; then
                fish -c "fisher remove jorgebucaran/fisher" 2>/dev/null || true
                cleanup_files "$fisher_state"
            fi
            sudo apt purge -y $pkg_fish
            sudo apt autoremove -y
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
    
    if [ -f "$fisher_state" ] || fish -c "fisher list" 2>/dev/null | grep -q fisher; then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            fish -c "fisher remove jorgebucaran/fisher" 2>/dev/null || true
            cleanup_files "$fisher_state"
            echo "Fisher desinstalado."
        fi
    elif confirm "Instalar Fisher (plugin manager)?"; then
        echo "Instalando Fisher..."
        curl -sL https://git.io/fisher | fish -c "source; fisher install jorgebucaran/fisher"
        touch "$fisher_state"
        echo "Fisher instalado."
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"
    
    if [ -f "$flatpak_state" ] || dpkg -l flatpak &>/dev/null; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            sudo apt purge -y $pkg_flatpak
            sudo apt autoremove -y
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        sudo apt install -y $pkg_flatpak
        if dpkg -l gnome-shell &>/dev/null; then
            sudo apt install -y gnome-software-plugin-flatpak
        elif dpkg -l plasma-desktop &>/dev/null; then
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
    
    if [ -f "$state_file" ] || dpkg -l fwupd &>/dev/null; then
        if confirm "Fwupd detectado. Desinstalar?"; then
            echo "Desinstalando Fwupd..."
            sudo apt purge -y $pkg_fwupd
            sudo apt autoremove -y
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
    
    if [ -f "$state_file" ] || dpkg -l gamemode &>/dev/null; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            sudo apt purge -y $pkg_gamemode
            sudo apt autoremove -y
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

mise_installer() {
    local state_file="$STATE_DIR/mise"
    
    if [ -f "$state_file" ] || command -v mise &>/dev/null; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            rm -f ~/.local/bin/mise
            cleanup_files "$state_file" ~/.local/share/bash-completion/completions/mise /usr/local/share/zsh/site-functions/_mise ~/.config/fish/completions/mise.fish
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            if [ -f "$HOME/.bashrc" ]; then
                curl https://mise.run/bash | sh
                mkdir -p ~/.local/share/bash-completion/
                ~/.local/bin/mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
            fi
            if [ -f "$HOME/.zshrc" ]; then
                curl https://mise.run/zsh | sh
                mkdir -p /usr/local/share/zsh/site-functions 2>/dev/null || true
                ~/.local/bin/mise completion zsh > /usr/local/share/zsh/site-functions/_mise 2>/dev/null || true
            fi
            if [ -f "$HOME/.config/fish/config.fish" ]; then
                curl https://mise.run/fish | sh
                mkdir -p ~/.config/fish/completions
                ~/.local/bin/mise completion fish > ~/.config/fish/completions/mise.fish
            fi
            touch "$state_file"
            echo "Mise instalado."
        fi
    fi
}

nala_installer() {
    local state_file="$STATE_DIR/nala"
    local pkg_nala="nala"
    
    if [ -f "$state_file" ] || dpkg -l nala &>/dev/null; then
        if confirm "Nala detectado. Desinstalar?"; then
            echo "Desinstalando Nala..."
            sudo apt purge -y $pkg_nala
            sudo apt autoremove -y
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

neovim_installer() {
    local state_file="$STATE_DIR/nvim"
    local pkg_neovim="neovim"
    
    if [ -f "$state_file" ] || dpkg -l neovim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            sudo apt purge -y $pkg_neovim
            sudo apt autoremove -y
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

nvidia_proprietary_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"
    
    if [ -f "$state_file" ] || dpkg -l nvidia-driver &>/dev/null; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            sudo apt purge -y nvidia-driver cuda-drivers cuda-toolkit
            sudo apt autoremove -y
            sudo rm -f /etc/apt/preferences.d/nvidia-repo
            sudo update-initramfs -u
            sudo update-grub
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        if confirm "Instalar Nvidia Proprietário com DKMS?"; then
            echo "Instalando Nvidia Proprietário..."
            sudo apt install -y dkms libdw-dev clang lld llvm build-essential linux-headers-amd64 pipewire-audio-client-libraries
            curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
            sudo dpkg -i /tmp/cuda-keyring.deb
            rm -f /tmp/cuda-keyring.deb
            echo 'Package: *
Pin: origin https://developer.download.nvidia.com
Pin-Priority: 900' | sudo tee /etc/apt/preferences.d/nvidia-repo >/dev/null
            sudo apt update
            sudo apt install -y nvidia-open
            sudo update-initramfs -u
            sudo update-grub
            touch "$state_file"
            echo "Nvidia Proprietário instalado. Reinicie para aplicar."
        fi
    fi
}

pacstall_installer() {
    local state_file="$STATE_DIR/pacstall"
    
    if [ -f "$state_file" ] || command -v pacstall &>/dev/null; then
        if confirm "Pacstall detectado. Desinstalar?"; then
            echo "Desinstalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/pacstall/pacstall/master/uninstall.sh)"
            cleanup_files "$state_file"
            echo "Pacstall desinstalado."
        fi
    else
        if confirm "Instalar Pacstall?"; then
            echo "Instalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://git.io/JsADh || wget -q https://git.io/JsADh -O -)"
            touch "$state_file"
            echo "Pacstall instalado."
        fi
    fi
}

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra fonts-noto-cjk-extra fonts-jetbrains-mono"
    
    if [ -f "$state_file" ] || dpkg -l fonts-jetbrains-mono &>/dev/null; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            sudo apt purge -y $pkg_base
            sudo apt autoremove -y
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
    
    if [ -f "$state_file" ] || dpkg -l gstreamer1.0-alsa &>/dev/null; then
        if confirm "Pacotes de Mídia detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Mídia..."
            sudo apt purge -y $pkg_media
            sudo apt autoremove -y
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
    
    if [ -f "$state_file" ] || dpkg -l podman &>/dev/null; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            sudo apt purge -y $pkg_podman
            sudo apt autoremove -y
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
            for shell_file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
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
            
            for file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
                [ -f "$file" ] && dest_file="$file" && break
            done
            [ -z "$dest_file" ] && dest_file="$HOME/.bashrc" && touch "$dest_file"
            
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
    
    if [ -f "$state_file" ] || dpkg -l snapd &>/dev/null; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket 2>/dev/null || true
            sudo systemctl disable snapd.socket 2>/dev/null || true
            sudo apt purge -y $pkg_snapd
            sudo apt autoremove -y
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

starship_installer() {
    local state_file="$STATE_DIR/starship"
    local pkg_starship="starship"
    
    if [ -f "$state_file" ] || dpkg -l starship &>/dev/null; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            sudo apt purge -y $pkg_starship
            sudo apt autoremove -y
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.bash_profile 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            sudo apt install -y $pkg_starship
            [ -f ~/.bashrc ] && grep -q "starship init" ~/.bashrc || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bashrc
            [ -f ~/.bash_profile ] && grep -q "starship init" ~/.bash_profile || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bash_profile
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
    
    if [ -f "$state_file" ] || dpkg -l ufw &>/dev/null; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            sudo systemctl stop ufw 2>/dev/null || true
            sudo systemctl disable ufw 2>/dev/null || true
            sudo apt purge -y $pkg_ufw
            sudo apt autoremove -y
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw 2>/dev/null || true
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
    
    if [ -f "$state_file" ] || dpkg -l xdg-user-dirs &>/dev/null; then
        if confirm "XDG Base detectado. Desinstalar?"; then
            echo "Desinstalando XDG Base..."
            sudo apt purge -y $pkg_xdg
            sudo apt autoremove -y
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

youtube_dl_installer() {
    local state_file="$STATE_DIR/youtube_dl"
    local pkg_ytdl="youtube-dl"
    
    if [ -f "$state_file" ] || dpkg -l youtube-dl &>/dev/null; then
        if confirm "youtube-dl detectado. Desinstalar?"; then
            echo "Desinstalando youtube-dl..."
            sudo apt purge -y $pkg_ytdl
            sudo apt autoremove -y
            cleanup_files "$state_file"
            echo "youtube-dl desinstalado."
        fi
    else
        if confirm "Instalar youtube-dl?"; then
            echo "Instalando youtube-dl..."
            sudo apt install -y $pkg_ytdl
            touch "$state_file"
            echo "youtube-dl instalado."
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
        echo "1)  AppArmor"
        echo "2)  AppImage FUSE"
        echo "3)  Aria2"
        echo "4)  Compactação"
        echo "5)  curl"
        echo "6)  DebMultimedia"
        echo "7)  Faugus Launcher"
        echo "8)  Fish Shell + Fisher"
        echo "9)  Flatpak + Flathub"
        echo "10) Fwupd"
        echo "11) Gamemode"
        echo "12) GNOME Desktop"
        echo "13) LazyVim"
        echo "14) Mise"
        echo "15) Nala"
        echo "16) NeoVim"
        echo "17) NON-FREE Repositórios"
        echo "18) NVIDIA Drivers"
        echo "19) Pacstall"
        echo "20) Pacotes Base"
        echo "21) Pacotes de Mídia"
        echo "22) Plasma Desktop"
        echo "23) Podman"
        echo "24) Shader Booster"
        echo "25) Snapd"
        echo "26) Starship"
        echo "27) Steam"
        echo "28) UFW"
        echo "29) Unmojang (Fjord)"
        echo "30) XDG Base"
        echo "31) youtube-dl"
        echo "32) Zen Browser"
        echo "33) Sair"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) apparmor_installer ;;
            2) appimage_fuse_installer ;;
            3) aria2_installer ;;
            4) archiving_compression_installer ;;
            5) curl_installer ;;
            6) deb_multimedia_installer ;;
            7) faugus_launcher_installer ;;
            8) fish_fisher_installer ;;
            9) flatpak_flathub_installer ;;
            10) fwupd_installer ;;
            11) gamemode_installer ;;
            12) de_gnome_installer ;;
            13) lazyvim_installer ;;
            14) mise_installer ;;
            15) nala_installer ;;
            16) neovim_installer ;;
            17) nonfree_repos_installer ;;
            18) nvidia_proprietary_dkms_installer ;;
            19) pacstall_installer ;;
            20) pessoal_base_installer ;;
            21) pessoal_media_installer ;;
            22) de_plasma_installer ;;
            23) podman_installer ;;
            24) shader_booster_installer ;;
            25) snapd_installer ;;
            26) starship_installer ;;
            27) steam_installer ;;
            28) ufw_installer ;;
            29) unmojang_installer ;;
            30) xdg_base_installer ;;
            31) youtube_dl_installer ;;
            32) zen_browser_installer ;;
            33) exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
