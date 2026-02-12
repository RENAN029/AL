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

echo "=== Verificando atualizações do sistema ==="
if confirm "Verificar e aplicar atualizações do sistema?"; then
    echo "Atualizando sistema..."
    sudo rpm-ostree update
    echo "Sistema atualizado."
fi

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

archiving_compression_installer() {
    local state_file="$STATE_DIR/archiving_compression"
    local pkg_compactacao="7zip unrar lhasa"

    if [ -f "$state_file" ] || rpm -q unrar &>/dev/null; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            sudo rpm-ostree uninstall 7zip unrar lhasa 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pacotes de Compactação desinstalados. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Pacotes de Compactação?"; then
            echo "Instalando Pacotes de Compactação..."
            sudo rpm-ostree install 7zip unrar lhasa
            touch "$state_file"
            echo "Pacotes de Compactação instalados. Reinicie para aplicar."
        fi
    fi
}

cachyconfs_installer() {
    local state_file="$STATE_DIR/cachyconfs"

    if [ -f "$state_file" ] || [ -f "/etc/sysctl.d/99-cachyos-settings.conf" ] || [ -f "/usr/lib/sysctl.d/99-cachyos-settings.conf" ]; then
        if confirm "CachyOS Configs detectado. Desinstalar?"; then
            sudo rm -f /etc/sysctl.d/99-cachyos-settings.conf 2>/dev/null || true
            sudo rm -f /usr/lib/sysctl.d/99-cachyos-settings.conf 2>/dev/null || true
            sudo sysctl --system
            cleanup_files "$state_file"
            echo "CachyOS Configs desinstalado."
        fi
    else
        if confirm "Instalar CachyOS Configs?"; then
            echo "Criando diretório /etc/sysctl.d/..."
            sudo mkdir -p /etc/sysctl.d
            echo "Baixando configurações do CachyOS..."
            curl -s https://raw.githubusercontent.com/CachyOS/CachyOS-Settings/main/sysctl/99-cachyos-settings.conf | sudo tee /etc/sysctl.d/99-cachyos-settings.conf > /dev/null
            sudo sysctl --system
            touch "$state_file"
            echo "CachyOS Configs instalado em /etc/sysctl.d/"
        fi
    fi
}

cpu_ondemand_installer() {
    local state_file="$STATE_DIR/cpu_ondemand"
    local service_file="/etc/systemd/system/set-ondemand-governor.service"

    if [ -f "$state_file" ] || [ -f "$service_file" ]; then
        if confirm "CPU Ondemand detectado. Desinstalar?"; then
            echo "Desinstalando CPU Ondemand..."
            sudo systemctl stop set-ondemand-governor.service 2>/dev/null || true
            sudo systemctl disable set-ondemand-governor.service 2>/dev/null || true
            sudo rm -f "$service_file" /etc/default/grub.d/01_intel_pstate_disable 2>/dev/null || true
            sudo rm -f /usr/local/bin/set-ondemand-governor.sh 2>/dev/null || true
            if command -v grub-mkconfig &>/dev/null; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            fi
            cleanup_files "$state_file"
            echo "CPU Ondemand desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar CPU Ondemand?"; then
            echo "Instalando CPU Ondemand..."
            echo '#!/bin/bash
echo "ondemand" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor' | sudo tee /usr/local/bin/set-ondemand-governor.sh
            sudo chmod +x /usr/local/bin/set-ondemand-governor.sh
            echo '[Unit]
Description=Set CPU governor to ondemand
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-ondemand-governor.sh

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/set-ondemand-governor.service
            sudo systemctl enable set-ondemand-governor.service
            sudo mkdir -p /etc/default/grub.d
            echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} intel_pstate=disable"' | sudo tee /etc/default/grub.d/01_intel_pstate_disable
            if command -v grub-mkconfig &>/dev/null; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            fi
            touch "$state_file"
            echo "CPU Ondemand instalado. Reinicie para aplicar."
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

eden_emulator_installer() {
    local state_file="$STATE_DIR/eden"
    local eden_dir="$HOME/Eden"
    local appimage_path="$eden_dir/Eden-Linux.AppImage"
    local version="0.1.1"

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "Eden Emulator detectado. Desinstalar?"; then
            echo "Desinstalando Eden Emulator..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            [ -d "$eden_dir" ] && rmdir "$eden_dir" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Eden Emulator desinstalado."
        fi
    else
        if confirm "Instalar Eden Emulator?"; then
            echo "Instalando Eden Emulator..."
            mkdir -p "$eden_dir"
            local download_url="https://github.com/eden-emulator/Releases/releases/download/v${version}/Eden-Linux-v${version}-amd64-gcc-standard.AppImage"
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            touch "$state_file"
            echo "Eden Emulator instalado."
        fi
    fi
}

extension_manager_installer() {
    local state_file="$STATE_DIR/extension_manager"
    local pkg_extension_manager="com.mattjakeman.ExtensionManager"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.mattjakeman.ExtensionManager 2>/dev/null; then
        if confirm "Extension Manager detectado. Desinstalar?"; then
            echo "Desinstalando Extension Manager..."
            flatpak uninstall --user -y $pkg_extension_manager 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Extension Manager desinstalado."
        fi
    else
        if confirm "Instalar Extension Manager?"; then
            echo "Instalando Extension Manager..."
            flatpak install --or-update --user --noninteractive flathub $pkg_extension_manager
            touch "$state_file"
            echo "Extension Manager instalado."
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

fish_fisher_installer() {
    local fish_state="$STATE_DIR/fish"
    local fisher_state="$STATE_DIR/fisher"
    local pkg_fish="fish"

    if [ -f "$fish_state" ] || command -v fish &>/dev/null; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ]; then
                echo "Removendo Fisher..."
                fish -c "fisher remove jorgebucaran/fisher" 2>/dev/null || true
                cleanup_files "$fisher_state"
            fi
            sudo rpm-ostree uninstall fish 2>/dev/null || true
            sudo chsh -s /usr/bin/bash "$USER" 2>/dev/null || true
            cleanup_files "$fish_state"
            rm -rf "$HOME/.config/fish" 2>/dev/null || true
            echo "Fish Shell desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Fish Shell?"; then
            echo "Instalando Fish Shell..."
            sudo rpm-ostree install fish
            sleep 2
            if command -v /usr/bin/fish &>/dev/null; then
                sudo chsh -s /usr/bin/fish "$USER"
            fi
            mkdir -p ~/.config/fish
            echo "set fish_greeting" > ~/.config/fish/config.fish
            touch "$fish_state"
            echo "Fish Shell instalado. Reinicie para aplicar."
        fi
    fi

    if [ -f "$fish_state" ] || command -v fish &>/dev/null; then
        if [ -f "$fisher_state" ]; then
            if confirm "Fisher detectado. Desinstalar?"; then
                echo "Desinstalando Fisher..."
                fish -c "fisher remove jorgebucaran/fisher" 2>/dev/null || true
                cleanup_files "$fisher_state"
                echo "Fisher desinstalado."
            fi
        elif confirm "Instalar Fisher (plugin manager)?"; then
            echo "Instalando Fisher..."
            fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
            touch "$fisher_state"
            echo "Fisher instalado."
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

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode"

    if [ -f "$state_file" ] || rpm -q gamemode &>/dev/null; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            sudo rpm-ostree uninstall gamemode 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Gamemode desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
            sudo rpm-ostree install gamemode
            touch "$state_file"
            echo "Gamemode instalado. Reinicie para aplicar."
        fi
    fi
}

gamescope_installer() {
    local state_file="$STATE_DIR/gamescope"
    local pkg_gamescope="gamescope"

    if [ -f "$state_file" ] || rpm -q gamescope &>/dev/null; then
        if confirm "Gamescope detectado. Desinstalar?"; then
            echo "Desinstalando Gamescope..."
            sudo rpm-ostree uninstall gamescope 2>/dev/null || true
            flatpak uninstall --user -y org.freedesktop.Platform.VulkanLayer.gamescope 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Gamescope desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Gamescope?"; then
            echo "Instalando Gamescope..."
            sudo rpm-ostree install gamescope
            flatpak install --user --noninteractive flathub org.freedesktop.Platform.VulkanLayer.gamescope 2>/dev/null || true
            touch "$state_file"
            echo "Gamescope instalado. Reinicie para aplicar."
        fi
    fi
}

gearlever_installer() {
    local state_file="$STATE_DIR/gearlever"
    local pkg_gearlever="it.mijorus.gearlever"

    if [ -f "$state_file" ] || flatpak list --app | grep -q it.mijorus.gearlever 2>/dev/null; then
        if confirm "Gear Lever detectado. Desinstalar?"; then
            echo "Desinstalando Gear Lever..."
            flatpak uninstall --user -y $pkg_gearlever 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Gear Lever desinstalado."
        fi
    else
        if confirm "Instalar Gear Lever?"; then
            echo "Instalando Gear Lever..."
            flatpak install --or-update --user --noninteractive flathub $pkg_gearlever
            touch "$state_file"
            echo "Gear Lever instalado."
        fi
    fi
}

gimp_photogimp_installer() {
    local gimp_state="$STATE_DIR/gimp"
    local photogimp_state="$STATE_DIR/photogimp"
    local pkg_gimp="org.gimp.GIMP"
    local gimp_config="$HOME/.config/GIMP"
    local gimp_share="$HOME/.local/share/GIMP"
    local gimp_installed=0

    if [ -f "$gimp_state" ] || flatpak list --app | grep -q org.gimp.GIMP 2>/dev/null; then
        gimp_installed=1
        if confirm "GIMP detectado. Desinstalar?"; then
            echo "Desinstalando GIMP..."
            flatpak uninstall --user -y $pkg_gimp 2>/dev/null || true
            rm -rf "$gimp_config" "$gimp_share"
            if [ -f "$photogimp_state" ]; then
                cleanup_files "$photogimp_state"
            fi
            cleanup_files "$gimp_state"
            echo "GIMP desinstalado."
        fi
    elif confirm "Instalar GIMP?"; then
        echo "Instalando GIMP..."
        flatpak install --or-update --user --noninteractive flathub $pkg_gimp
        touch "$gimp_state"
        echo "GIMP instalado."
        gimp_installed=1
    fi

    if [ $gimp_installed -eq 1 ] && [ -f "$gimp_state" ]; then
        if [ -f "$photogimp_state" ] || [ -d "$gimp_config" ]; then
            if confirm "PhotoGIMP detectado. Desinstalar?"; then
                echo "Desinstalando PhotoGIMP..."
                rm -rf "$gimp_config" "$gimp_share"
                cleanup_files "$photogimp_state"
                echo "PhotoGIMP desinstalado."
            fi
        elif confirm "Instalar PhotoGIMP (temas e configurações extras)?"; then
            echo "Instalando PhotoGIMP..."
            rm -rf "$gimp_config" "$gimp_share"
            git clone --depth=1 https://github.com/Diolinux/PhotoGIMP.git /tmp/photogimp
            cp -rvf /tmp/photogimp/.config/* ~/.config/
            cp -rvf /tmp/photogimp/.local/* ~/.local/
            rm -rf /tmp/photogimp
            touch "$photogimp_state"
            echo "PhotoGIMP instalado."
        fi
    fi
}

goverlay_installer() {
    local state_file="$STATE_DIR/goverlay"
    local pkg_mangohud="mangohud"
    local pkg_goverlay="io.github.benjamimgois.goverlay"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.benjamimgois.goverlay 2>/dev/null; then
        if confirm "Goverlay detectado. Desinstalar?"; then
            echo "Desinstalando Goverlay..."
            sudo rpm-ostree uninstall mangohud 2>/dev/null || true
            flatpak uninstall --user -y $pkg_goverlay 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Goverlay desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Goverlay?"; then
            echo "Instalando Goverlay..."
            sudo rpm-ostree install mangohud
            flatpak install --or-update --user --noninteractive flathub $pkg_goverlay
            flatpak install --or-update --user --noninteractive flathub com.valvesoftware.Steam.VulkanLayer.MangoHud/x86_64/stable org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08 2>/dev/null || true
            touch "$state_file"
            echo "Goverlay instalado. Reinicie para aplicar."
        fi
    fi
}

helium_browser_installer() {
    local state_file="$STATE_DIR/helium"
    local pkg_helium="com.imputnet.Helium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.imputnet.Helium 2>/dev/null; then
        if confirm "Helium Browser detectado. Desinstalar?"; then
            echo "Desinstalando Helium Browser..."
            flatpak uninstall --user -y $pkg_helium 2>/dev/null || true
            flatpak remote-delete --user helium-repo 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Helium Browser desinstalado."
        fi
    else
        if confirm "Instalar Helium Browser?"; then
            echo "Instalando Helium Browser..."
            flatpak remote-add --user --if-not-exists --no-gpg-verify helium-repo https://shyvortex.github.io/helium-flatpak/
            flatpak install --user --noninteractive helium-repo com.imputnet.Helium
            touch "$state_file"
            echo "Helium Browser instalado."
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

hwaccel_flatpak_installer() {
    local state_file="$STATE_DIR/hwaccel_flatpak"

    if [ -f "$state_file" ] || flatpak list | grep -q freedesktop.Platform.VAAPI 2>/dev/null; then
        if confirm "HW Acceleration Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando HW Acceleration Flatpak..."
            flatpak uninstall --user -y org.freedesktop.Platform.VAAPI 2>/dev/null || true
            flatpak uninstall --user -y org.freedesktop.Platform.VAAPI.Intel 2>/dev/null || true
            cleanup_files "$state_file"
            echo "HW Acceleration Flatpak desinstalado."
        fi
    else
        if confirm "Instalar HW Acceleration Flatpak?"; then
            echo "Instalando HW Acceleration Flatpak..."
            flatpak install --user -y flathub org.freedesktop.Platform.VAAPI.Intel 2>/dev/null || true
            flatpak override --user --device=all --env=GDK_SCALE=1 --env=GDK_DPI_SCALE=1 2>/dev/null || true
            touch "$state_file"
            echo "HW Acceleration Flatpak instalado."
        fi
    fi
}

hydra_launcher_installer() {
    local state_file="$STATE_DIR/hydra_launcher"
    local hydra_dir="$HOME/HydraLauncher"
    local appimage_path="$hydra_dir/hydralauncher.AppImage"
    local version="3.8.3"

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "Hydra Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Hydra Launcher..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            [ -d "$hydra_dir" ] && rmdir "$hydra_dir" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Hydra Launcher desinstalado."
        fi
    else
        if confirm "Instalar Hydra Launcher?"; then
            echo "Instalando Hydra Launcher..."
            mkdir -p "$hydra_dir"
            local download_url="https://github.com/hydralauncher/hydra/releases/download/v${version}/hydralauncher-${version}.AppImage"
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            touch "$state_file"
            echo "Hydra Launcher instalado."
        fi
    fi
}

iwd_installer() {
    local state_file="$STATE_DIR/iwd"
    local pkg_iwd="iwd"

    if [ -f "$state_file" ] || rpm -q iwd &>/dev/null; then
        if confirm "IWD detectado. Desinstalar?"; then
            echo "Desinstalando IWD..."
            sudo rpm-ostree uninstall iwd 2>/dev/null || true
            sudo rm -f /etc/NetworkManager/conf.d/iwd.conf 2>/dev/null || true
            sudo systemctl restart NetworkManager 2>/dev/null || true
            sudo systemctl enable --now wpa_supplicant 2>/dev/null || true
            cleanup_files "$state_file"
            echo "IWD desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar IWD (iNet Wireless Daemon)?"; then
            echo "Instalando IWD..."
            sudo rpm-ostree install iwd
            echo "[device]
wifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf > /dev/null
            sudo systemctl stop NetworkManager 2>/dev/null || true
            sleep 1
            sudo systemctl restart NetworkManager 2>/dev/null || true
            sudo systemctl enable --now iwd 2>/dev/null || true
            sudo systemctl disable wpa_supplicant 2>/dev/null || true
            touch "$state_file"
            echo "IWD instalado. Reinicie para aplicar."
        fi
    fi
}

kdenlive_installer() {
    local state_file="$STATE_DIR/kdenlive"
    local pkg_kdenlive="org.kde.kdenlive"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.kdenlive 2>/dev/null; then
        if confirm "Kdenlive detectado. Desinstalar?"; then
            echo "Desinstalando Kdenlive..."
            flatpak uninstall --user -y $pkg_kdenlive 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Kdenlive desinstalado."
        fi
    else
        if confirm "Instalar Kdenlive?"; then
            echo "Instalando Kdenlive..."
            flatpak install --or-update --user --noninteractive flathub $pkg_kdenlive
            touch "$state_file"
            echo "Kdenlive instalado."
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

mangojuice_installer() {
    local state_file="$STATE_DIR/mangojuice"
    local pkg_mangohud="mangohud"
    local pkg_mangojuice="io.github.radiolamp.mangojuice"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.radiolamp.mangojuice 2>/dev/null; then
        if confirm "MangoJuice detectado. Desinstalar?"; then
            echo "Desinstalando MangoJuice..."
            sudo rpm-ostree uninstall mangohud 2>/dev/null || true
            flatpak uninstall --user -y $pkg_mangojuice 2>/dev/null || true
            cleanup_files "$state_file"
            echo "MangoJuice desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar MangoJuice?"; then
            echo "Instalando MangoJuice..."
            sudo rpm-ostree install mangohud
            flatpak install --or-update --user --noninteractive flathub com.valvesoftware.Steam.VulkanLayer.MangoHud/x86_64/stable org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08 2>/dev/null || true
            flatpak install --or-update --user --noninteractive flathub $pkg_mangojuice
            touch "$state_file"
            echo "MangoJuice instalado. Reinicie para aplicar."
        fi
    fi
}

mise_installer() {
    local state_file="$STATE_DIR/mise"

    if [ -f "$state_file" ] || command -v mise &>/dev/null; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            rm -f ~/.local/bin/mise 2>/dev/null || true
            sed -i '/mise/d' ~/.bashrc 2>/dev/null || true
            sed -i '/mise/d' ~/.zshrc 2>/dev/null || true
            sed -i '/mise/d' ~/.config/fish/config.fish 2>/dev/null || true
            rm -f ~/.local/share/bash-completion/completions/mise 2>/dev/null || true
            rm -f /usr/local/share/zsh/site-functions/_mise 2>/dev/null || true
            rm -f ~/.config/fish/completions/mise.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            if [ -f ~/.bashrc ]; then
                curl https://mise.run | sh
                ~/.local/bin/mise use -g usage
                mkdir -p ~/.local/share/bash-completion/completions
                ~/.local/bin/mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
            fi
            if [ -f ~/.zshrc ]; then
                curl https://mise.run | sh
                ~/.local/bin/mise use -g usage
                sudo mkdir -p /usr/local/share/zsh/site-functions
                ~/.local/bin/mise completion zsh | sudo tee /usr/local/share/zsh/site-functions/_mise > /dev/null
            fi
            if [ -f ~/.config/fish/config.fish ]; then
                curl https://mise.run | sh
                ~/.local/bin/mise use -g usage
                mkdir -p ~/.config/fish/completions
                ~/.local/bin/mise completion fish > ~/.config/fish/completions/mise.fish
            fi
            touch "$state_file"
            echo "Mise instalado."
        fi
    fi
}

neovim_installer() {
    local state_file="$STATE_DIR/nvim"

    if [ -f "$state_file" ] || command -v nvim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            sudo rpm-ostree uninstall neovim 2>/dev/null || true
            cleanup_files "$state_file"
            echo "NeoVim desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            sudo rpm-ostree install neovim
            touch "$state_file"
            echo "NeoVim instalado. Reinicie para aplicar."
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

obs_installer() {
    local obs_state="$STATE_DIR/obs"
    local obs_plugins_state="$STATE_DIR/obs_plugins"
    local pkg_wireplumber="wireplumber xorg-xwayland"
    local pkg_obs="com.obsproject.Studio"

    if [ -f "$obs_state" ] || flatpak list --app --columns=application | grep -q "com.obsproject.Studio"; then
        if confirm "OBS Studio detectado. Desinstalar?"; then
            echo "Desinstalando OBS Studio..."
            flatpak uninstall --user -y $pkg_obs 2>/dev/null || true
            cleanup_files "$obs_state"
            if [ -f "$obs_plugins_state" ] || [ -d "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio" ]; then
                cleanup_files "$obs_plugins_state" "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio"
            fi
            if confirm "Desinstalar também wireplumber e xorg-xwayland?"; then
                sudo rpm-ostree uninstall wireplumber xorg-xwayland 2>/dev/null || true
            fi
            echo "OBS Studio desinstalado. Reinicie para aplicar."
        fi
    elif confirm "Instalar OBS Studio?"; then
        echo "Instalando OBS Studio..."
        flatpak install --user -y --noninteractive flathub $pkg_obs
        touch "$obs_state"
        echo "OBS Studio instalado."
    fi
    
    if [ ! -f "$obs_plugins_state" ] && [ ! -d "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio" ]; then
        if confirm "Instalar plugins recomendados (pipewire audio capture)?"; then
            echo "Instalando plugins do OBS Studio..."
            sudo rpm-ostree install wireplumber xorg-xwayland
            local ver=$(curl -s "https://api.github.com/repos/dimtpap/obs-pipewire-audio-capture/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')
            mkdir -p /tmp/obspipe && cd /tmp/obspipe
            curl -fsSL "https://github.com/dimtpap/obs-pipewire-audio-capture/releases/download/${ver}/linux-pipewire-audio-${ver}-flatpak-30.tar.gz" -o linux-pipewire-audio.tar.gz
            tar -xvzf linux-pipewire-audio.tar.gz
            mkdir -p "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio"
            cp -rf linux-pipewire-audio/* "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio/"
            flatpak override --user --filesystem=xdg-run/pipewire-0 $pkg_obs
            flatpak override --user --socket=x11 --nosocket=wayland --env=QT_QPA_PLATFORM=xcb $pkg_obs
            cd .. && rm -rf /tmp/obspipe
            touch "$obs_plugins_state"
            echo "Plugins do OBS Studio instalados."
        fi
    elif [ -f "$obs_plugins_state" ] || [ -d "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio" ]; then
        if confirm "Plugins do OBS detectados. Desinstalar?"; then
            echo "Desinstalando plugins do OBS Studio..."
            cleanup_files "$obs_plugins_state" "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio"
            if confirm "Desinstalar também wireplumber e xorg-xwayland?"; then
                sudo rpm-ostree uninstall wireplumber xorg-xwayland 2>/dev/null || true
            fi
            echo "Plugins do OBS Studio desinstalados."
        fi
    fi
}

obsidian_installer() {
    local state_file="$STATE_DIR/obsidian"
    local pkg_obsidian="md.obsidian.Obsidian"

    if [ -f "$state_file" ] || flatpak list --app | grep -q md.obsidian.Obsidian 2>/dev/null; then
        if confirm "Obsidian detectado. Desinstalar?"; then
            echo "Desinstalando Obsidian..."
            flatpak uninstall --user -y $pkg_obsidian 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Obsidian desinstalado."
        fi
    else
        if confirm "Instalar Obsidian?"; then
            echo "Instalando Obsidian..."
            flatpak install --or-update --user --noninteractive flathub $pkg_obsidian
            touch "$state_file"
            echo "Obsidian instalado."
        fi
    fi
}

oh_my_bash_installer() {
    local state_file="$STATE_DIR/oh_my_bash"

    if [ -f "$state_file" ] || [ -d "$HOME/.oh-my-bash" ]; then
        if confirm "Oh My Bash detectado. Desinstalar?"; then
            [ -d "$HOME/.oh-my-bash" ] && yes | "$HOME/.oh-my-bash/tools/uninstall.sh" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Oh My Bash desinstalado."
        fi
    else
        if confirm "Instalar Oh My Bash?"; then
            echo "Instalando Oh My Bash..."
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
            touch "$state_file"
            echo "Oh My Bash instalado."
        fi
    fi
}

onlyoffice_installer() {
    local state_file="$STATE_DIR/onlyoffice"
    local pkg_onlyoffice="org.onlyoffice.desktopeditors"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.onlyoffice.desktopeditors 2>/dev/null; then
        if confirm "OnlyOffice detectado. Desinstalar?"; then
            echo "Desinstalando OnlyOffice..."
            flatpak uninstall --user -y $pkg_onlyoffice 2>/dev/null || true
            cleanup_files "$state_file"
            echo "OnlyOffice desinstalado."
        fi
    else
        if confirm "Instalar OnlyOffice?"; then
            echo "Instalando OnlyOffice..."
            flatpak install --or-update --user --noninteractive flathub $pkg_onlyoffice
            touch "$state_file"
            echo "OnlyOffice instalado."
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

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="google-noto-fonts-all google-noto-sans-cjk-fonts google-noto-emoji-fonts google-noto-sans-hk-fonts google-noto-sans-cjk-vf-fonts cascadia-mono-nf-fonts"

    if [ -f "$state_file" ] || rpm -q google-noto-fonts-all &>/dev/null; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            sudo rpm-ostree uninstall google-noto-fonts-all google-noto-sans-cjk-fonts google-noto-emoji-fonts google-noto-sans-hk-fonts google-noto-sans-cjk-vf-fonts cascadia-mono-nf-fonts 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Pacotes Base (Fontes Google Noto e Cascadia)?"; then
            echo "Instalando Pacotes Base..."
            sudo rpm-ostree install $pkg_base
            touch "$state_file"
            echo "Pacotes Base instalados. Reinicie para aplicar."
        fi
    fi
}

podman_installer() {
    local state_file="$STATE_DIR/podman"
    local pkg_podman="podman podman-compose"

    if [ -f "$state_file" ] || rpm -q podman &>/dev/null; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            sudo rpm-ostree uninstall podman podman-compose 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Podman desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Podman?"; then
            echo "Instalando Podman..."
            sudo rpm-ostree install podman podman-compose
            touch "$state_file"
            echo "Podman instalado. Reinicie para aplicar."
        fi
    fi
}

preload_installer() {
    local state_file="$STATE_DIR/preload"
    local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_gb=$(( total_kb / 1024 / 1024 ))

    if [ -f "$state_file" ] || rpm -q preload &>/dev/null; then
        if confirm "Preload detectado. Desinstalar?"; then
            echo "Desinstalando Preload..."
            sudo systemctl stop preload 2>/dev/null || true
            sudo systemctl disable preload 2>/dev/null || true
            sudo rpm-ostree uninstall preload 2>/dev/null || true
            sudo rm -f /etc/yum.repos.d/elxreno-preload-*.repo 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Preload desinstalado. Reinicie para aplicar."
        fi
    else
        if [ $total_gb -gt 12 ]; then
            if confirm "Instalar Preload (otimização de RAM > 12GB)?"; then
                echo "Instalando Preload..."
                local fedora_version=$(rpm -E %fedora)
                cd $HOME
                curl -L -o elxreno-preload-fedora-${fedora_version}.repo \
                    https://copr.fedorainfracloud.org/coprs/elxreno/preload/repo/fedora-${fedora_version}/elxreno-preload-fedora-${fedora_version}.repo
                sudo install -o 0 -g 0 elxreno-preload-fedora-${fedora_version}.repo /etc/yum.repos.d/elxreno-preload-fedora-${fedora_version}.repo
                sudo rpm-ostree refresh-md
                rm elxreno-preload-fedora-${fedora_version}.repo
                sudo rpm-ostree install preload
                sudo systemctl enable --now preload
                touch "$state_file"
                echo "Preload instalado. Reinicie para aplicar."
            fi
        else
            echo "RAM insuficiente para Preload (requer > 12GB). Detectado: ${total_gb}GB"
            return 1
        fi
    fi
}

remover_bloatware() {
    echo "Identificando ambiente desktop atual..."
    
    local desktop_env=""
    if rpm-ostree status 2>/dev/null | grep -q "silverblue"; then
        desktop_env="GNOME"
    elif rpm-ostree status 2>/dev/null | grep -q "kinoite"; then
        desktop_env="KDE"
    elif rpm-ostree status 2>/dev/null | grep -q "cosmic-atomic"; then
        desktop_env="COSMIC"
    else
        echo "Não foi possível identificar o ambiente desktop ou ambiente não suportado para remoção de bloatware."
        return
    fi
    
    echo "Ambiente detectado: $desktop_env"
    
    if confirm "Remover aplicativos pré-instalados desnecessários do $desktop_env?"; then
        
        if [ "$desktop_env" = "GNOME" ]; then
            echo "Removendo bloatware do GNOME via override..."
            local gnome_bloat=(
                firefox
                gnome-photos
                gnome-maps
                gnome-music
                gnome-weather
                gnome-contacts
                gnome-calendar
                gnome-clocks
                gnome-characters
                gnome-logs
                gnome-tour
                totem
                rhythmbox
                cheese
                simple-scan
                evolution
                evince
            )
            for pkg in "${gnome_bloat[@]}"; do
                echo "Removendo $pkg..."
                sudo rpm-ostree override remove "$pkg" 2>/dev/null || true
            done
            sudo rpm-ostree override remove libreoffice-* 2>/dev/null || true
            
        elif [ "$desktop_env" = "KDE" ]; then
            echo "Removendo bloatware do KDE via override..."
            local kde_bloat=(
                firefox
                firefox-langpacks
                kate
                kwrite
                konversation
                kaddressbook
                kmail
                kontact
                korganizer
                akregator
                ktorrent
                kget
                k3b
                dragon
                juk
                kmahjongg
                kmines
                ksudoku
                kpat
            )
            for pkg in "${kde_bloat[@]}"; do
                echo "Removendo $pkg..."
                sudo rpm-ostree override remove "$pkg" 2>/dev/null || true
            done
            sudo rpm-ostree override remove libreoffice-* 2>/dev/null || true
            
        elif [ "$desktop_env" = "COSMIC" ]; then
            echo "Removendo bloatware do COSMIC via override..."
            local cosmic_bloat=(
                firefox
                gnome-photos
                gnome-maps
                gnome-music
                gnome-weather
            )
            for pkg in "${cosmic_bloat[@]}"; do
                echo "Removendo $pkg..."
                sudo rpm-ostree override remove "$pkg" 2>/dev/null || true
            done
            sudo rpm-ostree override remove libreoffice-* 2>/dev/null || true
        fi
        
        echo "Removendo pacotes Flatpak pré-instalados..."
        local flatpak_bloat=(
            org.gnome.Calculator
            org.gnome.Calendar
            org.gnome.Characters
            org.gnome.Connections
            org.gnome.Contacts
            org.gnome.Evince
            org.gnome.Logs
            org.gnome.Maps
            org.gnome.Music
            org.gnome.Weather
            org.gnome.clocks
            org.gnome.font-viewer
            org.gnome.TextEditor
            org.fedoraproject.MediaWriter
        )
        
        for app in "${flatpak_bloat[@]}"; do
            echo "Removendo Flatpak: $app..."
            flatpak uninstall --system -y "$app" 2>/dev/null || true
            flatpak uninstall --user -y "$app" 2>/dev/null || true
        done
        
        echo "Limpando dependências não utilizadas..."
        flatpak uninstall --unused -y 2>/dev/null || true
        
        touch "$STATE_DIR/bloatware_removed"
        echo "Remoção de bloatware concluída. Reinicie para aplicar as alterações."
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

shadps4_installer() {
    local shad_state="$STATE_DIR/shadps4"
    local pkg_state="$STATE_DIR/pkginstaller"
    local pkg_shadps4="net.shadps4.shadPS4"
    local pkg_dir="$HOME/PKGInstaller"
    local zip_path="$pkg_dir/PKGInstall.zip"
    local appimage_path="$pkg_dir/PKGInstall.AppImage"

    if [ -f "$shad_state" ] || flatpak list --app | grep -q net.shadps4.shadPS4 2>/dev/null; then
        if confirm "ShadPS4 detectado. Desinstalar?"; then
            echo "Desinstalando ShadPS4..."
            flatpak uninstall --user -y $pkg_shadps4 2>/dev/null || true
            cleanup_files "$shad_state"
            echo "ShadPS4 desinstalado."
        fi
    elif confirm "Instalar ShadPS4?"; then
        echo "Instalando ShadPS4..."
        flatpak install --or-update --user --noninteractive flathub $pkg_shadps4
        touch "$shad_state"
        echo "ShadPS4 instalado."
    fi
    
    if [ ! -f "$pkg_state" ] && [ ! -f "$appimage_path" ]; then
        if confirm "Instalar PKG Installer?"; then
            echo "Instalando PKG Installer..."
            mkdir -p "$pkg_dir"
            local download_url=$(curl -s https://api.github.com/repos/Muggle345/PKGInstall/releases/latest | grep -o '"browser_download_url": *"[^"]*"' | grep -i 'PKGInstall.*zip' | head -1 | cut -d'"' -f4)
            [ -z "$download_url" ] && download_url="https://github.com/Muggle345/PKGInstall/releases/latest/download/PKGInstall.zip"
            curl -L -o "$zip_path" "$download_url"
            unzip -q "$zip_path" -d "$pkg_dir"
            rm -f "$zip_path"
            find "$pkg_dir" -name "*.AppImage" -exec mv {} "$appimage_path" \;
            chmod +x "$appimage_path"
            touch "$pkg_state"
            echo "PKG Installer instalado."
        fi
    elif [ -f "$pkg_state" ] || [ -f "$appimage_path" ]; then
        if confirm "PKG Installer detectado. Desinstalar?"; then
            echo "Desinstalando PKG Installer..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            [ -f "$zip_path" ] && rm -f "$zip_path"
            [ -d "$pkg_dir" ] && rm -rf "$pkg_dir"
            cleanup_files "$pkg_state"
            echo "PKG Installer desinstalado."
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

starship_installer() {
    local state_file="$STATE_DIR/starship"

    if [ -f "$state_file" ] || command -v starship &>/dev/null; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            sudo rm -f /usr/local/bin/starship 2>/dev/null || true
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            curl -fsSL https://starship.rs/install.sh | sh -s -- -f -y
            grep -q "starship init" ~/.bashrc || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bashrc
            grep -q "starship init" ~/.zshrc || echo -e "\neval \"\$(starship init zsh)\"" >> ~/.zshrc
            mkdir -p ~/.config/fish
            if [ -f ~/.config/fish/config.fish ]; then
                grep -q "starship init fish" ~/.config/fish/config.fish || echo -e "\nstarship init fish | source" >> ~/.config/fish/config.fish
            else
                echo -e "starship init fish | source" >> ~/.config/fish/config.fish
            fi
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

unmojang_installer() {
    local state_file="$STATE_DIR/unmojang"
    local pkg_fjord="org.unmojang.FjordLauncher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.unmojang.FjordLauncher 2>/dev/null; then
        if confirm "Fjord Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Fjord Launcher..."
            flatpak uninstall --user -y $pkg_fjord 2>/dev/null || true
            flatpak remote-delete --user hero-persson 2>/dev/null || true
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

vscodium_installer() {
    local state_file="$STATE_DIR/vscodium"
    local pkg_vscodium="com.vscodium.codium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.vscodium.codium 2>/dev/null; then
        if confirm "VSCodium detectado. Desinstalar?"; then
            echo "Desinstalando VSCodium..."
            flatpak uninstall --user -y $pkg_vscodium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "VSCodium desinstalado."
        fi
    else
        if confirm "Instalar VSCodium?"; then
            echo "Instalando VSCodium..."
            flatpak install --user --or-update --noninteractive flathub $pkg_vscodium
            touch "$state_file"
            echo "VSCodium instalado."
        fi
    fi
}

winboat_installer() {
    local state_file="$STATE_DIR/winboat"
    local winboat_dir="$HOME/WinBoat"
    local appimage_path="$winboat_dir/winboat.AppImage"
    local version="0.9.0"

    if ! lsmod | grep -q kvm; then
        echo "KVM não está disponível. Verifique se a virtualização está habilitada no BIOS."
        return 1
    fi

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "WinBoat detectado. Desinstalar?"; then
            echo "Desinstalando WinBoat..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            [ -d "$winboat_dir" ] && rmdir "$winboat_dir" 2>/dev/null || true
            cleanup_files "$state_file" "$HOME/lsw" "$HOME/txtbox"
            echo "WinBoat desinstalado."
        fi
    else
        if confirm "Instalar WinBoat (Windows em container Docker)?"; then
            echo "Instalando WinBoat..."
            mkdir -p "$winboat_dir"
            local download_url="https://github.com/TibixDev/winboat/releases/download/v${version}/winboat-${version}-x86_64.AppImage"
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            touch "$state_file"
            echo "WinBoat instalado."
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

zsh_ohmyzsh_installer() {
    local zsh_state="$STATE_DIR/zsh"
    local ohmyzsh_state="$STATE_DIR/ohmyzsh"
    local pkg_zsh="zsh"

    if [ -f "$zsh_state" ] || command -v zsh &>/dev/null; then
        if confirm "Zsh detectado. Desinstalar?"; then
            echo "Desinstalando Zsh..."
            if [ -f "$ohmyzsh_state" ] || [ -d "$HOME/.oh-my-zsh" ]; then
                [ -d "$HOME/.oh-my-zsh" ] && {
                    chmod +x "$HOME/.oh-my-zsh/tools/uninstall.sh" 2>/dev/null || true
                    yes | "$HOME/.oh-my-zsh/tools/uninstall.sh" 2>/dev/null || true
                }
                cleanup_files "$ohmyzsh_state"
            fi
            sudo rpm-ostree uninstall zsh 2>/dev/null || true
            sudo chsh -s /usr/bin/bash "$USER" 2>/dev/null || true
            cleanup_files "$zsh_state"
            rm -rf "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc.backup" 2>/dev/null || true
            echo "Zsh desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Zsh?"; then
            echo "Instalando Zsh..."
            sudo rpm-ostree install zsh
            sleep 2
            if command -v /usr/bin/zsh &>/dev/null; then
                sudo chsh -s /usr/bin/zsh "$USER"
            fi
            touch "$HOME/.zshrc"
            touch "$zsh_state"
            echo "Zsh instalado. Reinicie para aplicar."
        fi
    fi
    
    if [ -f "$zsh_state" ] || command -v zsh &>/dev/null; then
        if [ -f "$ohmyzsh_state" ] || [ -d "$HOME/.oh-my-zsh" ]; then
            if confirm "Oh My Zsh detectado. Desinstalar?"; then
                echo "Desinstalando Oh My Zsh..."
                [ -d "$HOME/.oh-my-zsh" ] && {
                    chmod +x "$HOME/.oh-my-zsh/tools/uninstall.sh" 2>/dev/null || true
                    yes | "$HOME/.oh-my-zsh/tools/uninstall.sh" 2>/dev/null || true
                }
                cleanup_files "$ohmyzsh_state"
                echo "Oh My Zsh desinstalado."
            fi
        elif confirm "Instalar Oh My Zsh?"; then
            echo "Instalando Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            touch "$ohmyzsh_state"
            echo "Oh My Zsh instalado."
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
        echo "5) Xpadneo (Xbox Controller)"
        echo "6) Faugus Launcher"
        echo "7) Zen Browser"
        echo "8) Flatpak/Flathub"
        echo "9) Homebrew"
        echo "10) Nvidia Proprietary"
        echo "11) COSMIC Desktop (Fedora Cosmic-Atomic)"
        echo "12) GNOME Desktop (Silverblue)"
        echo "13) KDE Plasma Desktop (Kinoite)"
        echo "14) NeoVim"
        echo "15) LazyVim"
        echo "16) GIMP + PhotoGIMP"
        echo "17) Steam"
        echo "18) Archiving/Compression Tools (7zip, unrar)"
        echo "19) Pacotes Base (Fontes Google Noto e Cascadia)"
        echo "20) Remover Bloatware"
        echo "21) Kdenlive"
        echo "22) Fish Shell + Fisher"
        echo "23) Gamescope"
        echo "24) Gamemode"
        echo "25) Affinity Photo (AppImage)"
        echo "26) IWD (iNet Wireless Daemon)"
        echo "27) Mise (Dev Tools)"
        echo "28) Goverlay"
        echo "29) MangoJuice"
        echo "30) Fjord Launcher (Unmojang)"
        echo "31) VSCodium"
        echo "32) Helium Browser"
        echo "33) Hydra Launcher (AppImage)"
        echo "34) Gear Lever"
        echo "35) Extension Manager"
        echo "36) OBS Studio"
        echo "37) Zsh + Oh My Zsh"
        echo "38) Oh My Bash"
        echo "39) CPU Ondemand"
        echo "40) Shader Booster"
        echo "41) HW Acceleration Flatpak"
        echo "42) WinBoat (AppImage)"
        echo "43) Podman"
        echo "44) ShadPS4 + PKG Installer"
        echo "45) Eden Emulator (AppImage)"
        echo "46) Starship Prompt"
        echo "47) Preload (otimização de RAM)"
        echo "48) Obsidian"
        echo "49) OnlyOffice"
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
            14) neovim_installer ;;
            15) lazyvim_installer ;;
            16) gimp_photogimp_installer ;;
            17) steam_installer ;;
            18) archiving_compression_installer ;;
            19) pessoal_base_installer ;;
            20) remover_bloatware ;;
            21) kdenlive_installer ;;
            22) fish_fisher_installer ;;
            23) gamescope_installer ;;
            24) gamemode_installer ;;
            25) affinity_installer ;;
            26) iwd_installer ;;
            27) mise_installer ;;
            28) goverlay_installer ;;
            29) mangojuice_installer ;;
            30) unmojang_installer ;;
            31) vscodium_installer ;;
            32) helium_browser_installer ;;
            33) hydra_launcher_installer ;;
            34) gearlever_installer ;;
            35) extension_manager_installer ;;
            36) obs_installer ;;
            37) zsh_ohmyzsh_installer ;;
            38) oh_my_bash_installer ;;
            39) cpu_ondemand_installer ;;
            40) shader_booster_installer ;;
            41) hwaccel_flatpak_installer ;;
            42) winboat_installer ;;
            43) podman_installer ;;
            44) shadps4_installer ;;
            45) eden_emulator_installer ;;
            46) starship_installer ;;
            47) preload_installer ;;
            48) obsidian_installer ;;
            49) onlyoffice_installer ;;
            0) exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
