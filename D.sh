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

apt_install() {
    sudo apt install -y "$@"
}

apt_remove() {
    local pkg="$1"
    if dpkg -l "$pkg" &>/dev/null; then
        sudo apt remove --purge -y "$pkg"
        sudo apt autoremove -y
    fi
}

fish_fisher_installer() {
    local fish_state="$STATE_DIR/fish"
    local fisher_state="$STATE_DIR/fisher"
    local pkg_fish="fish"
    local pkg_fisher="fisher"

    if [ -f "$fish_state" ] || dpkg -l fish &>/dev/null; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ]; then
                if command -v fish >/dev/null; then
                    fish -c "fisher remove jorgebucaran/fisher" 2>/dev/null || true
                fi
                cleanup_files "$fisher_state"
            fi
            apt_remove "$pkg_fish"
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$fish_state" "$HOME/.config/fish"
            echo "Fish Shell desinstalado."
        fi
    elif confirm "Instalar Fish Shell?"; then
        echo "Instalando Fish Shell..."
        apt_install "$pkg_fish"
        sudo chsh -s "$(which fish)" "$USER"
        mkdir -p ~/.config/fish
        echo "set fish_greeting" > ~/.config/fish/config.fish
        touch "$fish_state"
        echo "Fish Shell instalado."
    fi

    if [ -f "$fisher_state" ] || (command -v fish >/dev/null && fish -c "functions -q fisher" 2>/dev/null); then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            if command -v fish >/dev/null; then
                fish -c "fisher remove jorgebucaran/fisher" 2>/dev/null || true
            fi
            cleanup_files "$fisher_state"
            echo "Fisher desinstalado."
        fi
    elif confirm "Instalar Fisher (plugin manager)?"; then
        echo "Instalando Fisher..."
        if command -v fish >/dev/null; then
            fish -c "curl -sL https://git.io/fisher | source; fisher install jorgebucaran/fisher" 2>/dev/null || true
            touch "$fisher_state"
            echo "Fisher instalado."
        else
            echo "Fish Shell não encontrado. Instale primeiro."
        fi
    fi
}

mise_installer() {
    local state_file="$STATE_DIR/mise"

    if [ -f "$state_file" ] || command -v mise &>/dev/null; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            [ -f "$HOME/.bashrc" ] && sed -i '/mise/d' "$HOME/.bashrc"
            [ -f "$HOME/.zshrc" ] && sed -i '/mise/d' "$HOME/.zshrc"
            [ -f "$HOME/.config/fish/config.fish" ] && sed -i '/mise/d' "$HOME/.config/fish/config.fish"
            rm -rf "$HOME/.local/share/mise" "$HOME/.config/mise" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            if [ -f "$HOME/.bashrc" ]; then
                curl https://mise.run/bash | sh
                mkdir -p ~/.local/share/bash-completion/
                mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise 2>/dev/null || true
            fi
            if [ -f "$HOME/.zshrc" ]; then
                curl https://mise.run/zsh | sh
                mkdir -p /usr/local/share/zsh/site-functions 2>/dev/null
                mise completion zsh > /usr/local/share/zsh/site-functions/_mise 2>/dev/null || true
            fi
            if [ -f "$HOME/.config/fish/config.fish" ]; then
                curl https://mise.run/fish | sh
                mkdir -p ~/.config/fish/completions
                mise completion fish > ~/.config/fish/completions/mise.fish 2>/dev/null || true
            fi
            touch "$state_file"
            echo "Mise instalado."
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
            rm -rf "$HOME/.local/share/starship" 2>/dev/null || true
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

snapd_installer() {
    local state_file="$STATE_DIR/snapd"
    local pkg_snapd="snapd"

    if [ -f "$state_file" ] || dpkg -l snapd &>/dev/null; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket snapd.service 2>/dev/null || true
            sudo systemctl disable snapd.socket snapd.service 2>/dev/null || true
            apt_remove "$pkg_snapd"
            cleanup_files "$state_file"
            echo "Snapd desinstalado."
        fi
    else
        if confirm "Instalar Snapd?"; then
            echo "Instalando Snapd..."
            apt_install "$pkg_snapd"
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
            apt_remove "$pkg_xdg"
            cleanup_files "$state_file"
            echo "XDG Base desinstalado."
        fi
    else
        if confirm "Instalar XDG Base?"; then
            echo "Instalando XDG Base..."
            apt_install "$pkg_xdg"
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
            apt_remove "$pkg_base"
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados."
        fi
    else
        if confirm "Instalar Pacotes Base?"; then
            echo "Instalando Pacotes Base..."
            apt_install "$pkg_base"
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
            apt_remove "$pkg_media"
            cleanup_files "$state_file"
            echo "Pacotes de Mídia desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Mídia?"; then
            echo "Instalando Pacotes de Mídia..."
            apt_install "$pkg_media"
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
            apt_remove "$pkg_ytdlp"
            cleanup_files "$state_file"
            echo "yt-dlp desinstalado."
        fi
    else
        if confirm "Instalar yt-dlp?"; then
            echo "Instalando yt-dlp..."
            apt_install "$pkg_ytdlp"
            touch "$state_file"
            echo "yt-dlp instalado."
        fi
    fi
}

nvidia_proprietary_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"

    if [ -f "$state_file" ] || dpkg -l nvidia-driver &>/dev/null || dpkg -l cuda-drivers &>/dev/null; then
        if confirm "Nvidia Proprietário detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário..."
            apt_remove "nvidia-driver"
            apt_remove "cuda-drivers"
            apt_remove "nvidia-open"
            sudo rm -f /etc/apt/preferences.d/nvidia-repo 2>/dev/null
            sudo rm -f /etc/apt/sources.list.d/cuda* 2>/dev/null
            sudo update-initramfs -u
            sudo update-grub
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        if confirm "Instalar Nvidia Proprietário?"; then
            echo "Instalando Nvidia Proprietário..."
            sudo apt install --no-install-recommends -y dkms libdw-dev clang lld llvm build-essential linux-headers-amd64 pipewire-audio-client-libraries
            curl -O https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
            sudo dpkg -i cuda-keyring_1.1-1_all.deb
            sudo apt update
            echo -e "Package: *\nPin: origin https://developer.download.nvidia.com\nPin-Priority: 900" | sudo tee /etc/apt/preferences.d/nvidia-repo
            apt_install nvidia-open
            sudo update-initramfs -u
            sudo update-grub
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
            apt_remove "$pkg_curl"
            cleanup_files "$state_file"
            echo "curl desinstalado."
        fi
    else
        if confirm "Instalar curl?"; then
            echo "Instalando curl..."
            apt_install "$pkg_curl"
            touch "$state_file"
            echo "curl instalado."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="fuse libfuse2"

    if [ -f "$state_file" ] || dpkg -l libfuse2 &>/dev/null; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            apt_remove "$pkg_fuse"
            cleanup_files "$state_file"
            echo "FUSE para AppImage desinstalado."
        fi
    else
        if confirm "Instalar FUSE para AppImage?"; then
            echo "Instalando FUSE para AppImage..."
            apt_install "$pkg_fuse"
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
            apt_remove "$pkg_aria2"
            cleanup_files "$state_file"
            echo "aria2 desinstalado."
        fi
    else
        if confirm "Instalar aria2?"; then
            echo "Instalando aria2..."
            apt_install "$pkg_aria2"
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
            systemctl is-active --quiet ufw 2>/dev/null && sudo systemctl stop ufw || true
            systemctl is-enabled --quiet ufw 2>/dev/null && sudo systemctl disable ufw || true
            apt_remove "$pkg_ufw"
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw /usr/bin/ufw /usr/sbin/ufw 2>/dev/null || true
            cleanup_files "$state_file"
            echo "UFW desinstalado."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
            apt_install "$pkg_ufw"
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
    local pkg_compactacao="tar 7zip unrar unzip gzip lrzip xz-utils zip lzop"

    if [ -f "$state_file" ] || dpkg -l 7zip &>/dev/null; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            apt_remove "$pkg_compactacao"
            cleanup_files "$state_file"
            echo "Pacotes de Compactação desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Compactação?"; then
            echo "Instalando Pacotes de Compactação..."
            apt_install "$pkg_compactacao"
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
            apt_remove "$pkg_apparmor"
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            apt_install "$pkg_apparmor"
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado."
        fi
    fi
}

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode"

    if [ -f "$state_file" ] || dpkg -l gamemode &>/dev/null; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            apt_remove "$pkg_gamemode"
            cleanup_files "$state_file"
            echo "Gamemode desinstalado."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
            apt_install "$pkg_gamemode"
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
            apt_remove "$pkg_fwupd"
            cleanup_files "$state_file"
            echo "Fwupd desinstalado."
        fi
    else
        if confirm "Instalar Fwupd?"; then
            echo "Instalando Fwupd..."
            apt_install "$pkg_fwupd"
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
            apt_remove "$pkg_flatpak"
            flatpak remote-delete flathub 2>/dev/null || true
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        apt_install "$pkg_flatpak"
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
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        touch "$flathub_state"
        echo "Flathub adicionado."
    fi
}

flatpak_plugin_installer() {
    local state_file="$STATE_DIR/flatpak_plugin"

    if [ -f "$state_file" ]; then
        if confirm "Plugin Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Plugin Flatpak..."
            sudo apt remove --purge -y gnome-software-plugin-flatpak plasma-discover-backend-flatpak 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Plugin Flatpak desinstalado."
        fi
    else
        if confirm "Instalar Plugin Flatpak para o seu DE?"; then
            echo "Instalando Plugin Flatpak..."
            if [ -f "/usr/bin/gnome-shell" ]; then
                sudo apt install -y gnome-software-plugin-flatpak
            elif [ -f "/usr/bin/plasmashell" ]; then
                sudo apt install -y plasma-discover-backend-flatpak
            fi
            touch "$state_file"
            echo "Plugin Flatpak instalado."
        fi
    fi
}

neovim_installer() {
    local state_file="$STATE_DIR/nvim"
    local pkg_neovim="neovim"

    if [ -f "$state_file" ] || dpkg -l neovim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            apt_remove "$pkg_neovim"
            cleanup_files "$state_file"
            echo "NeoVim desinstalado."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            apt_install "$pkg_neovim"
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
            apt_remove "$pkg_podman"
            cleanup_files "$state_file"
            echo "Podman desinstalado."
        fi
    else
        if confirm "Instalar Podman?"; then
            echo "Instalar Podman..."
            apt_install "$pkg_podman"
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
            sudo systemctl disable gdm 2>/dev/null || true
            apt_remove "$pkg_gnome"
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            apt_install "$pkg_gnome"
            sudo systemctl enable gdm
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
            apt_remove "$pkg_plasma"
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            apt_install "$pkg_plasma"
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

pacstall_installer() {
    local state_file="$STATE_DIR/pacstall"

    if [ -f "$state_file" ] || command -v pacstall &>/dev/null; then
        if confirm "Pacstall detectado. Desinstalar?"; then
            echo "Desinstalando Pacstall..."
            sudo bash -c "$(curl -s https://pacstall.dev/q/uninstall -)"
            cleanup_files "$state_file"
            echo "Pacstall desinstalado."
        fi
    else
        if confirm "Instalar Pacstall?"; then
            echo "Instalando Pacstall..."
            sudo bash -c "$(curl -s https://pacstall.dev/q/install -)"
            touch "$state_file"
            echo "Pacstall instalado."
        fi
    fi
}

nala_installer() {
    local state_file="$STATE_DIR/nala"
    local pkg_nala="nala"

    if [ -f "$state_file" ] || dpkg -l nala &>/dev/null; then
        if confirm "Nala detectado. Desinstalar?"; then
            echo "Desinstalando Nala..."
            apt_remove "$pkg_nala"
            cleanup_files "$state_file"
            echo "Nala desinstalado."
        fi
    else
        if confirm "Instalar Nala?"; then
            echo "Instalando Nala..."
            apt_install "$pkg_nala"
            touch "$state_file"
            echo "Nala instalado."
        fi
    fi
}

debmultimedia_repo_installer() {
    local state_file="$STATE_DIR/debmultimedia"

    if [ -f "$state_file" ] || [ -f "/etc/apt/sources.list.d/dmo.sources" ] || [ -f "/etc/apt/sources.list.d/deb-multimedia.list" ]; then
        if confirm "Repositório DebMultimedia detectado. Remover?"; then
            echo "Removendo repositório DebMultimedia..."
            sudo rm -f /etc/apt/sources.list.d/dmo.sources /etc/apt/sources.list.d/deb-multimedia.list 2>/dev/null
            sudo apt update
            cleanup_files "$state_file"
            echo "Repositório DebMultimedia removido."
        fi
    else
        if confirm "Adicionar repositório DebMultimedia?"; then
            echo "Adicionando repositório DebMultimedia..."
            curl -O https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb
            sudo dpkg -i deb-multimedia-keyring_2024.9.1_all.deb
            echo -e "Types: deb\nURIs: https://www.deb-multimedia.org\nSuites: $(lsb_release -cs)\nComponents: main non-free\nSigned-By: /usr/share/keyrings/deb-multimedia-keyring.pgp\nEnabled: yes" | sudo tee /etc/apt/sources.list.d/dmo.sources
            sudo apt update
            touch "$state_file"
            echo "Repositório DebMultimedia adicionado."
        fi
    fi
}

nonfree_repos_installer() {
    local state_file="$STATE_DIR/nonfree_repos"

    if [ -f "$state_file" ]; then
        if confirm "Repositórios Non-Free detectados. Remover?"; then
            echo "Removendo repositórios Non-Free..."
            sudo sed -i '/non-free\|non-free-firmware\|contrib/d' /etc/apt/sources.list
            sudo apt update
            cleanup_files "$state_file"
            echo "Repositórios Non-Free removidos."
        fi
    else
        if confirm "Adicionar repositórios CONTRIB, NON-FREE e NON-FREE-FIRMWARE?"; then
            echo "Adicionando repositórios Non-Free..."
            sudo sed -i "s/ main$/ main contrib non-free non-free-firmware/" /etc/apt/sources.list
            sudo apt update
            touch "$state_file"
            echo "Repositórios Non-Free adicionados."
        fi
    fi
}

admin_installer() {
    while true; do
        clear
        echo "=== Admin ==="
        echo "1) curl"
        echo "2) UFW"
        echo "3) AppArmor"
        echo "4) Fwupd"
        echo "5) Flatpak + Flathub"
        echo "6) Plugin Flatpak"
        echo "7) Snapd"
        echo "8) Nala"
        echo "9) Pacstall"
        echo "10) Non-Free Repos"
        echo "11) DebMultimedia Repo"
        echo "12) XDG Base"
        echo "13) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) curl_installer ;;
            2) ufw_installer ;;
            3) apparmor_installer ;;
            4) fwupd_installer ;;
            5) flatpak_flathub_installer ;;
            6) flatpak_plugin_installer ;;
            7) snapd_installer ;;
            8) nala_installer ;;
            9) pacstall_installer ;;
            10) nonfree_repos_installer ;;
            11) debmultimedia_repo_installer ;;
            12) xdg_base_installer ;;
            13) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

devs_installer() {
    while true; do
        clear
        echo "=== Devs ==="
        echo "1) Fish Shell + Fisher"
        echo "2) Mise"
        echo "3) Starship"
        echo "4) NeoVim"
        echo "5) LazyVim"
        echo "6) Podman"
        echo "7) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) fish_fisher_installer ;;
            2) mise_installer ;;
            3) starship_installer ;;
            4) neovim_installer ;;
            5) lazyvim_installer ;;
            6) podman_installer ;;
            7) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

drivers_installer() {
    while true; do
        clear
        echo "=== Drivers ==="
        echo "1) Nvidia Proprietário"
        echo "2) Shader Booster"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) nvidia_proprietary_dkms_installer ;;
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
        echo "1) Pacotes Base"
        echo "2) Pacotes de Mídia"
        echo "3) yt-dlp"
        echo "4) Pacotes de Compactação"
        echo "5) AppImage FUSE"
        echo "6) aria2"
        echo "7) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) pessoal_base_installer ;;
            2) pessoal_media_installer ;;
            3) yt_dlp_installer ;;
            4) archiving_compression_installer ;;
            5) appimage_fuse_installer ;;
            6) aria2_installer ;;
            7) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

apps_installer() {
    while true; do
        clear
        echo "=== Apps ==="
        echo "1) Steam"
        echo "2) Faugus Launcher"
        echo "3) Fjord Launcher"
        echo "4) Zen Browser"
        echo "5) Gamemode"
        echo "6) GNOME Desktop"
        echo "7) Plasma Desktop"
        echo "8) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) steam_installer ;;
            2) faugus_launcher_installer ;;
            3) unmojang_installer ;;
            4) zen_browser_installer ;;
            5) gamemode_installer ;;
            6) de_gnome_installer ;;
            7) de_plasma_installer ;;
            8) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu() {
    while true; do
        clear
        echo "=== Debian Scripts ==="
        echo "1) Admin"
        echo "2) Devs"
        echo "3) Drivers"
        echo "4) Educação"
        echo "5) Apps"
        echo "6) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) admin_installer ;;
            2) devs_installer ;;
            3) drivers_installer ;;
            4) educacao_installer ;;
            5) apps_installer ;;
            6) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
