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

echo "=== Verificando atualizações e limpando cache do sistema ==="
if confirm "Verificar e aplicar atualizações do sistema?"; then
    echo "Atualizando sistema..."
    sudo rpm-ostree update
    echo "Sistema atualizado."
fi

if confirm "Limpar cache de pacotes e repositórios?"; then
    echo "Limpando cache de pacotes e repositórios..."
    sudo rpm-ostree cleanup -m
    echo "Cache limpo."
fi

APPIMAGE_DIR="$HOME/AppImages"
mkdir -p "$APPIMAGE_DIR"

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

check_reboot() {
    echo
    echo "=== REINICIALIZAÇÃO DO SISTEMA ==="
    echo "Deseja reiniciar o sistema agora?"
    echo "Algumas alterações podem exigir uma reinicialização para aplicar completamente."
    
    if confirm "Reiniciar o sistema?"; then
        echo "Reiniciando o sistema em 5 segundos. Pressione Ctrl+C para cancelar..."
        sleep 5
        sudo systemctl reboot
    else
        echo "Lembre-se de reiniciar o sistema manualmente se necessário."
    fi
}

acer_manager_installer() {
    local state_file="$STATE_DIR/acer_manager"

    if [ -f "$state_file" ]; then
        if confirm "Acer Manager detectado. Desinstalar?"; then
            cleanup_files "$state_file"
        fi
    else
        if confirm "Instalar Acer Manager?"; then
            curl -fsSL https://raw.githubusercontent.com/PXDiv/Div-Acer-Manager-Max/refs/heads/main/scripts/remoteSetup.sh -o /tmp/setup.sh && sudo bash /tmp/setup.sh
            touch "$state_file"
        fi
    fi
}

affinity_installer() {
    local state_file="$STATE_DIR/affinity"
    local appimage_path="$APPIMAGE_DIR/Affinity.AppImage"

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "Affinity detectado. Desinstalar?"; then
            echo "Desinstalando Affinity..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            cleanup_files "$state_file"
            echo "Affinity desinstalado."
        fi
    else
        if confirm "Instalar Affinity Photo?"; then
            echo "Instalando Affinity Photo..."
            local download_url=$(curl -s https://api.github.com/repos/ryzendew/Linux-Affinity-Installer/releases/latest | grep -o '"browser_download_url": *"[^"]*"' | grep -i 'affinity.*appimage' | head -1 | cut -d'"' -f4)
            [ -z "$download_url" ] && download_url="https://github.com/ryzendew/Linux-Affinity-Installer/releases/latest/download/Affinity.AppImage"
            
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            
            touch "$state_file"
            echo "Affinity Photo instalado."
        fi
    fi
}

alpaca_installer() {
    local state_file="$STATE_DIR/alpaca_studio"
    local pkg_alpaca="com.jeffser.Alpaca"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.jeffser.Alpaca 2>/dev/null; then
        if confirm "Alpaca detectado. Desinstalar?"; then
            echo "Desinstalando Alpaca..."
            flatpak uninstall --user -y $pkg_alpaca 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Alpaca desinstalado."
        fi
    else
        if confirm "Instalar Alpaca?"; then
            echo "Instalando Alpaca..."
            flatpak install --user --or-update --noninteractive flathub $pkg_alpaca
            touch "$state_file"
            echo "Alpaca instalado."
        fi
    fi
}

android_studio_installer() {
    local state_file="$STATE_DIR/android_studio"
    local pkg_android="com.google.AndroidStudio"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.google.AndroidStudio 2>/dev/null; then
        if confirm "Android Studio detectado. Desinstalar?"; then
            echo "Desinstalando Android Studio..."
            flatpak uninstall --user -y $pkg_android 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Android Studio desinstalado."
        fi
    else
        if confirm "Instalar Android Studio?"; then
            echo "Instalando Android Studio..."
            flatpak install --user --or-update --noninteractive flathub $pkg_android
            touch "$state_file"
            echo "Android Studio instalado."
        fi
    fi
}

anydesk_installer() {
    local state_file="$STATE_DIR/anydesk"
    local pkg_anydesk="com.anydesk.Anydesk"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.anydesk.Anydesk 2>/dev/null; then
        if confirm "AnyDesk detectado. Desinstalar?"; then
            echo "Desinstalando AnyDesk..."
            flatpak uninstall --user -y $pkg_anydesk 2>/dev/null || true
            cleanup_files "$state_file"
            echo "AnyDesk desinstalado."
        fi
    else
        if confirm "Instalar AnyDesk?"; then
            echo "Instalando AnyDesk..."
            flatpak install --or-update --user --noninteractive flathub $pkg_anydesk
            touch "$state_file"
            echo "AnyDesk instalado."
        fi
    fi
}

aria2_installer() {
    local state_file="$STATE_DIR/aria2"

    if [ -f "$state_file" ] || rpm -q aria2 &>/dev/null; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            sudo rpm-ostree uninstall aria2 2>/dev/null || true
            cleanup_files "$state_file"
            echo "aria2 desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar aria2?"; then
            echo "Instalando aria2..."
            sudo rpm-ostree install aria2
            touch "$state_file"
            echo "aria2 instalado. Reinicie para aplicar."
        fi
    fi
}

audacity_installer() {
    local state_file="$STATE_DIR/audacity"
    local pkg_audacity="org.audacityteam.Audacity"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.audacityteam.Audacity 2>/dev/null; then
        if confirm "Audacity detectado. Desinstalar?"; then
            echo "Desinstalando Audacity..."
            flatpak uninstall --user -y $pkg_audacity 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Audacity desinstalado."
        fi
    else
        if confirm "Instalar Audacity?"; then
            echo "Instalando Audacity..."
            flatpak install --or-update --user --noninteractive flathub $pkg_audacity
            touch "$state_file"
            echo "Audacity instalado."
        fi
    fi
}

bazaar_installer() {
    local state_file="$STATE_DIR/bazaar"
    local pkg_bazaar="io.github.kolunmi.Bazaar"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.kolunmi.Bazaar 2>/dev/null; then
        if confirm "Bazaar detectado. Desinstalar?"; then
            echo "Desinstalando Bazaar..."
            flatpak uninstall --user -y $pkg_bazaar 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Bazaar desinstalado."
        fi
    else
        if confirm "Instalar Bazaar?"; then
            echo "Instalando Bazaar..."
            flatpak install --or-update --user --noninteractive flathub $pkg_bazaar
            touch "$state_file"
            echo "Bazaar instalado."
        fi
    fi
}

bitwarden_installer() {
    local state_file="$STATE_DIR/bitwarden"
    local pkg_bitwarden="com.bitwarden.desktop"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.bitwarden.desktop 2>/dev/null; then
        if confirm "Bitwarden detectado. Desinstalar?"; then
            echo "Desinstalando Bitwarden..."
            flatpak uninstall --user -y $pkg_bitwarden 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Bitwarden desinstalado."
        fi
    else
        if confirm "Instalar Bitwarden?"; then
            echo "Instalando Bitwarden..."
            flatpak install --or-update --user --noninteractive flathub $pkg_bitwarden
            touch "$state_file"
            echo "Bitwarden instalado."
        fi
    fi
}

blender_installer() {
    local state_file="$STATE_DIR/blender"
    local pkg_blender="org.blender.Blender"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.blender.Blender 2>/dev/null; then
        if confirm "Blender detectado. Desinstalar?"; then
            echo "Desinstalando Blender..."
            flatpak uninstall --user -y $pkg_blender 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Blender desinstalado."
        fi
    else
        if confirm "Instalar Blender?"; then
            echo "Instalando Blender..."
            flatpak install --or-update --user --noninteractive flathub $pkg_blender
            touch "$state_file"
            echo "Blender instalado."
        fi
    fi
}

bottles_installer() {
    local state_file="$STATE_DIR/bottles"
    local pkg_bottles="com.usebottles.bottles"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.usebottles.bottles 2>/dev/null; then
        if confirm "Bottles detectado. Desinstalar?"; then
            echo "Desinstalando Bottles..."
            flatpak uninstall --user -y $pkg_bottles 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Bottles desinstalado."
        fi
    else
        if confirm "Instalar Bottles?"; then
            echo "Instalando Bottles..."
            flatpak install --or-update --user --noninteractive flathub $pkg_bottles
            touch "$state_file"
            echo "Bottles instalado."
        fi
    fi
}

brave_browser_installer() {
    local state_file="$STATE_DIR/brave_browser"
    local pkg_brave="com.brave.Browser"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.brave.Browser 2>/dev/null; then
        if confirm "Brave Browser detectado. Desinstalar?"; then
            echo "Desinstalando Brave Browser..."
            flatpak uninstall --user -y $pkg_brave 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Brave Browser desinstalado."
        fi
    else
        if confirm "Instalar Brave Browser?"; then
            echo "Instalando Brave Browser..."
            flatpak install --or-update --user --noninteractive flathub $pkg_brave
            touch "$state_file"
            echo "Brave Browser instalado."
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

cargo_installer() {
    local state_file="$STATE_DIR/cargo"
    local pkg_cargo="rustup"

    if [ -f "$state_file" ] || rpm -q rustup &>/dev/null; then
        if confirm "Rustup detectado. Desinstalar?"; then
            echo "Desinstalando Rustup..."
            sudo rpm-ostree uninstall rustup 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Rustup desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Rustup?"; then
            echo "Instalando Rustup..."
            sudo rpm-ostree install rustup
            touch "$state_file"
            echo "Rustup instalado. Reinicie para aplicar."
        fi
    fi
}

chrome_installer() {
    local state_file="$STATE_DIR/chrome"
    local pkg_chrome="com.google.Chrome"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.google.Chrome 2>/dev/null; then
        if confirm "Google Chrome detectado. Desinstalar?"; then
            echo "Desinstalando Google Chrome..."
            flatpak uninstall --user -y $pkg_chrome 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Google Chrome desinstalado."
        fi
    else
        if confirm "Instalar Google Chrome?"; then
            echo "Instalando Google Chrome..."
            flatpak install --or-update --user --noninteractive flathub $pkg_chrome
            touch "$state_file"
            echo "Google Chrome instalado."
        fi
    fi
}

cockpit_client_installer() {
    local state_file="$STATE_DIR/cockpit_client"
    local pkg_cockpitc="org.cockpit_project.CockpitClient"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.cockpit_project.CockpitClient 2>/dev/null; then
        if confirm "Cockpit Client detectado. Desinstalar?"; then
            echo "Desinstalando Cockpit Client..."
            flatpak uninstall --user -y $pkg_cockpitc 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Cockpit Client desinstalado."
        fi
    else
        if confirm "Instalar Cockpit Client?"; then
            echo "Instalando Cockpit Client..."
            flatpak install --or-update --user --noninteractive flathub $pkg_cockpitc
            touch "$state_file"
            echo "Cockpit Client instalado."
        fi
    fi
}

cohesion_installer() {
    local state_file="$STATE_DIR/cohesion"
    local pkg_cohesion="io.github.brunofin.Cohesion"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.brunofin.Cohesion 2>/dev/null; then
        if confirm "Cohesion detectado. Desinstalar?"; then
            echo "Desinstalando Cohesion..."
            flatpak uninstall --user -y $pkg_cohesion 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Cohesion desinstalado."
        fi
    else
        if confirm "Instalar Cohesion?"; then
            echo "Instalando Cohesion..."
            flatpak install --or-update --user --noninteractive flathub $pkg_cohesion
            touch "$state_file"
            echo "Cohesion instalado."
        fi
    fi
}

cpux_installer() {
    local state_file="$STATE_DIR/cpux"
    local pkg_cpux="io.github.thetumultuousunicornofdarkness.cpu-x"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.thetumultuousunicornofdarkness.cpu-x 2>/dev/null; then
        if confirm "CPU-X detectado. Desinstalar?"; then
            echo "Desinstalando CPU-X..."
            flatpak uninstall --user -y $pkg_cpux 2>/dev/null || true
            cleanup_files "$state_file"
            echo "CPU-X desinstalado."
        fi
    else
        if confirm "Instalar CPU-X?"; then
            echo "Instalando CPU-X..."
            flatpak install --or-update --user --noninteractive flathub $pkg_cpux
            touch "$state_file"
            echo "CPU-X instalado."
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

cryptomator_installer() {
    local state_file="$STATE_DIR/cryptomator"
    local pkg_cryptomator="org.cryptomator.Cryptomator"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.cryptomator.Cryptomator 2>/dev/null; then
        if confirm "Cryptomator detectado. Desinstalar?"; then
            echo "Desinstalando Cryptomator..."
            flatpak uninstall --user -y $pkg_cryptomator 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Cryptomator desinstalado."
        fi
    else
        if confirm "Instalar Cryptomator?"; then
            echo "Instalando Cryptomator..."
            flatpak install --or-update --user --noninteractive flathub $pkg_cryptomator
            touch "$state_file"
            echo "Cryptomator instalado."
        fi
    fi
}

darktable_installer() {
    local state_file="$STATE_DIR/darktable"
    local pkg_darktable="org.darktable.Darktable"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.darktable.Darktable 2>/dev/null; then
        if confirm "Darktable detectado. Desinstalar?"; then
            echo "Desinstalando Darktable..."
            flatpak uninstall --user -y $pkg_darktable 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Darktable desinstalado."
        fi
    else
        if confirm "Instalar Darktable?"; then
            echo "Instalando Darktable..."
            flatpak install --or-update --user --noninteractive flathub $pkg_darktable
            touch "$state_file"
            echo "Darktable instalado."
        fi
    fi
}

davinci_resolve_free_installer() {
    local state_file="$STATE_DIR/davinci_resolve_free"
    local pkg_unzip="unzip"

    if [ -f "$state_file" ] || [ -f "/opt/resolve/bin/resolve" ]; then
        if confirm "DaVinci Resolve Free detectado. Desinstalar?"; then
            sudo rm -rf /opt/resolve
            sudo rm -f /usr/share/applications/davinci-resolve.desktop
            if confirm "Desinstalar também unzip?"; then
                sudo rpm-ostree uninstall unzip 2>/dev/null || true
            fi
            cleanup_files "$state_file"
            echo "DaVinci Resolve desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar DaVinci Resolve Free?"; then
            sudo rpm-ostree install unzip
            local useragent="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
            local releaseinfo=$(curl -s -H "$useragent" "https://www.blackmagicdesign.com/api/support/latest-stable-version/davinci-resolve/linux")
            local major=$(echo "$releaseinfo" | grep -o '"major":[0-9]*' | cut -d: -f2)
            local minor=$(echo "$releaseinfo" | grep -o '"minor":[0-9]*' | cut -d: -f2)
            local releaseNum=$(echo "$releaseinfo" | grep -o '"releaseNum":[0-9]*' | cut -d: -f2)
            local downloadId=$(echo "$releaseinfo" | grep -o '"downloadId":"[^"]*"' | cut -d'"' -f4)
            [ "$releaseNum" == "0" ] && filever="${major}.${minor}" || filever="${major}.${minor}.${releaseNum}"
            local archive_name="DaVinci_Resolve_${filever}_Linux"
            local reqjson='{"firstname": "Arch", "lastname": "Linux", "email": "someone@archlinux.org", "phone": "202-555-0194", "country": "us", "street": "Bowery 146", "state": "New York", "city": "AUR", "product": "DaVinci Resolve"}'
            local srcurl=$(curl -s \
                -H 'Host: www.blackmagicdesign.com' \
                -H 'Accept: application/json, text/plain, */*' \
                -H 'Origin: https://www.blackmagicdesign.com' \
                -H "$useragent" \
                -H 'Content-Type: application/json;charset=UTF-8' \
                -H 'Referer: https://www.blackmagicdesign.com/support/download/dfd43085ef224766b06b579ce8a6d097/Linux' \
                -H 'Accept-Encoding: gzip, deflate, br' \
                -H 'Accept-Language: en-US,en;q=0.9' \
                -H 'Authority: www.blackmagicdesign.com' \
                --data-ascii "$reqjson" \
                --compressed \
                "https://www.blackmagicdesign.com/api/register/us/download/${downloadId}")
            curl -L -o "/tmp/${archive_name}.zip" "$srcurl"
            cd /tmp
            unzip "${archive_name}.zip"
            chmod +x "${archive_name}.run"
            sudo ./"${archive_name}.run" --appimage-extract-and-run
            cleanup_files "/tmp/${archive_name}.zip" "/tmp/${archive_name}.run"
            touch "$state_file"
            echo "DaVinci Resolve instalado. Reinicie para aplicar."
        fi
    fi
}

davinci_resolve_studio_installer() {
    local state_file="$STATE_DIR/davinci_resolve_studio"
    local pkg_unzip="unzip"

    if [ -f "$state_file" ] || [ -f "/opt/resolve/bin/resolve" ]; then
        if confirm "DaVinci Resolve Studio detectado. Desinstalar?"; then
            sudo rm -rf /opt/resolve
            sudo rm -f /usr/share/applications/davinci-resolve.desktop
            if confirm "Desinstalar também unzip?"; then
                sudo rpm-ostree uninstall unzip 2>/dev/null || true
            fi
            cleanup_files "$state_file"
            echo "DaVinci Resolve desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar DaVinci Resolve Studio?"; then
            sudo rpm-ostree install unzip
            local useragent="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
            local releaseinfo=$(curl -s -H "$useragent" "https://www.blackmagicdesign.com/api/support/latest-stable-version/davinci-resolve-studio/linux")
            local major=$(echo "$releaseinfo" | grep -o '"major":[0-9]*' | cut -d: -f2)
            local minor=$(echo "$releaseinfo" | grep -o '"minor":[0-9]*' | cut -d: -f2)
            local releaseNum=$(echo "$releaseinfo" | grep -o '"releaseNum":[0-9]*' | cut -d: -f2)
            local downloadId=$(echo "$releaseinfo" | grep -o '"downloadId":"[^"]*"' | cut -d'"' -f4)
            [ "$releaseNum" == "0" ] && filever="${major}.${minor}" || filever="${major}.${minor}.${releaseNum}"
            local archive_name="DaVinci_Resolve_Studio_${filever}_Linux"
            local reqjson='{"firstname": "Arch", "lastname": "Linux", "email": "someone@archlinux.org", "phone": "202-555-0194", "country": "us", "street": "Bowery 146", "state": "New York", "city": "AUR", "product": "DaVinci Resolve Studio"}'
            local srcurl=$(curl -s \
                -H 'Host: www.blackmagicdesign.com' \
                -H 'Accept: application/json, text/plain, */*' \
                -H 'Origin: https://www.blackmagicdesign.com' \
                -H "$useragent" \
                -H 'Content-Type: application/json;charset=UTF-8' \
                -H 'Referer: https://www.blackmagicdesign.com/support/download/0978e9d6e191491da9f4e6eeeb722351/Linux' \
                -H 'Accept-Encoding: gzip, deflate, br' \
                -H 'Accept-Language: en-US,en;q=0.9' \
                -H 'Authority: www.blackmagicdesign.com' \
                --data-ascii "$reqjson" \
                --compressed \
                "https://www.blackmagicdesign.com/api/register/us/download/${downloadId}")
            curl -L -o "/tmp/${archive_name}.zip" "$srcurl"
            cd /tmp
            unzip "${archive_name}.zip"
            chmod +x "${archive_name}.run"
            sudo ./"${archive_name}.run" --appimage-extract-and-run
            cleanup_files "/tmp/${archive_name}.zip" "/tmp/${archive_name}.run"
            touch "$state_file"
            echo "DaVinci Resolve instalado. Reinicie para aplicar."
        fi
    fi
}

davinci_resolve_menu() {
    while true; do
        clear
        echo "=== DaVinci Resolve ==="
        echo "1) Free"
        echo "2) Studio"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; davinci_resolve_free_installer ;;
            2) clear; davinci_resolve_studio_installer ;;
            3) return ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
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

discord_installer() {
    local state_file="$STATE_DIR/discord"
    local pkg_discord="com.discordapp.Discord"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.discordapp.Discord 2>/dev/null; then
        if confirm "Discord detectado. Desinstalar?"; then
            echo "Desinstalando Discord..."
            flatpak uninstall --user -y $pkg_discord 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Discord desinstalado."
        fi
    else
        if confirm "Instalar Discord?"; then
            echo "Instalando Discord..."
            flatpak install --or-update --user --noninteractive flathub $pkg_discord
            touch "$state_file"
            echo "Discord instalado."
        fi
    fi
}

distrobox_installer() {
    local state_file="$STATE_DIR/distrobox"

    if [ -f "$state_file" ] || rpm -q distrobox &>/dev/null; then
        if confirm "Distrobox detectado. Desinstalar?"; then
            echo "Desinstalando Distrobox..."
            sudo rpm-ostree uninstall distrobox 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Distrobox desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Distrobox?"; then
            echo "Instalando Distrobox..."
            sudo rpm-ostree install distrobox
            touch "$state_file"
            echo "Distrobox instalado. Reinicie para aplicar."
        fi
    fi
}

distroshelf_installer() {
    local state_file="$STATE_DIR/distroshelf"
    local pkg_distroshelf="com.ranfdev.DistroShelf"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.ranfdev.DistroShelf 2>/dev/null; then
        if confirm "Distroshelf detectado. Desinstalar?"; then
            echo "Desinstalando Distroshelf..."
            flatpak uninstall --user -y $pkg_distroshelf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Distroshelf desinstalado."
        fi
    else
        if confirm "Instalar Distroshelf?"; then
            echo "Instalando Distroshelf..."
            flatpak install --or-update --user --noninteractive flathub $pkg_distroshelf
            touch "$state_file"
            echo "Distroshelf instalado."
        fi
    fi
}

dlpsgame_installer() {
    clear
    local state_file="$STATE_DIR/dlpsgame"
    local url="https://dlpsgame.com/category/ps4/"

    if [ -f "$state_file" ]; then
        if confirm "DLPSGame já foi aberto. Abrir novamente?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
        fi
    else
        if confirm "Abrir DLPSGame no navegador?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
            touch "$state_file"
            echo "DLPSGame aberto."
        fi
    fi
}

docker_installer() {
    local state_file="$STATE_DIR/docker"
    local pkg_docker="docker docker-compose"

    if [ -f "$state_file" ] || rpm -q docker &>/dev/null; then
        if confirm "Docker detectado. Desinstalar?"; then
            echo "Desinstalando Docker..."
            sudo systemctl stop docker docker.socket 2>/dev/null || true
            sudo systemctl disable docker docker.socket 2>/dev/null || true
            sudo rpm-ostree uninstall docker docker-compose 2>/dev/null || true
            sudo rm -rf /var/lib/docker 2>/dev/null || true
            sudo groupdel docker 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Docker desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Docker?"; then
            echo "Instalando Docker..."
            sudo rpm-ostree install docker docker-compose
            sudo systemctl enable --now docker docker.socket
            sudo usermod -aG docker "$USER"
            touch "$state_file"
            echo "Docker instalado. Reinicie para aplicar."
        fi
    fi
}

earlyoom_installer() {
    local state_file="$STATE_DIR/earlyoom"

    if [ -f "$state_file" ] || rpm -q earlyoom &>/dev/null; then
        if confirm "EarlyOOM detectado. Desinstalar?"; then
            echo "Desinstalando EarlyOOM..."
            sudo systemctl stop earlyoom 2>/dev/null || true
            sudo systemctl disable earlyoom 2>/dev/null || true
            sudo rpm-ostree uninstall earlyoom 2>/dev/null || true
            cleanup_files "$state_file"
            echo "EarlyOOM desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar EarlyOOM?"; then
            echo "Instalando EarlyOOM..."
            sudo rpm-ostree install earlyoom
            sudo systemctl enable earlyoom
            sudo systemctl start earlyoom
            touch "$state_file"
            echo "EarlyOOM instalado. Reinicie para aplicar."
        fi
    fi
}

easyeffects_installer() {
    local state_file="$STATE_DIR/easyeffects"
    local pkg_easyeffects="com.github.wwmm.easyeffects"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.wwmm.easyeffects 2>/dev/null; then
        if confirm "EasyEffects detectado. Desinstalar?"; then
            echo "Desinstalando EasyEffects..."
            flatpak uninstall --user -y $pkg_easyeffects 2>/dev/null || true
            cleanup_files "$state_file"
            echo "EasyEffects desinstalado."
        fi
    else
        if confirm "Instalar EasyEffects?"; then
            echo "Instalando EasyEffects..."
            flatpak install --or-update --user --noninteractive flathub $pkg_easyeffects
            touch "$state_file"
            echo "EasyEffects instalado."
        fi
    fi
}

eden_emulator_installer() {
    local state_file="$STATE_DIR/eden"
    local appimage_path="$APPIMAGE_DIR/Eden-Linux.AppImage"

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "Eden Emulator detectado. Desinstalar?"; then
            echo "Desinstalando Eden Emulator..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            cleanup_files "$state_file"
            echo "Eden Emulator desinstalado."
        fi
    else
        if confirm "Instalar Eden Emulator?"; then
            echo "Instalando Eden Emulator..."
            local download_url=$(curl -s https://api.github.com/repos/eden-emulator/Releases/releases/latest | grep -o '"browser_download_url": *"[^"]*"' | grep -i 'Eden-Linux.*AppImage' | head -1 | cut -d'"' -f4)
            [ -z "$download_url" ] && download_url="https://github.com/eden-emulator/Releases/releases/latest/download/Eden-Linux-amd64-gcc-standard.AppImage"
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            touch "$state_file"
            echo "Eden Emulator instalado."
        fi
    fi
}

endlesskey_installer() {
    local state_file="$STATE_DIR/endlesskey"
    local pkg_endlesskey="org.endlessos.Key"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.endlessos.Key 2>/dev/null; then
        if confirm "Endless Key detectado. Desinstalar?"; then
            echo "Desinstalando Endless Key..."
            flatpak uninstall --user -y $pkg_endlesskey 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Endless Key desinstalado."
        fi
    else
        if confirm "Instalar Endless Key?"; then
            echo "Instalando Endless Key..."
            flatpak install --or-update --user --noninteractive flathub $pkg_endlesskey
            touch "$state_file"
            echo "Endless Key instalado."
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

extra_flatpaks_installer() {
    while true; do
        clear
        echo "=== Extra Flatpaks ==="
        echo "1) Alpaca"
        echo "2) Audacity"
        echo "3) Blender"
        echo "4) CPU-X"
        echo "5) Darktable"
        echo "6) Discord"
        echo "7) Distroshelf"
        echo "8) Extension Manager"
        echo "9) Faugus Launcher"
        echo "10) Fjord Launcher (Unmojang)"
        echo "11) Flatseal"
        echo "12) Foliate"
        echo "13) Gear Lever"
        echo "14) Godot Engine"
        echo "15) Goverlay"
        echo "16) GPU Screen Recorder"
        echo "17) HandBrake"
        echo "18) Helium Browser"
        echo "19) Heroic Games Launcher"
        echo "20) Inkscape"
        echo "21) Kdenlive"
        echo "22) Krita"
        echo "23) LibreOffice"
        echo "24) MangoJuice"
        echo "25) OBS Studio"
        echo "26) Obsidian"
        echo "27) OnlyOffice"
        echo "28) PeaZip"
        echo "29) Pika Backup"
        echo "30) Pinta"
        echo "31) ProtonPlus"
        echo "32) ProtonUp"
        echo "33) Sober"
        echo "34) Steam"
        echo "35) VLC"
        echo "36) Warehouse"
        echo "37) Zen Browser"
        echo "38) Extra Flatpaks 2"
        echo "39) Flatpak 3 e Utilitários"
        echo "40) Voltar"
        echo
        read -p "Selecione uma opção: " flatpak_opcao

        case $flatpak_opcao in
            1) clear; alpaca_installer ;;
            2) clear; audacity_installer ;;
            3) clear; blender_installer ;;
            4) clear; cpux_installer ;;
            5) clear; darktable_installer ;;
            6) clear; discord_installer ;;
            7) clear; distroshelf_installer ;;
            8) clear; extension_manager_installer ;;
            9) clear; faugus_launcher_installer ;;
            10) clear; unmojang_installer ;;
            11) clear; flatseal_installer ;;
            12) clear; foliate_installer ;;
            13) clear; gearlever_installer ;;
            14) clear; godot_installer ;;
            15) clear; goverlay_installer ;;
            16) clear; gpu_screen_recorder_installer ;;
            17) clear; handbrake_installer ;;
            18) clear; helium_browser_installer ;;
            19) clear; heroic_games_launcher_installer ;;
            20) clear; inkscape_installer ;;
            21) clear; kdenlive_installer ;;
            22) clear; krita_installer ;;
            23) clear; libreoffice_installer ;;
            24) clear; mangojuice_installer ;;
            25) clear; obs_installer ;;
            26) clear; obsidian_installer ;;
            27) clear; onlyoffice_installer ;;
            28) clear; peazip_installer ;;
            29) clear; pika_backup_installer ;;
            30) clear; pinta_installer ;;
            31) clear; protonplus_installer ;;
            32) clear; protonup_installer ;;
            33) clear; sober_installer ;;
            34) clear; steam_installer ;;
            35) clear; vlc_installer ;;
            36) clear; warehouse_installer ;;
            37) clear; zen_browser_installer ;;
            38) clear; extra_flatpaks_2_installer ;;
            39) clear; flatpak3_utilitarios_installer ;;
            40) return ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

extra_flatpaks_2_installer() {
    while true; do
        clear
        echo "=== Extra Flatpaks 2 ==="
        echo "1) AnyDesk"
        echo "2) Bazaar"
        echo "3) Bitwarden"
        echo "4) Bottles"
        echo "5) Brave Browser"
        echo "6) Chrome"
        echo "7) Cockpit Client"
        echo "8) Cohesion"
        echo "9) Cryptomator"
        echo "10) EasyEffects"
        echo "11) Endless Key"
        echo "12) FreeCAD"
        echo "13) GCompris"
        echo "14) GeForce NOW"
        echo "15) GeoGebra"
        echo "16) Greenlight"
        echo "17) HTTPie"
        echo "18) Insomnia"
        echo "19) Kalzium"
        echo "20) KeePassXC"
        echo "21) KiCad"
        echo "22) Kolibri"
        echo "23) Lutris"
        echo "24) Microsoft Teams"
        echo "25) Minecraft Bedrock Launcher"
        echo "26) Mission Center"
        echo "27) Moonlight"
        echo "28) Osu!"
        echo "29) Postman"
        echo "30) Prism Launcher"
        echo "31) Protontricks"
        echo "32) QPWGraph"
        echo "33) Rclone UI"
        echo "34) S3Drive"
        echo "35) Signal"
        echo "36) Slack"
        echo "37) Stellarium"
        echo "38) Sunshine"
        echo "39) Telegram"
        echo "40) Voltar"
        echo
        read -p "Selecione uma opção: " flatpak_opcao

        case $flatpak_opcao in
            1) clear; anydesk_installer ;;
            2) clear; bazaar_installer ;;
            3) clear; bitwarden_installer ;;
            4) clear; bottles_installer ;;
            5) clear; brave_browser_installer ;;
            6) clear; chrome_installer ;;
            7) clear; cockpit_client_installer ;;
            8) clear; cohesion_installer ;;
            9) clear; cryptomator_installer ;;
            10) clear; easyeffects_installer ;;
            11) clear; endlesskey_installer ;;
            12) clear; freecad_installer ;;
            13) clear; gcompris_installer ;;
            14) clear; geforce_now_installer ;;
            15) clear; geogebra_installer ;;
            16) clear; greenlight_installer ;;
            17) clear; httpie_installer ;;
            18) clear; insomnia_installer ;;
            19) clear; kalzium_installer ;;
            20) clear; keepassxc_installer ;;
            21) clear; kicad_installer ;;
            22) clear; kolibri_installer ;;
            23) clear; lutris_installer ;;
            24) clear; microsoft_teams_installer ;;
            25) clear; minecraft_bedrock_launcher_installer ;;
            26) clear; missioncenter_installer ;;
            27) clear; moonlight_installer ;;
            28) clear; osu_installer ;;
            29) clear; postman_installer ;;
            30) clear; prism_launcher_installer ;;
            31) clear; protontricks_installer ;;
            32) clear; pwgraph_installer ;;
            33) clear; rcloneui_installer ;;
            34) clear; s3drive_installer ;;
            35) clear; signal_installer ;;
            36) clear; slack_installer ;;
            37) clear; stellarium_installer ;;
            38) clear; sunshine_installer ;;
            39) clear; telegram_installer ;;
            40) return ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

fastfetch_installer() {
    local state_file="$STATE_DIR/fastfetch"

    if [ -f "$state_file" ] || rpm -q fastfetch &>/dev/null; then
        if confirm "fastfetch detectado. Desinstalar?"; then
            echo "Desinstalando fastfetch..."
            sudo rpm-ostree uninstall fastfetch 2>/dev/null || true
            cleanup_files "$state_file"
            echo "fastfetch desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar fastfetch?"; then
            echo "Instalando fastfetch..."
            sudo rpm-ostree install fastfetch
            touch "$state_file"
            echo "fastfetch instalado. Reinicie para aplicar."
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
            sudo lchsh "$USER" <<< "/usr/bin/bash" 2>/dev/null || sudo chsh -s /usr/bin/bash "$USER" 2>/dev/null || true
            cleanup_files "$fish_state"
            rm -rf "$HOME/.config/fish" 2>/dev/null || true
            echo "Fish Shell desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Fish Shell?"; then
            echo "Instalando Fish Shell..."
            sudo rpm-ostree install fish
            sleep 2
            touch "$fish_state"
            echo "Fish Shell instalado."
            
            if confirm "Deseja tornar o Fish o shell padrão do sistema?"; then
                echo "Configurando Fish como shell padrão..."
                
                local fish_path=$(command -v fish 2>/dev/null || which fish 2>/dev/null || echo "/usr/bin/fish")
                
                if [ -f "$fish_path" ]; then
                    if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
                        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
                    fi
                    
                    if command -v lchsh &>/dev/null; then
                        echo "$fish_path" | sudo lchsh "$USER" || echo "Não foi possível alterar o shell com lchsh. Tentando chsh..."
                    fi
                    
                    sudo chsh -s "$fish_path" "$USER" 2>/dev/null || echo "Não foi possível alterar o shell automaticamente. Execute manualmente: chsh -s $fish_path"
                    
                    mkdir -p ~/.config/fish
                    echo "set fish_greeting" > ~/.config/fish/config.fish
                    echo "Fish configurado como shell padrão. Será ativado após o próximo login."
                else
                    echo "Fish instalado mas caminho não encontrado. Configure manualmente com: chsh -s /usr/bin/fish"
                fi
            else
                echo "Fish instalado mas o shell padrão permanece Bash."
                mkdir -p ~/.config/fish
                echo "set fish_greeting" > ~/.config/fish/config.fish
            fi
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

flathub_installer() {
    local flathub_state="$STATE_DIR/flathub"

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

flatpak3_utilitarios_installer() {
    while true; do
        clear
        echo "=== Flatpak 3 e Utilitários ==="
        echo "1) Android Studio"
        echo "2) Acer Manager"
        echo "3) Cargo (Rustup)"
        echo "4) Cockpit Client"
        echo "5) DaVinci Resolve (Menu)"
        echo "6) Docker"
        echo "7) fastfetch"
        echo "8) Gnome Boxes"
        echo "9) Java OpenJDK"
        echo "10) LACT"
        echo "11) LibreWolf"
        echo "12) Linux Toys"
        echo "13) LocalSend"
        echo "14) LogSEQ"
        echo "15) Maven"
        echo "16) Mullvad Browser"
        echo "17) NVM (Node Version Manager)"
        echo "18) Ollama"
        echo "19) OpenRGB"
        echo "20) Oversteer"
        echo "21) Pip (Python)"
        echo "22) Piper"
        echo "23) PNPM"
        echo "24) Portainer"
        echo "25) Powersave"
        echo "26) PyEnv"
        echo "27) Sdkman"
        echo "28) SiriKali"
        echo "29) Solaar"
        echo "30) Stirling PDF (Podman)"
        echo "31) StreamController"
        echo "32) Sublime Text"
        echo "33) Termius"
        echo "34) Thumbnailer"
        echo "35) Ungoogled Chromium"
        echo "36) VSCode"
        echo "37) VSCodium"
        echo "38) WiVRn"
        echo "39) Zed"
        echo "40) Voltar"
        echo
        read -p "Selecione uma opção: " flatpak_opcao

        case $flatpak_opcao in
            1) clear; android_studio_installer ;;
            2) clear; acer_manager_installer ;;
            3) clear; cargo_installer ;;
            4) clear; cockpit_client_installer ;;
            5) clear; davinci_resolve_menu ;;
            6) clear; docker_installer ;;
            7) clear; fastfetch_installer ;;
            8) clear; gnome_boxes_installer ;;
            9) clear; java_openjdk_installer ;;
            10) clear; lact_installer ;;
            11) clear; librewolf_installer ;;
            12) clear; linux_toys_installer ;;
            13) clear; localsend_installer ;;
            14) clear; logseq_installer ;;
            15) clear; maven_installer ;;
            16) clear; mullvad_browser_installer ;;
            17) clear; nvm_installer ;;
            18) clear; ollama_installer ;;
            19) clear; openrgb_installer ;;
            20) clear; oversteer_installer ;;
            21) clear; pip_installer ;;
            22) clear; piper_installer ;;
            23) clear; pnpm_installer ;;
            24) clear; portainer_installer ;;
            25) clear; psaver_installer ;;
            26) clear; pyenv_installer ;;
            27) clear; sdkman_installer ;;
            28) clear; sirikali_installer ;;
            29) clear; solaar_installer ;;
            30) clear; stirling_pdf_installer ;;
            31) clear; streamcontroller_installer ;;
            32) clear; sublime_text_installer ;;
            33) clear; termius_installer ;;
            34) clear; thumbnailer_installer ;;
            35) clear; ungoogled_chromium_installer ;;
            36) clear; vscode_installer ;;
            37) clear; vscodium_installer ;;
            38) clear; wivrn_installer ;;
            39) clear; zed_installer ;;
            40) return ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

flatseal_installer() {
    local state_file="$STATE_DIR/flatseal"
    local pkg_flatseal="com.github.tchx84.Flatseal"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.tchx84.Flatseal 2>/dev/null; then
        if confirm "Flatseal detectado. Desinstalar?"; then
            echo "Desinstalando Flatseal..."
            flatpak uninstall --user -y $pkg_flatseal 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Flatseal desinstalado."
        fi
    else
        if confirm "Instalar Flatseal?"; then
            echo "Instalando Flatseal..."
            flatpak install --or-update --user --noninteractive flathub $pkg_flatseal
            touch "$state_file"
            echo "Flatseal instalado."
        fi
    fi
}

foliate_installer() {
    local state_file="$STATE_DIR/foliate"
    local pkg_foliate="com.github.johnfactotum.Foliate"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.johnfactotum.Foliate 2>/dev/null; then
        if confirm "Foliate detectado. Desinstalar?"; then
            echo "Desinstalando Foliate..."
            flatpak uninstall --user -y $pkg_foliate 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Foliate desinstalado."
        fi
    else
        if confirm "Instalar Foliate?"; then
            echo "Instalando Foliate..."
            flatpak install --or-update --user --noninteractive flathub $pkg_foliate
            touch "$state_file"
            echo "Foliate instalado."
        fi
    fi
}

freecad_installer() {
    local state_file="$STATE_DIR/freecad"
    local pkg_freecad="org.freecad.FreeCAD"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.freecad.FreeCAD 2>/dev/null; then
        if confirm "FreeCAD detectado. Desinstalar?"; then
            echo "Desinstalando FreeCAD..."
            flatpak uninstall --user -y $pkg_freecad 2>/dev/null || true
            cleanup_files "$state_file"
            echo "FreeCAD desinstalado."
        fi
    else
        if confirm "Instalar FreeCAD?"; then
            echo "Instalando FreeCAD..."
            flatpak install --or-update --user --noninteractive flathub $pkg_freecad
            touch "$state_file"
            echo "FreeCAD instalado."
        fi
    fi
}

gcompris_installer() {
    local state_file="$STATE_DIR/gcompris"
    local pkg_gcompris="org.kde.gcompris"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.gcompris 2>/dev/null; then
        if confirm "GCompris detectado. Desinstalar?"; then
            echo "Desinstalando GCompris..."
            flatpak uninstall --user -y $pkg_gcompris 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GCompris desinstalado."
        fi
    else
        if confirm "Instalar GCompris?"; then
            echo "Instalando GCompris..."
            flatpak install --or-update --user --noninteractive flathub $pkg_gcompris
            touch "$state_file"
            echo "GCompris instalado."
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

geforce_now_installer() {
    local state_file="$STATE_DIR/geforce_now"
    local pkg_geforcenow="com.nvidia.geforcenow"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.nvidia.geforcenow 2>/dev/null; then
        if confirm "GeForce NOW detectado. Desinstalar?"; then
            echo "Desinstalando GeForce NOW..."
            flatpak uninstall --user -y $pkg_geforcenow 2>/dev/null || true
            flatpak remote-delete --user GeForceNOW 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GeForce NOW desinstalado."
        fi
    else
        if confirm "Instalar GeForce NOW?"; then
            echo "Instalando GeForce NOW..."
            flatpak install --or-update --user --noninteractive flathub org.freedesktop.Sdk//24.08 2>/dev/null || true
            flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo
            flatpak install --or-update --user --noninteractive GeForceNOW $pkg_geforcenow
            flatpak override --user --nosocket=wayland $pkg_geforcenow
            touch "$state_file"
            echo "GeForce NOW instalado."
        fi
    fi
}

geogebra_installer() {
    local state_file="$STATE_DIR/geogebra"
    local pkg_geogebra="org.geogebra.GeoGebra"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.geogebra.GeoGebra 2>/dev/null; then
        if confirm "GeoGebra detectado. Desinstalar?"; then
            echo "Desinstalando GeoGebra..."
            flatpak uninstall --user -y $pkg_geogebra 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GeoGebra desinstalado."
        fi
    else
        if confirm "Instalar GeoGebra?"; then
            echo "Instalando GeoGebra..."
            flatpak install --or-update --user --noninteractive flathub $pkg_geogebra
            touch "$state_file"
            echo "GeoGebra instalado."
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

gnome_boxes_installer() {
    local state_file="$STATE_DIR/gnome_boxes"
    local pkg_boxes="org.gnome.Boxes"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.gnome.Boxes 2>/dev/null; then
        if confirm "Gnome Boxes detectado. Desinstalar?"; then
            echo "Desinstalando Gnome Boxes..."
            flatpak uninstall --user -y $pkg_boxes 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Gnome Boxes desinstalado."
        fi
    else
        if confirm "Instalar Gnome Boxes?"; then
            echo "Instalando Gnome Boxes..."
            flatpak install --or-update --user --noninteractive flathub $pkg_boxes
            touch "$state_file"
            echo "Gnome Boxes instalado."
        fi
    fi
}

godot_installer() {
    local state_file="$STATE_DIR/godot"
    local pkg_godot="org.godotengine.Godot"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.godotengine.Godot 2>/dev/null; then
        if confirm "Godot Engine detectado. Desinstalar?"; then
            echo "Desinstalando Godot Engine..."
            flatpak uninstall --user -y $pkg_godot 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Godot Engine desinstalado."
        fi
    else
        if confirm "Instalar Godot Engine?"; then
            echo "Instalando Godot Engine..."
            flatpak install --or-update --user --noninteractive flathub $pkg_godot
            touch "$state_file"
            echo "Godot Engine instalado."
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

gpu_screen_recorder_installer() {
    local state_file="$STATE_DIR/gsr"
    local pkg_gsr="com.dec05eba.gpu_screen_recorder"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.dec05eba.gpu_screen_recorder 2>/dev/null; then
        if confirm "GPU Screen Recorder detectado. Desinstalar?"; then
            echo "Desinstalando GPU Screen Recorder..."
            flatpak uninstall --user -y $pkg_gsr 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GPU Screen Recorder desinstalado."
        fi
    else
        if confirm "Instalar GPU Screen Recorder?"; then
            echo "Instalando GPU Screen Recorder..."
            flatpak install --or-update --user --noninteractive flathub $pkg_gsr
            touch "$state_file"
            echo "GPU Screen Recorder instalado."
        fi
    fi
}

greenlight_installer() {
    local state_file="$STATE_DIR/greenlight"
    local pkg_greenlight="io.github.unknownskl.greenlight"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.unknownskl.greenlight 2>/dev/null; then
        if confirm "Greenlight detectado. Desinstalar?"; then
            echo "Desinstalando Greenlight..."
            flatpak uninstall --user -y $pkg_greenlight 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Greenlight desinstalado."
        fi
    else
        if confirm "Instalar Greenlight?"; then
            echo "Instalando Greenlight..."
            flatpak install --or-update --user --noninteractive flathub $pkg_greenlight
            touch "$state_file"
            echo "Greenlight instalado."
        fi
    fi
}

handbrake_installer() {
    local state_file="$STATE_DIR/handbrake"
    local pkg_handbrake="fr.handbrake.ghb"

    if [ -f "$state_file" ] || flatpak list --app | grep -q fr.handbrake.ghb 2>/dev/null; then
        if confirm "HandBrake detectado. Desinstalar?"; then
            echo "Desinstalando HandBrake..."
            flatpak uninstall --user -y $pkg_handbrake 2>/dev/null || true
            cleanup_files "$state_file"
            echo "HandBrake desinstalado."
        fi
    else
        if confirm "Instalar HandBrake?"; then
            echo "Instalando HandBrake..."
            flatpak install --or-update --user --noninteractive flathub $pkg_handbrake
            touch "$state_file"
            echo "HandBrake instalado."
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

heroic_games_launcher_installer() {
    local state_file="$STATE_DIR/heroic_games_launcher"
    local pkg_heroic="com.heroicgameslauncher.hgl"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.heroicgameslauncher.hgl 2>/dev/null; then
        if confirm "Heroic Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Heroic Launcher..."
            flatpak uninstall --user -y $pkg_heroic 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Heroic Launcher desinstalado."
        fi
    else
        if confirm "Instalar Heroic Launcher?"; then
            echo "Instalando Heroic Launcher..."
            flatpak install --or-update --user --noninteractive flathub $pkg_heroic
            touch "$state_file"
            echo "Heroic Launcher instalado."
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

httpie_installer() {
    local state_file="$STATE_DIR/httpie"
    local pkg_httpie="io.httpie.Httpie"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.httpie.Httpie 2>/dev/null; then
        if confirm "HTTPie detectado. Desinstalar?"; then
            echo "Desinstalando HTTPie..."
            flatpak uninstall --user -y $pkg_httpie 2>/dev/null || true
            cleanup_files "$state_file"
            echo "HTTPie desinstalado."
        fi
    else
        if confirm "Instalar HTTPie?"; then
            echo "Instalando HTTPie..."
            flatpak install --user --or-update --noninteractive flathub $pkg_httpie
            touch "$state_file"
            echo "HTTPie instalado."
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

hydra_installer() {
    clear
    local state_file="$STATE_DIR/hydra"
    local url="https://library.hydra.wiki/sources"

    if [ -f "$state_file" ]; then
        if confirm "Hydra Library já foi aberto. Abrir novamente?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
        fi
    else
        if confirm "Abrir Hydra Library no navegador?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
            touch "$state_file"
            echo "Hydra Library aberto."
        fi
    fi
}

hydra_launcher_installer() {
    local state_file="$STATE_DIR/hydra_launcher"
    local appimage_path="$APPIMAGE_DIR/hydralauncher.AppImage"

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "Hydra Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Hydra Launcher..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            cleanup_files "$state_file"
            echo "Hydra Launcher desinstalado."
        fi
    else
        if confirm "Instalar Hydra Launcher?"; then
            echo "Instalando Hydra Launcher..."
            local download_url=$(curl -s https://api.github.com/repos/hydralauncher/hydra/releases/latest | grep -o '"browser_download_url": *"[^"]*"' | grep -i 'hydralauncher.*AppImage' | head -1 | cut -d'"' -f4)
            [ -z "$download_url" ] && download_url="https://github.com/hydralauncher/hydra/releases/latest/download/hydralauncher-latest.AppImage"
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            touch "$state_file"
            echo "Hydra Launcher instalado."
        fi
    fi
}

inkscape_installer() {
    local state_file="$STATE_DIR/inkscape"
    local pkg_inkscape="org.inkscape.Inkscape"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.inkscape.Inkscape 2>/dev/null; then
        if confirm "Inkscape detectado. Desinstalar?"; then
            echo "Desinstalando Inkscape..."
            flatpak uninstall --user -y $pkg_inkscape 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Inkscape desinstalado."
        fi
    else
        if confirm "Instalar Inkscape?"; then
            echo "Instalando Inkscape..."
            flatpak install --or-update --user --noninteractive flathub $pkg_inkscape
            touch "$state_file"
            echo "Inkscape instalado."
        fi
    fi
}

insomnia_installer() {
    local state_file="$STATE_DIR/insomnia"
    local pkg_insomnia="rest.insomnia.Insomnia"

    if [ -f "$state_file" ] || flatpak list --app | grep -q rest.insomnia.Insomnia 2>/dev/null; then
        if confirm "Insomnia detectado. Desinstalar?"; then
            echo "Desinstalando Insomnia..."
            flatpak uninstall --user -y $pkg_insomnia 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Insomnia desinstalado."
        fi
    else
        if confirm "Instalar Insomnia?"; then
            echo "Instalando Insomnia..."
            flatpak install --user --or-update --noninteractive flathub $pkg_insomnia
            touch "$state_file"
            echo "Insomnia instalado."
        fi
    fi
}

instalacao_base_installer() {
    local state_file="$STATE_DIR/instalacao_base"
    local pkg_base="7zip unrar lhasa podman-compose cascadia-mono-nf-fonts"

    if [ -f "$state_file" ] || rpm -q 7zip &>/dev/null; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            sudo rpm-ostree uninstall 7zip unrar lhasa podman-compose cascadia-mono-nf-fonts 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Pacotes Base (compactação, podman-compose e fontes)?"; then
            echo "Instalando Pacotes Base..."
            sudo rpm-ostree install $pkg_base
            touch "$state_file"
            echo "Pacotes Base instalados. Reinicie para aplicar."
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

java_openjdk_installer() {
    local state_file="$STATE_DIR/java_openjdk"

    if [ -f "$state_file" ] || [ -d "/usr/lib/jvm" ]; then
        if confirm "Java OpenJDK detectado. Desinstalar?"; then
            echo "Desinstalando Java OpenJDK..."
            sudo rpm-ostree uninstall java-*-openjdk java-*-openjdk-devel 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Java OpenJDK desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Java OpenJDK?"; then
            echo "Instalando Java OpenJDK..."
            
            local javas=()
            local packages=()
            
            echo "Selecione as versões do Java para instalar:"
            echo "1) Java 8 LTS"
            echo "2) Java 11 LTS"
            echo "3) Java 17 LTS"
            echo "4) Java 21 LTS"
            echo "5) Java 24 Latest"
            echo "6) Todas as versões"
            read -p "Escolha (pode ser múltiplo, ex: 1 3 5): " java_choice
            
            for choice in $java_choice; do
                case $choice in
                    1) javas+=(8) ;;
                    2) javas+=(11) ;;
                    3) javas+=(17) ;;
                    4) javas+=(21) ;;
                    5) javas+=(24) ;;
                    6) javas=(8 11 17 21 24) ;;
                esac
            done
            
            for jav in "${javas[@]}"; do
                if [ $jav == "8" ]; then
                    packages+=(java-1.8.0-openjdk java-1.8.0-openjdk-devel)
                else
                    packages+=(java-${jav}-openjdk java-${jav}-openjdk-devel)
                fi
            done
            
            sudo rpm-ostree install "${packages[@]}"
            
            touch "$state_file"
            echo "Java OpenJDK instalado. Reinicie para aplicar."
        fi
    fi
}

kalzium_installer() {
    local state_file="$STATE_DIR/kalzium"
    local pkg_kalzium="org.kde.kalzium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.kalzium 2>/dev/null; then
        if confirm "Kalzium detectado. Desinstalar?"; then
            echo "Desinstalando Kalzium..."
            flatpak uninstall --user -y $pkg_kalzium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Kalzium desinstalado."
        fi
    else
        if confirm "Instalar Kalzium?"; then
            echo "Instalando Kalzium..."
            flatpak install --or-update --user --noninteractive flathub $pkg_kalzium
            touch "$state_file"
            echo "Kalzium instalado."
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

keepassxc_installer() {
    local state_file="$STATE_DIR/keepassxc"
    local pkg_keepassxc="org.keepassxc.KeePassXC"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.keepassxc.KeePassXC 2>/dev/null; then
        if confirm "KeePassXC detectado. Desinstalar?"; then
            echo "Desinstalando KeePassXC..."
            flatpak uninstall --user -y $pkg_keepassxc 2>/dev/null || true
            cleanup_files "$state_file"
            echo "KeePassXC desinstalado."
        fi
    else
        if confirm "Instalar KeePassXC?"; then
            echo "Instalando KeePassXC..."
            flatpak install --or-update --user --noninteractive flathub $pkg_keepassxc
            touch "$state_file"
            echo "KeePassXC instalado."
        fi
    fi
}

kicad_installer() {
    local state_file="$STATE_DIR/kicad"
    local pkg_kicad="org.kicad.KiCad"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kicad.KiCad 2>/dev/null; then
        if confirm "KiCad detectado. Desinstalar?"; then
            echo "Desinstalando KiCad..."
            flatpak uninstall --user -y $pkg_kicad 2>/dev/null || true
            cleanup_files "$state_file"
            echo "KiCad desinstalado."
        fi
    else
        if confirm "Instalar KiCad?"; then
            echo "Instalando KiCad..."
            flatpak install --or-update --user --noninteractive flathub $pkg_kicad
            touch "$state_file"
            echo "KiCad instalado."
        fi
    fi
}

kolibri_installer() {
    local state_file="$STATE_DIR/kolibri"
    local pkg_kolibri="org.learningequality.Kolibri"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.learningequality.Kolibri 2>/dev/null; then
        if confirm "Kolibri detectado. Desinstalar?"; then
            echo "Desinstalando Kolibri..."
            flatpak uninstall --user -y $pkg_kolibri 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Kolibri desinstalado."
        fi
    else
        if confirm "Instalar Kolibri?"; then
            echo "Instalando Kolibri..."
            flatpak install --or-update --user --noninteractive flathub $pkg_kolibri
            touch "$state_file"
            echo "Kolibri instalado."
        fi
    fi
}

krita_installer() {
    local state_file="$STATE_DIR/krita"
    local pkg_krita="org.kde.krita"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.krita 2>/dev/null; then
        if confirm "Krita detectado. Desinstalar?"; then
            echo "Desinstalando Krita..."
            flatpak uninstall --user -y $pkg_krita 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Krita desinstalado."
        fi
    else
        if confirm "Instalar Krita?"; then
            echo "Instalando Krita..."
            flatpak install --or-update --user --noninteractive flathub $pkg_krita
            touch "$state_file"
            echo "Krita instalado."
        fi
    fi
}

lact_installer() {
    local state_file="$STATE_DIR/lact"
    local pkg_lact="io.github.ilya_zlobintsev.LACT"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.ilya_zlobintsev.LACT 2>/dev/null; then
        if confirm "LACT detectado. Desinstalar?"; then
            echo "Desinstalando LACT..."
            flatpak uninstall --user -y $pkg_lact 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LACT desinstalado."
        fi
    else
        if confirm "Instalar LACT?"; then
            echo "Instalando LACT..."
            flatpak install --or-update --user --noninteractive flathub $pkg_lact
            touch "$state_file"
            echo "LACT instalado."
        fi
    fi
}

libreoffice_installer() {
    local state_file="$STATE_DIR/libreoffice"
    local pkg_libreoffice="org.libreoffice.LibreOffice"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.libreoffice.LibreOffice 2>/dev/null; then
        if confirm "LibreOffice detectado. Desinstalar?"; then
            echo "Desinstalando LibreOffice..."
            flatpak uninstall --user -y $pkg_libreoffice 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LibreOffice desinstalado."
        fi
    else
        if confirm "Instalar LibreOffice?"; then
            echo "Instalando LibreOffice..."
            flatpak install --or-update --user --noninteractive flathub $pkg_libreoffice
            touch "$state_file"
            echo "LibreOffice instalado."
        fi
    fi
}

librewolf_installer() {
    local state_file="$STATE_DIR/librewolf"
    local pkg_librewolf="io.gitlab.librewolf-community"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.gitlab.librewolf-community 2>/dev/null; then
        if confirm "LibreWolf detectado. Desinstalar?"; then
            echo "Desinstalando LibreWolf..."
            flatpak uninstall --user -y $pkg_librewolf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LibreWolf desinstalado."
        fi
    else
        if confirm "Instalar LibreWolf?"; then
            echo "Instalando LibreWolf..."
            flatpak install --or-update --user --noninteractive flathub $pkg_librewolf
            touch "$state_file"
            echo "LibreWolf instalado."
        fi
    fi
}

linux_toys_installer() {
    local state_file="$STATE_DIR/linux_toys"

    if [ -f "$state_file" ] || command -v linux-toys &>/dev/null; then
        if confirm "Linux Toys detectado. Desinstalar?"; then
            echo "Desinstalação manual necessária. Remova ~/.local/bin/linux-toys"
            cleanup_files "$state_file"
        fi
    else
        if confirm "Instalar Linux Toys?"; then
            echo "Instalando Linux Toys..."
            curl -fsSL https://linux.toys/install.sh | bash
            touch "$state_file"
            echo "Linux Toys instalado."
        fi
    fi
}

localsend_installer() {
    local state_file="$STATE_DIR/localsend"
    local pkg_localsend="org.localsend.localsend_app"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.localsend.localsend_app 2>/dev/null; then
        if confirm "LocalSend detectado. Desinstalar?"; then
            echo "Desinstalando LocalSend..."
            flatpak uninstall --user -y $pkg_localsend 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LocalSend desinstalado."
        fi
    else
        if confirm "Instalar LocalSend?"; then
            echo "Instalando LocalSend..."
            flatpak install --or-update --user --noninteractive flathub $pkg_localsend
            touch "$state_file"
            echo "LocalSend instalado."
        fi
    fi
}

logseq_installer() {
    local state_file="$STATE_DIR/logseq"
    local pkg_logseq="com.logseq.Logseq"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.logseq.Logseq 2>/dev/null; then
        if confirm "LogSEQ detectado. Desinstalar?"; then
            echo "Desinstalando LogSEQ..."
            flatpak uninstall --user -y $pkg_logseq 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LogSEQ desinstalado."
        fi
    else
        if confirm "Instalar LogSEQ?"; then
            echo "Instalando LogSEQ..."
            flatpak install --or-update --user --noninteractive flathub $pkg_logseq
            touch "$state_file"
            echo "LogSEQ instalado."
        fi
    fi
}

lutris_installer() {
    local state_file="$STATE_DIR/lutris"
    local pkg_lutris="net.lutris.Lutris"

    if [ -f "$state_file" ] || flatpak list --app | grep -q net.lutris.Lutris 2>/dev/null; then
        if confirm "Lutris detectado. Desinstalar?"; then
            echo "Desinstalando Lutris..."
            flatpak uninstall --user -y $pkg_lutris 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Lutris desinstalado."
        fi
    else
        if confirm "Instalar Lutris?"; then
            echo "Instalando Lutris..."
            flatpak install --or-update --user --noninteractive flathub $pkg_lutris
            touch "$state_file"
            echo "Lutris instalado."
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

maven_installer() {
    local state_file="$STATE_DIR/maven"
    local pkg_maven="maven"

    if [ -f "$state_file" ] || rpm -q maven &>/dev/null; then
        if confirm "Maven detectado. Desinstalar?"; then
            echo "Desinstalando Maven..."
            sudo rpm-ostree uninstall maven 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Maven desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Maven?"; then
            echo "Instalando Maven..."
            sudo rpm-ostree install maven
            touch "$state_file"
            echo "Maven instalado. Reinicie para aplicar."
        fi
    fi
}

microsoft_teams_installer() {
    local state_file="$STATE_DIR/microsoft_teams"
    local pkg_teams="com.github.IsmaelMartinez.teams_for_linux"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.IsmaelMartinez.teams_for_linux 2>/dev/null; then
        if confirm "Microsoft Teams detectado. Desinstalar?"; then
            echo "Desinstalando Microsoft Teams..."
            flatpak uninstall --user -y $pkg_teams 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Microsoft Teams desinstalado."
        fi
    else
        if confirm "Instalar Microsoft Teams?"; then
            echo "Instalando Microsoft Teams..."
            flatpak install --or-update --user --noninteractive flathub $pkg_teams
            touch "$state_file"
            echo "Microsoft Teams instalado."
        fi
    fi
}

minecraft_bedrock_launcher_installer() {
    local state_file="$STATE_DIR/minecraft_bedrock_launcher"
    local pkg_minecraft="io.mrarm.mcpelauncher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.mrarm.mcpelauncher 2>/dev/null; then
        if confirm "Minecraft Bedrock Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Minecraft Bedrock Launcher..."
            flatpak uninstall --user -y $pkg_minecraft 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Minecraft Bedrock Launcher desinstalado."
        fi
    else
        if confirm "Instalar Minecraft Bedrock Launcher?"; then
            echo "Instalando Minecraft Bedrock Launcher..."
            flatpak install --or-update --user --noninteractive flathub $pkg_minecraft
            touch "$state_file"
            echo "Minecraft Bedrock Launcher instalado."
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

missioncenter_installer() {
    local state_file="$STATE_DIR/missioncenter"
    local pkg_missioncenter="io.missioncenter.MissionCenter"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.missioncenter.MissionCenter 2>/dev/null; then
        if confirm "Mission Center detectado. Desinstalar?"; then
            echo "Desinstalando Mission Center..."
            flatpak uninstall --user -y $pkg_missioncenter 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mission Center desinstalado."
        fi
    else
        if confirm "Instalar Mission Center?"; then
            echo "Instalando Mission Center..."
            flatpak install --or-update --user --noninteractive flathub $pkg_missioncenter
            touch "$state_file"
            echo "Mission Center instalado."
        fi
    fi
}

moonlight_installer() {
    local state_file="$STATE_DIR/moonlight"
    local pkg_moonlight="com.moonlight_stream.Moonlight"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.moonlight_stream.Moonlight 2>/dev/null; then
        if confirm "Moonlight detectado. Desinstalar?"; then
            echo "Desinstalando Moonlight..."
            flatpak uninstall --user -y $pkg_moonlight 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Moonlight desinstalado."
        fi
    else
        if confirm "Instalar Moonlight?"; then
            echo "Instalando Moonlight..."
            flatpak install --or-update --user --noninteractive flathub $pkg_moonlight
            touch "$state_file"
            echo "Moonlight instalado."
        fi
    fi
}

mullvad_browser_installer() {
    local state_file="$STATE_DIR/mullvad_browser"
    local pkg_mullvad="net.mullvad.MullvadBrowser"

    if [ -f "$state_file" ] || flatpak list --app | grep -q net.mullvad.MullvadBrowser 2>/dev/null; then
        if confirm "Mullvad Browser detectado. Desinstalar?"; then
            echo "Desinstalando Mullvad Browser..."
            flatpak uninstall --user -y $pkg_mullvad 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mullvad Browser desinstalado."
        fi
    else
        if confirm "Instalar Mullvad Browser?"; then
            echo "Instalando Mullvad Browser..."
            flatpak install --or-update --user --noninteractive flathub $pkg_mullvad
            touch "$state_file"
            echo "Mullvad Browser instalado."
        fi
    fi
}

neovim_lazyvim_installer() {
    local nvim_state="$STATE_DIR/nvim"
    local lazyvim_state="$STATE_DIR/lazyvim"
    local nvim_dir="$HOME/.config/nvim"

    if [ -f "$nvim_state" ] || command -v nvim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            if [ -f "$lazyvim_state" ] || [ -d "$nvim_dir" ]; then
                if confirm "Remover também configuração do LazyVim?"; then
                    rm -rf "$nvim_dir"
                    cleanup_files "$lazyvim_state"
                fi
            fi
            sudo rpm-ostree uninstall neovim 2>/dev/null || true
            cleanup_files "$nvim_state"
            echo "NeoVim desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            sudo rpm-ostree install neovim
            touch "$nvim_state"
            echo "NeoVim instalado. Reinicie para aplicar."
            
            if confirm "Instalar também LazyVim (configuração)?"; then
                echo "Instalando LazyVim..."
                rm -rf "$nvim_dir"
                git clone https://github.com/LazyVim/starter "$nvim_dir"
                rm -rf "$nvim_dir/.git"
                touch "$lazyvim_state"
                echo "LazyVim instalado."
            fi
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
            
            if ! rpm -q rpmfusion-free-release &>/dev/null; then
                echo "AVISO: RPM Fusion não está instalado."
                echo "O RPM Fusion é necessário para instalar os drivers Nvidia."
                echo "Instale o RPM Fusion primeiro (opção no menu principal) e depois tente novamente."
                return 1
            fi
            
            if command -v mokutil &>/dev/null && sudo mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
                echo
                echo "SecureBoot detectado. Para que os drivers funcionem, você precisa configurar a assinatura dos módulos."
                if confirm "Deseja configurar assinatura dos módulos agora?"; then
                    echo "Configurando assinatura dos módulos..."
                    
                    if ! rpm -q akmods &>/dev/null; then
                        sudo rpm-ostree install akmods rpmdevtools
                    fi
                    
                    sudo kmodgenca
                    
                    echo
                    echo "ATENÇÃO: Uma tela azul aparecerá na próxima reinicialização para importar a chave."
                    echo "Durante a reinicialização, escolha 'Enroll MOK' e depois 'Continue'."
                    echo
                    
                    if sudo mokutil --list-new 2>/dev/null | grep -q "MOK"; then
                        echo "Chave MOK já existe. Pulando importação."
                    else
                        sudo mokutil --import /etc/pki/akmods/certs/public_key.der
                    fi
                    
                    cd $HOME
                    if [ ! -d "silverblue-akmods-keys" ]; then
                        git clone https://github.com/CheariX/silverblue-akmods-keys
                    fi
                    cd silverblue-akmods-keys
                    sudo bash setup.sh
                    sudo rpm-ostree install akmods-keys-*.noarch.rpm
                    cd ..
                    echo "Configuração de assinatura concluída."
                else
                    echo "Continuando sem configurar assinatura. O módulo pode não carregar com SecureBoot ativo."
                fi
            else
                echo "SecureBoot não está ativo. Continuando instalação..."
            fi
            
            sudo rpm-ostree install akmod-nvidia xorg-x11-drv-nvidia-cuda
            
            sudo tee /etc/modprobe.d/blacklist-nouveau-nova.conf <<EOF
blacklist nouveau
blacklist nova_core
EOF
            
            sudo rpm-ostree kargs --append=rd.driver.blacklist=nova_core \
                                   --append=modprobe.blacklist=nova_core \
                                   --append=rd.driver.blacklist=nouveau \
                                   --append=modprobe.blacklist=nouveau \
                                   --append=nvidia-drm.modeset=1
            
            touch "$state_file"
            echo
            echo "Nvidia Proprietário instalado. Reinicie o sistema para aplicar as alterações."
            echo "Após reiniciar, verifique com: nvidia-smi"
        fi
    fi
}

nvm_installer() {
    local state_file="$STATE_DIR/nvm"

    if [ -f "$state_file" ] || [ -d "$HOME/.nvm" ]; then
        if confirm "NVM detectado. Desinstalar?"; then
            echo "Desinstalando NVM..."
            rm -rf "$HOME/.nvm"
            sed -i '/NVM_DIR/d' ~/.bashrc ~/.zshrc ~/.profile 2>/dev/null || true
            cleanup_files "$state_file"
            echo "NVM desinstalado."
        fi
    else
        if confirm "Instalar NVM (Node Version Manager)?"; then
            echo "Instalando NVM..."
            
            sudo rpm-ostree install nodejs npm
            
            export NVM_DIR="$HOME/.nvm"
            git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
            cd "$NVM_DIR"
            git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))
            cd
            
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
            
            if [ -f ~/.zshrc ]; then
                echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
            fi
            
            npm i --global yarn
            
            touch "$state_file"
            echo "NVM instalado."
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

ollama_installer() {
    local state_file="$STATE_DIR/ollama"

    if [ -f "$state_file" ] || command -v ollama &>/dev/null; then
        if confirm "Ollama detectado. Desinstalar?"; then
            echo "Desinstalando Ollama..."
            sudo systemctl stop ollama 2>/dev/null || true
            sudo systemctl disable ollama 2>/dev/null || true
            sudo rm -f /usr/local/bin/ollama
            sudo rm -f /etc/systemd/system/ollama.service
            cleanup_files "$state_file"
            echo "Ollama desinstalado."
        fi
    else
        if confirm "Instalar Ollama?"; then
            echo "Instalando Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh
            touch "$state_file"
            echo "Ollama instalado."
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

opencode_installer() {
    local state_file="$STATE_DIR/opencode"

    if [ -f "$state_file" ] || command -v opencode &>/dev/null; then
        if confirm "Opencode detectado. Desinstalar?"; then
            echo "Desinstalando Opencode..."
            rm -f ~/.local/bin/opencode 2>/dev/null || true
            rm -rf ~/.opencode 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Opencode desinstalado."
        fi
    else
        if confirm "Instalar Opencode?"; then
            echo "Instalando Opencode..."
            curl -fsSL https://opencode.ai/install | bash
            touch "$state_file"
            echo "Opencode instalado."
        fi
    fi
}

openrgb_installer() {
    local state_file="$STATE_DIR/openrgb"
    local pkg_openrgb="org.openrgb.OpenRGB"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.openrgb.OpenRGB 2>/dev/null; then
        if confirm "OpenRGB detectado. Desinstalar?"; then
            echo "Desinstalando OpenRGB..."
            flatpak uninstall --user -y $pkg_openrgb 2>/dev/null || true
            cleanup_files "$state_file"
            echo "OpenRGB desinstalado."
        fi
    else
        if confirm "Instalar OpenRGB?"; then
            echo "Instalando OpenRGB..."
            flatpak install --or-update --user --noninteractive flathub $pkg_openrgb
            touch "$state_file"
            echo "OpenRGB instalado."
        fi
    fi
}

ostree_autoupd_installer() {
    local state_file="$STATE_DIR/ostree_autoupd"
    local AUTOPOLICY="stage"

    if [ -f "$state_file" ] || systemctl is-enabled rpm-ostreed-automatic.timer &>/dev/null; then
        if confirm "Auto-updates detectados. Desativar?"; then
            echo "Desativando auto-updates..."
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
            echo "Ativando auto-updates..."
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

osu_installer() {
    local state_file="$STATE_DIR/osu"
    local pkg_osu="sh.ppy.osu"

    if [ -f "$state_file" ] || flatpak list --app | grep -q sh.ppy.osu 2>/dev/null; then
        if confirm "Osu! detectado. Desinstalar?"; then
            echo "Desinstalando Osu!..."
            flatpak uninstall --user -y $pkg_osu 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Osu! desinstalado."
        fi
    else
        if confirm "Instalar Osu!?"; then
            echo "Instalando Osu!..."
            flatpak install --or-update --user --noninteractive flathub $pkg_osu
            touch "$state_file"
            echo "Osu! instalado."
        fi
    fi
}

oversteer_installer() {
    local state_file="$STATE_DIR/oversteer"
    local pkg_oversteer="io.github.berarma.Oversteer"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.berarma.Oversteer 2>/dev/null; then
        if confirm "Oversteer detectado. Desinstalar?"; then
            flatpak uninstall --user -y $pkg_oversteer 2>/dev/null || true
            sudo rm -f /etc/udev/rules.d/99-fanatec-wheel-perms.rules /etc/udev/rules.d/99-logitech-wheel-perms.rules /etc/udev/rules.d/99-thrustmaster-wheel-perms.rules 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Oversteer desinstalado."
        fi
    else
        if confirm "Instalar Oversteer?"; then
            echo "Instalando Oversteer..."
            flatpak install --or-update --user --noninteractive flathub $pkg_oversteer
            if confirm "Instalar configurações extras (regras udev para volantes)?"; then
                sudo curl -s https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-fanatec-wheel-perms.rules -o /etc/udev/rules.d/99-fanatec-wheel-perms.rules
                sudo curl -s https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-logitech-wheel-perms.rules -o /etc/udev/rules.d/99-logitech-wheel-perms.rules
                sudo curl -s https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-thrustmaster-wheel-perms.rules -o /etc/udev/rules.d/99-thrustmaster-wheel-perms.rules
            fi
            touch "$state_file"
            echo "Oversteer instalado."
        fi
    fi
}

peazip_installer() {
    local state_file="$STATE_DIR/peazip"
    local pkg_peazip="io.github.peazip.PeaZip"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.peazip.PeaZip 2>/dev/null; then
        if confirm "PeaZip detectado. Desinstalar?"; then
            echo "Desinstalando PeaZip..."
            flatpak uninstall --user -y $pkg_peazip 2>/dev/null || true
            cleanup_files "$state_file"
            echo "PeaZip desinstalado."
        fi
    else
        if confirm "Instalar PeaZip?"; then
            echo "Instalando PeaZip..."
            flatpak install --or-update --user --noninteractive flathub $pkg_peazip
            touch "$state_file"
            echo "PeaZip instalado."
        fi
    fi
}

pika_backup_installer() {
    local state_file="$STATE_DIR/pika_backup"
    local pkg_pika="org.gnome.World.PikaBackup"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.gnome.World.PikaBackup 2>/dev/null; then
        if confirm "Pika Backup detectado. Desinstalar?"; then
            echo "Desinstalando Pika Backup..."
            flatpak uninstall --user -y $pkg_pika 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pika Backup desinstalado."
        fi
    else
        if confirm "Instalar Pika Backup?"; then
            echo "Instalando Pika Backup..."
            flatpak install --or-update --user --noninteractive flathub $pkg_pika
            touch "$state_file"
            echo "Pika Backup instalado."
        fi
    fi
}

pinta_installer() {
    local state_file="$STATE_DIR/pinta"
    local pkg_pinta="com.github.PintaProject.Pinta"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.PintaProject.Pinta 2>/dev/null; then
        if confirm "Pinta detectado. Desinstalar?"; then
            echo "Desinstalando Pinta..."
            flatpak uninstall --user -y $pkg_pinta 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pinta desinstalado."
        fi
    else
        if confirm "Instalar Pinta?"; then
            echo "Instalando Pinta..."
            flatpak install --or-update --user --noninteractive flathub $pkg_pinta
            touch "$state_file"
            echo "Pinta instalado."
        fi
    fi
}

pip_installer() {
    local state_file="$STATE_DIR/pip"
    local pkg_pip="python-pip"

    if [ -f "$state_file" ] || rpm -q python-pip &>/dev/null; then
        if confirm "Pip detectado. Desinstalar?"; then
            echo "Desinstalando Pip..."
            sudo rpm-ostree uninstall python-pip 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pip desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Pip?"; then
            echo "Instalando Pip..."
            sudo rpm-ostree install python-pip
            touch "$state_file"
            echo "Pip instalado. Reinicie para aplicar."
        fi
    fi
}

piper_installer() {
    local state_file="$STATE_DIR/piper"
    local pkg_piper="org.freedesktop.Piper"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.freedesktop.Piper 2>/dev/null; then
        if confirm "Piper detectado. Desinstalar?"; then
            echo "Desinstalando Piper..."
            flatpak uninstall --user -y $pkg_piper 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Piper desinstalado."
        fi
    else
        if confirm "Instalar Piper?"; then
            echo "Instalando Piper..."
            flatpak install --or-update --user --noninteractive flathub $pkg_piper
            touch "$state_file"
            echo "Piper instalado."
        fi
    fi
}

piracy_installer() {
    clear
    local state_file="$STATE_DIR/piracy"
    local url="https://www.reddit.com/r/Piracy/wiki/megathread/"

    if [ -f "$state_file" ]; then
        if confirm "r/Piracy já foi aberto. Abrir novamente?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
        fi
    else
        if confirm "Abrir r/Piracy no navegador?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
            touch "$state_file"
            echo "r/Piracy aberto."
        fi
    fi
}

pnpm_installer() {
    local state_file="$STATE_DIR/pnpm"
    local pkg_pnpm="pnpm"

    if [ -f "$state_file" ] || rpm -q pnpm &>/dev/null; then
        if confirm "PNPM detectado. Desinstalar?"; then
            echo "Desinstalando PNPM..."
            sudo rpm-ostree uninstall pnpm 2>/dev/null || true
            cleanup_files "$state_file"
            echo "PNPM desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar PNPM?"; then
            echo "Instalando PNPM..."
            sudo rpm-ostree install pnpm
            touch "$state_file"
            echo "PNPM instalado. Reinicie para aplicar."
        fi
    fi
}

portainer_installer() {
    local state_file="$STATE_DIR/portainer"

    if [ -f "$state_file" ] || sudo podman ps -a --format "{{.Names}}" | grep -q "portainer" 2>/dev/null; then
        if confirm "Portainer detectado. Desinstalar?"; then
            echo "Desinstalando Portainer..."
            sudo podman stop portainer 2>/dev/null || true
            sudo podman rm portainer 2>/dev/null || true
            sudo podman volume rm portainer_data 2>/dev/null || true
            sudo rm -f /etc/systemd/system/portainer.service 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Portainer desinstalado."
        fi
    else
        if confirm "Instalar Portainer?"; then
            echo "Instalando Portainer..."
            
            if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
                echo "Docker ou Podman não encontrado. Instale o Docker primeiro."
                return 1
            fi
            
            if command -v docker &>/dev/null; then
                docker volume create portainer_data
                docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
            else
                podman volume create portainer_data
                podman run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data docker.io/portainer/portainer-ce:lts
            fi
            
            touch "$state_file"
            echo "Portainer instalado. Acesse em https://localhost:9443"
        fi
    fi
}

postman_installer() {
    local state_file="$STATE_DIR/postman"
    local pkg_postman="com.getpostman.Postman"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.getpostman.Postman 2>/dev/null; then
        if confirm "Postman detectado. Desinstalar?"; then
            echo "Desinstalando Postman..."
            flatpak uninstall --user -y $pkg_postman 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Postman desinstalado."
        fi
    else
        if confirm "Instalar Postman?"; then
            echo "Instalando Postman..."
            flatpak install --user --or-update --noninteractive flathub $pkg_postman
            touch "$state_file"
            echo "Postman instalado."
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

prism_launcher_installer() {
    local state_file="$STATE_DIR/prism_launcher"
    local pkg_prism="org.prismlauncher.PrismLauncher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.prismlauncher.PrismLauncher 2>/dev/null; then
        if confirm "Prism Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Prism Launcher..."
            flatpak uninstall --user -y $pkg_prism 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Prism Launcher desinstalado."
        fi
    else
        if confirm "Instalar Prism Launcher?"; then
            echo "Instalando Prism Launcher..."
            flatpak install --or-update --user --noninteractive flathub $pkg_prism
            touch "$state_file"
            echo "Prism Launcher instalado."
        fi
    fi
}

protonplus_installer() {
    local state_file="$STATE_DIR/protonplus"
    local pkg_protonplus="com.vysp3r.ProtonPlus"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.vysp3r.ProtonPlus 2>/dev/null; then
        if confirm "ProtonPlus detectado. Desinstalar?"; then
            echo "Desinstalando ProtonPlus..."
            flatpak uninstall --user -y $pkg_protonplus 2>/dev/null || true
            cleanup_files "$state_file"
            echo "ProtonPlus desinstalado."
        fi
    else
        if confirm "Instalar ProtonPlus?"; then
            echo "Instalando ProtonPlus..."
            flatpak install --or-update --user --noninteractive flathub $pkg_protonplus
            touch "$state_file"
            echo "ProtonPlus instalado."
        fi
    fi
}

protontricks_installer() {
    local state_file="$STATE_DIR/protontricks"
    local pkg_protontricks="com.github.Matoking.protontricks"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.Matoking.protontricks 2>/dev/null; then
        if confirm "Protontricks detectado. Desinstalar?"; then
            echo "Desinstalando Protontricks..."
            flatpak uninstall --user -y $pkg_protontricks 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Protontricks desinstalado."
        fi
    else
        if confirm "Instalar Protontricks?"; then
            echo "Instalando Protontricks..."
            flatpak install --or-update --user --noninteractive flathub $pkg_protontricks
            touch "$state_file"
            echo "Protontricks instalado."
        fi
    fi
}

protonup_installer() {
    local state_file="$STATE_DIR/protonup"
    local pkg_protonup="net.davidotek.pupgui2"

    if [ -f "$state_file" ] || flatpak list --app | grep -q net.davidotek.pupgui2 2>/dev/null; then
        if confirm "ProtonUp detectado. Desinstalar?"; then
            echo "Desinstalando ProtonUp..."
            flatpak uninstall --user -y $pkg_protonup 2>/dev/null || true
            cleanup_files "$state_file"
            echo "ProtonUp desinstalado."
        fi
    else
        if confirm "Instalar ProtonUp?"; then
            echo "Instalando ProtonUp..."
            flatpak install --or-update --user --noninteractive flathub $pkg_protonup
            touch "$state_file"
            echo "ProtonUp instalado."
        fi
    fi
}

psaver_installer() {
    local state_file="$STATE_DIR/psaver"

    if [ -f "$state_file" ] || [ -f "/etc/systemd/system/powersave" ]; then
        if confirm "Powersave detectado. Desinstalar?"; then
            echo "Desinstalando Powersave..."
            sudo systemctl stop powersave 2>/dev/null || true
            sudo systemctl disable powersave 2>/dev/null || true
            sudo rm -f /etc/systemd/system/powersave /usr/local/bin/powersave.sh 2>/dev/null || true
            sudo sed -i '/powersave/d' /etc/default/grub 2>/dev/null || true
            sudo rm -f /etc/default/grub.d/powersave.cfg 2>/dev/null || true
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Powersave desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Powersave?"; then
            echo "Instalando Powersave..."
            echo '#!/bin/bash
set -e

CPU_GOV="powersave"
SCHEDULER="none"
ENERGY_PERF="power"
CPU_MAX="100"
CPU_MIN="0"

apply_settings() {
    echo "$CPU_GOV" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    echo "$ENERGY_PERF" | tee /sys/devices/system/cpu/cpu*/power/energy_performance_preference >/dev/null 2>&1 || true

    if [ -f /sys/devices/system/cpu/intel_pstate/max_perf_pct ]; then
        echo "$CPU_MAX" | tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null
        echo "$CPU_MIN" | tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null
    fi

    if [ -f /sys/block/sda/queue/scheduler ]; then
        echo "$SCHEDULER" | tee /sys/block/sd*/queue/scheduler >/dev/null 2>&1 || true
    fi
}

apply_settings
exit 0' | sudo tee /usr/local/bin/powersave.sh >/dev/null
            sudo chmod +x /usr/local/bin/powersave.sh
            echo '[Unit]
Description=Power Save Settings
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/powersave.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/powersave >/dev/null
            sudo systemctl enable powersave
            sudo systemctl start powersave
            sudo mkdir -p /etc/default/grub.d
            echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} intel_pstate=passive"' | sudo tee /etc/default/grub.d/powersave.cfg >/dev/null
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            touch "$state_file"
            echo "Powersave instalado. Reinicie para aplicar."
        fi
    fi
}

pwgraph_installer() {
    local state_file="$STATE_DIR/pwgraph"
    local pkg_pwgraph="org.rncbc.qpwgraph"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.rncbc.qpwgraph 2>/dev/null; then
        if confirm "QPWGraph detectado. Desinstalar?"; then
            echo "Desinstalando QPWGraph..."
            flatpak uninstall --user -y $pkg_pwgraph 2>/dev/null || true
            cleanup_files "$state_file"
            echo "QPWGraph desinstalado."
        fi
    else
        if confirm "Instalar QPWGraph?"; then
            echo "Instalando QPWGraph..."
            flatpak install --or-update --user --noninteractive flathub $pkg_pwgraph
            touch "$state_file"
            echo "QPWGraph instalado."
        fi
    fi
}

pyenv_installer() {
    local state_file="$STATE_DIR/pyenv"

    if [ -f "$state_file" ] || [ -d "$HOME/.pyenv" ]; then
        if confirm "PyEnv detectado. Desinstalar?"; then
            echo "Desinstalando PyEnv..."
            rm -rf "$HOME/.pyenv"
            sed -i '/PYENV_ROOT/d' ~/.bashrc ~/.zshrc ~/.profile 2>/dev/null || true
            cleanup_files "$state_file"
            echo "PyEnv desinstalado."
        fi
    else
        if confirm "Instalar PyEnv?"; then
            echo "Instalando PyEnv..."
            
            local packages=()
            if [[ "$ID_LIKE" =~ (rhel|fedora) ]] || [[ "$ID" =~ (fedora) ]]; then
                packages=(make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2)
            fi
            
            if [ ${#packages[@]} -gt 0 ]; then
                sudo rpm-ostree install "${packages[@]}"
            fi
            
            curl -fsSL https://pyenv.run | bash
            
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
            echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
            echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
            
            if [ -f ~/.zshrc ]; then
                echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
                echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
                echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc
            fi
            
            git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
            echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
            
            touch "$state_file"
            echo "PyEnv instalado."
        fi
    fi
}

rcloneui_installer() {
    local state_file="$STATE_DIR/rcloneui"
    local pkg_rcloneui="com.rcloneui.RcloneUI"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.rcloneui.RcloneUI 2>/dev/null; then
        if confirm "Rclone UI detectado. Desinstalar?"; then
            echo "Desinstalando Rclone UI..."
            flatpak uninstall --user -y $pkg_rcloneui 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Rclone UI desinstalado."
        fi
    else
        if confirm "Instalar Rclone UI?"; then
            echo "Instalando Rclone UI..."
            flatpak install --or-update --user --noninteractive flathub $pkg_rcloneui
            touch "$state_file"
            echo "Rclone UI instalado."
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
        
        echo "ATENÇÃO: A remoção via override no rpm-ostree requer um reboot para aplicar as alterações."
        echo "Os seguintes pacotes serão marcados para remoção permanente via override:"
        
        if [ "$desktop_env" = "GNOME" ]; then
            local gnome_bloat=(
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
                libreoffice-*
            )
            
            local filtered_bloat=()
            for pkg in "${gnome_bloat[@]}"; do
                if rpm -q "$pkg" &>/dev/null 2>&1; then
                    filtered_bloat+=("$pkg")
                fi
            done
            
            if rpm -q firefox &>/dev/null 2>&1 || rpm -q firefox-langpacks &>/dev/null 2>&1; then
                echo "Removendo Firefox e langpacks..."
                sudo rpm-ostree override remove firefox firefox-langpacks || true
            fi
            
            if [ ${#filtered_bloat[@]} -gt 0 ]; then
                if confirm "Aplicar overrides para remover estes pacotes permanentemente?"; then
                    echo "Removendo todos os pacotes em uma única operação..."
                    sudo rpm-ostree override remove "${filtered_bloat[@]}" || true
                fi
            else
                echo "Nenhum pacote encontrado para remover."
            fi
            
            echo "Removendo pacotes Flatpak do GNOME..."
            local flatpak_gnome_bloat=(
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
            for app in "${flatpak_gnome_bloat[@]}"; do
                echo "Removendo Flatpak: $app..."
                flatpak uninstall --system -y "$app" 2>/dev/null || true
                flatpak uninstall --user -y "$app" 2>/dev/null || true
            done
            
        elif [ "$desktop_env" = "KDE" ]; then
            local kde_bloat=(
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
                libreoffice-*
            )
            
            local filtered_bloat=()
            for pkg in "${kde_bloat[@]}"; do
                if rpm -q "$pkg" &>/dev/null 2>&1; then
                    filtered_bloat+=("$pkg")
                fi
            done
            
            if rpm -q firefox &>/dev/null 2>&1 || rpm -q firefox-langpacks &>/dev/null 2>&1; then
                echo "Removendo Firefox e langpacks..."
                sudo rpm-ostree override remove firefox firefox-langpacks || true
            fi
            
            if [ ${#filtered_bloat[@]} -gt 0 ]; then
                if confirm "Aplicar overrides para remover estes pacotes permanentemente?"; then
                    echo "Removendo todos os pacotes em uma única operação..."
                    sudo rpm-ostree override remove "${filtered_bloat[@]}" || true
                fi
            else
                echo "Nenhum pacote encontrado para remover."
            fi
            
            echo "Removendo pacotes Flatpak do KDE..."
            local flatpak_kde_bloat=(
                org.kde.kalendar
                org.kde.kontact
                org.kde.kmail
                org.kde.korganizer
                org.kde.akregator
                org.kde.kget
                org.kde.k3b
                org.kde.dragonplayer
                org.kde.juk
                org.kde.kmahjongg
                org.kde.kmines
                org.kde.ksudoku
                org.kde.kpat
            )
            for app in "${flatpak_kde_bloat[@]}"; do
                echo "Removendo Flatpak: $app..."
                flatpak uninstall --system -y "$app" 2>/dev/null || true
                flatpak uninstall --user -y "$app" 2>/dev/null || true
            done
            
        elif [ "$desktop_env" = "COSMIC" ]; then
            local cosmic_bloat=(
                gnome-photos
                gnome-maps
                gnome-music
                gnome-weather
                libreoffice-*
            )
            
            local filtered_bloat=()
            for pkg in "${cosmic_bloat[@]}"; do
                if rpm -q "$pkg" &>/dev/null 2>&1; then
                    filtered_bloat+=("$pkg")
                fi
            done
            
            if rpm -q firefox &>/dev/null 2>&1 || rpm -q firefox-langpacks &>/dev/null 2>&1; then
                echo "Removendo Firefox e langpacks..."
                sudo rpm-ostree override remove firefox firefox-langpacks || true
            fi
            
            if [ ${#filtered_bloat[@]} -gt 0 ]; then
                if confirm "Aplicar overrides para remover estes pacotes permanentemente?"; then
                    echo "Removendo todos os pacotes em uma única operação..."
                    sudo rpm-ostree override remove "${filtered_bloat[@]}" || true
                fi
            else
                echo "Nenhum pacote encontrado para remover."
            fi
            
            echo "Removendo pacotes Flatpak do COSMIC..."
            local flatpak_cosmic_bloat=(
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
            )
            for app in "${flatpak_cosmic_bloat[@]}"; do
                echo "Removendo Flatpak: $app..."
                flatpak uninstall --system -y "$app" 2>/dev/null || true
                flatpak uninstall --user -y "$app" 2>/dev/null || true
            done
        fi
        
        echo "Limpando dependências não utilizadas..."
        flatpak uninstall --unused -y 2>/dev/null || true
        
        touch "$STATE_DIR/bloatware_removed"
        echo "Remoção de bloatware concluída. Reinicie para aplicar as alterações do rpm-ostree."
    fi
}

romsfun_installer() {
    clear
    local state_file="$STATE_DIR/romsfun"
    local url="https://romsfun.com/"

    if [ -f "$state_file" ]; then
        if confirm "RomsFun já foi aberto. Abrir novamente?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
        fi
    else
        if confirm "Abrir RomsFun no navegador?"; then
            xdg-open "$url" 2>/dev/null || open "$url" 2>/dev/null || echo "Abra manualmente: $url"
            touch "$state_file"
            echo "RomsFun aberto."
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

s3drive_installer() {
    local state_file="$STATE_DIR/s3drive"
    local pkg_s3drive="io.kapsa.drive"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.kapsa.drive 2>/dev/null; then
        if confirm "S3Drive detectado. Desinstalar?"; then
            echo "Desinstalando S3Drive..."
            flatpak uninstall --user -y $pkg_s3drive 2>/dev/null || true
            cleanup_files "$state_file"
            echo "S3Drive desinstalado."
        fi
    else
        if confirm "Instalar S3Drive?"; then
            echo "Instalando S3Drive..."
            flatpak install --or-update --user --noninteractive flathub $pkg_s3drive
            touch "$state_file"
            echo "S3Drive instalado."
        fi
    fi
}

sdkman_installer() {
    local state_file="$STATE_DIR/sdkman"
    local pkg_unzip="unzip zip"

    if [ -f "$state_file" ] || [ -d "$HOME/.sdkman" ]; then
        if confirm "Sdkman detectado. Desinstalar?"; then
            rm -rf "$HOME/.sdkman"
            sed -i '/SDKMAN/d' ~/.bashrc
            [ -f ~/.zshrc ] && sed -i '/SDKMAN/d' ~/.zshrc
            [ -f ~/.config/fish/config.fish ] && sed -i '/SDKMAN/d' ~/.config/fish/config.fish
            if confirm "Desinstalar também unzip e zip?"; then
                sudo rpm-ostree uninstall unzip zip 2>/dev/null || true
            fi
            cleanup_files "$state_file"
        fi
    else
        if confirm "Instalar Sdkman?"; then
            sudo rpm-ostree install unzip zip
            curl -s "https://get.sdkman.io" | bash
            touch "$state_file"
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

signal_installer() {
    local state_file="$STATE_DIR/signal"
    local pkg_signal="org.signal.Signal"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.signal.Signal 2>/dev/null; then
        if confirm "Signal detectado. Desinstalar?"; then
            echo "Desinstalando Signal..."
            flatpak uninstall --user -y $pkg_signal 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Signal desinstalado."
        fi
    else
        if confirm "Instalar Signal?"; then
            echo "Instalando Signal..."
            flatpak install --or-update --user --noninteractive flathub $pkg_signal
            touch "$state_file"
            echo "Signal instalado."
        fi
    fi
}

sirikali_installer() {
    local state_file="$STATE_DIR/sirikali"
    local pkg_sirikali="io.github.mhogomchungu.sirikali"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.mhogomchungu.sirikali 2>/dev/null; then
        if confirm "SiriKali detectado. Desinstalar?"; then
            echo "Desinstalando SiriKali..."
            flatpak uninstall --user -y $pkg_sirikali 2>/dev/null || true
            cleanup_files "$state_file"
            echo "SiriKali desinstalado."
        fi
    else
        if confirm "Instalar SiriKali?"; then
            echo "Instalando SiriKali..."
            flatpak install --or-update --user --noninteractive flathub $pkg_sirikali
            touch "$state_file"
            echo "SiriKali instalado."
        fi
    fi
}

slack_installer() {
    local state_file="$STATE_DIR/slack"
    local pkg_slack="com.slack.Slack"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.slack.Slack 2>/dev/null; then
        if confirm "Slack detectado. Desinstalar?"; then
            echo "Desinstalando Slack..."
            flatpak uninstall --user -y $pkg_slack 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Slack desinstalado."
        fi
    else
        if confirm "Instalar Slack?"; then
            echo "Instalando Slack..."
            flatpak install --or-update --user --noninteractive flathub $pkg_slack
            touch "$state_file"
            echo "Slack instalado."
        fi
    fi
}

snapd_installer() {
    local state_file="$STATE_DIR/snapd"

    if [ -f "$state_file" ] || rpm -q snapd &>/dev/null; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket 2>/dev/null || true
            sudo systemctl disable snapd.socket 2>/dev/null || true
            sudo rpm-ostree uninstall snapd 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Snapd desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Snapd?"; then
            echo "Instalando Snapd..."
            sudo rpm-ostree install snapd
            sudo systemctl enable --now snapd.socket 2>/dev/null || echo "Serviço snapd.socket não disponível. Pode ser necessário reiniciar."
            touch "$state_file"
            echo "Snapd instalado. Reinicie para aplicar."
        fi
    fi
}

sober_installer() {
    local state_file="$STATE_DIR/sober"
    local pkg_sober="org.vinegarhq.Sober"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.vinegarhq.Sober 2>/dev/null; then
        if confirm "Sober detectado. Desinstalar?"; then
            echo "Desinstalando Sober..."
            flatpak uninstall --user -y $pkg_sober 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Sober desinstalado."
        fi
    else
        if confirm "Instalar Sober?"; then
            echo "Instalando Sober..."
            flatpak install --or-update --user --noninteractive flathub $pkg_sober
            touch "$state_file"
            echo "Sober instalado."
        fi
    fi
}

solaar_installer() {
    local state_file="$STATE_DIR/solaar"
    local pkg_solaar="io.github.pwr_solaar.solaar"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.pwr_solaar.solaar 2>/dev/null; then
        if confirm "Solaar detectado. Desinstalar?"; then
            echo "Desinstalando Solaar..."
            flatpak uninstall --user -y $pkg_solaar 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Solaar desinstalado."
        fi
    else
        if confirm "Instalar Solaar?"; then
            echo "Instalando Solaar..."
            flatpak install --or-update --user --noninteractive flathub $pkg_solaar
            touch "$state_file"
            echo "Solaar instalado."
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

stellarium_installer() {
    local state_file="$STATE_DIR/stellarium"
    local pkg_stellarium="org.stellarium.Stellarium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.stellarium.Stellarium 2>/dev/null; then
        if confirm "Stellarium detectado. Desinstalar?"; then
            echo "Desinstalando Stellarium..."
            flatpak uninstall --user -y $pkg_stellarium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Stellarium desinstalado."
        fi
    else
        if confirm "Instalar Stellarium?"; then
            echo "Instalando Stellarium..."
            flatpak install --or-update --user --noninteractive flathub $pkg_stellarium
            touch "$state_file"
            echo "Stellarium instalado."
        fi
    fi
}

stirling_pdf_installer() {
    local state_file="$STATE_DIR/stirling_pdf"

    if [ -f "$state_file" ] || docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "stirling-pdf"; then
        if confirm "Stirling PDF detectado. Desinstalar?"; then
            echo "Desinstalando Stirling PDF..."
            docker stop stirling-pdf 2>/dev/null || true
            docker rm stirling-pdf 2>/dev/null || true
            docker rmi stirlingtools/stirling-pdf:latest 2>/dev/null || true
            docker rmi stirlingtools/stirling-pdf:latest-fat 2>/dev/null || true
            docker rmi stirlingtools/stirling-pdf:latest-ultra-lite 2>/dev/null || true
            rm -rf ~/stirling-pdf-data 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Stirling PDF desinstalado."
        fi
    else
        if confirm "Instalar Stirling PDF (via Docker)?"; then
            if ! command -v docker &>/dev/null; then
                echo "Docker não encontrado. Instale o Docker primeiro (opção Docker no menu Flatpak 3 e Utilitários)."
                return 1
            fi
            
            echo "Selecione a versão:"
            echo "1) Standard (latest) - All PDF features, balanced features & size (Recomendado)"
            echo "2) Fat (latest-fat) - Everything + extra tools, maximum features"
            echo "3) Ultra-Lite (latest-ultra-lite) - Core features only, minimal size"
            read -p "Escolha (1-3): " version_choice
            
            case $version_choice in
                1) TAG="latest" ;;
                2) TAG="latest-fat" ;;
                3) TAG="latest-ultra-lite" ;;
                *) echo "Opção inválida. Usando latest."; TAG="latest" ;;
            esac
            
            echo "Instalando Stirling PDF com tag: $TAG"
            
            mkdir -p ~/stirling-pdf-data
            
            echo "Baixando imagem Docker..."
            docker pull stirlingtools/stirling-pdf:$TAG
            
            echo "Iniciando container..."
            docker run -d \
                --name stirling-pdf \
                --restart unless-stopped \
                -p 8080:8080 \
                -v ~/stirling-pdf-data:/configs \
                -e MODE=BOTH \
                stirlingtools/stirling-pdf:$TAG
            
            echo "Aguardando inicialização..."
            sleep 3
            
            if docker ps | grep -q stirling-pdf; then
                touch "$state_file"
                echo
                echo "✓ Stirling PDF instalado com sucesso!"
                echo "✓ Acesse em: http://localhost:8080"
                echo "✓ Dados persistentes salvos em: ~/stirling-pdf-data"
                echo
                echo "Comandos úteis:"
                echo "  - Ver logs: docker logs stirling-pdf"
                echo "  - Parar: docker stop stirling-pdf"
                echo "  - Iniciar: docker start stirling-pdf"
                echo "  - Remover: docker rm -f stirling-pdf"
            else
                echo "Erro: Falha ao iniciar o container Stirling PDF."
                return 1
            fi
        fi
    fi
}

streamcontroller_installer() {
    local state_file="$STATE_DIR/streamcontroller"
    local pkg_streamcontroller="com.core447.StreamController"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.core447.StreamController 2>/dev/null; then
        if confirm "StreamController detectado. Desinstalar?"; then
            echo "Desinstalando StreamController..."
            flatpak uninstall --user -y $pkg_streamcontroller 2>/dev/null || true
            cleanup_files "$state_file"
            echo "StreamController desinstalado."
        fi
    else
        if confirm "Instalar StreamController?"; then
            echo "Instalando StreamController..."
            flatpak install --or-update --user --noninteractive flathub $pkg_streamcontroller
            touch "$state_file"
            echo "StreamController instalado."
        fi
    fi
}

sublime_text_installer() {
    local state_file="$STATE_DIR/sublime"
    local pkg_sublime="com.sublimehq.SublimeText"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.sublimehq.SublimeText 2>/dev/null; then
        if confirm "Sublime Text detectado. Desinstalar?"; then
            echo "Desinstalando Sublime Text..."
            flatpak uninstall --user -y $pkg_sublime 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Sublime Text desinstalado."
        fi
    else
        if confirm "Instalar Sublime Text?"; then
            echo "Instalando Sublime Text..."
            flatpak install --or-update --user --noninteractive flathub $pkg_sublime
            touch "$state_file"
            echo "Sublime Text instalado."
        fi
    fi
}

sunshine_installer() {
    local state_file="$STATE_DIR/sunshine"
    local pkg_sunshine="dev.lizardbyte.app.Sunshine"

    if [ -f "$state_file" ] || flatpak list --app | grep -q dev.lizardbyte.app.Sunshine 2>/dev/null; then
        if confirm "Sunshine detectado. Desinstalar?"; then
            echo "Desinstalando Sunshine..."
            flatpak uninstall --user -y $pkg_sunshine 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Sunshine desinstalado."
        fi
    else
        if confirm "Instalar Sunshine?"; then
            echo "Instalando Sunshine..."
            flatpak install --or-update --user --noninteractive flathub $pkg_sunshine
            flatpak run --command=additional-install.sh $pkg_sunshine 2>/dev/null || true
            touch "$state_file"
            echo "Sunshine instalado."
        fi
    fi
}

telegram_installer() {
    local state_file="$STATE_DIR/telegram"
    local pkg_telegram="org.telegram.desktop"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.telegram.desktop 2>/dev/null; then
        if confirm "Telegram detectado. Desinstalar?"; then
            echo "Desinstalando Telegram..."
            flatpak uninstall --user -y $pkg_telegram 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Telegram desinstalado."
        fi
    else
        if confirm "Instalar Telegram?"; then
            echo "Instalando Telegram..."
            flatpak install --or-update --user --noninteractive flathub $pkg_telegram
            touch "$state_file"
            echo "Telegram instalado."
        fi
    fi
}

termius_installer() {
    local state_file="$STATE_DIR/termius"
    local pkg_termius="com.termius.Termius"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.termius.Termius 2>/dev/null; then
        if confirm "Termius detectado. Desinstalar?"; then
            echo "Desinstalando Termius..."
            flatpak uninstall --user -y $pkg_termius 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Termius desinstalado."
        fi
    else
        if confirm "Instalar Termius?"; then
            echo "Instalando Termius..."
            flatpak install --or-update --user --noninteractive flathub $pkg_termius
            touch "$state_file"
            echo "Termius instalado."
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

thumbnailer_installer() {
    local state_file="$STATE_DIR/thumbnailer"
    local pkg_thumbnailer="ffmpegthumbnailer"

    if [ -f "$state_file" ] || rpm -q ffmpegthumbnailer &>/dev/null; then
        if confirm "Thumbnailer detectado. Desinstalar?"; then
            echo "Desinstalando Thumbnailer..."
            sudo rpm-ostree uninstall ffmpegthumbnailer 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Thumbnailer desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Thumbnailer?"; then
            echo "Instalando Thumbnailer..."
            sudo rpm-ostree install ffmpegthumbnailer
            touch "$state_file"
            echo "Thumbnailer instalado. Reinicie para aplicar."
        fi
    fi
}

ufw_installer() {
    local state_file="$STATE_DIR/ufw"

    if [ -f "$state_file" ] || rpm -q ufw &>/dev/null; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            sudo systemctl stop ufw 2>/dev/null || true
            sudo systemctl disable ufw 2>/dev/null || true
            sudo rpm-ostree uninstall ufw 2>/dev/null || true
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw /usr/bin/ufw /usr/sbin/ufw 2>/dev/null || true
            cleanup_files "$state_file"
            echo "UFW desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
            sudo rpm-ostree install ufw
            
            if confirm "Deseja configurar as regras padrão recomendadas?"; then
                echo "Configurando regras padrão..."
                sudo ufw default deny incoming
                sudo ufw default allow outgoing
                sudo ufw allow 53317/udp
                sudo ufw allow 53317/tcp
                sudo ufw allow 1714:1764/udp
                sudo ufw allow 1714:1764/tcp
                sudo ufw --force enable
                sudo ufw status verbose
                echo "Regras configuradas."
            else
                echo "UFW instalado sem regras adicionais. Configure manualmente com 'sudo ufw'."
            fi
            
            sudo systemctl enable ufw
            touch "$state_file"
            echo "UFW instalado. Reinicie para aplicar."
        fi
    fi
}

ungoogled_chromium_installer() {
    local state_file="$STATE_DIR/ungoogled_chromium"
    local pkg_chromium="io.github.ungoogled_software.ungoogled_chromium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.ungoogled_software.ungoogled_chromium 2>/dev/null; then
        if confirm "Ungoogled Chromium detectado. Desinstalar?"; then
            echo "Desinstalando Ungoogled Chromium..."
            flatpak uninstall --user -y $pkg_chromium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Ungoogled Chromium desinstalado."
        fi
    else
        if confirm "Instalar Ungoogled Chromium?"; then
            echo "Instalando Ungoogled Chromium..."
            flatpak install --or-update --user --noninteractive flathub $pkg_chromium
            touch "$state_file"
            echo "Ungoogled Chromium instalado."
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

vlc_installer() {
    local state_file="$STATE_DIR/vlc"
    local pkg_vlc="org.videolan.VLC"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.videolan.VLC 2>/dev/null; then
        if confirm "VLC detectado. Desinstalar?"; then
            echo "Desinstalando VLC..."
            flatpak uninstall --user -y $pkg_vlc 2>/dev/null || true
            cleanup_files "$state_file"
            echo "VLC desinstalado."
        fi
    else
        if confirm "Instalar VLC?"; then
            echo "Instalando VLC..."
            flatpak install --or-update --user --noninteractive flathub $pkg_vlc
            touch "$state_file"
            echo "VLC instalado."
        fi
    fi
}

vscode_installer() {
    local state_file="$STATE_DIR/vscode"
    local pkg_vscode="com.visualstudio.code"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.visualstudio.code 2>/dev/null; then
        if confirm "VSCode detectado. Desinstalar?"; then
            echo "Desinstalando VSCode..."
            flatpak uninstall --user -y $pkg_vscode 2>/dev/null || true
            cleanup_files "$state_file"
            echo "VSCode desinstalado."
        fi
    else
        if confirm "Instalar VSCode?"; then
            echo "Instalando VSCode..."
            flatpak install --user --or-update --noninteractive flathub $pkg_vscode
            touch "$state_file"
            echo "VSCode instalado."
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

warehouse_installer() {
    local state_file="$STATE_DIR/warehouse"
    local pkg_warehouse="io.github.flattool.Warehouse"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.flattool.Warehouse 2>/dev/null; then
        if confirm "Warehouse detectado. Desinstalar?"; then
            echo "Desinstalando Warehouse..."
            flatpak uninstall --user -y $pkg_warehouse 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Warehouse desinstalado."
        fi
    else
        if confirm "Instalar Warehouse?"; then
            echo "Instalando Warehouse..."
            flatpak install --or-update --user --noninteractive flathub $pkg_warehouse
            touch "$state_file"
            echo "Warehouse instalado."
        fi
    fi
}

web_apps_menu() {
    while true; do
        clear
        echo "=== Aplicações Web ==="
        echo "1) DLPSGame (PS4 Games)"
        echo "2) RomsFun"
        echo "3) Hydra Library"
        echo "4) r/Piracy"
        echo "5) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; dlpsgame_installer ;;
            2) clear; romsfun_installer ;;
            3) clear; hydra_installer ;;
            4) clear; piracy_installer ;;
            5) return ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

winboat_installer() {
    local state_file="$STATE_DIR/winboat"
    local appimage_path="$APPIMAGE_DIR/winboat.AppImage"

    if ! lsmod | grep -q kvm; then
        echo "KVM não está disponível. Verifique se a virtualização está habilitada no BIOS."
        return 1
    fi

    if [ -f "$state_file" ] || [ -f "$appimage_path" ]; then
        if confirm "WinBoat detectado. Desinstalar?"; then
            echo "Desinstalando WinBoat..."
            [ -f "$appimage_path" ] && rm -f "$appimage_path"
            cleanup_files "$state_file" "$HOME/lsw" "$HOME/txtbox"
            echo "WinBoat desinstalado."
        fi
    else
        if confirm "Instalar WinBoat (Windows em container Docker)?"; then
            echo "Instalando WinBoat..."
            local download_url=$(curl -s https://api.github.com/repos/TibixDev/winboat/releases/latest | grep -o '"browser_download_url": *"[^"]*"' | grep -i 'winboat.*AppImage' | head -1 | cut -d'"' -f4)
            [ -z "$download_url" ] && download_url="https://github.com/TibixDev/winboat/releases/latest/download/winboat-x86_64.AppImage"
            curl -L -o "$appimage_path" "$download_url"
            chmod +x "$appimage_path"
            touch "$state_file"
            echo "WinBoat instalado."
        fi
    fi
}

wivrn_installer() {
    local state_file="$STATE_DIR/wivrn"
    local pkg_wivrn="io.github.wivrn.wivrn"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.wivrn.wivrn 2>/dev/null; then
        if confirm "WiVRn detectado. Desinstalar?"; then
            echo "Desinstalando WiVRn..."
            flatpak uninstall --user -y $pkg_wivrn 2>/dev/null || true
            cleanup_files "$state_file"
            echo "WiVRn desinstalado."
        fi
    else
        if confirm "Instalar WiVRn?"; then
            echo "Instalando WiVRn..."
            flatpak install --or-update --user --noninteractive flathub $pkg_wivrn
            touch "$state_file"
            echo "WiVRn instalado."
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

yt_dlp_installer() {
    local state_file="$STATE_DIR/yt_dlp"

    if [ -f "$state_file" ] || rpm -q yt-dlp &>/dev/null; then
        if confirm "yt-dlp detectado. Desinstalar?"; then
            echo "Desinstalando yt-dlp..."
            sudo rpm-ostree uninstall yt-dlp 2>/dev/null || true
            cleanup_files "$state_file"
            echo "yt-dlp desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar yt-dlp?"; then
            echo "Instalando yt-dlp..."
            sudo rpm-ostree install yt-dlp
            touch "$state_file"
            echo "yt-dlp instalado. Reinicie para aplicar."
        fi
    fi
}

zed_installer() {
    local state_file="$STATE_DIR/zed"
    local pkg_zed="dev.zed.Zed"

    if [ -f "$state_file" ] || flatpak list --app | grep -q dev.zed.Zed 2>/dev/null; then
        if confirm "Zed detectado. Desinstalar?"; then
            echo "Desinstalando Zed..."
            flatpak uninstall --user -y $pkg_zed 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Zed desinstalado."
        fi
    else
        if confirm "Instalar Zed?"; then
            echo "Instalando Zed..."
            flatpak install --or-update --user --noninteractive flathub $pkg_zed
            touch "$state_file"
            echo "Zed instalado."
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
            sudo lchsh "$USER" <<< "/usr/bin/bash" 2>/dev/null || sudo chsh -s /usr/bin/bash "$USER" 2>/dev/null || true
            cleanup_files "$zsh_state"
            rm -rf "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc.backup" 2>/dev/null || true
            echo "Zsh desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar Zsh?"; then
            echo "Instalando Zsh..."
            sudo rpm-ostree install zsh
            sleep 2
            touch "$zsh_state"
            echo "Zsh instalado."
            
            if confirm "Deseja tornar o Zsh o shell padrão do sistema?"; then
                echo "Configurando Zsh como shell padrão..."
                
                local zsh_path=$(command -v zsh 2>/dev/null || which zsh 2>/dev/null || echo "/usr/bin/zsh")
                
                if [ -f "$zsh_path" ]; then
                    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
                    fi
                    
                    if command -v lchsh &>/dev/null; then
                        echo "$zsh_path" | sudo lchsh "$USER" || echo "Não foi possível alterar o shell com lchsh. Tentando chsh..."
                    fi
                    
                    sudo chsh -s "$zsh_path" "$USER" 2>/dev/null || echo "Não foi possível alterar o shell automaticamente. Execute manualmente: chsh -s $zsh_path"
                    
                    echo "Zsh configurado como shell padrão. Será ativado após o próximo login."
                else
                    echo "Zsh instalado mas caminho não encontrado. Configure manualmente com: chsh -s /usr/bin/zsh"
                fi
            else
                echo "Zsh instalado mas o shell padrão permanece Bash."
            fi
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
        echo "1) Affinity Photo (AppImage)"
        echo "2) aria2"
        echo "3) CachyOS Configs"
        echo "4) COSMIC Desktop (Fedora Cosmic-Atomic)"
        echo "5) CPU Ondemand"
        echo "6) Distrobox"
        echo "7) EarlyOOM"
        echo "8) Eden Emulator (AppImage)"
        echo "9) Extra Flatpaks"
        echo "10) Fish Shell + Fisher"
        echo "11) Flathub"
        echo "12) GIMP + PhotoGIMP"
        echo "13) GNOME Desktop (Silverblue)"
        echo "14) Homebrew"
        echo "15) HW Acceleration Flatpak"
        echo "16) Hydra Launcher (AppImage)"
        echo "17) Instalação Base (compactação, podman-compose e fontes)"
        echo "18) IWD (iNet Wireless Daemon)"
        echo "19) KDE Plasma Desktop (Kinoite)"
        echo "20) Mise (Dev Tools)"
        echo "21) NeoVim + LazyVim"
        echo "22) Nvidia Proprietary"
        echo "23) Oh My Bash"
        echo "24) Opencode"
        echo "25) Ostree Auto-updates"
        echo "26) Preload (otimização de RAM)"
        echo "27) Remover Bloatware"
        echo "28) RPM Fusion"
        echo "29) ShadPS4 + PKG Installer"
        echo "30) Shader Booster"
        echo "31) Snapd"
        echo "32) Starship Prompt"
        echo "33) Terra Repository"
        echo "34) UFW"
        echo "35) Web Apps"
        echo "36) WinBoat (AppImage)"
        echo "37) Xpadneo (Xbox Controller)"
        echo "38) yt-dlp"
        echo "39) Zsh + Oh My Zsh"
        echo "40) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; affinity_installer ;;
            2) clear; aria2_installer ;;
            3) clear; cachyconfs_installer ;;
            4) clear; de_cosmic_installer ;;
            5) clear; cpu_ondemand_installer ;;
            6) clear; distrobox_installer ;;
            7) clear; earlyoom_installer ;;
            8) clear; eden_emulator_installer ;;
            9) clear; extra_flatpaks_installer ;;
            10) clear; fish_fisher_installer ;;
            11) clear; flathub_installer ;;
            12) clear; gimp_photogimp_installer ;;
            13) clear; de_gnome_installer ;;
            14) clear; homebrew_installer ;;
            15) clear; hwaccel_flatpak_installer ;;
            16) clear; hydra_launcher_installer ;;
            17) clear; instalacao_base_installer ;;
            18) clear; iwd_installer ;;
            19) clear; de_plasma_installer ;;
            20) clear; mise_installer ;;
            21) clear; neovim_lazyvim_installer ;;
            22) clear; nvidia_proprietary_installer ;;
            23) clear; oh_my_bash_installer ;;
            24) clear; opencode_installer ;;
            25) clear; ostree_autoupd_installer ;;
            26) clear; preload_installer ;;
            27) clear; remover_bloatware ;;
            28) clear; rpmfusion_installer ;;
            29) clear; shadps4_installer ;;
            30) clear; shader_booster_installer ;;
            31) clear; snapd_installer ;;
            32) clear; starship_installer ;;
            33) clear; terra_installer ;;
            34) clear; ufw_installer ;;
            35) clear; web_apps_menu ;;
            36) clear; winboat_installer ;;
            37) clear; xpadneo_installer ;;
            38) clear; yt_dlp_installer ;;
            39) clear; zsh_ohmyzsh_installer ;;
            40) clear; check_reboot; exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
