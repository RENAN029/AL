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

fish_fisher_installer() {
    local fish_state="$STATE_DIR/fish"
    local fisher_state="$STATE_DIR/fisher"
    local pkg_fish="fish"

    if [ -f "$fish_state" ] || dpkg -l fish &>/dev/null; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ] || [ -f "$HOME/.config/fish/functions/fisher.fish" ]; then
                rm -f "$HOME/.config/fish/functions/fisher.fish" 2>/dev/null || true
                cleanup_files "$fisher_state"
            fi
            sudo apt remove -y --purge $pkg_fish
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$fish_state" "$HOME/.config/fish"
            echo "Fish Shell desinstalado."
        fi
    elif confirm "Instalar Fish Shell?"; then
        echo "Instalando Fish Shell..."
        sudo apt update && sudo apt install -y $pkg_fish
        sudo chsh -s "$(which fish)" "$USER"
        mkdir -p ~/.config/fish
        echo "set fish_greeting" > ~/.config/fish/config.fish
        touch "$fish_state"
        echo "Fish Shell instalado."
    fi

    if [ -f "$fisher_state" ] || [ -f "$HOME/.config/fish/functions/fisher.fish" ]; then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            rm -f "$HOME/.config/fish/functions/fisher.fish" 2>/dev/null || true
            cleanup_files "$fisher_state"
            echo "Fisher desinstalado."
        fi
    elif confirm "Instalar Fisher (plugin manager)?"; then
        echo "Instalando Fisher..."
        if command -v fish >/dev/null 2>&1; then
            fish -c "curl -sL https://git.io/fisher | source; fisher install jorgebucaran/fisher" 2>/dev/null || true
            touch "$fisher_state"
            echo "Fisher instalado."
        fi
    fi
}

mise_installer() {
    local state_file="$STATE_DIR/mise"

    if [ -f "$state_file" ] || command -v mise &>/dev/null; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            if [ -f "$HOME/.bashrc" ]; then
                sed -i '/mise.sh/d' ~/.bashrc 2>/dev/null || true
            fi
            if [ -f "$HOME/.zshrc" ]; then
                sed -i '/mise.sh/d' ~/.zshrc 2>/dev/null || true
            fi
            if [ -f "$HOME/.config/fish/config.fish" ]; then
                sed -i '/mise.fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            fi
            cleanup_files "$state_file"
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
                mise use -g usage
                sudo mkdir -p /usr/local/share/zsh/site-functions 2>/dev/null || true
                mise completion zsh | sudo tee /usr/local/share/zsh/site-functions/_mise >/dev/null
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

starship_installer() {
    local state_file="$STATE_DIR/starship"
    local pkg_starship="starship"

    if [ -f "$state_file" ] || dpkg -l starship &>/dev/null; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            sudo apt remove -y --purge $pkg_starship
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            sudo apt update && sudo apt install -y $pkg_starship
            [ -f ~/.bashrc ] && grep -q "starship init" ~/.bashrc || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bashrc
            [ -f ~/.zshrc ] && grep -q "starship init" ~/.zshrc || echo -e "\neval \"\$(starship init zsh)\"" >> ~/.zshrc
            command -v fish &>/dev/null && mkdir -p ~/.config/fish && if [ -f ~/.config/fish/config.fish ]; then grep -q "starship init fish" ~/.config/fish/config.fish || echo -e "\nstarship init fish | source" >> ~/.config/fish/config.fish; else echo -e "starship init fish | source" >> ~/.config/fish/config.fish; fi
            touch "$state_file"
            echo "Starship instalado."
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
            sudo apt remove -y --purge $pkg_snapd
            cleanup_files "$state_file"
            echo "Snapd desinstalado."
        fi
    else
        if confirm "Instalar Snapd?"; then
            echo "Instalando Snapd..."
            sudo apt update && sudo apt install -y $pkg_snapd
            sudo systemctl enable --now snapd.socket
            touch "$state_file"
            echo "Snapd instalado."
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
            sudo apt remove -y --purge $pkg_xdg
            cleanup_files "$state_file"
            echo "XDG Base desinstalado."
        fi
    else
        if confirm "Instalar XDG Base?"; then
            echo "Instalando XDG Base..."
            sudo apt update && sudo apt install -y $pkg_xdg
            touch "$state_file"
            echo "XDG Base instalado."
        fi
    fi
}

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra fonts-noto-cjk-extra fonts-jetbrains-mono"

    if [ -f "$state_file" ] || dpkg -l fonts-jetbrains-mono &>/dev/null; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            sudo apt remove -y --purge $pkg_base
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados."
        fi
    else
        if confirm "Instalar Pacotes Base?"; then
            echo "Instalando Pacotes Base..."
            sudo apt update && sudo apt install -y $pkg_base
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
            sudo apt remove -y --purge $pkg_media
            cleanup_files "$state_file"
            echo "Pacotes de Mídia desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Mídia?"; then
            echo "Instalando Pacotes de Mídia..."
            sudo apt update && sudo apt install -y $pkg_media
            touch "$state_file"
            echo "Pacotes de Mídia instalados."
        fi
    fi
}

yt_dlp_installer() {
    local state_file="$STATE_DIR/yt_dlp"
    local pkg_ytdlp="yt-dlp"

    if [ -f "$state_file" ] || dpkg -l yt-dlp &>/dev/null; then
        if confirm "yt-dlp detectado. Desinstalar?"; then
            echo "Desinstalando yt-dlp..."
            sudo apt remove -y --purge $pkg_ytdlp
            cleanup_files "$state_file"
            echo "yt-dlp desinstalado."
        fi
    else
        if confirm "Instalar yt-dlp?"; then
            echo "Instalando yt-dlp..."
            sudo apt update && sudo apt install -y $pkg_ytdlp
            touch "$state_file"
            echo "yt-dlp instalado."
        fi
    fi
}

nvidia_proprietary_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"
    local pkg_nvidia="nvidia-driver"

    if [ -f "$state_file" ] || dpkg -l nvidia-driver &>/dev/null; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            sudo apt remove -y --purge '*nvidia*' cuda-keyring
            sudo apt autoremove -y
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        if confirm "Instalar Nvidia Proprietário?"; then
            echo "Instalando Nvidia Proprietário..."
            curl -O https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
            sudo dpkg -i cuda-keyring_1.1-1_all.deb
            sudo apt update
            sudo apt install -y cuda-drivers nvidia-settings
            sudo update-initramfs -u
            sudo update-grub
            rm -f cuda-keyring_1.1-1_all.deb
            touch "$state_file"
            echo "Nvidia Proprietário instalado. Reinicie para aplicar."
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

curl_installer() {
    local state_file="$STATE_DIR/curl"
    local pkg_curl="curl"

    if [ -f "$state_file" ] || dpkg -l curl &>/dev/null; then
        if confirm "curl detectado. Desinstalar?"; then
            echo "Desinstalando curl..."
            sudo apt remove -y --purge $pkg_curl
            cleanup_files "$state_file"
            echo "curl desinstalado."
        fi
    else
        if confirm "Instalar curl?"; then
            echo "Instalando curl..."
            sudo apt update && sudo apt install -y $pkg_curl
            touch "$state_file"
            echo "curl instalado."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="fuse3 libfuse2"

    if [ -f "$state_file" ] || dpkg -l fuse3 &>/dev/null; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            sudo apt remove -y --purge $pkg_fuse
            cleanup_files "$state_file"
            echo "FUSE para AppImage desinstalado."
        fi
    else
        if confirm "Instalar FUSE para AppImage?"; then
            echo "Instalando FUSE para AppImage..."
            sudo apt update && sudo apt install -y $pkg_fuse
            touch "$state_file"
            echo "FUSE para AppImage instalado."
        fi
    fi
}

aria2_installer() {
    local state_file="$STATE_DIR/aria2"
    local pkg_aria2="aria2"

    if [ -f "$state_file" ] || dpkg -l aria2 &>/dev/null; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            sudo apt remove -y --purge $pkg_aria2
            cleanup_files "$state_file"
            echo "aria2 desinstalado."
        fi
    else
        if confirm "Instalar aria2?"; then
            echo "Instalando aria2..."
            sudo apt update && sudo apt install -y $pkg_aria2
            touch "$state_file"
            echo "aria2 instalado."
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

ufw_installer() {
    local state_file="$STATE_DIR/ufw"
    local pkg_ufw="ufw"

    if [ -f "$state_file" ] || dpkg -l ufw &>/dev/null; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            sudo systemctl stop ufw 2>/dev/null || true
            sudo systemctl disable ufw 2>/dev/null || true
            sudo apt remove -y --purge $pkg_ufw
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw 2>/dev/null || true
            cleanup_files "$state_file"
            echo "UFW desinstalado."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
            sudo apt update && sudo apt install -y $pkg_ufw
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

archiving_compression_installer() {
    local state_file="$STATE_DIR/pessoal_compactacao"
    local pkg_compactacao="tar p7zip-full unrar unzip gzip lrzip xz-utils zip lzop"

    if [ -f "$state_file" ] || dpkg -l p7zip-full &>/dev/null; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            sudo apt remove -y --purge $pkg_compactacao
            cleanup_files "$state_file"
            echo "Pacotes de Compactação desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Compactação?"; then
            echo "Instalando Pacotes de Compactação..."
            sudo apt update && sudo apt install -y $pkg_compactacao
            touch "$state_file"
            echo "Pacotes de Compactação instalados."
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
            sudo apt remove -y --purge $pkg_apparmor
            sudo sed -i '/apparmor=1/d' /etc/default/grub 2>/dev/null || true
            sudo update-grub 2>/dev/null
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            sudo apt update && sudo apt install -y $pkg_apparmor
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 apparmor=1 security=apparmor"/' /etc/default/grub
            sudo update-grub
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado. Reinicie para aplicar."
        fi
    fi
}

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode"

    if [ -f "$state_file" ] || dpkg -l gamemode &>/dev/null; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            sudo apt remove -y --purge $pkg_gamemode
            cleanup_files "$state_file"
            echo "Gamemode desinstalado."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
            sudo apt update && sudo apt install -y $pkg_gamemode
            touch "$state_file"
            echo "Gamemode instalado."
        fi
    fi
}

fwupd_installer() {
    local state_file="$STATE_DIR/fwupd"
    local pkg_fwupd="fwupd"

    if [ -f "$state_file" ] || dpkg -l fwupd &>/dev/null; then
        if confirm "Fwupd detectado. Desinstalar?"; then
            echo "Desinstalando Fwupd..."
            sudo apt remove -y --purge $pkg_fwupd
            cleanup_files "$state_file"
            echo "Fwupd desinstalado."
        fi
    else
        if confirm "Instalar Fwupd?"; then
            echo "Instalando Fwupd..."
            sudo apt update && sudo apt install -y $pkg_fwupd
            touch "$state_file"
            echo "Fwupd instalado."
        fi
    fi
}

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"

    if [ -f "$flatpak_state" ] || dpkg -l flatpak &>/dev/null; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            sudo apt remove -y --purge $pkg_flatpak
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        sudo apt update && sudo apt install -y $pkg_flatpak
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

neovim_installer() {
    local state_file="$STATE_DIR/nvim"
    local pkg_neovim="neovim"

    if [ -f "$state_file" ] || dpkg -l neovim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            sudo apt remove -y --purge $pkg_neovim
            cleanup_files "$state_file"
            echo "NeoVim desinstalado."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            sudo apt update && sudo apt install -y $pkg_neovim
            touch "$state_file"
            echo "NeoVim instalado."
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

podman_installer() {
    local state_file="$STATE_DIR/podman"
    local pkg_podman="podman podman-compose"

    if [ -f "$state_file" ] || dpkg -l podman &>/dev/null; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            sudo apt remove -y --purge $pkg_podman
            cleanup_files "$state_file"
            echo "Podman desinstalado."
        fi
    else
        if confirm "Instalar Podman?"; then
            echo "Instalando Podman..."
            sudo apt update && sudo apt install -y $pkg_podman
            touch "$state_file"
            echo "Podman instalado."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-shell gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds gdm3"

    if [ -f "$state_file" ] || dpkg -l gnome-shell &>/dev/null; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm3 2>/dev/null || true
            sudo apt remove -y --purge $pkg_gnome
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            sudo apt update && sudo apt install -y $pkg_gnome
            sudo systemctl enable gdm3
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="plasma-desktop konsole dolphin kdeconnect partitionmanager ark sddm"

    if [ -f "$state_file" ] || dpkg -l plasma-desktop &>/dev/null; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            sudo apt remove -y --purge $pkg_plasma
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            sudo apt update && sudo apt install -y $pkg_plasma
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
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

cachyconfs_installer() {
    local state_file="$STATE_DIR/cachyconfs"

    if [ -f "$state_file" ] || [ -f "/etc/sysctl.d/99-cachyos-settings.conf" ]; then
        if confirm "CachyOS Configs detectado. Desinstalar?"; then
            sudo rm -f /etc/sysctl.d/99-cachyos-settings.conf
            sudo sysctl --system
            cleanup_files "$state_file"
        fi
    else
        if confirm "Instalar CachyOS Configs?"; then
            curl -s https://raw.githubusercontent.com/CachyOS/CachyOS-Settings/main/sysctl/99-cachyos-settings.conf | sudo tee /etc/sysctl.d/99-cachyos-settings.conf > /dev/null
            sudo sysctl --system
            touch "$state_file"
        fi
    fi
}

zsh_ohmyzsh_installer() {
    local zsh_state="$STATE_DIR/zsh"
    local ohmyzsh_state="$STATE_DIR/ohmyzsh"
    local pkg_zsh="zsh"

    if [ -f "$zsh_state" ] || dpkg -l zsh &>/dev/null; then
        if confirm "Zsh detectado. Desinstalar?"; then
            echo "Desinstalando Zsh..."
            if [ -f "$ohmyzsh_state" ] || [ -d "$HOME/.oh-my-zsh" ]; then
                [ -d "$HOME/.oh-my-zsh" ] && {
                    chmod +x "$HOME/.oh-my-zsh/tools/uninstall.sh"
                    yes | "$HOME/.oh-my-zsh/tools/uninstall.sh"
                }
                cleanup_files "$ohmyzsh_state"
            fi
            sudo apt remove -y --purge $pkg_zsh
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$zsh_state" "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc.backup"
            echo "Zsh desinstalado."
        fi
    elif confirm "Instalar Zsh?"; then
        echo "Instalando Zsh..."
        sudo apt update && sudo apt install -y $pkg_zsh
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

deb_multimedia_installer() {
    local state_file="$STATE_DIR/deb_multimedia"
    local keyring_file="deb-multimedia-keyring_2024.9.1_all.deb"

    if [ -f "$state_file" ] || [ -f "/etc/apt/sources.list.d/deb-multimedia.sources" ]; then
        if confirm "DebMultimedia detectado. Desinstalar?"; then
            echo "Desinstalando DebMultimedia..."
            sudo rm -f /etc/apt/sources.list.d/deb-multimedia.sources
            sudo apt update
            cleanup_files "$state_file" "$keyring_file"
            echo "DebMultimedia desinstalado."
        fi
    else
        if confirm "Instalar repositório DebMultimedia?"; then
            echo "Instalando DebMultimedia..."
            curl -O https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb
            sudo dpkg -i $keyring_file
            echo "Types: deb
URIs: https://www.deb-multimedia.org
Suites: forky
Components: main non-free
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.gpg
Enabled: yes" | sudo tee /etc/apt/sources.list.d/deb-multimedia.sources > /dev/null
            sudo apt update
            cleanup_files "$keyring_file"
            touch "$state_file"
            echo "DebMultimedia instalado."
        fi
    fi
}

nonfree_contrib_installer() {
    local state_file="$STATE_DIR/nonfree_contrib"

    if [ -f "$state_file" ] || grep -q "contrib" /etc/apt/sources.list; then
        if confirm "Repositórios non-free e contrib detectados. Remover?"; then
            echo "Removendo non-free e contrib..."
            sudo sed -i 's/ main non-free-firmware/ main/' /etc/apt/sources.list
            sudo sed -i 's/ main non-free-firmware/ main/' /etc/apt/sources.list.d/*.list 2>/dev/null || true
            sudo apt update
            cleanup_files "$state_file"
            echo "Repositórios removidos."
        fi
    else
        if confirm "Adicionar repositórios non-free e contrib?"; then
            echo "Adicionando non-free e contrib..."
            sudo sed -i 's/ main/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
            sudo apt update
            touch "$state_file"
            echo "Repositórios adicionados."
        fi
    fi
}

zswap_installer() {
    local state_file="$STATE_DIR/zswap"

    if [ -f "$state_file" ] || grep -q "zswap.enabled=1" /etc/default/grub; then
        if confirm "ZSWAP detectado. Desinstalar?"; then
            echo "Desinstalando ZSWAP..."
            sudo sed -i 's/ apparmor=1 security=apparmor zswap.enabled=1//g' /etc/default/grub
            sudo update-grub
            cleanup_files "$state_file"
            echo "ZSWAP desinstalado."
        fi
    else
        if confirm "Ativar ZSWAP?"; then
            echo "Ativando ZSWAP..."
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 zswap.enabled=1"/' /etc/default/grub
            sudo update-grub
            touch "$state_file"
            echo "ZSWAP ativado. Reinicie para aplicar."
        fi
    fi
}

nala_installer() {
    local state_file="$STATE_DIR/nala"
    local pkg_nala="nala"

    if [ -f "$state_file" ] || dpkg -l nala &>/dev/null; then
        if confirm "Nala detectado. Desinstalar?"; then
            echo "Desinstalando Nala..."
            sudo apt remove -y --purge $pkg_nala
            cleanup_files "$state_file"
            echo "Nala desinstalado."
        fi
    else
        if confirm "Instalar Nala?"; then
            echo "Instalando Nala..."
            sudo apt update && sudo apt install -y $pkg_nala
            touch "$state_file"
            echo "Nala instalado."
        fi
    fi
}

pacstall_installer() {
    local state_file="$STATE_DIR/pacstall"

    if [ -f "$state_file" ] || command -v pacstall &>/dev/null; then
        if confirm "Pacstall detectado. Desinstalar?"; then
            echo "Desinstalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://git.io/JsADh || wget -q https://git.io/JsADh -O -)"
            cleanup_files "$state_file"
            echo "Pacstall desinstalado."
        fi
    else
        if confirm "Instalar Pacstall?"; then
            echo "Instalando Pacstall..."
            sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install || wget -q https://pacstall.dev/q/install -O -)"
            touch "$state_file"
            echo "Pacstall instalado."
        fi
    fi
}

main_menu() {
    while true; do
        clear
        echo "=== Debian Scripts ==="
        echo "1) Shells e Terminais"
        echo "2) Mídia e Codecs"
        echo "3) Jogos e Launchers"
        echo "4) Segurança e Sistema"
        echo "5) Desktops"
        echo "6) Ferramentas e Utilitários"
        echo "7) Repositórios Extras"
        echo "8) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1)
                fish_fisher_installer
                zsh_ohmyzsh_installer
                starship_installer
                neovim_installer
                lazyvim_installer
                ;;
            2)
                pessoal_media_installer
                yt_dlp_installer
                curl_installer
                aria2_installer
                appimage_fuse_installer
                ;;
            3)
                steam_installer
                faugus_launcher_installer
                unmojang_installer
                gamemode_installer
                shader_booster_installer
                ;;
            4)
                ufw_installer
                apparmor_installer
                fwupd_installer
                podman_installer
                ;;
            5)
                de_gnome_installer
                de_plasma_installer
                flatpak_flathub_installer
                xdg_base_installer
                ;;
            6)
                pessoal_base_installer
                archiving_compression_installer
                mise_installer
                snapd_installer
                zen_browser_installer
                affinity_installer
                cachyconfs_installer
                ;;
            7)
                deb_multimedia_installer
                nonfree_contrib_installer
                nvidia_proprietary_dkms_installer
                zswap_installer
                nala_installer
                pacstall_installer
                ;;
            8) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
