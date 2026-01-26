#!/bin/bash
set -e

[ ! -f /etc/arch-release ] && { echo "Apenas Arch Linux é suportado."; exit 1; }

STATE_DIR="$HOME/.config/arch_scripts"
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

acer_manager_installer() {
    local state_file="$STATE_DIR/acer_manager"
    local pkg_acer="base-devel linux-headers"

    if [ -f "$state_file" ] || [ -d "/tmp/damx" ] || [ -f "/usr/local/bin/damx" ]; then
        if confirm "Acer Manager detectado. Desinstalar?"; then
            echo "Desinstalando Acer Manager..."
            [ -d "/tmp/damx" ] && cd /tmp/damx/ 2>/dev/null && echo -e "2\nq\nq\n" | sudo bash setup.sh 2>/dev/null || true
            sudo rm -rf /tmp/damx /usr/local/bin/damx 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Acer Manager desinstalado."
        fi
    else
        echo "Instalando Acer Manager..."
        local gh_user="PXDiv"
        local gh_repo="Div-Acer-Manager-Max"
        local vers=$(curl -s https://api.github.com/repos/$gh_user/$gh_repo/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
        curl -L "https://github.com/$gh_user/$gh_repo/archive/refs/tags/$vers.tar.gz" -o /tmp/damx.tar.gz
        mkdir -p /tmp/damx
        tar -xzf /tmp/damx.tar.gz -C /tmp/damx --strip-components=1
        sudo pacman -S --noconfirm $pkg_acer
        cd /tmp/damx/
        echo -e "1\nq\nq\n" | sudo bash setup.sh
        touch "$state_file"
        echo "Acer Manager instalado. Reinicie para aplicar."
    fi
}

admin_menu() {
    while true; do
        clear
        echo "=== Admin ==="
        echo "1) Cockpit Client"
        echo "2) Cockpit Server"
        echo "3) CPU-X"
        echo "4) Termius"
        echo "5) Topgrade"
        echo "6) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; cockpit_client_installer ;;
            2) clear; cockpit_server_installer ;;
            3) clear; cpux_installer ;;
            4) clear; termius_installer ;;
            5) clear; topgrade_installer ;;
            6) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 5 ] && read -p "Pressione Enter para continuar..."
    done
}

ollama_menu() {
    while true; do
        clear
        echo "=== Ollama ==="
        echo "1) Instalar Ollama"
        echo "2) Instalar Ollama Cuda"
        echo "3) Instalar Ollama Rocm"
        echo "4) Instalar Ollama Vulkan"
        echo "5) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; ollama_installer ;;
            2) clear; ollama_cuda_installer ;;
            3) clear; ollama_rocm_installer ;;
            4) clear; ollama_vulkan_installer ;;
            5) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 4 ] && read -p "Pressione Enter para continuar..."
    done
}

ollama_cuda_installer() {
    local state_file="$STATE_DIR/ollama_cuda"
    local pkg_ollamac="ollama-cuda"

    if [ -f "$state_file" ] || pacman -Q ollama-cuda &>/dev/null; then
        if confirm "Ollama Cuda detectado. Desinstalar?"; then
            echo "Desinstalando Ollama Cuda..."
            pacman -Qq ollama-cuda &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ollamac || true
            cleanup_files "$state_file"
            echo "Ollama Cuda desinstalado."
        fi
    else
        if confirm "Instalar Ollama Cuda?"; then
            echo "Instalando Ollama Cuda..."
            sudo pacman -S --noconfirm $pkg_ollamac
            touch "$state_file"
            echo "Ollama Cuda instalado."
        fi
    fi
}

ollama_rocm_installer() {
    local state_file="$STATE_DIR/ollama_rocm"
    local pkg_ollamar="ollama-rocm"

    if [ -f "$state_file" ] || pacman -Q ollama-rocm &>/dev/null; then
        if confirm "Ollama Rocm detectado. Desinstalar?"; then
            echo "Desinstalando Ollama Rocm..."
            pacman -Qq ollama-rocm &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ollamar || true
            cleanup_files "$state_file"
            echo "Ollama Rocm desinstalado."
        fi
    else
        if confirm "Instalar Ollama Rocm?"; then
            echo "Instalando Ollama Rocm..."
            sudo pacman -S --noconfirm $pkg_ollamar
            touch "$state_file"
            echo "Ollama Rocm instalado."
        fi
    fi
}

ollama_vulkan_installer() {
    local state_file="$STATE_DIR/ollama_vulkan"
    local pkg_ollamav="ollama-vulkan"

    if [ -f "$state_file" ] || pacman -Q ollama-vulkan &>/dev/null; then
        if confirm "Ollama Vulkan detectado. Desinstalar?"; then
            echo "Desinstalando Ollama Vulkan..."
            pacman -Qq ollama-vulkan &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ollamav || true
            cleanup_files "$state_file"
            echo "Ollama Vulkan desinstalado."
        fi
    else
        if confirm "Instalar Ollama Vulkan?"; then
            echo "Instalando Ollama Vulkan..."
            sudo pacman -S --noconfirm $pkg_ollamav
            touch "$state_file"
            echo "Ollama Vulkan instalado."
        fi
    fi
}

amd_ucode_installer() {
    local state_file="$STATE_DIR/amd_ucode"
    local pkg_amd="amd-ucode"

    if [ -f "$state_file" ] || pacman -Q amd-ucode &>/dev/null; then
        if confirm "AMD Ucode detectado. Desinstalar?"; then
            echo "Desinstalando AMD Ucode..."
            pacman -Qq amd-ucode &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_amd || true
            cleanup_files "$state_file"
            echo "AMD Ucode desinstalado."
        fi
    else
        if confirm "Instalar AMD Ucode?"; then
            echo "Instalando AMD Ucode..."
            sudo pacman -S --noconfirm $pkg_amd
            touch "$state_file"
            echo "AMD Ucode instalado."
        fi
    fi
}

ollama_installer() {
    local state_file="$STATE_DIR/ollama"
    local pkg_ollama="ollama"

    if [ -f "$state_file" ] || pacman -Q ollama &>/dev/null; then
        if confirm "Ollama detectado. Desinstalar?"; then
            echo "Desinstalando Ollama..."
            sudo systemctl stop ollama.service 2>/dev/null || true
            sudo systemctl disable ollama.service 2>/dev/null || true
            pacman -Qq ollama &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ollama || true
            cleanup_files "$state_file"
            echo "Ollama desinstalado."
        fi
    else
        if confirm "Instalar Ollama?"; then
            echo "Instalando Ollama..."
            sudo pacman -S --noconfirm $pkg_ollama
            sudo systemctl enable --now ollama.service
            touch "$state_file"
            echo "Ollama instalado."
        fi
    fi
}

ananicy_cpp_installer() {
    local state_file="$STATE_DIR/ananicy_cpp"
    local pkg_ananicy="ananicy-cpp cachyos-ananicy-rules-git"

    if [ -f "$state_file" ] || pacman -Q ananicy-cpp &>/dev/null; then
        if confirm "Ananicy-cpp detectado. Desinstalar?"; then
            echo "Desinstalando Ananicy-cpp..."
            sudo systemctl stop ananicy-cpp.service 2>/dev/null || true
            sudo systemctl disable ananicy-cpp.service 2>/dev/null || true
            pacman -Qq ananicy-cpp &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ananicy || true
            cleanup_files "$state_file"
            echo "Ananicy-cpp desinstalado."
        fi
    else
        if confirm "Instalar Ananicy-cpp?"; then
            echo "Instalando Ananicy-cpp..."
            sudo pacman -S --noconfirm $pkg_ananicy
            sudo systemctl enable --now ananicy-cpp.service
            touch "$state_file"
            echo "Ananicy-cpp instalado."
        fi
    fi
}

android_studio_installer() {
    local state_file="$STATE_DIR/android_studio"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.google.AndroidStudio 2>/dev/null; then
        if confirm "Android Studio detectado. Desinstalar?"; then
            echo "Desinstalando Android Studio..."
            flatpak uninstall --user -y com.google.AndroidStudio 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Android Studio desinstalado."
        fi
    else
        if confirm "Instalar Android Studio?"; then
            echo "Instalando Android Studio..."
            flatpak install --user --or-update --noninteractive flathub com.google.AndroidStudio
            touch "$state_file"
            echo "Android Studio instalado."
        fi
    fi
}

anydesk_installer() {
    local state_file="$STATE_DIR/anydesk"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.anydesk.Anydesk 2>/dev/null; then
        if confirm "AnyDesk detectado. Desinstalar?"; then
            echo "Desinstalando AnyDesk..."
            flatpak uninstall --user -y com.anydesk.Anydesk 2>/dev/null || true
            cleanup_files "$state_file"
            echo "AnyDesk desinstalado."
        fi
    else
        if confirm "Instalar AnyDesk?"; then
            echo "Instalando AnyDesk..."
            flatpak install --or-update --user --noninteractive flathub com.anydesk.Anydesk
            touch "$state_file"
            echo "AnyDesk instalado."
        fi
    fi
}

apparmor_installer() {
    local state_file="$STATE_DIR/apparmor"
    local pkg_apparmor="apparmor"

    if [ -f "$state_file" ] || pacman -Q apparmor &>/dev/null; then
        if confirm "AppArmor detectado. Desinstalar?"; then
            echo "Desinstalando AppArmor..."
            sudo systemctl stop apparmor 2>/dev/null || true
            sudo systemctl disable apparmor 2>/dev/null || true
            sudo rm -f /etc/default/grub.d/99-apparmor.cfg /etc/kernel/cmdline.d/99-apparmor.conf 2>/dev/null || true
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            sudo bootctl update 2>/dev/null || true
            pacman -Qq apparmor &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_apparmor || true
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            sudo pacman -S --noconfirm $pkg_apparmor
            if pacman -Qq grub &>/dev/null; then
                sudo mkdir -p /etc/default/grub.d
                echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} apparmor=1 security=apparmor"' | sudo tee /etc/default/grub.d/99-apparmor.cfg
                sudo mkdir -p /boot/grub 2>/dev/null || true
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            else
                sudo mkdir -p /etc/kernel/cmdline.d
                echo "apparmor=1 security=apparmor" | sudo tee /etc/kernel/cmdline.d/99-apparmor.conf
                sudo bootctl update 2>/dev/null || true
            fi
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado. Reinicie para aplicar."
        fi
    fi
}

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="fuse2 fuse3"

    if [ -f "$state_file" ] || pacman -Q fuse2 &>/dev/null; then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            pacman -Qq fuse2 &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fuse || true
            cleanup_files "$state_file"
            echo "FUSE para AppImage desinstalado."
        fi
    else
        if confirm "Instalar FUSE para AppImage?"; then
            echo "Instalando FUSE para AppImage..."
            sudo pacman -S --noconfirm $pkg_fuse
            touch "$state_file"
            echo "FUSE para AppImage instalado."
        fi
    fi
}

archsb_installer() {
    local state_file="$STATE_DIR/archsb"
    local pkg_archsb="sbctl efibootmgr"

    if [ -f "$state_file" ] || pacman -Q sbctl &>/dev/null; then
        if confirm "Secure Boot detectado. Desinstalar?"; then
            echo "Desinstalando Secure Boot..."
            sudo sbctl remove-keys 2>/dev/null || true
            sudo rm -rf /usr/share/secureboot 2>/dev/null || true
            sudo rm -f /boot/*.efi.signed 2>/dev/null || true
            pacman -Qq sbctl &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_archsb || true
            cleanup_files "$state_file"
            echo "Secure Boot desinstalado."
        fi
    else
        if confirm "Configurar Secure Boot?"; then
            echo "Configurando Secure Boot..."
            sudo pacman -S --noconfirm $pkg_archsb
            if sbctl status | grep -qi "secure boot.*disabled" && sbctl status | grep -qi "setup mode.*enabled"; then
                command -v grub-install &>/dev/null && sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
                sudo sbctl create-keys
                sudo sbctl enroll-keys -m -f
                while IFS= read -r line; do
                    [[ "$line" =~ ✗ ]] && file=$(echo "$line" | awk '{print $2}') && echo "Assinando: $file" && sudo sbctl sign -s "$file"
                done < <(sudo sbctl verify)
                sudo sbctl verify
                touch "$state_file"
                echo "Secure Boot configurado."
            else
                echo "Secure Boot não está desabilitado ou Setup Mode não está ativado."
                return 1
            fi
        fi
    fi
}

arch_update_installer() {
    local state_file="$STATE_DIR/arch_update"
    local pkg_archupdate="arch-update"

    if [ -f "$state_file" ] || pacman -Q arch-update &>/dev/null; then
        if confirm "Arch Update detectado. Desinstalar?"; then
            echo "Desinstalando Arch Update..."
            systemctl --user stop arch-update-tray.service 2>/dev/null || true
            systemctl --user disable arch-update-tray.service 2>/dev/null || true
            systemctl --user stop arch-update.timer 2>/dev/null || true
            systemctl --user disable arch-update.timer 2>/dev/null || true
            pacman -Qq arch-update &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_archupdate || true
            cleanup_files "$state_file"
            echo "Arch Update desinstalado."
        fi
    else
        if confirm "Instalar Arch Update?"; then
            echo "Instalando Arch Update..."
            sudo pacman -S --noconfirm $pkg_archupdate
            systemctl --user enable --now arch-update-tray.service
            systemctl --user enable --now arch-update.timer
            sleep 1
            arch-update --tray --enable
            touch "$state_file"
            echo "Arch Update instalado."
        fi
    fi
}

aria2_installer() {
    local state_file="$STATE_DIR/aria2"
    local pkg_aria2="aria2"

    if [ -f "$state_file" ] || pacman -Q aria2 &>/dev/null; then
        if confirm "aria2 detectado. Desinstalar?"; then
            echo "Desinstalando aria2..."
            pacman -Qq aria2 &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_aria2 || true
            cleanup_files "$state_file"
            echo "aria2 desinstalado."
        fi
    else
        if confirm "Instalar aria2?"; then
            echo "Instalando aria2..."
            sudo pacman -S --noconfirm $pkg_aria2
            touch "$state_file"
            echo "aria2 instalado."
        fi
    fi
}

audacity_installer() {
    local state_file="$STATE_DIR/audacity"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.audacityteam.Audacity 2>/dev/null; then
        if confirm "Audacity detectado. Desinstalar?"; then
            echo "Desinstalando Audacity..."
            flatpak uninstall --user -y org.audacityteam.Audacity 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Audacity desinstalado."
        fi
    else
        if confirm "Instalar Audacity?"; then
            echo "Instalando Audacity..."
            flatpak install --or-update --user --noninteractive flathub org.audacityteam.Audacity
            touch "$state_file"
            echo "Audacity instalado."
        fi
    fi
}

bazaar_installer() {
    local state_file="$STATE_DIR/bazaar"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.kolunmi.Bazaar 2>/dev/null; then
        if confirm "Bazaar detectado. Desinstalar?"; then
            echo "Desinstalando Bazaar..."
            flatpak uninstall --user -y io.github.kolunmi.Bazaar 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Bazaar desinstalado."
        fi
    else
        if confirm "Instalar Bazaar?"; then
            echo "Instalando Bazaar..."
            flatpak install --or-update --user --noninteractive flathub io.github.kolunmi.Bazaar
            touch "$state_file"
            echo "Bazaar instalado."
        fi
    fi
}

bitwarden_installer() {
    local state_file="$STATE_DIR/bitwarden"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.bitwarden.desktop 2>/dev/null; then
        if confirm "Bitwarden detectado. Desinstalar?"; then
            echo "Desinstalando Bitwarden..."
            flatpak uninstall --user -y com.bitwarden.desktop 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Bitwarden desinstalado."
        fi
    else
        if confirm "Instalar Bitwarden?"; then
            echo "Instalando Bitwarden..."
            flatpak install --or-update --user --noninteractive flathub com.bitwarden.desktop
            touch "$state_file"
            echo "Bitwarden instalado."
        fi
    fi
}

blender_installer() {
    local state_file="$STATE_DIR/blender"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.blender.Blender 2>/dev/null; then
        if confirm "Blender detectado. Desinstalar?"; then
            echo "Desinstalando Blender..."
            flatpak uninstall --user -y org.blender.Blender 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Blender desinstalado."
        fi
    else
        if confirm "Instalar Blender?"; then
            echo "Instalando Blender..."
            flatpak install --or-update --user --noninteractive flathub org.blender.Blender
            touch "$state_file"
            echo "Blender instalado."
        fi
    fi
}

bottles_installer() {
    local state_file="$STATE_DIR/bottles"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.usebottles.bottles 2>/dev/null; then
        if confirm "Bottles detectado. Desinstalar?"; then
            echo "Desinstalando Bottles..."
            flatpak uninstall --user -y com.usebottles.bottles 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Bottles desinstalado."
        fi
    else
        if confirm "Instalar Bottles?"; then
            echo "Instalando Bottles..."
            flatpak install --or-update --user --noninteractive flathub com.usebottles.bottles
            touch "$state_file"
            echo "Bottles instalado."
        fi
    fi
}

brave_browser_installer() {
    local state_file="$STATE_DIR/brave_browser"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.brave.Browser 2>/dev/null; then
        if confirm "Brave Browser detectado. Desinstalar?"; then
            echo "Desinstalando Brave Browser..."
            flatpak uninstall --user -y com.brave.Browser 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Brave Browser desinstalado."
        fi
    else
        if confirm "Instalar Brave Browser?"; then
            echo "Instalando Brave Browser..."
            flatpak install --or-update --user --noninteractive flathub com.brave.Browser
            touch "$state_file"
            echo "Brave Browser instalado."
        fi
    fi
}

broadcom_wifi_dkms_installer() {
    local state_file="$STATE_DIR/broadcom_wifi"
    local pkg_broadcom="linux-headers broadcom-wl-dkms"

    if [ -f "$state_file" ] || pacman -Q broadcom-wl-dkms &>/dev/null; then
        if confirm "Broadcom WiFi com DKMS detectado. Desinstalar?"; then
            echo "Desinstalando Broadcom WiFi com DKMS..."
            pacman -Qq broadcom-wl-dkms &>/dev/null && sudo pacman -Rsnu --noconfirm broadcom-wl-dkms || true
            cleanup_files "$state_file"
            echo "Broadcom WiFi desinstalado."
        fi
    else
        echo "Instalando Broadcom WiFi com DKMS..."
        sudo pacman -S --noconfirm $pkg_broadcom
        touch "$state_file"
        echo "Broadcom WiFi instalado. Reinicie para aplicar."
    fi
}

broadcom_wifi_no_dkms_installer() {
    local state_file="$STATE_DIR/broadcom_wifi"
    local pkg_broadcom="broadcom-wl"

    if [ -f "$state_file" ] || pacman -Q broadcom-wl &>/dev/null; then
        if confirm "Broadcom WiFi sem DKMS detectado. Desinstalar?"; then
            echo "Desinstalando Broadcom WiFi sem DKMS..."
            pacman -Qq broadcom-wl &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_broadcom || true
            cleanup_files "$state_file"
            echo "Broadcom WiFi desinstalado."
        fi
    else
        echo "Instalando Broadcom WiFi sem DKMS..."
        sudo pacman -S --noconfirm $pkg_broadcom
        touch "$state_file"
        echo "Broadcom WiFi instalado. Reinicie para aplicar."
    fi
}

broadcom_wifi_menu() {
    while true; do
        clear
        echo "=== Broadcom WiFi ==="
        echo "1) Instalar com DKMS (recomendado)"
        echo "2) Instalar sem DKMS"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; broadcom_wifi_dkms_installer ;;
            2) clear; broadcom_wifi_no_dkms_installer ;;
            3) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

btrfs_assistant_installer() {
    local state_file="$STATE_DIR/btrfs_assistant"
    local pkg_btrfs_assistant="btrfs-assistant"

    if [ -f "$state_file" ] || pacman -Q btrfs-assistant &>/dev/null; then
        if confirm "Btrfs Assistant detectado. Desinstalar?"; then
            echo "Desinstalando Btrfs Assistant..."
            pacman -Qq btrfs-assistant &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_btrfs_assistant || true
            cleanup_files "$state_file"
            echo "Btrfs Assistant desinstalado."
        fi
    else
        findmnt -n -o FSTYPE / | grep -q "btrfs" || { echo "Sistema de arquivos raiz não é Btrfs."; return 1; }
        if confirm "Instalar Btrfs Assistant?"; then
            echo "Instalando Btrfs Assistant..."
            sudo pacman -S --noconfirm $pkg_btrfs_assistant
            touch "$state_file"
            echo "Btrfs Assistant instalado."
        fi
    fi
}

btop_installer() {
    local state_file="$STATE_DIR/btop"
    local pkg_btop="btop"

    if [ -f "$state_file" ] || pacman -Q btop &>/dev/null; then
        if confirm "btop detectado. Desinstalar?"; then
            echo "Desinstalando btop..."
            pacman -Qq btop &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_btop || true
            cleanup_files "$state_file"
            echo "btop desinstalado."
        fi
    else
        if confirm "Instalar btop?"; then
            echo "Instalando btop..."
            sudo pacman -S --noconfirm $pkg_btop
            touch "$state_file"
            echo "btop instalado."
        fi
    fi
}

cachyconfs_installer() {
    local state_file="$STATE_DIR/cachyconfs"

    if [ -f "$state_file" ] || [ -f "/usr/lib/sysctl.d/99-cachyos-settings.conf" ]; then
        if confirm "CachyOS Configs detectado. Desinstalar?"; then
            echo "Desinstalando CachyOS Configs..."
            sudo rm -f /usr/lib/sysctl.d/99-cachyos-settings.conf 2>/dev/null || true
            sudo sysctl --system 2>/dev/null || true
            cleanup_files "$state_file"
            echo "CachyOS Configs desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar CachyOS Configs?"; then
            echo "Instalando CachyOS Configs..."
            sudo mkdir -p /usr/lib/sysctl.d
            curl -s https://raw.githubusercontent.com/CachyOS/CachyOS-Settings/main/sysctl/99-cachyos-settings.conf | sudo tee /usr/lib/sysctl.d/99-cachyos-settings.conf > /dev/null
            sudo sysctl --system
            touch "$state_file"
            echo "CachyOS Configs instalado. Reinicie para aplicar."
        fi
    fi
}

cachyos_installer() {
    local state_file="$STATE_DIR/cachyos"
    local pkg_cachyos="linux-cachyos linux-cachyos-headers"

    if [ -f "$state_file" ] || pacman -Q linux-cachyos &>/dev/null; then
        if confirm "CachyOS kernel detectado. Desinstalar?"; then
            echo "Desinstalando CachyOS kernel..."
            pacman -Qq linux-cachyos &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cachyos || true
            cleanup_files "$state_file"
            echo "CachyOS kernel desinstalado."
        fi
    else
        if confirm "Instalar CachyOS kernel?"; then
            echo "Instalando CachyOS kernel..."
            sudo pacman -S --noconfirm $pkg_cachyos
            touch "$state_file"
            echo "CachyOS kernel instalado. Reinicie para aplicar."
        fi
    fi
}

cargo_installer() {
    local state_file="$STATE_DIR/cargo"
    local pkg_cargo="rustup"

    if [ -f "$state_file" ] || pacman -Q rustup &>/dev/null; then
        if confirm "Rustup detectado. Desinstalar?"; then
            echo "Desinstalando Rustup..."
            pacman -Qq rustup &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cargo || true
            cleanup_files "$state_file"
            echo "Rustup desinstalado."
        fi
    else
        if confirm "Instalar Rustup?"; then
            echo "Instalando Rustup..."
            sudo pacman -S --noconfirm $pkg_cargo
            touch "$state_file"
            echo "Rustup instalado."
        fi
    fi
}

chaotic_aur_installer() {
    local state_file="$STATE_DIR/chaotic_aur"
    local pkg_chaotic="chaotic-keyring chaotic-mirrorlist"

    if [ -f "$state_file" ] || (pacman -Q chaotic-keyring &>/dev/null && pacman -Q chaotic-mirrorlist &>/dev/null); then
        if confirm "Chaotic AUR detectado. Desinstalar?"; then
            echo "Desinstalando Chaotic AUR..."
            sudo sed -i '/\[chaotic-aur\]/,/^$/d' /etc/pacman.conf 2>/dev/null || true
            pacman -Qq chaotic-keyring &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_chaotic || true
            sudo pacman-key --delete 3056513887B78AEB 2>/dev/null || true
            sudo sed -i '/^ILoveCandy/d' /etc/pacman.conf 2>/dev/null || true
            sudo sed -i '/^ParallelDownloads/d' /etc/pacman.conf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Chaotic AUR desinstalado."
        fi
    else
        if confirm "Instalar Chaotic AUR?"; then
            echo "Instalando Chaotic AUR..."
            sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
            sudo pacman-key --lsign-key 3056513887B78AEB
            sudo pacman -U --noconfirm \
                "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" \
                "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
            sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
            sudo sed -i '/Color/a ILoveCandy' /etc/pacman.conf
            sudo sed -i '/^ParallelDownloads/d' /etc/pacman.conf
            sudo sed -i '/ILoveCandy/a ParallelDownloads = 15' /etc/pacman.conf
            echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
            sudo pacman -Syu
            touch "$state_file"
            echo "Chaotic AUR instalado."
        fi
    fi
}

chrome_installer() {
    local state_file="$STATE_DIR/chrome"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.google.Chrome 2>/dev/null; then
        if confirm "Google Chrome detectado. Desinstalar?"; then
            echo "Desinstalando Google Chrome..."
            flatpak uninstall --user -y com.google.Chrome 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Google Chrome desinstalado."
        fi
    else
        if confirm "Instalar Google Chrome?"; then
            echo "Instalando Google Chrome..."
            flatpak install --or-update --user --noninteractive flathub com.google.Chrome
            touch "$state_file"
            echo "Google Chrome instalado."
        fi
    fi
}

cockpit_client_installer() {
    local state_file="$STATE_DIR/cockpit_client"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.cockpit_project.CockpitClient 2>/dev/null; then
        if confirm "Cockpit Client detectado. Desinstalar?"; then
            echo "Desinstalando Cockpit Client..."
            flatpak uninstall --user -y org.cockpit_project.CockpitClient 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Cockpit Client desinstalado."
        fi
    else
        if confirm "Instalar Cockpit Client?"; then
            echo "Instalando Cockpit Client..."
            flatpak install --or-update --user --noninteractive flathub org.cockpit_project.CockpitClient
            touch "$state_file"
            echo "Cockpit Client instalado."
        fi
    fi
}

cockpit_server_installer() {
    local state_file="$STATE_DIR/cockpit_server"
    local pkg_cockpit="cockpit"

    if [ -f "$state_file" ] || pacman -Q cockpit &>/dev/null; then
        if confirm "Cockpit Server detectado. Desinstalar?"; then
            echo "Desinstalando Cockpit Server..."
            sudo systemctl stop cockpit.socket 2>/dev/null || true
            sudo systemctl disable cockpit.socket 2>/dev/null || true
            pacman -Qq cockpit &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cockpit || true
            cleanup_files "$state_file"
            echo "Cockpit Server desinstalado."
        fi
    else
        if confirm "Instalar Cockpit Server?"; then
            echo "Instalando Cockpit Server..."
            sudo pacman -S --noconfirm $pkg_cockpit
            sudo systemctl enable --now cockpit.socket
            touch "$state_file"
            echo "Cockpit Server instalado."
        fi
    fi
}

cohesion_installer() {
    local state_file="$STATE_DIR/cohesion"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.brunofin.Cohesion 2>/dev/null; then
        if confirm "Cohesion detectado. Desinstalar?"; then
            echo "Desinstalando Cohesion..."
            flatpak uninstall --user -y io.github.brunofin.Cohesion 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Cohesion desinstalado."
        fi
    else
        if confirm "Instalar Cohesion?"; then
            echo "Instalando Cohesion..."
            flatpak install --or-update --user --noninteractive flathub io.github.brunofin.Cohesion
            touch "$state_file"
            echo "Cohesion instalado."
        fi
    fi
}

cpu_ondemand_installer() {
    local state_file="$STATE_DIR/cpu_ondemand"

    if [ -f "$state_file" ] || [ -f "/etc/systemd/system/set-ondemand-governor.service" ]; then
        if confirm "CPU Ondemand detectado. Desinstalar?"; then
            echo "Desinstalando CPU Ondemand..."
            sudo systemctl stop set-ondemand-governor.service 2>/dev/null || true
            sudo systemctl disable set-ondemand-governor.service 2>/dev/null || true
            sudo rm -f /etc/systemd/system/set-ondemand-governor.service /etc/default/grub.d/01_intel_pstate_disable /etc/kernel/cmdline.d/10-intel-pstate-disable.conf /usr/local/bin/set-ondemand-governor.sh 2>/dev/null || true
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            sudo bootctl update 2>/dev/null || true
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
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            touch "$state_file"
            echo "CPU Ondemand instalado. Reinicie para aplicar."
        fi
    fi
}

cpux_installer() {
    local state_file="$STATE_DIR/cpux"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.thetumultuousunicornofdarkness.cpu-x 2>/dev/null; then
        if confirm "CPU-X detectado. Desinstalar?"; then
            echo "Desinstalando CPU-X..."
            flatpak uninstall --user -y io.github.thetumultuousunicornofdarkness.cpu-x 2>/dev/null || true
            cleanup_files "$state_file"
            echo "CPU-X desinstalado."
        fi
    else
        if confirm "Instalar CPU-X?"; then
            echo "Instalando CPU-X..."
            flatpak install --or-update --user --noninteractive flathub io.github.thetumultuousunicornofdarkness.cpu-x
            touch "$state_file"
            echo "CPU-X instalado."
        fi
    fi
}

cryptomator_installer() {
    local state_file="$STATE_DIR/cryptomator"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.cryptomator.Cryptomator 2>/dev/null; then
        if confirm "Cryptomator detectado. Desinstalar?"; then
            echo "Desinstalando Cryptomator..."
            flatpak uninstall --user -y org.cryptomator.Cryptomator 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Cryptomator desinstalado."
        fi
    else
        if confirm "Instalar Cryptomator?"; then
            echo "Instalando Cryptomator..."
            flatpak install --or-update --user --noninteractive flathub org.cryptomator.Cryptomator
            touch "$state_file"
            echo "Cryptomator instalado."
        fi
    fi
}

curl_installer() {
    local state_file="$STATE_DIR/curl"
    local pkg_curl="curl"

    if [ -f "$state_file" ] || pacman -Q curl &>/dev/null; then
        if confirm "curl detectado. Desinstalar?"; then
            echo "Desinstalando curl..."
            pacman -Qq curl &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_curl || true
            cleanup_files "$state_file"
            echo "curl desinstalado."
        fi
    else
        if confirm "Instalar curl?"; then
            echo "Instalando curl..."
            sudo pacman -S --noconfirm $pkg_curl
            touch "$state_file"
            echo "curl instalado."
        fi
    fi
}

darktable_installer() {
    local state_file="$STATE_DIR/darktable"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.darktable.Darktable 2>/dev/null; then
        if confirm "Darktable detectado. Desinstalar?"; then
            echo "Desinstalando Darktable..."
            flatpak uninstall --user -y org.darktable.Darktable 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Darktable desinstalado."
        fi
    else
        if confirm "Instalar Darktable?"; then
            echo "Instalando Darktable..."
            flatpak install --or-update --user --noninteractive flathub org.darktable.Darktable
            touch "$state_file"
            echo "Darktable instalado."
        fi
    fi
}

davinci_resolve_free_installer() {
    local state_file="$STATE_DIR/davinci_resolve_free"

    if [ -f "$state_file" ] || [ -f "/opt/resolve/bin/resolve" ]; then
        if confirm "DaVinci Resolve Free detectado. Desinstalar?"; then
            echo "Desinstalando DaVinci Resolve Free..."
            sudo rm -rf /opt/resolve 2>/dev/null || true
            sudo rm -f /usr/share/applications/davinci-resolve.desktop 2>/dev/null || true
            cleanup_files "$state_file"
            echo "DaVinci Resolve Free desinstalado."
        fi
    else
        if confirm "Instalar DaVinci Resolve Free?"; then
            echo "Instalando DaVinci Resolve Free..."
            local siteurl="https://www.blackmagicdesign.com/api/support/latest-stable-version/davinci-resolve/linux"
            local useragent="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
            local releaseinfo=$(curl -s -H "$useragent" "$siteurl")
            local major=$(echo "$releaseinfo" | grep -o '"major":[0-9]*' | cut -d: -f2)
            local minor=$(echo "$releaseinfo" | grep -o '"minor":[0-9]*' | cut -d: -f2)
            local releaseNum=$(echo "$releaseinfo" | grep -o '"releaseNum":[0-9]*' | cut -d: -f2)
            local downloadId=$(echo "$releaseinfo" | grep -o '"downloadId":"[^"]*"' | cut -d'"' -f4)
            if [ "$releaseNum" == "0" ]; then
                local filever="${major}.${minor}"
            else
                local filever="${major}.${minor}.${releaseNum}"
            fi
            local archive_name="DaVinci_Resolve_${filever}_Linux"
            local archive_run_name="DaVinci_Resolve_${filever}_Linux"
            local reqjson='{"firstname": "Arch", "lastname": "Linux", "email": "someone@archlinux.org", "phone": "202-555-0194", "country": "us", "street": "Bowery 146", "state": "New York", "city": "AUR", "product": "DaVinci Resolve"}'
            local siteurl="https://www.blackmagicdesign.com/api/register/us/download/${downloadId}"
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
                -H 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
                --data-ascii "$reqjson" \
                --compressed \
                "$siteurl")
            curl -L -o "/tmp/${archive_name}.zip" "$srcurl"
            cd /tmp
            unzip "${archive_name}.zip"
            chmod +x "${archive_run_name}.run"
            sudo ./"${archive_run_name}.run" --appimage-extract-and-run
            cleanup_files "/tmp/${archive_name}.zip" "/tmp/${archive_run_name}.run"
            touch "$state_file"
            echo "DaVinci Resolve Free instalado."
        fi
    fi
}

davinci_resolve_studio_installer() {
    local state_file="$STATE_DIR/davinci_resolve_studio"

    if [ -f "$state_file" ] || [ -f "/opt/resolve/bin/resolve" ]; then
        if confirm "DaVinci Resolve Studio detectado. Desinstalar?"; then
            echo "Desinstalando DaVinci Resolve Studio..."
            sudo rm -rf /opt/resolve 2>/dev/null || true
            sudo rm -f /usr/share/applications/davinci-resolve.desktop 2>/dev/null || true
            cleanup_files "$state_file"
            echo "DaVinci Resolve Studio desinstalado."
        fi
    else
        if confirm "Instalar DaVinci Resolve Studio?"; then
            echo "Instalando DaVinci Resolve Studio..."
            local siteurl="https://www.blackmagicdesign.com/api/support/latest-stable-version/davinci-resolve-studio/linux"
            local useragent="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
            local releaseinfo=$(curl -s -H "$useragent" "$siteurl")
            local major=$(echo "$releaseinfo" | grep -o '"major":[0-9]*' | cut -d: -f2)
            local minor=$(echo "$releaseinfo" | grep -o '"minor":[0-9]*' | cut -d: -f2)
            local releaseNum=$(echo "$releaseinfo" | grep -o '"releaseNum":[0-9]*' | cut -d: -f2)
            local downloadId=$(echo "$releaseinfo" | grep -o '"downloadId":"[^"]*"' | cut -d'"' -f4)
            if [ "$releaseNum" == "0" ]; then
                local filever="${major}.${minor}"
            else
                local filever="${major}.${minor}.${releaseNum}"
            fi
            local archive_name="DaVinci_Resolve_Studio_${filever}_Linux"
            local archive_run_name="DaVinci_Resolve_Studio_${filever}_Linux"
            local reqjson='{"firstname": "Arch", "lastname": "Linux", "email": "someone@archlinux.org", "phone": "202-555-0194", "country": "us", "street": "Bowery 146", "state": "New York", "city": "AUR", "product": "DaVinci Resolve Studio"}'
            local siteurl="https://www.blackmagicdesign.com/api/register/us/download/${downloadId}"
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
                -H 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
                --data-ascii "$reqjson" \
                --compressed \
                "$siteurl")
            curl -L -o "/tmp/${archive_name}.zip" "$srcurl"
            cd /tmp
            unzip "${archive_name}.zip"
            chmod +x "${archive_run_name}.run"
            sudo ./"${archive_run_name}.run" --appimage-extract-and-run
            cleanup_files "/tmp/${archive_name}.zip" "/tmp/${archive_run_name}.run"
            touch "$state_file"
            echo "DaVinci Resolve Studio instalado."
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
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

de_cosmic_installer() {
    local state_file="$STATE_DIR/de_cosmic"
    local pkg_cosmic="cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers"

    if [ -f "$state_file" ] || pacman -Q cosmic-session &>/dev/null; then
        if confirm "Cosmic detectado. Desinstalar?"; then
            echo "Desinstalando Cosmic..."
            sudo systemctl disable cosmic-greeter 2>/dev/null || true
            pacman -Qq cosmic-session &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cosmic || true
            cleanup_files "$state_file"
            echo "Cosmic desinstalado."
        fi
    else
        if confirm "Instalar Cosmic?"; then
            echo "Instalando Cosmic..."
            sudo pacman -S --noconfirm $pkg_cosmic
            sudo systemctl enable cosmic-greeter
            touch "$state_file"
            echo "Cosmic instalado. Reinicie para aplicar."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-initial-setup gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"

    if [ -f "$state_file" ] || pacman -Q gnome-shell &>/dev/null; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            pacman -Qq gnome-shell &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gnome || true
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            sudo pacman -S --noconfirm $pkg_gnome
            sudo systemctl enable gdm
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_hyprland_installer() {
    curl -fsSL https://install.danklinux.com | sh
    sudo pacman -S --noconfirm sddm
    sudo systemctl enable sddm
}

de_installer() {
    while true; do
        clear
        echo "=== Ambientes Desktop ==="
        echo "1) Cosmic"
        echo "2) Gnome"
        echo "3) Hyprland"
        echo "4) Plasma"
        echo "5) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; de_cosmic_installer ;;
            2) clear; de_gnome_installer ;;
            3) clear; de_hyprland_installer ;;
            4) clear; de_plasma_installer ;;
            5) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 4 ] && read -p "Pressione Enter para continuar..."
    done
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="plasma-meta konsole dolphin kdeconnect partitionmanager ark"

    if [ -f "$state_file" ] || pacman -Q plasma-meta &>/dev/null; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            pacman -Qq plasma-meta &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_plasma || true
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            sudo pacman -S --noconfirm $pkg_plasma
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

devs_menu() {
    while true; do
        clear
        echo "=== Devs ==="
        echo "1) Docker"
        echo "2) Fish Shell"
        echo "3) Godot Engine"
        echo "4) HTTPie"
        echo "5) Insomnia"
        echo "6) Java OpenJDK"
        echo "7) Maven"
        echo "8) Mise"
        echo "9) NVM"
        echo "10) Oh My Bash"
        echo "11) PNPM"
        echo "12) Portainer"
        echo "13) Postman"
        echo "14) PyEnv"
        echo "15) SDKMAN"
        echo "16) Starship"
        echo "17) Tailscale"
        echo "18) ZeroTier"
        echo "19) Zsh Shell"
        echo "20) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; docker_installer ;;
            2) clear; fish_menu ;;
            3) clear; godot_installer ;;
            4) clear; httpie_installer ;;
            5) clear; insomnia_installer ;;
            6) clear; java_openjdk_installer ;;
            7) clear; maven_installer ;;
            8) clear; mise_installer ;;
            9) clear; nvm_installer ;;
            10) clear; oh_my_bash_installer ;;
            11) clear; pnpm_installer ;;
            12) clear; portainer_installer ;;
            13) clear; postman_installer ;;
            14) clear; pyenv_installer ;;
            15) clear; sdkman_installer ;;
            16) clear; starship_installer ;;
            17) clear; tailscale_installer ;;
            18) clear; zerotier_installer ;;
            19) clear; zsh_menu ;;
            20) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 19 ] && read -p "Pressione Enter para continuar..."
    done
}

discord_installer() {
    local state_file="$STATE_DIR/discord"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.discordapp.Discord 2>/dev/null; then
        if confirm "Discord detectado. Desinstalar?"; then
            echo "Desinstalando Discord..."
            flatpak uninstall --user -y com.discordapp.Discord 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Discord desinstalado."
        fi
    else
        if confirm "Instalar Discord?"; then
            echo "Instalando Discord..."
            flatpak install --or-update --user --noninteractive flathub com.discordapp.Discord
            touch "$state_file"
            echo "Discord instalado."
        fi
    fi
}

distroshelf_installer() {
    local state_file="$STATE_DIR/distroshelf"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.ranfdev.DistroShelf 2>/dev/null; then
        if confirm "Distroshelf detectado. Desinstalar?"; then
            echo "Desinstalando Distroshelf..."
            flatpak uninstall --user -y com.ranfdev.DistroShelf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Distroshelf desinstalado."
        fi
    else
        if confirm "Instalar Distroshelf?"; then
            echo "Instalando Distroshelf..."
            flatpak install --or-update --user --noninteractive flathub com.ranfdev.DistroShelf
            touch "$state_file"
            echo "Distroshelf instalado."
        fi
    fi
}

distrobox_adv_installer() {
    local state_file="$STATE_DIR/distrobox_adv"
    local pkg_distrobox="pcsc-lite ccid"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.ranfdev.DistroShelf 2>/dev/null; then
        if confirm "Distrobox-Adv detectado. Desinstalar?"; then
            echo "Desinstalando Distrobox-Adv..."
            pacman -Qq pcsc-lite &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_distrobox || true
            sudo systemctl disable pcscd.service 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Distrobox-Adv desinstalado."
        fi
    else
        if confirm "Instalar Distrobox-Adv?"; then
            echo "Instalando Distrobox-Adv..."
            sudo pacman -S --noconfirm $pkg_distrobox
            sudo systemctl enable --now pcscd.service
            distrobox-assemble create --file https://raw.githubusercontent.com/pedrohqb/distrobox-adv-br/refs/heads/main/distrobox-adv-br
            flatpak install --or-update --user --noninteractive flathub com.ranfdev.DistroShelf
            touch "$state_file"
            echo "Distrobox-Adv instalado."
        fi
    fi
}

distrobox_handler_installer() {
    local state_file="$STATE_DIR/distrobox_handler"
    local handler_dir="$HOME/.local/distrobox-handler"

    if [ -f "$state_file" ] || [ -f "$handler_dir/command_not_found_handle" ]; then
        if confirm "Distrobox Command Handler detectado. Desinstalar?"; then
            echo "Desinstalando Distrobox Command Handler..."
            rm -rf "$handler_dir" 2>/dev/null || true
            sudo rm -f /etc/bash.bashrc.d/99-distrobox-cnf /etc/zsh/zshrc.d/99-distrobox-cnf.zsh /etc/profile.d/distrobox-host-aliases.sh 2>/dev/null || true
            [ -f "$HOME/.bashrc" ] && grep -v "distrobox-handler" "$HOME/.bashrc" > "$HOME/.bashrc.tmp" && mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
            [ -f "$HOME/.zshrc" ] && grep -v "distrobox-handler" "$HOME/.zshrc" > "$HOME/.zshrc.tmp" && mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
            cleanup_files "$state_file"
            echo "Distrobox Command Handler desinstalado."
        fi
    else
        if confirm "Instalar Distrobox Command Handler?"; then
            echo "Instalando Distrobox Command Handler..."
            mkdir -p "$handler_dir"
            echo '#!/bin/bash
command_not_found_handle() {
    local cmd="$1"
    shift
    if command -v distrobox-host-exec >/dev/null 2>&1; then
        if distrobox-host-exec which "$cmd" >/dev/null 2>&1; then
            echo "Command \"$cmd\" not found in container, executing on host..." >&2
            exec distrobox-host-exec "$cmd" "$@"
        else
            echo "bash: $cmd: command not found" >&2
            return 127
        fi
    else
        echo "bash: $cmd: command not found" >&2
        return 127
    fi
}' > "$handler_dir/command_not_found_handle"
            echo '#!/bin/bash
zsh_command_not_found_handler() {
    local cmd="$1"
    shift
    if command -v distrobox-host-exec >/dev/null 2>&1; then
        if distrobox-host-exec which "$cmd" >/dev/null 2>&1; then
            echo "Command \"$cmd\" not found in container, executing on host..." >&2
            exec distrobox-host-exec "$cmd" "$@"
        else
            echo "zsh: command not found: $cmd" >&2
            return 127
        fi
    else
        echo "zsh: command not found: $cmd" >&2
        return 127
    fi
}' > "$handler_dir/zsh_command_not_found_handler"
            chmod +x "$handler_dir/command_not_found_handle" "$handler_dir/zsh_command_not_found_handler"
            sudo mkdir -p /etc/bash.bashrc.d
            echo '# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/command_not_found_handle" ]; then
    source "$HOME/.local/distrobox-handler/command_not_found_handle"
fi' | sudo tee /etc/bash.bashrc.d/99-distrobox-cnf > /dev/null
            sudo mkdir -p /etc/zsh/zshrc.d
            echo '# Distrobox Command-Not-Found Handler Integration for ZSH
if [ -f "$HOME/.local/distrobox-handler/zsh_command_not_found_handler" ]; then
    source "$HOME/.local/distrobox-handler/zsh_command_not_found_handler"
fi' | sudo tee /etc/zsh/zshrc.d/99-distrobox-cnf.zsh > /dev/null
            echo '# Common host command aliases for distrobox containers
alias xdg-open="distrobox-host-exec xdg-open"
alias nautilus="distrobox-host-exec nautilus"
alias dolphin="distrobox-host-exec dolphin"
alias htop="distrobox-host-exec htop"
alias lscpu="distrobox-host-exec lscpu"
alias lsusb="distrobox-host-exec lsusb"
alias lspci="distrobox-host-exec lspci"
alias nmcli="distrobox-host-exec nmcli"
alias nmtui="distrobox-host-exec nmtui"
alias flatpak="distrobox-host-exec flatpak"
alias firefox="distrobox-host-exec firefox"
alias chromium="distrobox-host-exec chromium"' | sudo tee /etc/profile.d/distrobox-host-aliases.sh > /dev/null
            [ -f "$HOME/.bashrc" ] && grep -q "distrobox-handler" "$HOME/.bashrc" || echo -e '\nif [ -f "$HOME/.local/distrobox-handler/command_not_found_handle" ]; then\n    source "$HOME/.local/distrobox-handler/command_not_found_handle"\nfi' >> "$HOME/.bashrc"
            [ -f "$HOME/.zshrc" ] && grep -q "distrobox-handler" "$HOME/.zshrc" || echo -e '\nif [ -f "$HOME/.local/distrobox-handler/zsh_command_not_found_handler" ]; then\n    source "$HOME/.local/distrobox-handler/zsh_command_not_found_handler"\nfi' >> "$HOME/.zshrc"
            touch "$state_file"
            echo "Distrobox Command Handler instalado."
        fi
    fi
}

dnsmasq_installer() {
    local state_file="$STATE_DIR/dnsmasq"
    local pkg_dnsmasq="dnsmasq"

    if [ -f "$state_file" ] || pacman -Q dnsmasq &>/dev/null; then
        if confirm "DNSMasq detectado. Desinstalar?"; then
            echo "Desinstalando DNSMasq..."
            sudo systemctl stop dnsmasq 2>/dev/null || true
            sudo systemctl disable dnsmasq 2>/dev/null || true
            pacman -Qq dnsmasq &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_dnsmasq || true
            sudo rm -rf /etc/dnsmasq.d /etc/dnsmasq.conf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "DNSMasq desinstalado."
        fi
    else
        if confirm "Instalar DNSMasq?"; then
            echo "Instalando DNSMasq..."
            sudo pacman -S --noconfirm $pkg_dnsmasq
            sudo systemctl enable dnsmasq
            touch "$state_file"
            echo "DNSMasq instalado."
        fi
    fi
}

docker_installer() {
    local state_file="$STATE_DIR/docker"
    local pkg_docker="docker docker-compose"

    if [ -f "$state_file" ] || pacman -Q docker &>/dev/null; then
        if confirm "Docker detectado. Desinstalar?"; then
            echo "Desinstalando Docker..."
            sudo systemctl stop docker.service docker.socket 2>/dev/null || true
            sudo systemctl disable docker.service docker.socket 2>/dev/null || true
            pacman -Qq docker &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_docker || true
            sudo rm -rf /var/lib/docker 2>/dev/null || true
            sudo groupdel docker 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Docker desinstalado."
        fi
    else
        if confirm "Instalar Docker?"; then
            echo "Instalando Docker..."
            sudo pacman -S --noconfirm $pkg_docker
            sudo systemctl enable --now docker.service docker.socket
            sudo usermod -aG docker "$USER"
            touch "$state_file"
            echo "Docker instalado. Reinicie para aplicar."
        fi
    fi
}

drivers_menu() {
    while true; do
        clear
        echo "=== Drivers ==="
        echo "1) Acer Manager"
        echo "2) AMD ucode"
        echo "3) Broadcom WiFi"
        echo "4) Intel ucode"
        echo "5) Nvidia (Open Modules)"
        echo "6) Nvidia (Proprietário)"
        echo "7) Nvidia Drivers (v470)"
        echo "8) OptimusUI"
        echo "9) Realtek WiFi 8821CE"
        echo "10) Xpadneo"
        echo "11) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; acer_manager_installer ;;
            2) clear; amd_ucode_installer ;;
            3) clear; broadcom_wifi_menu ;;
            4) clear; intel_ucode_installer ;;
            5) clear; nvidia_open_menu ;;
            6) clear; nvidia_proprietary_menu ;;
            7) clear; nvidia_v470_installer ;;
            8) clear; optimusui_installer ;;
            9) clear; realtek_wifi_installer ;;
            10) clear; xpadneo_installer ;;
            11) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 10 ] && read -p "Pressione Enter para continuar..."
    done
}

dsplitm_installer() {
    local state_file="$STATE_DIR/dsplitm"

    if [ -f "$state_file" ] || grep -q "split_lock_detect=off" /proc/cmdline 2>/dev/null; then
        if confirm "Split-lock Mitigation desativado detectado. Desinstalar?"; then
            echo "Desinstalando desativação de Split-lock Mitigation..."
            sudo sed -i '/split_lock_detect=off/d' /etc/default/grub 2>/dev/null || true
            sudo rm -f /etc/default/grub.d/99-split-lock-disable.cfg /etc/kernel/cmdline.d/99-split-lock-disable.conf 2>/dev/null || true
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            sudo bootctl update 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Split-lock Mitigation reativado. Reinicie para aplicar."
        fi
    else
        if confirm "Desativar Split-lock Mitigation?"; then
            echo "Desativando Split-lock Mitigation..."
            if pacman -Qq grub &>/dev/null; then
                sudo mkdir -p /etc/default/grub.d
                echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} split_lock_detect=off"' | sudo tee /etc/default/grub.d/99-split-lock-disable.cfg
                sudo mkdir -p /boot/grub 2>/dev/null || true
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            else
                sudo mkdir -p /etc/kernel/cmdline.d
                echo "split_lock_detect=off" | sudo tee /etc/kernel/cmdline.d/99-split-lock-disable.conf
                sudo bootctl update 2>/dev/null || true
            fi
            touch "$state_file"
            echo "Split-lock Mitigation desativado. Reinicie para aplicar."
        fi
    fi
}

earlyoom_installer() {
    local state_file="$STATE_DIR/earlyoom"
    local pkg_earlyoom="earlyoom"

    if [ -f "$state_file" ] || pacman -Q earlyoom &>/dev/null; then
        if confirm "EarlyOOM detectado. Desinstalar?"; then
            echo "Desinstalando EarlyOOM..."
            sudo systemctl stop earlyoom 2>/dev/null || true
            sudo systemctl disable earlyoom 2>/dev/null || true
            pacman -Qq earlyoom &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_earlyoom || true
            cleanup_files "$state_file"
            echo "EarlyOOM desinstalado."
        fi
    else
        if confirm "Instalar EarlyOOM?"; then
            echo "Instalando EarlyOOM..."
            sudo pacman -S --noconfirm $pkg_earlyoom
            sudo systemctl enable earlyoom
            sudo systemctl start earlyoom
            touch "$state_file"
            echo "EarlyOOM instalado."
        fi
    fi
}

easyeffects_installer() {
    local state_file="$STATE_DIR/easyeffects"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.wwmm.easyeffects 2>/dev/null; then
        if confirm "EasyEffects detectado. Desinstalar?"; then
            echo "Desinstalando EasyEffects..."
            flatpak uninstall --user -y com.github.wwmm.easyeffects 2>/dev/null || true
            cleanup_files "$state_file"
            echo "EasyEffects desinstalado."
        fi
    else
        if confirm "Instalar EasyEffects?"; then
            echo "Instalando EasyEffects..."
            flatpak install --or-update --user --noninteractive flathub com.github.wwmm.easyeffects
            touch "$state_file"
            echo "EasyEffects instalado."
        fi
    fi
}

educacao_menu() {
    while true; do
        clear
        echo "=== Educação ==="
        echo "1) Endless Key"
        echo "2) GCompris"
        echo "3) GeoGebra"
        echo "4) Kalzium"
        echo "5) Kolibri"
        echo "6) Stellarium"
        echo "7) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; endlesskey_installer ;;
            2) clear; gcompris_installer ;;
            3) clear; geogebra_installer ;;
            4) clear; kalzium_installer ;;
            5) clear; kolibri_installer ;;
            6) clear; stellarium_installer ;;
            7) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 6 ] && read -p "Pressione Enter para continuar..."
    done
}

endlesskey_installer() {
    local state_file="$STATE_DIR/endlesskey"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.endlessos.Key 2>/dev/null; then
        if confirm "Endless Key detectado. Desinstalar?"; then
            echo "Desinstalando Endless Key..."
            flatpak uninstall --user -y org.endlessos.Key 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Endless Key desinstalado."
        fi
    else
        if confirm "Instalar Endless Key?"; then
            echo "Instalando Endless Key..."
            flatpak install --or-update --user --noninteractive flathub org.endlessos.Key
            touch "$state_file"
            echo "Endless Key instalado."
        fi
    fi
}

expressvpn_installer() {
    local state_file="$STATE_DIR/expressvpn"
    local pkg_expressvpn="expressvpn"

    if [ -f "$state_file" ] || pacman -Q expressvpn &>/dev/null; then
        if confirm "Expressvpn detectado. Desinstalar?"; then
            echo "Desinstalando Expressvpn..."
            pacman -Qq expressvpn &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_expressvpn || true
            cleanup_files "$state_file"
            echo "Expressvpn desinstalado."
        fi
    else
        if confirm "Instalar Expressvpn?"; then
            echo "Instalando Expressvpn..."
            sudo pacman -S --noconfirm $pkg_expressvpn
            touch "$state_file"
            echo "Expressvpn instalado."
        fi
    fi
}

extras_menu() {
    while true; do
        clear
        echo "=== Extras ==="
        echo "1) Ananicy-cpp"
        echo "2) AppArmor"
        echo "3) Arch Secure Boot"
        echo "4) Btrfs Assistant"
        echo "5) CachyOS Configs"
        echo "6) CPU Ondemand"
        echo "7) Distrobox Command Handler"
        echo "8) DNSMasq"
        echo "9) DsplitM"
        echo "10) EarlyOOM"
        echo "11) GRUB Btrfs"
        echo "12) HW Acceleration Flatpak"
        echo "13) IWD"
        echo "14) Microsoft Core Fonts"
        echo "15) MinFreeFix"
        echo "16) Powersave"
        echo "17) Preload"
        echo "18) Shader Booster"
        echo "19) Swapfile"
        echo "20) Thumbnailer"
        echo "21) UFW"
        echo "22) WinBoat"
        echo "23) Lucidglyph"
        echo "24) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; ananicy_cpp_installer ;;
            2) clear; apparmor_installer ;;
            3) clear; archsb_installer ;;
            4) clear; btrfs_assistant_installer ;;
            5) clear; cachyconfs_installer ;;
            6) clear; cpu_ondemand_installer ;;
            7) clear; distrobox_handler_installer ;;
            8) clear; dnsmasq_installer ;;
            9) clear; dsplitm_installer ;;
            10) clear; earlyoom_installer ;;
            11) clear; grub_btrfs_installer ;;
            12) clear; hwaccel_flatpak_installer ;;
            13) clear; iwd_installer ;;
            14) clear; mscorefonts_installer ;;
            15) clear; minfreefix_installer ;;
            16) clear; psaver_installer ;;
            17) clear; preload_installer ;;
            18) clear; shader_booster_installer ;;
            19) clear; swapfile_installer ;;
            20) clear; thumbnailer_installer ;;
            21) clear; ufw_installer ;;
            22) clear; winboat_installer ;;
            23) clear; lucidglyph_installer ;;
            24) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 23 ] && read -p "Pressione Enter para continuar..."
    done
}

f3_installer() {
    local state_file="$STATE_DIR/f3"
    local pkg_f3="f3"

    if [ -f "$state_file" ] || pacman -Q f3 &>/dev/null; then
        if confirm "F3 detectado. Desinstalar?"; then
            echo "Desinstalando F3..."
            pacman -Qq f3 &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_f3 || true
            cleanup_files "$state_file"
            echo "F3 desinstalado."
        fi
    else
        if confirm "Instalar F3?"; then
            echo "Instalando F3..."
            sudo pacman -S --noconfirm $pkg_f3
            touch "$state_file"
            echo "F3 instalado."
        fi
    fi
}

faugus_launcher_installer() {
    local state_file="$STATE_DIR/faugus_launcher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.Faugus.faugus-launcher 2>/dev/null; then
        if confirm "Faugus Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Faugus Launcher..."
            flatpak uninstall --user -y io.github.Faugus.faugus-launcher 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Faugus Launcher desinstalado."
        fi
    else
        if confirm "Instalar Faugus Launcher?"; then
            echo "Instalando Faugus Launcher..."
            flatpak install --user --noninteractive flathub io.github.Faugus.faugus-launcher
            sudo flatpak override io.github.Faugus.faugus-launcher --filesystem=~/.var/app/com.valvesoftware.Steam/.steam/steam/userdata/
            sudo flatpak override com.valvesoftware.Steam --talk-name=org.freedesktop.Flatpak
            sudo flatpak override com.valvesoftware.Steam --filesystem=~/.var/app/io.github.Faugus.faugus-launcher/config/faugus-launcher/
            touch "$state_file"
            echo "Faugus Launcher instalado."
        fi
    fi
}

fastfetch_installer() {
    local state_file="$STATE_DIR/fastfetch"
    local pkg_fastfetch="fastfetch"

    if [ -f "$state_file" ] || pacman -Q fastfetch &>/dev/null; then
        if confirm "fastfetch detectado. Desinstalar?"; then
            echo "Desinstalando fastfetch..."
            pacman -Qq fastfetch &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fastfetch || true
            cleanup_files "$state_file"
            echo "fastfetch desinstalado."
        fi
    else
        if confirm "Instalar fastfetch?"; then
            echo "Instalando fastfetch..."
            sudo pacman -S --noconfirm $pkg_fastfetch
            touch "$state_file"
            echo "fastfetch instalado."
        fi
    fi
}


zellij_installer() {
    local state_file="$STATE_DIR/zellij"
    local pkg_zellij="zellij"

    if [ -f "$state_file" ] || pacman -Q zellij &>/dev/null; then
        if confirm "Zellij detectado. Desinstalar?"; then
            echo "Desinstalando Zellij..."
            pacman -Qq zellij &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_zellij || true
            cleanup_files "$state_file"
            echo "Zellij desinstalado."
        fi
    else
        if confirm "Instalar Zellij?"; then
            echo "Instalando Zellij..."
            sudo pacman -S --noconfirm $pkg_zellij
            touch "$state_file"
            echo "Zellij instalado."
        fi
    fi
}

ferramentas_menu() {
    while true; do
        clear
        echo "=== Ferramentas ==="
        echo "1) Modern Unix Tools"
        echo "2) aria2"
        echo "3) btop"
        echo "4) curl"
        echo "5) distrobox"
        echo "6) fastfetch"
        echo "7) Opencode"
        echo "8) github-cli"
        echo "9) git"
        echo "10) lazygit"
        echo "11) lazydocker"
        echo "12) libqalculate"
        echo "13) ly"
        echo "14) smartmontools"
        echo "15) superfile"
        echo "16) XDG Base"
        echo "17) yt-dlp"
        echo "18) fzf"
        echo "19) gdu"
        echo "20) croc"
        echo "21) Podman"
        echo "22) Ollama"
        echo "23) Voxtype"
        echo "24) Zellij"
        echo "25) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; modern_unix_installer ;;
            2) clear; aria2_installer ;;
            3) clear; btop_installer ;;
            4) clear; curl_installer ;;
            5) clear; distrobox_installer ;;
            6) clear; fastfetch_installer ;;
            7) clear; opencode_installer ;;
            8) clear; github_cli_installer ;;
            9) clear; git_installer ;;
            10) clear; lazygit_installer ;;
            11) clear; lazydocker_installer ;;
            12) clear; libqalculate_installer ;;
            13) clear; smartmontools_installer ;;
            14) clear; superfile_installer ;;
            15) clear; xdg_base_installer ;;
            16) clear; yt_dlp_installer ;;
            17) clear; fzf_installer ;;
            18) clear; gdu_installer ;;
            19) clear; croc_installer ;;
            20) clear; podman_installer ;;
            21) clear; ollama_menu ;;
            22) clear; voxtype_installer ;;
            23) clear; zellij_installer ;;
            24) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 25 ] && read -p "Pressione Enter para continuar..."
    done
}

figma_installer() {
    local state_file="$STATE_DIR/figma"
    local pkg_figma="figma-linux-bin"

    if [ -f "$state_file" ] || pacman -Q figma-linux-bin &>/dev/null; then
        if confirm "Figma detectado. Desinstalar?"; then
            echo "Desinstalando Figma..."
            pacman -Qq figma-linux-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_figma || true
            cleanup_files "$state_file"
            echo "Figma desinstalado."
        fi
    else
        if confirm "Instalar Figma?"; then
            echo "Instalando Figma..."
            yay -S --noconfirm $pkg_figma
            touch "$state_file"
            echo "Figma instalado."
        fi
    fi
}

opencode_installer() {
    local state_file="$STATE_DIR/opencode"
    local pkg_opencode="opencode-bin"

    if [ -f "$state_file" ] || pacman -Q opencode-bin &>/dev/null; then
        if confirm "Opencode detectado. Desinstalar?"; then
            echo "Desinstalando Opencode..."
            pacman -Qq opencode-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_opencode || true
            cleanup_files "$state_file"
            echo "Opencode desinstalado."
        fi
    else
        if confirm "Instalar Opencode?"; then
            echo "Instalando Opencode..."
            yay -S --noconfirm $pkg_opencode
            touch "$state_file"
            echo "Opencode instalado."
        fi
    fi
}

voxtype_installer() {
    local state_file="$STATE_DIR/voxtype"
    local pkg_voxtype="voxtype-bin"

    if [ -f "$state_file" ] || pacman -Q voxtype-bin &>/dev/null; then
        if confirm "Voxtype detectado. Desinstalar?"; then
            echo "Desinstalando Voxtype..."
            pacman -Qq voxtype-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_voxtype || true
            cleanup_files "$state_file"
            echo "Voxtype desinstalado."
        fi
    else
        if confirm "Instalar Voxtype?"; then
            echo "Instalando Voxtype..."
            yay -S --noconfirm $pkg_voxtype
            touch "$state_file"
            echo "Voxtype instalado."
        fi
    fi
}

fish_installer() {
    local state_file="$STATE_DIR/fish"
    local pkg_fish="fish"

    if [ -f "$state_file" ] || pacman -Q fish &>/dev/null; then
        if confirm "Fish básico detectado. Desinstalar?"; then
            echo "Desinstalando Fish básico..."
            pacman -Qq fish &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fish || true
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$state_file" "$HOME/.config/fish"
            echo "Fish básico desinstalado."
        fi
    else
        if confirm "Instalar Fish básico?"; then
            echo "Instalando Fish básico..."
            sudo pacman -S --noconfirm $pkg_fish
            sudo chsh -s "$(which fish)" "$USER"
            mkdir -p ~/.config/fish
            echo "set fish_greeting" > ~/.config/fish/config.fish
            touch "$state_file"
            echo "Fish básico instalado."
        fi
    fi
}

fish_menu() {
    while true; do
        clear
        echo "=== Fish Shell ==="
        echo "1) Fish"
        echo "2) Fisher"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; fish_installer ;;
            2) clear; fisher_installer ;;
            3) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

fisher_installer() {
    local state_file="$STATE_DIR/fisher"
    local pkg_fisher="fisher"

    if [ -f "$state_file" ] || pacman -Q fisher &>/dev/null; then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            pacman -Qq fisher &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fisher || true
            cleanup_files "$state_file"
            echo "Fisher desinstalado."
        fi
    else
        if confirm "Instalar Fisher?"; then
            echo "Instalando Fisher..."
            sudo pacman -S --noconfirm $pkg_fisher
            fish -c "fisher install jorgebucaran/fisher" 2>/dev/null || true
            touch "$state_file"
            echo "Fisher instalado."
        fi
    fi
}

flatpak_installer() {
    local state_file="$STATE_DIR/flatpak"
    local pkg_flatpak="flatpak"

    if [ -f "$state_file" ] || pacman -Q flatpak &>/dev/null; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            pacman -Qq flatpak &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_flatpak || true
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Flatpak desinstalado."
        fi
    else
        echo "Instalando Flatpak..."
        sudo pacman -S --noconfirm $pkg_flatpak
        touch "$state_file"
        echo "Flatpak instalado."
    fi
}

flatseal_installer() {
    local state_file="$STATE_DIR/flatseal"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.tchx84.Flatseal 2>/dev/null; then
        if confirm "Flatseal detectado. Desinstalar?"; then
            echo "Desinstalando Flatseal..."
            flatpak uninstall --user -y com.github.tchx84.Flatseal 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Flatseal desinstalado."
        fi
    else
        if confirm "Instalar Flatseal?"; then
            echo "Instalando Flatseal..."
            flatpak install --or-update --user --noninteractive flathub com.github.tchx84.Flatseal
            touch "$state_file"
            echo "Flatseal instalado."
        fi
    fi
}

foliate_installer() {
    local state_file="$STATE_DIR/foliate"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.johnfactotum.Foliate 2>/dev/null; then
        if confirm "Foliate detectado. Desinstalar?"; then
            echo "Desinstalando Foliate..."
            flatpak uninstall --user -y com.github.johnfactotum.Foliate 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Foliate desinstalado."
        fi
    else
        if confirm "Instalar Foliate?"; then
            echo "Instalando Foliate..."
            flatpak install --or-update --user --noninteractive flathub com.github.johnfactotum.Foliate
            touch "$state_file"
            echo "Foliate instalado."
        fi
    fi
}

freecad_installer() {
    local state_file="$STATE_DIR/freecad"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.freecad.FreeCAD 2>/dev/null; then
        if confirm "FreeCAD detectado. Desinstalar?"; then
            echo "Desinstalando FreeCAD..."
            flatpak uninstall --user -y org.freecad.FreeCAD 2>/dev/null || true
            cleanup_files "$state_file"
            echo "FreeCAD desinstalado."
        fi
    else
        if confirm "Instalar FreeCAD?"; then
            echo "Instalando FreeCAD..."
            flatpak install --or-update --user --noninteractive flathub org.freecad.FreeCAD
            touch "$state_file"
            echo "FreeCAD instalado."
        fi
    fi
}

fwupd_installer() {
    local state_file="$STATE_DIR/fwupd"
    local pkg_fwupd="fwupd"

    if [ -f "$state_file" ] || pacman -Q fwupd &>/dev/null; then
        if confirm "Fwupd detectado. Desinstalar?"; then
            echo "Desinstalando Fwupd..."
            pacman -Qq fwupd &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fwupd || true
            cleanup_files "$state_file"
            echo "Fwupd desinstalado."
        fi
    else
        if confirm "Instalar Fwupd?"; then
            echo "Instalando Fwupd..."
            sudo pacman -S --noconfirm $pkg_fwupd
            touch "$state_file"
            echo "Fwupd instalado."
        fi
    fi
}

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode lib32-gamemode"

    if [ -f "$state_file" ] || pacman -Q gamemode &>/dev/null; then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            pacman -Qq gamemode &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gamemode || true
            cleanup_files "$state_file"
            echo "Gamemode desinstalado."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
            sudo pacman -S --noconfirm $pkg_gamemode
            touch "$state_file"
            echo "Gamemode instalado."
        fi
    fi
}

gamescope_installer() {
    local state_file="$STATE_DIR/gamescope"
    local pkg_gamescope="gamescope"

    if [ -f "$state_file" ] || pacman -Q gamescope &>/dev/null; then
        if confirm "Gamescope detectado. Desinstalar?"; then
            echo "Desinstalando Gamescope..."
            pacman -Qq gamescope &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gamescope || true
            flatpak uninstall --user -y org.freedesktop.Platform.VulkanLayer.gamescope 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Gamescope desinstalado."
        fi
    else
        if confirm "Instalar Gamescope?"; then
            echo "Instalando Gamescope..."
            sudo pacman -S --noconfirm $pkg_gamescope
            flatpak install --user --noninteractive flathub org.freedesktop.Platform.VulkanLayer.gamescope 2>/dev/null || true
            touch "$state_file"
            echo "Gamescope instalado."
        fi
    fi
}

gcompris_installer() {
    local state_file="$STATE_DIR/gcompris"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.gcompris 2>/dev/null; then
        if confirm "GCompris detectado. Desinstalar?"; then
            echo "Desinstalando GCompris..."
            flatpak uninstall --user -y org.kde.gcompris 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GCompris desinstalado."
        fi
    else
        if confirm "Instalar GCompris?"; then
            echo "Instalando GCompris..."
            flatpak install --or-update --user --noninteractive flathub org.kde.gcompris
            touch "$state_file"
            echo "GCompris instalado."
        fi
    fi
}

gearlever_installer() {
    local state_file="$STATE_DIR/gearlever"

    if [ -f "$state_file" ] || flatpak list --app | grep -q it.mijorus.gearlever 2>/dev/null; then
        if confirm "Gear Lever detectado. Desinstalar?"; then
            echo "Desinstalando Gear Lever..."
            flatpak uninstall --user -y it.mijorus.gearlever 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Gear Lever desinstalado."
        fi
    else
        if confirm "Instalar Gear Lever?"; then
            echo "Instalando Gear Lever..."
            flatpak install --or-update --user --noninteractive flathub it.mijorus.gearlever
            touch "$state_file"
            echo "Gear Lever instalado."
        fi
    fi
}

geforce_now_installer() {
    local state_file="$STATE_DIR/geforce_now"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.nvidia.geforcenow 2>/dev/null; then
        if confirm "GeForce NOW detectado. Desinstalar?"; then
            echo "Desinstalando GeForce NOW..."
            flatpak uninstall --user -y com.nvidia.geforcenow 2>/dev/null || true
            flatpak remote-delete GeForceNOW 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GeForce NOW desinstalado."
        fi
    else
        if confirm "Instalar GeForce NOW?"; then
            echo "Instalando GeForce NOW..."
            flatpak install --or-update --user --noninteractive flathub org.freedesktop.Sdk//24.08
            flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo
            flatpak install --or-update --user --noninteractive GeForceNOW com.nvidia.geforcenow
            flatpak override --user --nosocket=wayland com.nvidia.geforcenow
            touch "$state_file"
            echo "GeForce NOW instalado."
        fi
    fi
}

geogebra_installer() {
    local state_file="$STATE_DIR/geogebra"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.geogebra.GeoGebra 2>/dev/null; then
        if confirm "GeoGebra detectado. Desinstalar?"; then
            echo "Desinstalando GeoGebra..."
            flatpak uninstall --user -y org.geogebra.GeoGebra 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GeoGebra desinstalado."
        fi
    else
        if confirm "Instalar GeoGebra?"; then
            echo "Instalando GeoGebra..."
            flatpak install --or-update --user --noninteractive flathub org.geogebra.GeoGebra
            touch "$state_file"
            echo "GeoGebra instalado."
        fi
    fi
}

github_cli_installer() {
    local state_file="$STATE_DIR/github_cli"
    local pkg_gh="github-cli"

    if [ -f "$state_file" ] || pacman -Q github-cli &>/dev/null; then
        if confirm "github-cli detectado. Desinstalar?"; then
            echo "Desinstalando github-cli..."
            pacman -Qq github-cli &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gh || true
            cleanup_files "$state_file"
            echo "github-cli desinstalado."
        fi
    else
        if confirm "Instalar github-cli?"; then
            echo "Instalando github-cli..."
            sudo pacman -S --noconfirm $pkg_gh
            touch "$state_file"
            echo "github-cli instalado."
        fi
    fi
}

git_installer() {
    local state_file="$STATE_DIR/git"
    local pkg_git="git"

    if [ -f "$state_file" ] || pacman -Q git &>/dev/null; then
        if confirm "git detectado. Desinstalar?"; then
            echo "Desinstalando git..."
            pacman -Qq git &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_git || true
            cleanup_files "$state_file"
            echo "git desinstalado."
        fi
    else
        if confirm "Instalar git?"; then
            echo "Instalando git..."
            sudo pacman -S --noconfirm $pkg_git
            touch "$state_file"
            echo "git instalado."
        fi
    fi
}

gimp_installer() {
    local state_file="$STATE_DIR/gimp"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.gimp.GIMP 2>/dev/null; then
        if confirm "GIMP detectado. Desinstalar?"; then
            echo "Desinstalando GIMP..."
            flatpak uninstall --user -y org.gimp.GIMP 2>/dev/null || true
            rm -rf "$HOME/.config/GIMP" "$HOME/.local/share/GIMP" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GIMP desinstalado."
        fi
    else
        if confirm "Instalar GIMP?"; then
            echo "Instalando GIMP..."
            flatpak install --or-update --user --noninteractive flathub org.gimp.GIMP
            touch "$state_file"
            echo "GIMP instalado."
        fi
    fi
}

photogimp_installer() {
    local state_file="$STATE_DIR/photogimp"

    if [ -f "$state_file" ] || [ -d "$HOME/.config/GIMP" ]; then
        if confirm "PhotoGIMP detectado. Desinstalar?"; then
            echo "Desinstalando PhotoGIMP..."
            rm -rf "$HOME/.config/GIMP" "$HOME/.local/share/GIMP" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "PhotoGIMP desinstalado."
        fi
    else
        if confirm "Instalar PhotoGIMP (temas e configurações extras)?"; then
            echo "Instalando PhotoGIMP..."
            git clone --depth=1 https://github.com/Diolinux/PhotoGIMP.git /tmp/photogimp
            cp -rvf /tmp/photogimp/.config/* ~/.config/ 2>/dev/null || true
            cp -rvf /tmp/photogimp/.local/* ~/.local/ 2>/dev/null || true
            rm -rf /tmp/photogimp
            touch "$state_file"
            echo "PhotoGIMP instalado."
        fi
    fi
}

gimp_menu() {
    while true; do
        clear
        echo "=== GIMP ==="
        echo "1) GIMP"
        echo "2) PhotoGIMP"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; gimp_installer ;;
            2) clear; photogimp_installer ;;
            3) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

gnome_boxes_installer() {
    local state_file="$STATE_DIR/gnome_boxes"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.gnome.Boxes 2>/dev/null; then
        if confirm "GNOME Boxes detectado. Desinstalar?"; then
            echo "Desinstalando GNOME Boxes..."
            flatpak uninstall --user -y org.gnome.Boxes 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GNOME Boxes desinstalado."
        fi
    else
        if confirm "Instalar GNOME Boxes?"; then
            echo "Instalando GNOME Boxes..."
            flatpak install --or-update --user --noninteractive flathub org.gnome.Boxes
            touch "$state_file"
            echo "GNOME Boxes instalado."
        fi
    fi
}

godot_installer() {
    local state_file="$STATE_DIR/godot"
    local pkg_godot="godot"

    if [ -f "$state_file" ] || pacman -Q godot &>/dev/null; then
        if confirm "Godot detectado. Desinstalar?"; then
            echo "Desinstalando Godot..."
            pacman -Qq godot &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_godot || true
            cleanup_files "$state_file"
            echo "Godot desinstalado."
        fi
    else
        if confirm "Instalar Godot Engine?"; then
            echo "Instalando Godot Engine..."
            sudo pacman -S --noconfirm $pkg_godot
            touch "$state_file"
            echo "Godot Engine instalado."
        fi
    fi
}

goverlay_installer() {
    local state_file="$STATE_DIR/goverlay"
    local pkg_goverlay="mangohud goverlay"

    if [ -f "$state_file" ] || pacman -Q goverlay &>/dev/null; then
        if confirm "GOverlay detectado. Desinstalar?"; then
            echo "Desinstalando GOverlay..."
            pacman -Qq goverlay &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_goverlay || true
            cleanup_files "$state_file"
            echo "GOverlay desinstalado."
        fi
    else
        if confirm "Instalar GOverlay?"; then
            echo "Instalando GOverlay..."
            sudo pacman -S --noconfirm $pkg_goverlay
            command -v flatpak &>/dev/null && flatpak install --or-update --user --noninteractive flathub com.valvesoftware.Steam.VulkanLayer.MangoHud/x86_64/stable org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
            touch "$state_file"
            echo "GOverlay instalado."
        fi
    fi
}

gpu_screen_recorder_installer() {
    local state_file="$STATE_DIR/gpu_screen_recorder"
    local pkg_gsr="gpu-screen-recorder"

    if [ -f "$state_file" ] || pacman -Q gpu-screen-recorder &>/dev/null; then
        if confirm "GPU Screen Recorder detectado. Desinstalar?"; then
            echo "Desinstalando GPU Screen Recorder..."
            pacman -Qq gpu-screen-recorder &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gsr || true
            cleanup_files "$state_file"
            echo "GPU Screen Recorder desinstalado."
        fi
    else
        if confirm "Instalar GPU Screen Recorder?"; then
            echo "Instalando GPU Screen Recorder..."
            sudo pacman -S --noconfirm $pkg_gsr
            touch "$state_file"
            echo "GPU Screen Recorder instalado."
        fi
    fi
}

grub_btrfs_installer() {
    local state_file="$STATE_DIR/grub_btrfs"
    local pkg_grub_btrfs="grub-btrfs snapper"

    if [ -f "$state_file" ] || pacman -Q grub-btrfs &>/dev/null; then
        if confirm "GRUB Btrfs detectado. Desinstalar?"; then
            echo "Desinstalando GRUB Btrfs..."
            sudo systemctl stop grub-btrfsd 2>/dev/null || true
            sudo systemctl disable grub-btrfsd 2>/dev/null || true
            pacman -Qq grub-btrfs &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_grub_btrfs || true
            pacman -Qq snapper &>/dev/null && sudo systemctl stop snapper-boot.timer snapper-cleanup.timer 2>/dev/null || true && sudo systemctl disable snapper-boot.timer snapper-cleanup.timer 2>/dev/null || true && sudo pacman -Rsnu --noconfirm snapper || true
            sudo rm -rf /.snapshots /etc/snapper/configs 2>/dev/null || true
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            cleanup_files "$state_file"
            echo "GRUB Btrfs desinstalado. Reinicie para aplicar."
        fi
    else
        findmnt -n -o FSTYPE / | grep -q "btrfs" || { echo "Sistema de arquivos raiz não é Btrfs."; return 1; }
        if confirm "Instalar GRUB Btrfs (snapshots no GRUB)?"; then
            echo "Instalando GRUB Btrfs..."
            sudo pacman -S --noconfirm $pkg_grub_btrfs
            sudo btrfs subvolume delete -R /.snapshots 2>/dev/null || true
            sudo snapper -c root create-config /
            sudo snapper -c root create --command pacman 2>/dev/null || true
            sudo sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' /etc/snapper/configs/root 2>/dev/null || true
            sudo sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="5"/' /etc/snapper/configs/root 2>/dev/null || true
            sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/root 2>/dev/null || true
            sudo systemctl enable snapper-boot.timer snapper-cleanup.timer
            sudo systemctl start snapper-cleanup.timer
            sudo mkdir -p /boot/grub 2>/dev/null || true
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            sudo systemctl enable --now grub-btrfsd
            touch "$state_file"
            echo "GRUB Btrfs instalado. Reinicie para aplicar."
        fi
    fi
}

handbrake_installer() {
    local state_file="$STATE_DIR/handbrake"

    if [ -f "$state_file" ] || flatpak list --app | grep -q fr.handbrake.ghb 2>/dev/null; then
        if confirm "HandBrake detectado. Desinstalar?"; then
            echo "Desinstalando HandBrake..."
            flatpak uninstall --user -y fr.handbrake.ghb 2>/dev/null || true
            cleanup_files "$state_file"
            echo "HandBrake desinstalado."
        fi
    else
        if confirm "Instalar HandBrake?"; then
            echo "Instalando HandBrake..."
            flatpak install --or-update --user --noninteractive flathub fr.handbrake.ghb
            touch "$state_file"
            echo "HandBrake instalado."
        fi
    fi
}

heroic_games_launcher_installer() {
    local state_file="$STATE_DIR/heroic_games_launcher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.heroicgameslauncher.hgl 2>/dev/null; then
        if confirm "Heroic Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Heroic Launcher..."
            flatpak uninstall --user -y com.heroicgameslauncher.hgl 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Heroic Launcher desinstalado."
        fi
    else
        if confirm "Instalar Heroic Launcher?"; then
            echo "Instalando Heroic Launcher..."
            flatpak install --or-update --user --noninteractive flathub com.heroicgameslauncher.hgl
            touch "$state_file"
            echo "Heroic Launcher instalado."
        fi
    fi
}

homebrew_installer() {
    local state_file="$STATE_DIR/homebrew"
    local pkg_brew="brew-git"

    if [ -f "$state_file" ] || pacman -Q brew-git &>/dev/null; then
        if confirm "Brew detectado. Desinstalar?"; then
            echo "Desinstalando Brew..."
            pacman -Qq brew-git &>/dev/null && yay -Rsnu --noconfirm $pkg_brew || true
            cleanup_files "$state_file"
            echo "Brew desinstalado."
        fi
    else
        if confirm "Instalar Brew?"; then
            echo "Instalando Brew..."
            yay -S --noconfirm $pkg_brew
            touch "$state_file"
            echo "Brew instalado."
        fi
    fi
}

httpie_installer() {
    local state_file="$STATE_DIR/httpie"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.httpie.Httpie 2>/dev/null; then
        if confirm "HTTPie detectado. Desinstalar?"; then
            echo "Desinstalando HTTPie..."
            flatpak uninstall --user -y io.httpie.Httpie 2>/dev/null || true
            cleanup_files "$state_file"
            echo "HTTPie desinstalado."
        fi
    else
        if confirm "Instalar HTTPie?"; then
            echo "Instalando HTTPie..."
            flatpak install --user --or-update --noninteractive flathub io.httpie.Httpie
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
            flatpak uninstall --user -y freedesktop.Platform.VAAPI 2>/dev/null || true
            flatpak uninstall --user -y freedesktop.Platform.VAAPI.Intel 2>/dev/null || true
            cleanup_files "$state_file"
            echo "HW Acceleration Flatpak desinstalado."
        fi
    else
        if confirm "Instalar HW Acceleration Flatpak?"; then
            echo "Instalando HW Acceleration Flatpak..."
            pacman -Q flatpak &>/dev/null || { sudo pacman -S --noconfirm flatpak; flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; }
            flatpak install --user -y flathub org.freedesktop.Platform.VAAPI.Intel 2>/dev/null || true
            flatpak override --user --device=all --env=GDK_SCALE=1 --env=GDK_DPI_SCALE=1 2>/dev/null || true
            touch "$state_file"
            echo "HW Acceleration Flatpak instalado."
        fi
    fi
}

hydra_launcher_installer() {
    local state_file="$STATE_DIR/hydra_launcher"
    local pkg_hydra="hydra-launcher-bin"

    if [ -f "$state_file" ] || pacman -Q hydra-launcher-bin &>/dev/null; then
        if confirm "Hydra Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Hydra Launcher..."
            pacman -Qq hydra-launcher-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_hydra || true
            cleanup_files "$state_file"
            echo "Hydra Launcher desinstalado."
        fi
    else
        if confirm "Instalar Hydra Launcher?"; then
            echo "Instalando Hydra Launcher..."
            yay -S --noconfirm $pkg_hydra
            touch "$state_file"
            echo "Hydra Launcher instalado."
        fi
    fi
}

ides_menu() {
    while true; do
        clear
        echo "=== IDEs ==="
        echo "1) Android Studio"
        echo "2) JetBrains Toolbox"
        echo "3) NeoVim"
        echo "4) Sublime Text"
        echo "5) Visual Studio Code"
        echo "6) VSCodium"
        echo "7) Zed"
        echo "8) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; android_studio_installer ;;
            2) clear; jetbrains_toolbox_installer ;;
            3) clear; nvim_menu ;;
            4) clear; sublime_text_installer ;;
            5) clear; vscode_installer ;;
            6) clear; vscodium_installer ;;
            7) clear; zed_installer ;;
            8) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 7 ] && read -p "Pressione Enter para continuar..."
    done
}

inkscape_installer() {
    local state_file="$STATE_DIR/inkscape"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.inkscape.Inkscape 2>/dev/null; then
        if confirm "Inkscape detectado. Desinstalar?"; then
            echo "Desinstalando Inkscape..."
            flatpak uninstall --user -y org.inkscape.Inkscape 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Inkscape desinstalado."
        fi
    else
        if confirm "Instalar Inkscape?"; then
            echo "Instalando Inkscape..."
            flatpak install --or-update --user --noninteractive flathub org.inkscape.Inkscape
            touch "$state_file"
            echo "Inkscape instalado."
        fi
    fi
}

input_remapper_installer() {
    local state_file="$STATE_DIR/input_remapper"
    local pkg_input="input-remapper-git"

    if [ -f "$state_file" ] || pacman -Q input-remapper-git &>/dev/null; then
        if confirm "Input Remapper detectado. Desinstalar?"; then
            echo "Desinstalando Input Remapper..."
            pacman -Qq input-remapper-git &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_input || true
            cleanup_files "$state_file"
            echo "Input Remapper desinstalado."
        fi
    else
        if confirm "Instalar Input Remapper?"; then
            echo "Instalando Input Remapper..."
            sudo pacman -S --noconfirm $pkg_input
            touch "$state_file"
            echo "Input Remapper instalado."
        fi
    fi
}

insomnia_installer() {
    local state_file="$STATE_DIR/insomnia"

    if [ -f "$state_file" ] || flatpak list --app | grep -q rest.insomnia.Insomnia 2>/dev/null; then
        if confirm "Insomnia detectado. Desinstalar?"; then
            echo "Desinstalando Insomnia..."
            flatpak uninstall --user -y rest.insomnia.Insomnia 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Insomnia desinstalado."
        fi
    else
        if confirm "Instalar Insomnia?"; then
            echo "Instalando Insomnia..."
            flatpak install --user --or-update --noninteractive flathub rest.insomnia.Insomnia
            touch "$state_file"
            echo "Insomnia instalado."
        fi
    fi
}

intel_ucode_installer() {
    local state_file="$STATE_DIR/intel_ucode"
    local pkg_intel="intel-ucode"

    if [ -f "$state_file" ] || pacman -Q intel-ucode &>/dev/null; then
        if confirm "Intel ucode detectado. Desinstalar?"; then
            echo "Desinstalando Intel ucode..."
            pacman -Qq intel-ucode &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_intel || true
            cleanup_files "$state_file"
            echo "Intel ucode desinstalado."
        fi
    else
        if confirm "Instalar Intel ucode?"; then
            echo "Instalando Intel ucode..."
            sudo pacman -S --noconfirm $pkg_intel
            touch "$state_file"
            echo "Intel ucode instalado."
        fi
    fi
}

iwd_installer() {
    local state_file="$STATE_DIR/iwd"
    local pkg_iwd="iwd"

    if [ -f "$state_file" ] || pacman -Q iwd &>/dev/null; then
        if confirm "IWD detectado. Desinstalar?"; then
            echo "Desinstalando IWD..."
            pacman -Qq iwd &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_iwd || true
            sudo rm -f /etc/NetworkManager/conf.d/iwd.conf 2>/dev/null || true
            sudo systemctl restart NetworkManager 2>/dev/null || true
            sudo systemctl enable --now wpa_supplicant 2>/dev/null || true
            cleanup_files "$state_file"
            echo "IWD desinstalado."
        fi
    else
        if confirm "Instalar IWD (iNet Wireless Daemon)?"; then
            echo "Instalando IWD..."
            sudo pacman -S --noconfirm $pkg_iwd
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
    local pkg_jdk="jdk-openjdk"

    if [ -f "$state_file" ] || pacman -Q jdk-openjdk &>/dev/null; then
        if confirm "Java OpenJDK detectado. Desinstalar?"; then
            echo "Desinstalando Java OpenJDK..."
            pacman -Qq jdk-openjdk &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_jdk || true
            cleanup_files "$state_file"
            echo "Java OpenJDK desinstalado."
        fi
    else
        if confirm "Instalar Java OpenJDK?"; then
            echo "Instalando Java OpenJDK..."
            sudo pacman -S --noconfirm $pkg_jdk
            touch "$state_file"
            echo "Java OpenJDK instalado."
        fi
    fi
}

jetbrains_toolbox_installer() {
    local state_file="$STATE_DIR/jetbrains"
    local pkg_jetbrains="jetbrains-toolbox"

    if [ -f "$state_file" ] || pacman -Q jetbrains-toolbox &>/dev/null; then
        if confirm "Jetbrains Toolbox detectado. Desinstalar?"; then
            echo "Desinstalando Jetbrains Toolbox..."
            pacman -Qq jetbrains-toolbox &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_jetbrains || true
            cleanup_files "$state_file"
            echo "Jetbrains Toolbox desinstalado."
        fi
    else
        if confirm "Instalar Jetbrains Toolbox?"; then
            echo "Instalando Jetbrains Toolbox..."
            sudo pacman -S --noconfirm $pkg_jetbrains
            touch "$state_file"
            echo "Jetbrains Toolbox instalado."
        fi
    fi
}

jogos_menu() {
    while true; do
        clear
        echo "=== Jogos ==="
        echo "1) Faugus Launcher"
        echo "2) Gamemode"
        echo "3) Gamescope"
        echo "4) GeForce NOW"
        echo "5) GOverlay"
        echo "6) GPU Screen Recorder"
        echo "7) Heroic Games Launcher"
        echo "8) Lossless Scaling"
        echo "9) Lutris"
        echo "10) Minecraft Bedrock Launcher"
        echo "11) MangoJuice"
        echo "12) Moonlight"
        echo "13) Osu!"
        echo "14) Prism Launcher"
        echo "15) ProtonPlus"
        echo "16) Protontricks"
        echo "17) ProtonUp"
        echo "18) Sober"
        echo "19) Steam"
        echo "20) Sunshine"
        echo "21) Vinegar"
        echo "22) WiVRn"
        echo "23) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; faugus_launcher_installer ;;
            2) clear; gamemode_installer ;;
            3) clear; gamescope_installer ;;
            4) clear; geforce_now_installer ;;
            5) clear; goverlay_installer ;;
            6) clear; gpu_screen_recorder_installer ;;
            7) clear; heroic_games_launcher_installer ;;
            8) clear; lossless_scaling_installer ;;
            9) clear; lutris_installer ;;
            10) clear; minecraft_bedrock_launcher_installer ;;
            11) clear; mangojuice_installer ;;
            12) clear; moonlight_installer ;;
            13) clear; osu_installer ;;
            14) clear; prism_launcher_installer ;;
            15) clear; protonplus_installer ;;
            16) clear; protontricks_installer ;;
            17) clear; protonup_installer ;;
            18) clear; sober_installer ;;
            19) clear; steam_installer ;;
            20) clear; sunshine_installer ;;
            21) clear; vinegar_installer ;;
            22) clear; wivrn_installer ;;
            23) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 22 ] && read -p "Pressione Enter para continuar..."
    done
}

kalzium_installer() {
    local state_file="$STATE_DIR/kalzium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.kalzium 2>/dev/null; then
        if confirm "Kalzium detectado. Desinstalar?"; then
            echo "Desinstalando Kalzium..."
            flatpak uninstall --user -y org.kde.kalzium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Kalzium desinstalado."
        fi
    else
        if confirm "Instalar Kalzium?"; then
            echo "Instalando Kalzium..."
            flatpak install --or-update --user --noninteractive flathub org.kde.kalzium
            touch "$state_file"
            echo "Kalzium instalado."
        fi
    fi
}

keepassxc_installer() {
    local state_file="$STATE_DIR/keepassxc"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.keepassxc.KeePassXC 2>/dev/null; then
        if confirm "KeePassXC detectado. Desinstalar?"; then
            echo "Desinstalando KeePassXC..."
            flatpak uninstall --user -y org.keepassxc.KeePassXC 2>/dev/null || true
            cleanup_files "$state_file"
            echo "KeePassXC desinstalado."
        fi
    else
        if confirm "Instalar KeePassXC?"; then
            echo "Instalando KeePassXC..."
            flatpak install --or-update --user --noninteractive flathub org.keepassxc.KeePassXC
            touch "$state_file"
            echo "KeePassXC instalado."
        fi
    fi
}

kdenlive_installer() {
    local state_file="$STATE_DIR/kdenlive"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.kdenlive 2>/dev/null; then
        if confirm "Kdenlive detectado. Desinstalar?"; then
            echo "Desinstalando Kdenlive..."
            flatpak uninstall --user -y org.kde.kdenlive 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Kdenlive desinstalado."
        fi
    else
        if confirm "Instalar Kdenlive?"; then
            echo "Instalando Kdenlive..."
            flatpak install --or-update --user --noninteractive flathub org.kde.kdenlive
            touch "$state_file"
            echo "Kdenlive instalado."
        fi
    fi
}

kicad_installer() {
    local state_file="$STATE_DIR/kicad"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kicad.KiCad 2>/dev/null; then
        if confirm "KiCad detectado. Desinstalar?"; then
            echo "Desinstalando KiCad..."
            flatpak uninstall --user -y org.kicad.KiCad 2>/dev/null || true
            cleanup_files "$state_file"
            echo "KiCad desinstalado."
        fi
    else
        if confirm "Instalar KiCad?"; then
            echo "Instalando KiCad..."
            flatpak install --or-update --user --noninteractive flathub org.kicad.KiCad
            touch "$state_file"
            echo "KiCad instalado."
        fi
    fi
}

kolibri_installer() {
    local state_file="$STATE_DIR/kolibri"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.learningequality.Kolibri 2>/dev/null; then
        if confirm "Kolibri detectado. Desinstalar?"; then
            echo "Desinstalando Kolibri..."
            flatpak uninstall --user -y org.learningequality.Kolibri 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Kolibri desinstalado."
        fi
    else
        if confirm "Instalar Kolibri?"; then
            echo "Instalando Kolibri..."
            flatpak install --or-update --user --noninteractive flathub org.learningequality.Kolibri
            touch "$state_file"
            echo "Kolibri instalado."
        fi
    fi
}

krita_installer() {
    local state_file="$STATE_DIR/krita"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.kde.krita 2>/dev/null; then
        if confirm "Krita detectado. Desinstalar?"; then
            echo "Desinstalando Krita..."
            flatpak uninstall --user -y org.kde.krita 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Krita desinstalado."
        fi
    else
        if confirm "Instalar Krita?"; then
            echo "Instalando Krita..."
            flatpak install --or-update --user --noninteractive flathub org.kde.krita
            touch "$state_file"
            echo "Krita instalado."
        fi
    fi
}

lact_installer() {
    local state_file="$STATE_DIR/lact"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.ilya_zlobintsev.LACT 2>/dev/null; then
        if confirm "LACT detectado. Desinstalar?"; then
            echo "Desinstalando LACT..."
            flatpak uninstall --user -y io.github.ilya_zlobintsev.LACT 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LACT desinstalado."
        fi
    else
        if confirm "Instalar LACT?"; then
            echo "Instalando LACT..."
            flatpak install --or-update --user --noninteractive flathub io.github.ilya_zlobintsev.LACT
            touch "$state_file"
            echo "LACT instalado."
        fi
    fi
}

lazydocker_installer() {
    local state_file="$STATE_DIR/lazydocker"
    local pkg_lazydocker="lazydocker"

    if [ -f "$state_file" ] || pacman -Q lazydocker &>/dev/null; then
        if confirm "lazydocker detectado. Desinstalar?"; then
            echo "Desinstalando lazydocker..."
            pacman -Qq lazydocker &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_lazydocker || true
            cleanup_files "$state_file"
            echo "lazydocker desinstalado."
        fi
    else
        if confirm "Instalar lazydocker?"; then
            echo "Instalando lazydocker..."
            sudo pacman -S --noconfirm $pkg_lazydocker
            touch "$state_file"
            echo "lazydocker instalado."
        fi
    fi
}

lazygit_installer() {
    local state_file="$STATE_DIR/lazygit"
    local pkg_lazygit="lazygit"

    if [ -f "$state_file" ] || pacman -Q lazygit &>/dev/null; then
        if confirm "lazygit detectado. Desinstalar?"; then
            echo "Desinstalando lazygit..."
            pacman -Qq lazygit &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_lazygit || true
            cleanup_files "$state_file"
            echo "lazygit desinstalado."
        fi
    else
        if confirm "Instalar lazygit?"; then
            echo "Instalando lazygit..."
            sudo pacman -S --noconfirm $pkg_lazygit
            touch "$state_file"
            echo "lazygit instalado."
        fi
    fi
}

libqalculate_installer() {
    local state_file="$STATE_DIR/libqalculate"
    local pkg_qalc="libqalculate"

    if [ -f "$state_file" ] || pacman -Q libqalculate &>/dev/null; then
        if confirm "libqalculate detectado. Desinstalar?"; then
            echo "Desinstalando libqalculate..."
            pacman -Qq libqalculate &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_qalc || true
            cleanup_files "$state_file"
            echo "libqalculate desinstalado."
        fi
    else
        if confirm "Instalar libqalculate?"; then
            echo "Instalando libqalculate..."
            sudo pacman -S --noconfirm $pkg_qalc
            touch "$state_file"
            echo "libqalculate instalado."
        fi
    fi
}

libreoffice_installer() {
    local state_file="$STATE_DIR/libreoffice"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.libreoffice.LibreOffice 2>/dev/null; then
        if confirm "LibreOffice detectado. Desinstalar?"; then
            echo "Desinstalando LibreOffice..."
            flatpak uninstall --user -y org.libreoffice.LibreOffice 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LibreOffice desinstalado."
        fi
    else
        if confirm "Instalar LibreOffice?"; then
            echo "Instalando LibreOffice..."
            flatpak install --or-update --user --noninteractive flathub org.libreoffice.LibreOffice
            touch "$state_file"
            echo "LibreOffice instalado."
        fi
    fi
}

librewolf_installer() {
    local state_file="$STATE_DIR/librewolf"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.gitlab.librewolf-community 2>/dev/null; then
        if confirm "LibreWolf detectado. Desinstalar?"; then
            echo "Desinstalando LibreWolf..."
            flatpak uninstall --user -y io.gitlab.librewolf-community 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LibreWolf desinstalado."
        fi
    else
        if confirm "Instalar LibreWolf?"; then
            echo "Instalando LibreWolf..."
            flatpak install --or-update --user --noninteractive flathub io.gitlab.librewolf-community
            touch "$state_file"
            echo "LibreWolf instalado."
        fi
    fi
}

logseq_installer() {
    local state_file="$STATE_DIR/logseq"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.logseq.Logseq 2>/dev/null; then
        if confirm "LogSEQ detectado. Desinstalar?"; then
            echo "Desinstalando LogSEQ..."
            flatpak uninstall --user -y com.logseq.Logseq 2>/dev/null || true
            cleanup_files "$state_file"
            echo "LogSEQ desinstalado."
        fi
    else
        if confirm "Instalar LogSEQ?"; then
            echo "Instalando LogSEQ..."
            flatpak install --or-update --user --noninteractive flathub com.logseq.Logseq
            touch "$state_file"
            echo "LogSEQ instalado."
        fi
    fi
}

lossless_scaling_installer() {
    local state_file="$STATE_DIR/lossless_scaling"
    local pkg_lsfg="lsfg-vk"

    if [ -f "$state_file" ] || pacman -Q lsfg-vk &>/dev/null; then
        if confirm "Lossless Scaling detectado. Desinstalar?"; then
            echo "Desinstalando Lossless Scaling..."
            pacman -Qq lsfg-vk &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_lsfg || true
            cleanup_files "$state_file"
            echo "Lossless Scaling desinstalado."
        fi
    else
        if confirm "Instalar Lossless Scaling (LSFG-VK)?"; then
            echo "Instalando Lossless Scaling..."
            sudo pacman -S --noconfirm $pkg_lsfg
            touch "$state_file"
            echo "Lossless Scaling instalado."
        fi
    fi
}

lucidglyph_installer() {
    local state_file="$STATE_DIR/lucidglyph"
    local pkg_lucidglyph="lucidglyph"

    if [ -f "$state_file" ] || pacman -Q lucidglyph &>/dev/null; then
        if confirm "Lucidglyph detectado. Desinstalar?"; then
            echo "Desinstalando Lucidglyph..."
            pacman -Qq lucidglyph &>/dev/null && yay -Rsnu --noconfirm $pkg_lucidglyph || true
            cleanup_files "$state_file"
            echo "Lucidglyph desinstalado."
        fi
    else
        if confirm "Instalar Lucidglyph?"; then
            echo "Instalando Lucidglyph..."
            yay -S --noconfirm $pkg_lucidglyph
            touch "$state_file"
            echo "Lucidglyph instalado."
        fi
    fi
}

lutris_installer() {
    local state_file="$STATE_DIR/lutris"

    if [ -f "$state_file" ] || flatpak list --app | grep -q net.lutris.Lutris 2>/dev/null; then
        if confirm "Lutris detectado. Desinstalar?"; then
            echo "Desinstalando Lutris..."
            flatpak uninstall --user -y net.lutris.Lutris 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Lutris desinstalado."
        fi
    else
        if confirm "Instalar Lutris?"; then
            echo "Instalando Lutris..."
            flatpak install --or-update --user --noninteractive net.lutris.Lutris
            touch "$state_file"
            echo "Lutris instalado."
        fi
    fi
}

mangojuice_installer() {
    local state_file="$STATE_DIR/mangojuice"
    local pkg_mangohud="mangohud"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.radiolamp.mangojuice 2>/dev/null; then
        if confirm "MangoJuice detectado. Desinstalar?"; then
            echo "Desinstalando MangoJuice..."
            pacman -Qq mangohud &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_mangohud || true
            flatpak uninstall --user -y io.github.radiolamp.mangojuice 2>/dev/null || true
            cleanup_files "$state_file"
            echo "MangoJuice desinstalado."
        fi
    else
        if confirm "Instalar MangoJuice?"; then
            echo "Instalando MangoJuice..."
            sudo pacman -S --noconfirm $pkg_mangohud
            flatpak install --or-update --user --noninteractive flathub com.valvesoftware.Steam.VulkanLayer.MangoHud/x86_64/stable org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
            flatpak install --or-update --user --noninteractive flathub io.github.radiolamp.mangojuice
            touch "$state_file"
            echo "MangoJuice instalado."
        fi
    fi
}

maven_installer() {
    local state_file="$STATE_DIR/maven"
    local pkg_maven="maven"

    if [ -f "$state_file" ] || pacman -Q maven &>/dev/null; then
        if confirm "Maven detectado. Desinstalar?"; then
            echo "Desinstalando Maven..."
            pacman -Qq maven &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_maven || true
            cleanup_files "$state_file"
            echo "Maven desinstalado."
        fi
    else
        if confirm "Instalar Maven?"; then
            echo "Instalando Maven..."
            sudo pacman -S --noconfirm $pkg_maven
            touch "$state_file"
            echo "Maven instalado."
        fi
    fi
}

microsoft_teams_installer() {
    local state_file="$STATE_DIR/microsoft_teams"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.IsmaelMartinez.teams_for_linux 2>/dev/null; then
        if confirm "Microsoft Teams detectado. Desinstalar?"; then
            echo "Desinstalando Microsoft Teams..."
            flatpak uninstall --user -y com.github.IsmaelMartinez.teams_for_linux 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Microsoft Teams desinstalado."
        fi
    else
        if confirm "Instalar Microsoft Teams?"; then
            echo "Instalando Microsoft Teams..."
            flatpak install --or-update --user --noninteractive flathub com.github.IsmaelMartinez.teams_for_linux
            touch "$state_file"
            echo "Microsoft Teams instalado."
        fi
    fi
}

minecraft_bedrock_launcher_installer() {
    local state_file="$STATE_DIR/minecraft_bedrock_launcher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.mrarm.mcpelauncher 2>/dev/null; then
        if confirm "Minecraft Bedrock Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Minecraft Bedrock Launcher..."
            flatpak uninstall --user -y io.mrarm.mcpelauncher 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Minecraft Bedrock Launcher desinstalado."
        fi
    else
        if confirm "Instalar Minecraft Bedrock Launcher?"; then
            echo "Instalando Minecraft Bedrock Launcher..."
            flatpak install --or-update --user --noninteractive flathub io.mrarm.mcpelauncher
            touch "$state_file"
            echo "Minecraft Bedrock Launcher instalado."
        fi
    fi
}

minfreefix_installer() {
    local state_file="$STATE_DIR/minfreefix"
    local sysctl_file="/etc/sysctl.d/99-minfreefix.conf"

    if [ -f "$state_file" ] || [ -f "$sysctl_file" ]; then
        if confirm "MinFreeFix detectado. Desinstalar?"; then
            echo "Desinstalando MinFreeFix..."
            sudo rm -f "$sysctl_file" 2>/dev/null || true
            sudo sysctl --system 2>/dev/null || true
            cleanup_files "$state_file"
            echo "MinFreeFix desinstalado."
        fi
    else
        if confirm "Configurar vm.min_free_kbytes dinâmico?"; then
            echo "Configurando MinFreeFix..."
            local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            local min_free_kbytes=$(( total_kb / 128 ))
            echo "vm.min_free_kbytes = $min_free_kbytes" | sudo tee "$sysctl_file" > /dev/null
            sudo sysctl -p "$sysctl_file"
            touch "$state_file"
            echo "MinFreeFix configurado. vm.min_free_kbytes = $min_free_kbytes"
        fi
    fi
}

mise_installer() {
    local state_file="$STATE_DIR/mise"
    local pkg_mise="mise"

    if [ -f "$state_file" ] || pacman -Q mise &>/dev/null; then
        if confirm "Mise detectado. Desinstalar?"; then
            echo "Desinstalando Mise..."
            pacman -Qq mise &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_mise || true
            cleanup_files "$state_file"
            echo "Mise desinstalado."
        fi
    else
        if confirm "Instalar Mise?"; then
            echo "Instalando Mise..."
            sudo pacman -S --noconfirm $pkg_mise
            touch "$state_file"
            echo "Mise instalado."
        fi
    fi
}

missioncenter_installer() {
    local state_file="$STATE_DIR/missioncenter"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.missioncenter.MissionCenter 2>/dev/null; then
        if confirm "Mission Center detectado. Desinstalar?"; then
            echo "Desinstalando Mission Center..."
            flatpak uninstall --user -y io.missioncenter.MissionCenter 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mission Center desinstalado."
        fi
    else
        if confirm "Instalar Mission Center?"; then
            echo "Instalando Mission Center..."
            flatpak install --or-update --user --noninteractive flathub io.missioncenter.MissionCenter
            touch "$state_file"
            echo "Mission Center instalado."
        fi
    fi
}

modern_unix_installer() {
    local state_file="$STATE_DIR/modern_unix"
    local pkg_unix="tealdeer ripgrep zoxide eza bat fd jq"

    if [ -f "$state_file" ] || pacman -Q tealdeer &>/dev/null; then
        if confirm "Modern Unix Tools detectado. Desinstalar?"; then
            echo "Desinstalando Modern Unix Tools..."
            pacman -Qq tealdeer &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_unix || true
            sed -i '/alias man=tldr/d' "$HOME/.bashrc" 2>/dev/null || true
            sed -i '/alias ls=eza/d' "$HOME/.bashrc" 2>/dev/null || true
            sed -i '/alias cat=bat/d' "$HOME/.bashrc" 2>/dev/null || true
            sed -i '/alias find=fd/d' "$HOME/.bashrc" 2>/dev/null || true
            sed -i '/alias cd=z/d' "$HOME/.bashrc" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Modern Unix Tools desinstalado."
        fi
    else
        if confirm "Instalar Modern Unix Tools?"; then
            echo "Instalando Modern Unix Tools..."
            sudo pacman -S --noconfirm $pkg_unix
            echo -e "\nalias man=tldr\nalias ls=eza\nalias cat=bat\nalias find=fd\nalias cd=z" >> "$HOME/.bashrc"
            touch "$state_file"
            echo "Modern Unix Tools instalado."
        fi
    fi
}

croc_installer() {
    local state_file="$STATE_DIR/croc"
    local pkg_croc="croc"

    if [ -f "$state_file" ] || pacman -Q croc &>/dev/null; then
        if confirm "Croc detectado. Desinstalar?"; then
            echo "Desinstalando Croc..."
            pacman -Qq croc &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_croc || true
            cleanup_files "$state_file"
            echo "Croc desinstalado."
        fi
    else
        if confirm "Instalar Croc?"; then
            echo "Instalando Croc..."
            sudo pacman -S --noconfirm $pkg_croc
            touch "$state_file"
            echo "Croc instalado."
        fi
    fi
}

gdu_installer() {
    local state_file="$STATE_DIR/gdu"
    local pkg_gdu="gdu"

    if [ -f "$state_file" ] || pacman -Q gdu &>/dev/null; then
        if confirm "Gdu detectado. Desinstalar?"; then
            echo "Desinstalando Gdu..."
            pacman -Qq gdu &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gdu || true
            cleanup_files "$state_file"
            echo "Gdu desinstalado."
        fi
    else
        if confirm "Instalar Gdu?"; then
            echo "Instalando Gdu..."
            sudo pacman -S --noconfirm $pkg_gdu
            touch "$state_file"
            echo "Gdu instalado."
        fi
    fi
}

fzf_installer() {
    local state_file="$STATE_DIR/fzf"
    local pkg_fzf="fzf"

    if [ -f "$state_file" ] || pacman -Q fzf &>/dev/null; then
        if confirm "Fzf detectado. Desinstalar?"; then
            echo "Desinstalando Fzf..."
            pacman -Qq fzf &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fzf || true
            cleanup_files "$state_file"
            echo "Fzf desinstalado."
        fi
    else
        if confirm "Instalar Fzf?"; then
            echo "Instalando Fzf..."
            sudo pacman -S --noconfirm $pkg_fzf
            touch "$state_file"
            echo "Fzf instalado."
        fi
    fi
}

moonlight_installer() {
    local state_file="$STATE_DIR/moonlight"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.moonlight_stream.Moonlight 2>/dev/null; then
        if confirm "Moonlight detectado. Desinstalar?"; then
            echo "Desinstalando Moonlight..."
            flatpak uninstall --user -y com.moonlight_stream.Moonlight 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Moonlight desinstalado."
        fi
    else
        if confirm "Instalar Moonlight?"; then
            echo "Instalando Moonlight..."
            flatpak install --or-update --user --noninteractive flathub com.moonlight_stream.Moonlight
            touch "$state_file"
            echo "Moonlight instalado."
        fi
    fi
}

mscorefonts_installer() {
    local state_file="$STATE_DIR/mscorefonts"
    local font_dir="$HOME/.local/share/fonts/mscorefonts"
    local pkg_cabextract="cabextract"

    if [ -f "$state_file" ] || [ -d "$font_dir" ]; then
        if confirm "Microsoft Core Fonts detectado. Desinstalar?"; then
            echo "Desinstalando Microsoft Core Fonts..."
            pacman -Qq cabextract &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cabextract || true
            cleanup_files "$state_file" "$font_dir" "$HOME/*32.exe" "$HOME/fonts"
            fc-cache -f
            echo "Microsoft Core Fonts desinstalado."
        fi
    else
        if confirm "Instalar Microsoft Core Fonts?"; then
            echo "Instalando Microsoft Core Fonts..."
            sudo pacman -S --noconfirm $pkg_cabextract
            local fonts=(
                "http://downloads.sourceforge.net/corefonts/andale32.exe"
                "http://downloads.sourceforge.net/corefonts/arial32.exe"
                "http://downloads.sourceforge.net/corefonts/arialb32.exe"
                "http://downloads.sourceforge.net/corefonts/comic32.exe"
                "http://downloads.sourceforge.net/corefonts/courie32.exe"
                "http://downloads.sourceforge.net/corefonts/georgi32.exe"
                "http://downloads.sourceforge.net/corefonts/impact32.exe"
                "http://downloads.sourceforge.net/corefonts/times32.exe"
                "http://downloads.sourceforge.net/corefonts/trebuc32.exe"
                "http://downloads.sourceforge.net/corefonts/verdan32.exe"
                "http://downloads.sourceforge.net/corefonts/webdin32.exe"
            )
            mkdir -p "$HOME/fonts"
            for font_url in "${fonts[@]}"; do
                curl -s -L "$font_url" -o "$HOME/$(basename "$font_url")"
                cabextract "$HOME/$(basename "$font_url")" -d "$HOME/fonts"
                rm "$HOME/$(basename "$font_url")"
            done
            mkdir -p "$font_dir"
            cp -v "$HOME/fonts"/*.ttf "$HOME/fonts"/*.TTF "$font_dir/"
            rm -rf "$HOME/fonts"
            fc-cache -f
            touch "$state_file"
            echo "Microsoft Core Fonts instalado."
        fi
    fi
}

mullvad_browser_installer() {
    local state_file="$STATE_DIR/mullvad_browser"

    if [ -f "$state_file" ] || flatpak list --app | grep -q net.mullvad.MullvadBrowser 2>/dev/null; then
        if confirm "Mullvad Browser detectado. Desinstalar?"; then
            echo "Desinstalando Mullvad Browser..."
            flatpak uninstall --user -y net.mullvad.MullvadBrowser 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Mullvad Browser desinstalado."
        fi
    else
        if confirm "Instalar Mullvad Browser?"; then
            echo "Instalando Mullvad Browser..."
            flatpak install --or-update --user --noninteractive flathub net.mullvad.MullvadBrowser
            touch "$state_file"
            echo "Mullvad Browser instalado."
        fi
    fi
}

mullvad_vpn_installer() {
    local state_file="$STATE_DIR/mullvad_vpn"
    local pkg_mullvad="mullvad-vpn"

    if [ -f "$state_file" ] || pacman -Q mullvad-vpn &>/dev/null; then
        if confirm "Mullvad VPN detectado. Desinstalar?"; then
            echo "Desinstalando Mullvad VPN..."
            pacman -Qq mullvad-vpn &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_mullvad || true
            cleanup_files "$state_file"
            echo "Mullvad VPN desinstalado."
        fi
    else
        if confirm "Instalar Mullvad VPN?"; then
            echo "Instalando Mullvad VPN..."
            sudo pacman -S --noconfirm $pkg_mullvad
            touch "$state_file"
            echo "Mullvad VPN instalado."
        fi
    fi
}

nerd_fonts_installer() {
    local state_file="$STATE_DIR/nerd"
    local pkg_nerd="nerd-fonts"

    if [ -f "$state_file" ] || pacman -Q ttf-noto-nerd &>/dev/null; then
        if confirm "Nerd Fonts detectado. Desinstalar?"; then
            echo "Desinstalando Nerd Fonts..."
            pacman -Qq ttf-noto-nerd &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nerd || true
            cleanup_files "$state_file"
            echo "Nerd Fonts desinstalado."
        fi
    else
        if confirm "Instalar Nerd Fonts?"; then
            echo "Instalando Nerd Fonts..."
            sudo pacman -S --noconfirm $pkg_nerd
            touch "$state_file"
            echo "Nerd Fonts instalado."
        fi
    fi
}

nordvpn_installer() {
    local state_file="$STATE_DIR/nordvpn"
    local pkg_nordvpn="nordvpn-bin"

    if [ -f "$state_file" ] || pacman -Q nordvpn-bin &>/dev/null; then
        if confirm "NordVPN detectado. Desinstalar?"; then
            echo "Desinstalando NordVPN..."
            pacman -Qq nordvpn-bin &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nordvpn || true
            cleanup_files "$state_file"
            echo "NordVPN desinstalado."
        fi
    else
        if confirm "Instalar NordVPN?"; then
            echo "Instalando NordVPN..."
            sudo pacman -S --noconfirm $pkg_nordvpn
            touch "$state_file"
            echo "NordVPN instalado."
        fi
    fi
}

nvim_installer() {
    local state_file="$STATE_DIR/nvim"
    local pkg_neovim="neovim"

    if [ -f "$state_file" ] || pacman -Q neovim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            pacman -Qq neovim &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_neovim || true
            cleanup_files "$state_file"
            echo "NeoVim desinstalado."
        fi
    else
        if confirm "Instalar NeoVim ?"; then
            echo "Instalando NeoVim..."
            sudo pacman -S --noconfirm $pkg_neovim
            touch "$state_file"
            echo "NeoVim instalado."
        fi
    fi
}

nvim_menu() {
    while true; do
        clear
        echo "=== NeoVim ==="
        echo "1) NeoVim"
        echo "2) Lazyman"
        echo "3) LazyVim"
        echo "4) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; nvim_installer ;;
            2) clear; nvim_lazyman_installer ;;
            3) clear; nvim_lazyvim_installer ;;
            4) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 3 ] && read -p "Pressione Enter para continuar..."
    done
}

nvim_lazyman_installer() {
    local state_file="$STATE_DIR/nvim_lazyman"
    local lazyman_dir="$HOME/.config/nvim-Lazyman"

    if [ -f "$state_file" ] || [ -d "$lazyman_dir" ]; then
        if confirm "Lazyman detectado. Desinstalar?"; then
            echo "Desinstalando Lazyman..."
            cleanup_files "$state_file" "$lazyman_dir"
            echo "Lazyman desinstalado."
        fi
    else
        if confirm "Instalar Lazyman?"; then
            echo "Instalando Lazyman..."
            cleanup_files "$lazyman_dir"
            git clone https://github.com/doctorfree/nvim-lazyman "$lazyman_dir"
            "$lazyman_dir"/lazyman.sh
            touch "$state_file"
            echo "Lazyman instalado."
        fi
    fi
}

nvim_lazyvim_installer() {
    local state_file="$STATE_DIR/nvim_lazyvim"
    local nvim_dir="$HOME/.config/nvim"

    if [ -f "$state_file" ] || [ -d "$nvim_dir" ]; then
        if confirm "LazyVim detectado. Desinstalar?"; then
            echo "Desinstalando LazyVim..."
            cleanup_files "$state_file" "$nvim_dir"
            echo "LazyVim desinstalado."
        fi
    else
        if confirm "Instalar LazyVim?"; then
            echo "Instalando LazyVim..."
            cleanup_files "$nvim_dir"
            git clone https://github.com/LazyVim/starter "$nvim_dir"
            rm -rf "$nvim_dir/.git"
            touch "$state_file"
            echo "LazyVim instalado."
        fi
    fi
}

nvidia_open_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_open"
    local pkg_nvidia="nvidia-open-dkms nvidia-utils nvidia-settings"

    if [ -f "$state_file" ] || pacman -Q nvidia-open-dkms &>/dev/null; then
        if confirm "Nvidia Open Modules com DKMS detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Open Modules com DKMS..."
            pacman -Qq nvidia-open-dkms &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nvidia || true
            cleanup_files "$state_file"
            echo "Nvidia Open Modules desinstalado."
        fi
    else
        echo "Instalando Nvidia Open Modules com DKMS..."
        sudo pacman -S --noconfirm $pkg_nvidia
        sudo mkinitcpio -P
        touch "$state_file"
        echo "Nvidia Open Modules instalado. Reinicie para aplicar."
    fi
}

nvidia_open_no_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_open"
    local pkg_nvidia="nvidia-open nvidia-utils nvidia-settings"

    if [ -f "$state_file" ] || pacman -Q nvidia-open &>/dev/null; then
        if confirm "Nvidia Open Modules sem DKMS detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Open Modules sem DKMS..."
            pacman -Qq nvidia-open &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nvidia || true
            cleanup_files "$state_file"
            echo "Nvidia Open Modules desinstalado."
        fi
    else
        echo "Instalando Nvidia Open Modules sem DKMS..."
        sudo pacman -S --noconfirm $pkg_nvidia
        sudo mkinitcpio -P
        touch "$state_file"
        echo "Nvidia Open Modules instalado. Reinicie para aplicar."
    fi
}

nvidia_open_menu() {
    while true; do
        clear
        echo "=== Nvidia Open Modules ==="
        echo "1) Instalar com DKMS (recomendado)"
        echo "2) Instalar sem DKMS"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; nvidia_open_dkms_installer ;;
            2) clear; nvidia_open_no_dkms_installer ;;
            3) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

nvidia_proprietary_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"
    local pkg_nvidia="nvidia-dkms nvidia-utils nvidia-settings"

    if [ -f "$state_file" ] || pacman -Q nvidia-dkms &>/dev/null; then
        if confirm "Nvidia Proprietário com DKMS detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário com DKMS..."
            pacman -Qq nvidia-dkms &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nvidia || true
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        echo "Instalando Nvidia Proprietário com DKMS..."
        sudo pacman -S --noconfirm $pkg_nvidia
        sudo mkinitcpio -P
        touch "$state_file"
        echo "Nvidia Proprietário instalado. Reinicie para aplicar."
    fi
}

nvidia_proprietary_no_dkms_installer() {
    local state_file="$STATE_DIR/nvidia_proprietary"
    local pkg_nvidia="nvidia nvidia-utils nvidia-settings"

    if [ -f "$state_file" ] || pacman -Q nvidia &>/dev/null; then
        if confirm "Nvidia Proprietário sem DKMS detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Proprietário sem DKMS..."
            pacman -Qq nvidia &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nvidia || true
            cleanup_files "$state_file"
            echo "Nvidia Proprietário desinstalado."
        fi
    else
        echo "Instalando Nvidia Proprietário sem DKMS..."
        sudo pacman -S --noconfirm $pkg_nvidia
        sudo mkinitcpio -P
        touch "$state_file"
        echo "Nvidia Proprietário instalado. Reinicie para aplicar."
    fi
}

nvidia_proprietary_menu() {
    while true; do
        clear
        echo "=== Nvidia Proprietário ==="
        echo "1) Instalar com DKMS (recomendado)"
        echo "2) Instalar sem DKMS"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; nvidia_proprietary_dkms_installer ;;
            2) clear; nvidia_proprietary_no_dkms_installer ;;
            3) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

nvidia_v470_installer() {
    local state_file="$STATE_DIR/nvidia_v470"
    local pkg_nvidia="nvidia-470xx-dkms nvidia-470xx-utils nvidia-470xx-settings"

    if [ -f "$state_file" ] || pacman -Q nvidia-470xx-dkms &>/dev/null; then
        if confirm "Nvidia Drivers v470 detectado. Desinstalar?"; then
            echo "Desinstalando Nvidia Drivers v470..."
            pacman -Qq nvidia-470xx-dkms &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nvidia || true
            sudo rm -f /etc/modprobe.d/10-nvidia.conf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Nvidia Drivers v470 desinstalado."
        fi
    else
        echo "Instalando Nvidia Drivers v470..."
        sudo pacman -S --noconfirm $pkg_nvidia
        curl -s https://raw.githubusercontent.com/psygreg/linuxtoys/master/resources/10-nvidia.conf | sudo tee /etc/modprobe.d/10-nvidia.conf > /dev/null
        sudo mkinitcpio -P
        touch "$state_file"
        echo "Nvidia Drivers v470 instalado. Reinicie para aplicar."
    fi
}

nvm_installer() {
    local state_file="$STATE_DIR/nvm"
    local pkg_nvm="nvm"

    if [ -f "$state_file" ] || pacman -Q nvm &>/dev/null; then
        if confirm "NVM detectado. Desinstalar?"; then
            echo "Desinstalando NVM..."
            pacman -Qq nvm &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_nvm || true
            cleanup_files "$state_file" "$HOME/.nvm"
            echo "NVM desinstalado."
        fi
    else
        if confirm "Instalar NVM (Node Version Manager)?"; then
            echo "Instalando NVM..."
            sudo pacman -S --noconfirm $pkg_nvm
            touch "$state_file"
            echo "NVM instalado."
        fi
    fi
}

obs_installer() {
    local state_file="$STATE_DIR/obs"

    if [ -f "$state_file" ] || flatpak list --app --columns=application | grep -q "com.obsproject.Studio"; then
        if confirm "OBS Studio detectado. Desinstalar?"; then
            echo "Desinstalando OBS Studio..."
            flatpak remove --user -y --noninteractive com.obsproject.Studio 2>/dev/null || true
            cleanup_files "$state_file" "$HOME/.var/app/com.obsproject.Studio"
            echo "OBS Studio desinstalado."
        fi
    else
        if confirm "Instalar OBS Studio?"; then
            echo "Instalando OBS Studio..."
            flatpak install --user -y --noninteractive flathub com.obsproject.Studio
            
            local ver=$(curl -s "https://api.github.com/repos/dimtpap/obs-pipewire-audio-capture/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')
            mkdir -p /tmp/obspipe && cd /tmp/obspipe
            curl -fsSL "https://github.com/dimtpap/obs-pipewire-audio-capture/releases/download/${ver}/linux-pipewire-audio-${ver}-flatpak-30.tar.gz" -o linux-pipewire-audio.tar.gz
            tar -xvzf linux-pipewire-audio.tar.gz
            mkdir -p "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio"
            cp -rf linux-pipewire-audio/* "$HOME/.var/app/com.obsproject.Studio/config/obs-studio/plugins/linux-pipewire-audio/"
            
            flatpak override --user --filesystem=xdg-run/pipewire-0 com.obsproject.Studio
            flatpak override --user --socket=x11 --nosocket=wayland --env=QT_QPA_PLATFORM=xcb com.obsproject.Studio
            
            cd .. && rm -rf /tmp/obspipe
            touch "$state_file"
            echo "OBS Studio instalado."
        fi
    fi
}

obsidian_installer() {
    local state_file="$STATE_DIR/obsidian"

    if [ -f "$state_file" ] || flatpak list --app | grep -q md.obsidian.Obsidian 2>/dev/null; then
        if confirm "Obsidian detectado. Desinstalar?"; then
            echo "Desinstalando Obsidian..."
            flatpak uninstall --user -y md.obsidian.Obsidian 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Obsidian desinstalado."
        fi
    else
        if confirm "Instalar Obsidian?"; then
            echo "Instalando Obsidian..."
            flatpak install --or-update --user --noninteractive flathub md.obsidian.Obsidian
            touch "$state_file"
            echo "Obsidian instalado."
        fi
    fi
}

office_menu() {
    while true; do
        clear
        echo "=== Office ==="
        echo "1) AnyDesk"
        echo "2) Audacity"
        echo "3) Blender"
        echo "4) Google Chrome"
        echo "5) Cohesion"
        echo "6) Darktable"
        echo "7) DaVinci Resolve"
        echo "8) Figma"
        echo "9) Foliate"
        echo "10) FreeCAD"
        echo "11) GIMP"
        echo "12) Inkscape"
        echo "13) Kdenlive"
        echo "14) KiCad"
        echo "15) Krita"
        echo "16) LibreOffice"
        echo "17) Obsidian"
        echo "18) OnlyOffice"
        echo "19) Pinta"
        echo "20) Zen Browser"
        echo "21) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; anydesk_installer ;;
            2) clear; audacity_installer ;;
            3) clear; blender_installer ;;
            4) clear; chrome_installer ;;
            5) clear; cohesion_installer ;;
            6) clear; darktable_installer ;;
            7) clear; davinci_resolve_menu ;;
            8) clear; figma_installer ;;
            9) clear; foliate_installer ;;
            10) clear; freecad_installer ;;
            11) clear; gimp_menu ;;
            12) clear; inkscape_installer ;;
            13) clear; kdenlive_installer ;;
            14) clear; kicad_installer ;;
            15) clear; krita_installer ;;
            16) clear; libreoffice_installer ;;
            17) clear; obsidian_installer ;;
            18) clear; onlyoffice_installer ;;
            19) clear; pinta_installer ;;
            20) clear; zen_browser_installer ;;
            21) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 20 ] && read -p "Pressione Enter para continuar..."
    done
}

oh_my_bash_installer() {
    local state_file="$STATE_DIR/oh_my_bash"
    local osh_dir="$HOME/.oh-my-bash"

    if [ -f "$state_file" ] || [ -d "$osh_dir" ]; then
        if confirm "Oh My Bash detectado. Desinstalar?"; then
            echo "Desinstalando Oh My Bash..."
            [ -d "$osh_dir" ] && yes | "$osh_dir"/tools/uninstall.sh 2>/dev/null || true
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

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.onlyoffice.desktopeditors 2>/dev/null; then
        if confirm "OnlyOffice detectado. Desinstalar?"; then
            echo "Desinstalando OnlyOffice..."
            flatpak uninstall --user -y org.onlyoffice.desktopeditors 2>/dev/null || true
            cleanup_files "$state_file"
            echo "OnlyOffice desinstalado."
        fi
    else
        if confirm "Instalar OnlyOffice?"; then
            echo "Instalando OnlyOffice..."
            flatpak install --or-update --user --noninteractive flathub org.onlyoffice.desktopeditors
            touch "$state_file"
            echo "OnlyOffice instalado."
        fi
    fi
}

openlinkhub_installer() {
    local state_file="$STATE_DIR/openlinkhub"
    local pkg_openlink="openlinkhub"

    if [ -f "$state_file" ] || pacman -Q openlinkhub &>/dev/null; then
        if confirm "OpenLinkHub detectado. Desinstalar?"; then
            echo "Desinstalando OpenLinkHub..."
            pacman -Qq openlinkhub &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_openlink || true
            sudo systemctl stop OpenLinkHub.service 2>/dev/null || true
            sudo systemctl disable OpenLinkHub.service 2>/dev/null || true
            cleanup_files "$state_file"
            echo "OpenLinkHub desinstalado."
        fi
    else
        if confirm "Instalar OpenLinkHub?"; then
            echo "Instalando OpenLinkHub..."
            sudo pacman -S --noconfirm $pkg_openlink
            sudo systemctl enable --now OpenLinkHub.service
            touch "$state_file"
            echo "OpenLinkHub instalado."
        fi
    fi
}

openrgb_installer() {
    local state_file="$STATE_DIR/openrgb"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.openrgb.OpenRGB 2>/dev/null; then
        if confirm "OpenRGB detectado. Desinstalar?"; then
            echo "Desinstalando OpenRGB..."
            flatpak uninstall --user -y org.openrgb.OpenRGB 2>/dev/null || true
            cleanup_files "$state_file"
            echo "OpenRGB desinstalado."
        fi
    else
        if confirm "Instalar OpenRGB?"; then
            echo "Instalando OpenRGB..."
            flatpak install --or-update --user --noninteractive flathub org.openrgb.OpenRGB
            touch "$state_file"
            echo "OpenRGB instalado."
        fi
    fi
}

openrazer_installer() {
    local state_file="$STATE_DIR/openrazer"
    local pkg_openrazer="polychromatic"

    if [ -f "$state_file" ] || pacman -Q polychromatic &>/dev/null; then
        if confirm "OpenRazer detectado. Desinstalar?"; then
            echo "Desinstalando OpenRazer..."
            pacman -Qq polychromatic &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_openrazer || true
            cleanup_files "$state_file"
            echo "OpenRazer desinstalado."
        fi
    else
        if confirm "Instalar OpenRazer?"; then
            echo "Instalando OpenRazer..."
            sudo pacman -S --noconfirm $pkg_openrazer
            sudo gpasswd -a $USER plugdev
            touch "$state_file"
            echo "OpenRazer instalado."
        fi
    fi
}

optimusui_installer() {
    local state_file="$STATE_DIR/optimusui"

    if [ -f "$state_file" ] || flatpak list --app | grep -q de.z_ray.OptimusUI 2>/dev/null; then
        if confirm "OptimusUI detectado. Desinstalar?"; then
            echo "Desinstalando OptimusUI..."
            flatpak uninstall --user -y de.z_ray.OptimusUI 2>/dev/null || true
            cleanup_files "$state_file"
            echo "OptimusUI desinstalado."
        fi
    else
        if confirm "Instalar OptimusUI?"; then
            echo "Instalando OptimusUI..."
            flatpak install --or-update --user --noninteractive flathub de.z_ray.OptimusUI
            touch "$state_file"
            echo "OptimusUI instalado."
        fi
    fi
}

osu_installer() {
    local state_file="$STATE_DIR/osu"

    if [ -f "$state_file" ] || flatpak list --app | grep -q sh.ppy.osu 2>/dev/null; then
        if confirm "Osu! detectado. Desinstalar?"; then
            echo "Desinstalando Osu!..."
            flatpak uninstall --user -y sh.ppy.osu 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Osu! desinstalado."
        fi
    else
        if confirm "Instalar Osu!?"; then
            echo "Instalando Osu!..."
            flatpak install --or-update --user --noninteractive flathub sh.ppy.osu
            touch "$state_file"
            echo "Osu! instalado."
        fi
    fi
}

oversteer_installer() {
    local state_file="$STATE_DIR/oversteer"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.berarma.Oversteer 2>/dev/null; then
        if confirm "Oversteer detectado. Desinstalar?"; then
            echo "Desinstalando Oversteer..."
            flatpak uninstall --user -y io.github.berarma.Oversteer 2>/dev/null || true
            sudo rm -f /etc/udev/rules.d/99-fanatec-wheel-perms.rules /etc/udev/rules.d/99-logitech-wheel-perms.rules /etc/udev/rules.d/99-thrustmaster-wheel-perms.rules 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Oversteer desinstalado."
        fi
    else
        if confirm "Instalar Oversteer?"; then
            echo "Instalando Oversteer..."
            flatpak install --or-update --user --noninteractive flathub io.github.berarma.Oversteer
            sudo curl -s https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-fanatec-wheel-perms.rules -o /etc/udev/rules.d/99-fanatec-wheel-perms.rules
            sudo curl -s https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-logitech-wheel-perms.rules -o /etc/udev/rules.d/99-logitech-wheel-perms.rules
            sudo curl -s https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-thrustmaster-wheel-perms.rules -o /etc/udev/rules.d/99-thrustmaster-wheel-perms.rules
            touch "$state_file"
            echo "Oversteer instalado."
        fi
    fi
}

paru_installer() {
    local state_file="$STATE_DIR/paru"
    local pkg_paru="paru"

    if [ -f "$state_file" ] || pacman -Q paru &>/dev/null; then
        if confirm "Paru detectado. Desinstalar?"; then
            echo "Desinstalando Paru..."
            pacman -Qq paru &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_paru || true
            cleanup_files "$state_file"
            echo "Paru desinstalado."
        fi
    else
        if confirm "Instalar Paru (AUR helper)?"; then
            echo "Instalando Paru..."
            sudo pacman -S --noconfirm $pkg_paru
            touch "$state_file"
            echo "Paru instalado."
        fi
    fi
}

peazip_installer() {
    local state_file="$STATE_DIR/peazip"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.peazip.PeaZip 2>/dev/null; then
        if confirm "PeaZip detectado. Desinstalar?"; then
            echo "Desinstalando PeaZip..."
            flatpak uninstall --user -y io.github.peazip.PeaZip 2>/dev/null || true
            cleanup_files "$state_file"
            echo "PeaZip desinstalado."
        fi
    else
        if confirm "Instalar PeaZip?"; then
            echo "Instalando PeaZip..."
            flatpak install --or-update --user --noninteractive flathub io.github.peazip.PeaZip
            touch "$state_file"
            echo "PeaZip instalado."
        fi
    fi
}

perifericos_menu() {
    while true; do
        clear
        echo "=== Periféricos ==="
        echo "1) Input Remapper"
        echo "2) OpenLinkHub"
        echo "3) OpenRazer"
        echo "4) OpenRGB"
        echo "5) Oversteer"
        echo "6) Piper"
        echo "7) Solaar"
        echo "8) StreamController"
        echo "9) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; input_remapper_installer ;;
            2) clear; openlinkhub_installer ;;
            3) clear; openrazer_installer ;;
            4) clear; openrgb_installer ;;
            5) clear; oversteer_installer ;;
            6) clear; piper_installer ;;
            7) clear; solaar_installer ;;
            8) clear; streamcontroller_installer ;;
            9) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 8 ] && read -p "Pressione Enter para continuar..."
    done
}

pessoal_menu() {
    while true; do
        clear
        echo "=== Pessoal ==="
        echo "1) Pacotes Base"
        echo "2) Pacotes de Mídia"
        echo "3) Ambientes Desktop"
        echo "4) Ferramentas"
        echo "5) Fjord Launcher"
        echo "6) Gnome Boxes"
        echo "7) Hydra Launcher"
        echo "8) CachyOS Kernel"
        echo "9) Stirling PDF"
        echo "10) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; pessoal_base_installer ;;
            2) clear; pessoal_media_installer ;;
            3) clear; de_installer ;;
            4) clear; ferramentas_menu ;;
            5) clear; unmojang_installer ;;
            6) clear; gnome_boxes_installer ;;
            7) clear; hydra_launcher_installer ;;
            8) clear; cachyos_installer ;;
            9) clear; stirlingpdf_menu ;;
            10) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 9 ] && read -p "Pressione Enter para continuar..."
    done
}

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono"

    if [ -f "$state_file" ]; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            pacman -Qq noto-fonts &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_base || true
            cleanup_files "$state_file"
            echo "Pacotes Base desinstalados."
        fi
    else
        if confirm "Instalar Pacotes Base?"; then
            echo "Instalando Pacotes Base..."
            sudo pacman -S --noconfirm $pkg_base
            touch "$state_file"
            echo "Pacotes Base instalados."
        fi
    fi
}

pessoal_media_installer() {
    local state_file="$STATE_DIR/pessoal_media"
    local pkg_media="ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer"

    if [ -f "$state_file" ]; then
        if confirm "Pacotes de Mídia detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Mídia..."
            pacman -Qq ffmpeg &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_media || true
            cleanup_files "$state_file"
            echo "Pacotes de Mídia desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Mídia?"; then
            echo "Instalando Pacotes de Mídia..."
            sudo pacman -S --noconfirm $pkg_media
            touch "$state_file"
            echo "Pacotes de Mídia instalados."
        fi
    fi
}

pika_backup_installer() {
    local state_file="$STATE_DIR/pika_backup"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.gnome.World.PikaBackup 2>/dev/null; then
        if confirm "Pika Backup detectado. Desinstalar?"; then
            echo "Desinstalando Pika Backup..."
            flatpak uninstall --user -y org.gnome.World.PikaBackup 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pika Backup desinstalado."
        fi
    else
        if confirm "Instalar Pika Backup?"; then
            echo "Instalando Pika Backup..."
            flatpak install --or-update --user --noninteractive flathub org.gnome.World.PikaBackup
            touch "$state_file"
            echo "Pika Backup instalado."
        fi
    fi
}

pinta_installer() {
    local state_file="$STATE_DIR/pinta"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.PintaProject.Pinta 2>/dev/null; then
        if confirm "Pinta detectado. Desinstalar?"; then
            echo "Desinstalando Pinta..."
            flatpak uninstall --user -y com.github.PintaProject.Pinta 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Pinta desinstalado."
        fi
    else
        if confirm "Instalar Pinta?"; then
            echo "Instalando Pinta..."
            flatpak install --or-update --user --noninteractive flathub com.github.PintaProject.Pinta
            touch "$state_file"
            echo "Pinta instalado."
        fi
    fi
}

piper_installer() {
    local state_file="$STATE_DIR/piper"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.freedesktop.Piper 2>/dev/null; then
        if confirm "Piper detectado. Desinstalar?"; then
            echo "Desinstalando Piper..."
            flatpak uninstall --user -y org.freedesktop.Piper 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Piper desinstalado."
        fi
    else
        if confirm "Instalar Piper?"; then
            echo "Instalando Piper..."
            flatpak install --or-update --user --noninteractive flathub org.freedesktop.Piper
            touch "$state_file"
            echo "Piper instalado."
        fi
    fi
}

pip_installer() {
    local state_file="$STATE_DIR/pip"
    local pkg_pip="python-pip"

    if [ -f "$state_file" ] || pacman -Q python-pip &>/dev/null; then
        if confirm "Pip detectado. Desinstalar?"; then
            echo "Desinstalando Pip..."
            pacman -Qq python-pip &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_pip || true
            cleanup_files "$state_file"
            echo "Pip desinstalado."
        fi
    else
        if confirm "Instalar Pip?"; then
            echo "Instalando Pip..."
            sudo pacman -S --noconfirm $pkg_pip
            touch "$state_file"
            echo "Pip instalado."
        fi
    fi
}

pnpm_installer() {
    local state_file="$STATE_DIR/pnpm"
    local pkg_pnpm="pnpm"

    if [ -f "$state_file" ] || pacman -Q pnpm &>/dev/null; then
        if confirm "PNPM detectado. Desinstalar?"; then
            echo "Desinstalando PNPM..."
            pacman -Qq pnpm &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_pnpm || true
            cleanup_files "$state_file"
            echo "PNPM desinstalado."
        fi
    else
        if confirm "Instalar PNPM?"; then
            echo "Instalando PNPM..."
            sudo pacman -S --noconfirm $pkg_pnpm
            touch "$state_file"
            echo "PNPM instalado."
        fi
    fi
}

podman_installer() {
    local state_file="$STATE_DIR/podman"
    local pkg_podman="podman podman-compose"

    if [ -f "$state_file" ] || pacman -Q podman &>/dev/null; then
        if confirm "Podman detectado. Desinstalar?"; then
            echo "Desinstalando Podman..."
            pacman -Qq podman &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_podman || true
            cleanup_files "$state_file"
            echo "Podman desinstalado."
        fi
    else
        if confirm "Instalar Podman?"; then
            echo "Instalando Podman..."
            sudo pacman -S --noconfirm $pkg_podman
            touch "$state_file"
            echo "Podman instalado."
        fi
    fi
}

portainer_installer() {
    local state_file="$STATE_DIR/portainer"

    if [ -f "$state_file" ] || docker ps -a | grep -q portainer 2>/dev/null; then
        if confirm "Portainer detectado. Desinstalar?"; then
            echo "Desinstalando Portainer..."
            docker stop portainer 2>/dev/null || true
            docker rm portainer 2>/dev/null || true
            docker volume rm portainer_data 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Portainer desinstalado."
        fi
    else
        if confirm "Instalar Portainer CE?"; then
            echo "Instalando Portainer CE..."
            docker volume create portainer_data
            docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
            touch "$state_file"
            echo "Portainer instalado. Acesse: https://localhost:9443"
        fi
    fi
}

postman_installer() {
    local state_file="$STATE_DIR/postman"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.getpostman.Postman 2>/dev/null; then
        if confirm "Postman detectado. Desinstalar?"; then
            echo "Desinstalando Postman..."
            flatpak uninstall --user -y com.getpostman.Postman 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Postman desinstalado."
        fi
    else
        if confirm "Instalar Postman?"; then
            echo "Instalando Postman..."
            flatpak install --user --or-update --noninteractive flathub com.getpostman.Postman
            touch "$state_file"
            echo "Postman instalado."
        fi
    fi
}

preload_installer() {
    local state_file="$STATE_DIR/preload"
    local pkg_preload="preload"

    if [ -f "$state_file" ] || pacman -Q preload &>/dev/null; then
        if confirm "Preload detectado. Desinstalar?"; then
            echo "Desinstalando Preload..."
            sudo systemctl stop preload 2>/dev/null || true
            sudo systemctl disable preload 2>/dev/null || true
            pacman -Qq preload &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_preload || true
            cleanup_files "$state_file"
            echo "Preload desinstalado."
        fi
    else
        local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local total_gb=$(( total_kb / 1024 / 1024 ))
        [ $total_gb -gt 12 ] || { echo "RAM insuficiente para Preload (requer > 12GB)."; return; }
        if confirm "Instalar Preload (otimização de RAM > 12GB)?"; then
            echo "Instalando Preload..."
            sudo pacman -S --noconfirm $pkg_preload
            sudo systemctl enable --now preload
            touch "$state_file"
            echo "Preload instalado."
        fi
    fi
}

prism_launcher_installer() {
    local state_file="$STATE_DIR/prism_launcher"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.prismlauncher.PrismLauncher 2>/dev/null; then
        if confirm "Prism Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Prism Launcher..."
            flatpak uninstall --user -y org.prismlauncher.PrismLauncher 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Prism Launcher desinstalado."
        fi
    else
        if confirm "Instalar Prism Launcher?"; then
            echo "Instalando Prism Launcher..."
            flatpak install --or-update --user --noninteractive flathub org.prismlauncher.PrismLauncher
            touch "$state_file"
            echo "Prism Launcher instalado."
        fi
    fi
}

privacidade_menu() {
    while true; do
        clear
        echo "=== Privacidade ==="
        echo "1) Bitwarden"
        echo "2) Brave Browser"
        echo "3) Cryptomator"
        echo "4) ExpressVPN"
        echo "5) KeePassXC"
        echo "6) LibreWolf"
        echo "7) LogSEQ"
        echo "8) Mullvad Browser"
        echo "9) Mullvad VPN"
        echo "10) NordVPN"
        echo "11) ProtonVPN"
        echo "12) SiriKali"
        echo "13) Surfshark VPN"
        echo "14) Ungoogled Chromium"
        echo "15) Windscribe VPN"
        echo "16) WireGuard"
        echo "17) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; bitwarden_installer ;;
            2) clear; brave_browser_installer ;;
            3) clear; cryptomator_installer ;;
            4) clear; expressvpn_installer ;;
            5) clear; keepassxc_installer ;;
            6) clear; librewolf_installer ;;
            7) clear; logseq_installer ;;
            8) clear; mullvad_browser_installer ;;
            9) clear; mullvad_vpn_installer ;;
            10) clear; nordvpn_installer ;;
            11) clear; protonvpn_installer ;;
            12) clear; sirikali_installer ;;
            13) clear; surfsharkvpn_installer ;;
            14) clear; ungoogled_chromium_installer ;;
            15) clear; windscribevpn_installer ;;
            16) clear; wireguard_installer ;;
            17) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 16 ] && read -p "Pressione Enter para continuar..."
    done
}

protonplus_installer() {
    local state_file="$STATE_DIR/protonplus"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.vysp3r.ProtonPlus 2>/dev/null; then
        if confirm "ProtonPlus detectado. Desinstalar?"; then
            echo "Desinstalando ProtonPlus..."
            flatpak uninstall --user -y com.vysp3r.ProtonPlus 2>/dev/null || true
            cleanup_files "$state_file"
            echo "ProtonPlus desinstalado."
        fi
    else
        if confirm "Instalar ProtonPlus?"; then
            echo "Instalando ProtonPlus..."
            flatpak install --or-update --user --noninteractive flathub com.vysp3r.ProtonPlus
            touch "$state_file"
            echo "ProtonPlus instalado."
        fi
    fi
}

protonvpn_installer() {
    local state_file="$STATE_DIR/protonvpn"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.protonvpn.www 2>/dev/null; then
        if confirm "ProtonVPN detectado. Desinstalar?"; then
            echo "Desinstalando ProtonVPN..."
            flatpak uninstall --user -y com.protonvpn.www 2>/dev/null || true
            cleanup_files "$state_file"
            echo "ProtonVPN desinstalado."
        fi
    else
        if confirm "Instalar ProtonVPN?"; then
            echo "Instalando ProtonVPN..."
            flatpak install --or-update --user --noninteractive flathub com.protonvpn.www
            touch "$state_file"
            echo "ProtonVPN instalado."
        fi
    fi
}

protontricks_installer() {
    local state_file="$STATE_DIR/protontricks"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.Matoking.protontricks 2>/dev/null; then
        if confirm "Protontricks detectado. Desinstalar?"; then
            echo "Desinstalando Protontricks..."
            flatpak uninstall --user -y com.github.Matoking.protontricks 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Protontricks desinstalado."
        fi
    else
        if confirm "Instalar Protontricks?"; then
            echo "Instalando Protontricks..."
            flatpak install --or-update --user --noninteractive flathub com.github.Matoking.protontricks
            touch "$state_file"
            echo "Protontricks instalado."
        fi
    fi
}

protonup_installer() {
    local state_file="$STATE_DIR/protonup"

    if [ -f "$state_file" ] || flatpak list --app | grep -q net.davidotek.pupgui2 2>/dev/null; then
        if confirm "ProtonUp detectado. Desinstalar?"; then
            echo "Desinstalando ProtonUp..."
            flatpak uninstall --user -y net.davidotek.pupgui2 2>/dev/null || true
            cleanup_files "$state_file"
            echo "ProtonUp desinstalado."
        fi
    else
        if confirm "Instalar ProtonUp?"; then
            echo "Instalando ProtonUp..."
            flatpak install --or-update --user --noninteractive flathub net.davidotek.pupgui2
            touch "$state_file"
            echo "ProtonUp instalado."
        fi
    fi
}

psaver_installer() {
    local state_file="$STATE_DIR/psaver"

    if [ -f "$state_file" ] || [ -f "/etc/systemd/system/powersave.service" ]; then
        if confirm "Powersave detectado. Desinstalar?"; then
            echo "Desinstalando Powersave..."
            sudo systemctl stop powersave.service 2>/dev/null || true
            sudo systemctl disable powersave.service 2>/dev/null || true
            sudo rm -f /etc/systemd/system/powersave.service /usr/local/bin/powersave.sh 2>/dev/null || true
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
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/powersave.service >/dev/null
            sudo systemctl enable powersave.service
            sudo systemctl start powersave.service
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

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.rncbc.qpwgraph 2>/dev/null; then
        if confirm "QPWGraph detectado. Desinstalar?"; then
            echo "Desinstalando QPWGraph..."
            flatpak uninstall --user -y org.rncbc.qpwgraph 2>/dev/null || true
            cleanup_files "$state_file"
            echo "QPWGraph desinstalado."
        fi
    else
        if confirm "Instalar QPWGraph?"; then
            echo "Instalando QPWGraph..."
            flatpak install --or-update --user --noninteractive flathub org.rncbc.qpwgraph
            touch "$state_file"
            echo "QPWGraph instalado."
        fi
    fi
}

pyenv_installer() {
    local state_file="$STATE_DIR/pyenv"
    local pkg_pyenv="pyenv"

    if [ -f "$state_file" ] || pacman -Q pyenv &>/dev/null; then
        if confirm "PyEnv detectado. Desinstalar?"; then
            echo "Desinstalando PyEnv..."
            pacman -Qq pyenv &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_pyenv || true
            cleanup_files "$state_file" "$HOME/.pyenv"
            echo "PyEnv desinstalado."
        fi
    else
        if confirm "Instalar PyEnv?"; then
            echo "Instalando PyEnv..."
            sudo pacman -S --noconfirm $pkg_pyenv
            touch "$state_file"
            echo "PyEnv instalado."
        fi
    fi
}

rcloneui_installer() {
    local state_file="$STATE_DIR/rcloneui"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.rcloneui.RcloneUI 2>/dev/null; then
        if confirm "Rclone UI detectado. Desinstalar?"; then
            echo "Desinstalando Rclone UI..."
            flatpak uninstall --user -y com.rcloneui.RcloneUI 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Rclone UI desinstalado."
        fi
    else
        if confirm "Instalar Rclone UI?"; then
            echo "Instalando Rclone UI..."
            flatpak install --or-update --user --noninteractive flathub com.rcloneui.RcloneUI
            touch "$state_file"
            echo "Rclone UI instalado."
        fi
    fi
}

realtek_8821ce_installer() {
    local state_file="$STATE_DIR/rtl8821ce"
    local pkg_rtl8821ce="rtl8821ce-dkms-git"

    if [ -f "$state_file" ] || [ -d "/usr/src/rtl8821ce" ]; then
        if confirm "Driver Realtek 8821CE detectado. Desinstalar?"; then
            echo "Desinstalando..."
            pacman -Qq rtl8821ce-dkms-git &>/dev/null && yay -Rsnu --noconfirm $pkg_rtl8821ce || true
            cleanup_files "$state_file"
            echo "Driver removido."
        fi
    else
        if confirm "Instalar driver Realtek 8821CE?"; then
            echo "Instalando..."
            yay -S --noconfirm $pkg_rtl8821ce
            touch "$state_file"
            echo "Driver instalado. Reinicie o sistema."
        fi
    fi
}

repositorios_menu() {
    while true; do
        clear
        echo "=== Repositórios ==="
        echo "1) AppImage FUSE"
        echo "2) Cargo (Rustup)"
        echo "3) Chaotic AUR"
        echo "4) Flatpak"
        echo "5) Fwupd"
        echo "6) Homebrew"
        echo "7) Paru"
        echo "8) Pip"
        echo "9) Yay"
        echo "10) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; appimage_fuse_installer ;;
            2) clear; cargo_installer ;;
            3) clear; chaotic_aur_installer ;;
            4) clear; flatpak_installer ;;
            5) clear; fwupd_installer ;;
            6) clear; homebrew_installer ;;
            7) clear; paru_installer ;;
            8) clear; pip_installer ;;
            9) clear; yay_installer ;;
            10) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 9 ] && read -p "Pressione Enter para continuar..."
    done
}

s3drive_installer() {
    local state_file="$STATE_DIR/s3drive"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.kapsa.drive 2>/dev/null; then
        if confirm "S3Drive detectado. Desinstalar?"; then
            echo "Desinstalando S3Drive..."
            flatpak uninstall --user -y io.kapsa.drive 2>/dev/null || true
            cleanup_files "$state_file"
            echo "S3Drive desinstalado."
        fi
    else
        if confirm "Instalar S3Drive?"; then
            echo "Instalando S3Drive..."
            flatpak install --or-update --user --noninteractive flathub io.kapsa.drive
            touch "$state_file"
            echo "S3Drive instalado."
        fi
    fi
}

sdkman_installer() {
    local state_file="$STATE_DIR/sdkman"
    local pkg_sdkman="sdkman-bin"

    if [ -f "$state_file" ] || pacman -Q sdkman-bin &>/dev/null; then
        if confirm "Sdkman detectado. Desinstalar?"; then
            echo "Desinstalando Sdkman..."
            pacman -Qq sdkman-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_sdkman || true
            cleanup_files "$state_file" 
            echo "Sdkman desinstalado."
        fi
    else
        if confirm "Instalar Sdkman?"; then
            echo "Instalando Sdkman..."
            yay -S --noconfirm $pkg_sdkman
            touch "$state_file"
            echo "Sdkman instalado."
        fi
    fi
}

shader_booster_installer() {
    local state_file="$STATE_DIR/shader_booster"
    local boost_file="$HOME/.booster"

    if [ -f "$state_file" ] || [ -f "$boost_file" ]; then
        if confirm "Shader Booster detectado. Desinstalar?"; then
            echo "Desinstalando Shader Booster..."
            for shell_file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
                [ -f "$shell_file" ] && sed -i '/# Shader Booster patches/,/# End Shader Booster/d' "$shell_file" 2>/dev/null || true
            done
            cleanup_files "$state_file" "$boost_file" "$HOME/patch-nvidia" "$HOME/patch-mesa"
            echo "Shader Booster desinstalado."
        fi
    else
        if confirm "Instalar Shader Booster?"; then
            echo "Instalando Shader Booster..."
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
            [ $patch_applied -eq 1 ] && echo "1" > "$boost_file" && touch "$state_file" && echo "Shader Booster instalado. Reinicie para aplicar." || echo "Nenhuma GPU compatível detectada."
        fi
    fi
}

signal_installer() {
    local state_file="$STATE_DIR/signal"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.signal.Signal 2>/dev/null; then
        if confirm "Signal detectado. Desinstalar?"; then
            echo "Desinstalando Signal..."
            flatpak uninstall --user -y org.signal.Signal 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Signal desinstalado."
        fi
    else
        if confirm "Instalar Signal?"; then
            echo "Instalando Signal..."
            flatpak install --or-update --user --noninteractive flathub org.signal.Signal
            touch "$state_file"
            echo "Signal instalado."
        fi
    fi
}

sirikali_installer() {
    local state_file="$STATE_DIR/sirikali"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.mhogomchungu.sirikali 2>/dev/null; then
        if confirm "SiriKali detectado. Desinstalar?"; then
            echo "Desinstalando SiriKali..."
            flatpak uninstall --user -y io.github.mhogomchungu.sirikali 2>/dev/null || true
            cleanup_files "$state_file"
            echo "SiriKali desinstalado."
        fi
    else
        if confirm "Instalar SiriKali?"; then
            echo "Instalando SiriKali..."
            flatpak install --or-update --user --noninteractive flathub io.github.mhogomchungu.sirikali
            touch "$state_file"
            echo "SiriKali instalado."
        fi
    fi
}

slack_installer() {
    local state_file="$STATE_DIR/slack"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.slack.Slack 2>/dev/null; then
        if confirm "Slack detectado. Desinstalar?"; then
            echo "Desinstalando Slack..."
            flatpak uninstall --user -y com.slack.Slack 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Slack desinstalado."
        fi
    else
        if confirm "Instalar Slack?"; then
            echo "Instalando Slack..."
            flatpak install --or-update --user --noninteractive flathub com.slack.Slack
            touch "$state_file"
            echo "Slack instalado."
        fi
    fi
}

smartmontools_installer() {
    local state_file="$STATE_DIR/smartmontools"
    local pkg_smart="smartmontools"

    if [ -f "$state_file" ] || pacman -Q smartmontools &>/dev/null; then
        if confirm "smartmontools detectado. Desinstalar?"; then
            echo "Desinstalando smartmontools..."
            pacman -Qq smartmontools &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_smart || true
            cleanup_files "$state_file"
            echo "smartmontools desinstalado."
        fi
    else
        if confirm "Instalar smartmontools?"; then
            echo "Instalando smartmontools..."
            sudo pacman -S --noconfirm $pkg_smart
            touch "$state_file"
            echo "smartmontools instalado."
        fi
    fi
}

sober_installer() {
    local state_file="$STATE_DIR/sober"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.vinegarhq.Sober 2>/dev/null; then
        if confirm "Sober detectado. Desinstalar?"; then
            echo "Desinstalando Sober..."
            flatpak uninstall --user -y org.vinegarhq.Sober 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Sober desinstalado."
        fi
    else
        if confirm "Instalar Sober?"; then
            echo "Instalando Sober..."
            flatpak install --or-update --user --noninteractive flathub org.vinegarhq.Sober
            touch "$state_file"
            echo "Sober instalado."
        fi
    fi
}

social_menu() {
    while true; do
        clear
        echo "=== Aplicativos Sociais ==="
        echo "1) Discord"
        echo "2) Microsoft Teams"
        echo "3) Signal"
        echo "4) Slack"
        echo "5) Telegram"
        echo "6) ZapZap"
        echo "7) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; discord_installer ;;
            2) clear; microsoft_teams_installer ;;
            3) clear; signal_installer ;;
            4) clear; slack_installer ;;
            5) clear; telegram_installer ;;
            6) clear; zapzap_installer ;;
            7) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 6 ] && read -p "Pressione Enter para continuar..."
    done
}

solaar_installer() {
    local state_file="$STATE_DIR/solaar"
    local pkg_solaar="solaar"

    if [ -f "$state_file" ] || pacman -Q solaar &>/dev/null; then
        if confirm "Solaar detectado. Desinstalar?"; then
            echo "Desinstalando Solaar..."
            pacman -Qq solaar &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_solaar || true
            cleanup_files "$state_file"
            echo "Solaar desinstalado."
        fi
    else
        if confirm "Instalar Solaar?"; then
            echo "Instalando Solaar..."
            sudo pacman -S --noconfirm $pkg_solaar
            touch "$state_file"
            echo "Solaar instalado."
        fi
    fi
}

starship_installer() {
    local state_file="$STATE_DIR/starship"
    local pkg_starship="starship"

    if [ -f "$state_file" ] || pacman -Q starship &>/dev/null; then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            pacman -Qq starship &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_starship || true
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            [ -f ~/.config/fish/config.fish ] && sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            sudo pacman -S --noconfirm $pkg_starship
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
    local pkg_steam="steam steam-devices"

    if [ -f "$state_file" ] || pacman -Q steam &>/dev/null; then
        if confirm "Steam detectado. Desinstalar?"; then
            echo "Desinstalando Steam..."
            pacman -Qq steam &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_steam || true
            cleanup_files "$state_file"
            echo "Steam desinstalado."
        fi
    else
        if confirm "Instalar Steam?"; then
            echo "Instalando Steam..."
            sudo pacman -S --noconfirm $pkg_steam
            touch "$state_file"
            echo "Steam instalado."
        fi
    fi
}

stellarium_installer() {
    local state_file="$STATE_DIR/stellarium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.stellarium.Stellarium 2>/dev/null; then
        if confirm "Stellarium detectado. Desinstalar?"; then
            echo "Desinstalando Stellarium..."
            flatpak uninstall --user -y org.stellarium.Stellarium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Stellarium desinstalado."
        fi
    else
        if confirm "Instalar Stellarium?"; then
            echo "Instalando Stellarium..."
            flatpak install --or-update --user --noninteractive flathub org.stellarium.Stellarium
            touch "$state_file"
            echo "Stellarium instalado."
        fi
    fi
}

stirlingpdf_installer() {
    local state_file="$STATE_DIR/stirling"
    local pkg_stirling="stirling-pdf-bin"

    if [ -f "$state_file" ] || pacman -Q stirling-pdf-bin &>/dev/null; then
        if confirm "Stirling Pdf detectado. Desinstalar?"; then
            echo "Desinstalando Stirling Pdf..."
            sudo systemctl stop stirling-pdf 2>/dev/null || true
            sudo systemctl disable stirling-pdf 2>/dev/null || true
            pacman -Qq stirling-pdf-bin &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_stirling || true
            cleanup_files "$state_file"
            echo "Stirling Pdf desinstalado."
        fi
    else
        if confirm "Instalar Stirling Pdf?"; then
            echo "Instalando Stirling Pdf..."
            sudo pacman -S --noconfirm $pkg_stirling
            sudo systemctl enable --now stirling-pdf
            touch "$state_file"
            echo "Stirling Pdf instalado."
        fi
    fi
}

streamcontroller_installer() {
    local state_file="$STATE_DIR/streamcontroller"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.core447.StreamController 2>/dev/null; then
        if confirm "StreamController detectado. Desinstalar?"; then
            echo "Desinstalando StreamController..."
            flatpak uninstall --user -y com.core447.StreamController 2>/dev/null || true
            cleanup_files "$state_file"
            echo "StreamController desinstalado."
        fi
    else
        if confirm "Instalar StreamController?"; then
            echo "Instalando StreamController..."
            flatpak install --or-update --user --noninteractive flathub com.core447.StreamController
            touch "$state_file"
            echo "StreamController instalado."
        fi
    fi
}

sublime_text_installer() {
    local state_file="$STATE_DIR/sublime_text"
    local pkg_sublime="sublime-text"

    if [ -f "$state_file" ] || pacman -Q sublime-text &>/dev/null; then
        if confirm "Sublime Text detectado. Desinstalar?"; then
            echo "Desinstalando Sublime Text..."
            pacman -Qq sublime-text &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_sublime || true
            sudo sed -i '/\[sublime-text\]/,+3d' /etc/pacman.conf 2>/dev/null || true
            sudo pacman-key --delete 8A8F901A 2>/dev/null || true
            sudo pacman -Syu 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Sublime Text desinstalado."
        fi
    else
        if confirm "Instalar Sublime Text?"; then
            echo "Instalando Sublime Text..."
            curl -O https://download.sublimetext.com/sublimehq-pub.gpg && sudo pacman-key --add sublimehq-pub.gpg && sudo pacman-key --lsign-key 8A8F901A && rm sublimehq-pub.gpg
            echo -e "\n[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64" | sudo tee -a /etc/pacman.conf
            sudo pacman -Syu
            sudo pacman -S --noconfirm $pkg_sublime
            touch "$state_file"
            echo "Sublime Text instalado."
        fi
    fi
}

sunshine_installer() {
    local state_file="$STATE_DIR/sunshine"

    if [ -f "$state_file" ] || flatpak list --app | grep -q dev.lizardbyte.app.Sunshine 2>/dev/null; then
        if confirm "Sunshine detectado. Desinstalar?"; then
            echo "Desinstalando Sunshine..."
            flatpak uninstall --user -y dev.lizardbyte.app.Sunshine 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Sunshine desinstalado."
        fi
    else
        if confirm "Instalar Sunshine?"; then
            echo "Instalando Sunshine..."
            flatpak install --or-update --user --noninteractive flathub dev.lizardbyte.app.Sunshine
            flatpak run --command=additional-install.sh dev.lizardbyte.app.Sunshine
            touch "$state_file"
            echo "Sunshine instalado."
        fi
    fi
}

superfile_installer() {
    local state_file="$STATE_DIR/superfile"
    local pkg_superfile="superfile"

    if [ -f "$state_file" ] || pacman -Q superfile &>/dev/null; then
        if confirm "superfile detectado. Desinstalar?"; then
            echo "Desinstalando superfile..."
            pacman -Qq superfile &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_superfile || true
            cleanup_files "$state_file"
            echo "superfile desinstalado."
        fi
    else
        if confirm "Instalar superfile?"; then
            echo "Instalando superfile..."
            sudo pacman -S --noconfirm $pkg_superfile
            touch "$state_file"
            echo "superfile instalado."
        fi
    fi
}

surfsharkvpn_installer() {
    local state_file="$STATE_DIR/surfsharkvpn"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.surfshark.Surfshark 2>/dev/null; then
        if confirm "Surfshark VPN detectado. Desinstalar?"; then
            echo "Desinstalando Surfshark VPN..."
            flatpak uninstall --user -y com.surfshark.Surfshark 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Surfshark VPN desinstalado."
        fi
    else
        if confirm "Instalar Surfshark VPN?"; then
            echo "Instalando Surfshark VPN..."
            flatpak install --or-update --user --noninteractive flathub com.surfshark.Surfshark
            touch "$state_file"
            echo "Surfshark VPN instalado."
        fi
    fi
}

swapfile_create() {
    local location="$1"
    local size="$2"
    
    case $location in
        1)
            if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
                sudo btrfs subvolume create /swap 2>/dev/null || true
                sudo btrfs filesystem mkswapfile --size ${size}g --uuid clear /swap/swapfile
                sudo swapon /swap/swapfile
                echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            else
                sudo dd if=/dev/zero of=/swapfile bs=1G count=$size status=progress 2>/dev/null || true
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                echo "/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            fi
            ;;
        2)
            if findmnt -n -o FSTYPE /home | grep -q "btrfs"; then
                sudo btrfs subvolume create /home/swap 2>/dev/null || true
                sudo btrfs filesystem mkswapfile --size ${size}g --uuid clear /home/swap/swapfile
                sudo swapon /home/swap/swapfile
                echo "/home/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            else
                sudo dd if=/dev/zero of=/home/swapfile bs=1G count=$size status=progress 2>/dev/null || true
                sudo chmod 600 /home/swapfile
                sudo mkswap /home/swapfile
                sudo swapon /home/swapfile
                echo "/home/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            fi
            ;;
        *) echo "Opção inválida"; return 1 ;;
    esac
    
    echo "# swapfile" | sudo tee -a /etc/fstab
    return 0
}

swapfile_installer() {
    local state_file="$STATE_DIR/swapfile"
    
    if [ -f "$state_file" ] || swapon --show | grep -q '.'; then
        if confirm "Swapfile detectado. Desinstalar?"; then
            echo "Desinstalando Swapfile..."
            sudo swapoff -a 2>/dev/null || true
            [ -f "/swapfile" ] && sudo swapoff /swapfile 2>/dev/null || true && sudo rm -f /swapfile 2>/dev/null || true && sudo sed -i '/\/swapfile/d' /etc/fstab 2>/dev/null || true
            [ -f "/home/swapfile" ] && sudo swapoff /home/swapfile 2>/dev/null || true && sudo rm -f /home/swapfile 2>/dev/null || true && sudo sed -i '/\/home\/swapfile/d' /etc/fstab 2>/dev/null || true
            [ -d "/swap" ] && sudo swapoff /swap/swapfile 2>/dev/null || true && sudo rm -rf /swap 2>/dev/null || true && sudo sed -i '/\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true
            [ -d "/home/swap" ] && sudo swapoff /home/swap/swapfile 2>/dev/null || true && sudo rm -rf /home/swap 2>/dev/null || true && sudo sed -i '/\/home\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true
            sudo sed -i '/# swapfile/d' /etc/fstab 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Swapfile desinstalado."
        fi
    else
        echo "=== Swapfile ==="
        echo "1) Criar em / (root)"
        echo "2) Criar em /home"
        echo "3) Cancelar"
        echo
        read -p "Selecione local: " location
        
        case $location in
            1|2)
                read -p "Tamanho em GB (padrão: 8): " size
                size=${size:-8}
                [[ "$size" =~ ^[0-9]+$ ]] || { echo "Tamanho inválido"; return; }
                if confirm "Criar swapfile de ${size}GB?"; then
                    echo "Criando swapfile de ${size}GB..."
                    swapfile_create "$location" "$size" && touch "$state_file" && echo "Swapfile criado com sucesso."
                fi
                ;;
            3) return ;;
            *) echo "Opção inválida" ;;
        esac
    fi
}

tailscale_installer() {
    local state_file="$STATE_DIR/tailscale"
    local pkg_tailscale="tailscale"

    if [ -f "$state_file" ] || pacman -Q tailscale &>/dev/null; then
        if confirm "Tailscale detectado. Desinstalar?"; then
            echo "Desinstalando Tailscale..."
            sudo systemctl stop tailscaled 2>/dev/null || true
            sudo systemctl disable tailscaled 2>/dev/null || true
            pacman -Qq tailscale &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_tailscale || true
            cleanup_files "$state_file"
            echo "Tailscale desinstalado."
        fi
    else
        if confirm "Instalar Tailscale?"; then
            echo "Instalando Tailscale..."
            sudo pacman -S --noconfirm $pkg_tailscale
            sudo systemctl enable --now tailscaled
            touch "$state_file"
            echo "Tailscale instalado."
        fi
    fi
}

telegram_installer() {
    local state_file="$STATE_DIR/telegram"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.telegram.desktop 2>/dev/null; then
        if confirm "Telegram detectado. Desinstalar?"; then
            echo "Desinstalando Telegram..."
            flatpak uninstall --user -y org.telegram.desktop 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Telegram desinstalado."
        fi
    else
        if confirm "Instalar Telegram?"; then
            echo "Instalando Telegram..."
            flatpak install --or-update --user --noninteractive flathub org.telegram.desktop
            touch "$state_file"
            echo "Telegram instalado."
        fi
    fi
}

termius_installer() {
    local state_file="$STATE_DIR/termius"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.termius.Termius 2>/dev/null; then
        if confirm "Termius detectado. Desinstalar?"; then
            echo "Desinstalando Termius..."
            flatpak uninstall --user -y com.termius.Termius 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Termius desinstalado."
        fi
    else
        if confirm "Instalar Termius?"; then
            echo "Instalando Termius..."
            flatpak install --or-update --user --noninteractive flathub com.termius.Termius
            touch "$state_file"
            echo "Termius instalado."
        fi
    fi
}

thumbnailer_installer() {
    local state_file="$STATE_DIR/thumbnailer"
    local pkg_thumbnailer="ffmpegthumbnailer"

    if [ -f "$state_file" ] || pacman -Q ffmpegthumbnailer &>/dev/null; then
        if confirm "Thumbnailer detectado. Desinstalar?"; then
            echo "Desinstalando Thumbnailer..."
            pacman -Qq ffmpegthumbnailer &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_thumbnailer || true
            cleanup_files "$state_file"
            echo "Thumbnailer desinstalado."
        fi
    else
        if confirm "Instalar Thumbnailer?"; then
            echo "Instalando Thumbnailer..."
            sudo pacman -S --noconfirm $pkg_thumbnailer
            touch "$state_file"
            echo "Thumbnailer instalado."
        fi
    fi
}

topgrade_installer() {
    local state_file="$STATE_DIR/topgrade"
    local pkg_pipx="python-pipx"

    if [ -f "$state_file" ] || pipx list | grep -q topgrade 2>/dev/null; then
        if confirm "Topgrade detectado. Desinstalar?"; then
            echo "Desinstalando Topgrade..."
            pipx uninstall topgrade 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Topgrade desinstalado."
        fi
    else
        if confirm "Instalar Topgrade?"; then
            echo "Instalando Topgrade..."
            sudo pacman -S --noconfirm $pkg_pipx
            pipx install topgrade
            touch "$state_file"
            echo "Topgrade instalado."
        fi
    fi
}

ufw_installer() {
    local state_file="$STATE_DIR/ufw"
    local pkg_ufw="ufw"

    if [ -f "$state_file" ] || pacman -Q ufw &>/dev/null; then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            systemctl is-active --quiet ufw 2>/dev/null && sudo systemctl stop ufw || true
            systemctl is-enabled --quiet ufw 2>/dev/null && sudo systemctl disable ufw || true
            pacman -Qq ufw &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ufw || true
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw /usr/bin/ufw /usr/sbin/ufw 2>/dev/null || true
            cleanup_files "$state_file"
            echo "UFW desinstalado."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
            sudo pacman -S --noconfirm $pkg_ufw
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

ungoogled_chromium_installer() {
    local state_file="$STATE_DIR/ungoogled_chromium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.ungoogled_software.ungoogled_chromium 2>/dev/null; then
        if confirm "Ungoogled Chromium detectado. Desinstalar?"; then
            echo "Desinstalando Ungoogled Chromium..."
            flatpak uninstall --user -y io.github.ungoogled_software.ungoogled_chromium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Ungoogled Chromium desinstalado."
        fi
    else
        if confirm "Instalar Ungoogled Chromium?"; then
            echo "Instalando Ungoogled Chromium..."
            flatpak install --or-update --user --noninteractive flathub io.github.ungoogled_software.ungoogled_chromium
            touch "$state_file"
            echo "Ungoogled Chromium instalado."
        fi
    fi
}

unmojang_installer() {
    local state_file="$STATE_DIR/unmojang"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.unmojang.FjordLauncher 2>/dev/null; then
        if confirm "Fjord Launcher detectado. Desinstalar?"; then
            echo "Desinstalando Fjord Launcher..."
            flatpak uninstall --user -y org.unmojang.FjordLauncher 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Fjord Launcher desinstalado."
        fi
    else
        if confirm "Instalar Fjord Launcher?"; then
            echo "Instalando Fjord Launcher..."
            flatpak remote-add --user --if-not-exists hero-persson https://hero-persson.github.io/unmojang-flatpak/index.flatpakrepo
            flatpak install --user --or-update --noninteractive hero-persson org.unmojang.FjordLauncher
            touch "$state_file"
            echo "Fjord Launcher instalado."
        fi
    fi
}

utilidades_menu() {
    while true; do
        clear
        echo "=== Utilidades ==="
        echo "1) Arch Update"
        echo "2) Bazaar"
        echo "3) Bottles"
        echo "4) Distroshelf"
        echo "5) Distrobox-Adv"
        echo "6) EasyEffects"
        echo "7) F3"
        echo "8) Flatseal"
        echo "9) Gear Lever"
        echo "10) HandBrake"
        echo "11) LACT"
        echo "12) Mission Center"
        echo "13) Nerd Fonts"
        echo "14) OBS Studio"
        echo "15) PeaZip"
        echo "16) Pika Backup"
        echo "17) PWGraph"
        echo "18) Rclone UI"
        echo "19) S3Drive"
        echo "20) VLC"
        echo "21) Warehouse"
        echo "22) Waydroid"
        echo "23) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; arch_update_installer ;;
            2) clear; bazaar_installer ;;
            3) clear; bottles_installer ;;
            4) clear; distroshelf_installer ;;
            5) clear; distrobox_adv_installer ;;
            6) clear; easyeffects_installer ;;
            7) clear; f3_installer ;;
            8) clear; flatseal_installer ;;
            9) clear; gearlever_installer ;;
            10) clear; handbrake_installer ;;
            11) clear; lact_installer ;;
            12) clear; missioncenter_installer ;;
            13) clear; nerd_fonts_installer ;;
            14) clear; obs_installer ;;
            15) clear; peazip_installer ;;
            16) clear; pika_backup_installer ;;
            17) clear; pwgraph_installer ;;
            18) clear; rcloneui_installer ;;
            19) clear; s3drive_installer ;;
            20) clear; vlc_installer ;;
            21) clear; warehouse_installer ;;
            22) clear; waydroid_installer ;;
            23) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 22 ] && read -p "Pressione Enter para continuar..."
    done
}

vinegar_installer() {
    local state_file="$STATE_DIR/vinegar"

    if [ -f "$state_file" ] || flatpak list --app | grep -q org.vinegarhq.Vinegar 2>/dev/null; then
        if confirm "Vinegar detectado. Desinstalar?"; then
            echo "Desinstalando Vinegar..."
            flatpak uninstall --user -y org.vinegarhq.Vinegar 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Vinegar desinstalado."
        fi
    else
        if confirm "Instalar Vinegar?"; then
            echo "Instalando Vinegar..."
            flatpak install --or-update --user --noninteractive flathub org.vinegarhq.Vinegar
            touch "$state_file"
            echo "Vinegar instalado."
        fi
    fi
}

vlc_installer() {
    local state_file="$STATE_DIR/vlc"
    local pkg_vlc="vlc"

    if [ -f "$state_file" ] || pacman -Q vlc &>/dev/null; then
        if confirm "VLC detectado. Desinstalar?"; then
            echo "Desinstalando VLC..."
            pacman -Qq vlc &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_vlc || true
            cleanup_files "$state_file"
            echo "VLC desinstalado."
        fi
    else
        if confirm "Instalar VLC?"; then
            echo "Instalando VLC..."
            sudo pacman -S --noconfirm $pkg_vlc
            touch "$state_file"
            echo "VLC instalado."
        fi
    fi
}

vscode_installer() {
    local state_file="$STATE_DIR/vscode"
    local pkg_vscode="visual-studio-code-bin"

    if [ -f "$state_file" ] || pacman -Q visual-studio-code-bin &>/dev/null; then
        if confirm "Visual Studio Code detectado. Desinstalar?"; then
            echo "Desinstalando Visual Studio Code..."
            pacman -Qq visual-studio-code-bin &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_vscode || true
            cleanup_files "$state_file"
            echo "Visual Studio Code desinstalado."
        fi
    else
        if confirm "Instalar Visual Studio Code?"; then
            echo "Instalando Visual Studio Code..."
            sudo pacman -S --noconfirm $pkg_vscode
            touch "$state_file"
            echo "Visual Studio Code instalado."
        fi
    fi
}

vscodium_installer() {
    local state_file="$STATE_DIR/vscodium"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.vscodium.codium 2>/dev/null; then
        if confirm "VSCodium detectado. Desinstalar?"; then
            echo "Desinstalando VSCodium..."
            flatpak uninstall --user -y com.vscodium.codium 2>/dev/null || true
            cleanup_files "$state_file"
            echo "VSCodium desinstalado."
        fi
    else
        if confirm "Instalar VSCodium?"; then
            echo "Instalando VSCodium..."
            flatpak install --user --or-update --noninteractive flathub com.vscodium.codium
            touch "$state_file"
            echo "VSCodium instalado."
        fi
    fi
}

warehouse_installer() {
    local state_file="$STATE_DIR/warehouse"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.flattool.Warehouse 2>/dev/null; then
        if confirm "Warehouse detectado. Desinstalar?"; then
            echo "Desinstalando Warehouse..."
            flatpak uninstall --user -y io.github.flattool.Warehouse 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Warehouse desinstalado."
        fi
    else
        if confirm "Instalar Warehouse?"; then
            echo "Instalando Warehouse..."
            flatpak install --or-update --user --noninteractive flathub io.github.flattool.Warehouse
            touch "$state_file"
            echo "Warehouse instalado."
        fi
    fi
}

waydroid_installer() {
    local state_file="$STATE_DIR/waydroid"
    local pkg_waydroid="waydroid"

    if [ -f "$state_file" ] || pacman -Q waydroid &>/dev/null; then
        if confirm "Waydroid detectado. Desinstalar?"; then
            echo "Desinstalando Waydroid..."
            sudo systemctl stop waydroid-container 2>/dev/null || true
            sudo systemctl disable waydroid-container 2>/dev/null || true
            pacman -Qq waydroid &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_waydroid || true
            cleanup_files "$state_file"
            echo "Waydroid desinstalado."
        fi
    else
        if confirm "Instalar Waydroid?"; then
            echo "Instalando Waydroid..."
            sudo pacman -S --noconfirm $pkg_waydroid
            sudo systemctl enable --now waydroid-container
            waydroid init -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor -s GAPPS
            sudo firewall-cmd --zone=trusted --add-interface=waydroid0 --permanent 2>/dev/null || true
            sudo iptables -P FORWARD ACCEPT
            touch "$state_file"
            echo "Waydroid instalado."
        fi
    fi
}

winboat_installer() {
    local state_file="$STATE_DIR/winboat"
    local pkg_winboat="winboat-bin"

    if [ -f "$state_file" ] || pacman -Q winboat-bin &>/dev/null; then
        if confirm "WinBoat detectado. Desinstalar?"; then
            echo "Desinstalando WinBoat..."
            pacman -Qq winboat-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_winboat || true
            cleanup_files "$state_file" "$HOME/lsw" "$HOME/txtbox"
            echo "WinBoat desinstalado."
        fi
    else
        lsmod | grep -q kvm || { echo "KVM não está disponível. Verifique se a virtualização está habilitada no BIOS."; return 1; }
        if confirm "Instalar WinBoat (Windows em container Docker)?"; then
            echo "Instalando WinBoat..."
            yay -S --noconfirm $pkg_winboat
            touch "$state_file"
            echo "WinBoat instalado. Reinicie para carregar módulos do kernel."
        fi
    fi
}

windscribevpn_installer() {
    local state_file="$STATE_DIR/windscribe"
    local pkg_windscribe="windscribe-v2-bin"

    if [ -f "$state_file" ] || pacman -Q windscribe-v2-bin &>/dev/null; then
        if confirm "Windscribe detectado. Desinstalar?"; then
            echo "Desinstalando Windscribe..."
            pacman -Qq windscribe-v2-bin &>/dev/null && yay -Rsnu --noconfirm $pkg_windscribe || true
            cleanup_files "$state_file" 
            echo "Windscribe desinstalado."
        fi
    else
        if confirm "Instalar Windscribe?"; then
            echo "Instalando Windscribe..."
            yay -S --noconfirm $pkg_windscribe
            touch "$state_file"
            echo "Windscribe instalado."
        fi
    fi
}

wireguard_installer() {
    local state_file="$STATE_DIR/wireguard"
    local pkg_wireguard="wireguard-tools"

    if [ -f "$state_file" ] || pacman -Q wireguard-tools &>/dev/null; then
        if confirm "WireGuard detectado. Desinstalar?"; then
            echo "Desinstalando WireGuard..."
            pacman -Qq wireguard-tools &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_wireguard || true
            cleanup_files "$state_file"
            echo "WireGuard desinstalado."
        fi
    else
        if confirm "Instalar WireGuard?"; then
            echo "Instalando WireGuard..."
            sudo pacman -S --noconfirm $pkg_wireguard
            touch "$state_file"
            echo "WireGuard instalado."
        fi
    fi
}

wivrn_installer() {
    local state_file="$STATE_DIR/wivrn"

    if [ -f "$state_file" ] || flatpak list --app | grep -q io.github.wivrn.wivrn 2>/dev/null; then
        if confirm "WiVRn detectado. Desinstalar?"; then
            echo "Desinstalando WiVRn..."
            flatpak uninstall --user -y io.github.wivrn.wivrn 2>/dev/null || true
            cleanup_files "$state_file"
            echo "WiVRn desinstalado."
        fi
    else
        if confirm "Instalar WiVRn?"; then
            echo "Instalando WiVRn..."
            flatpak install --or-update --user --noninteractive flathub io.github.wivrn.wivrn
            touch "$state_file"
            echo "WiVRn instalado."
        fi
    fi
}

xdg_base_installer() {
    local state_file="$STATE_DIR/xdg_base"
    local pkg_xdg="xdg-user-dirs xdg-utils"

    if [ -f "$state_file" ]; then
        if confirm "XDG Base detectado. Desinstalar?"; then
            echo "Desinstalando XDG Base..."
            pacman -Qq xdg-user-dirs &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_xdg || true
            cleanup_files "$state_file"
            echo "XDG Base desinstalado."
        fi
    else
        if confirm "Instalar XDG Base?"; then
            echo "Instalando XDG Base..."
            sudo pacman -S --noconfirm $pkg_xdg
            touch "$state_file"
            echo "XDG Base instalado."
        fi
    fi
}

xpadneo_installer() {
    local state_file="$STATE_DIR/xpadneo"
    local pkg_xpadneo="xpadneo-dkms"

    if [ -f "$state_file" ]; then
        if confirm "Xpadneo detectado. Desinstalar?"; then
            echo "Desinstalando Xpadneo..."
            pacman -Qq xpadneo-dkms &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_xpadneo || true
            cleanup_files "$state_file"
            echo "Xpadneo desinstalado."
        fi
    else
        if confirm "Instalar Xpadneo?"; then
            echo "Instalando Xpadneo..."
            sudo pacman -S --noconfirm $pkg_xpadneo
            touch "$state_file"
            echo "Xpadneo instalado."
        fi
    fi
}

yay_installer() {
    local state_file="$STATE_DIR/yay"
    local pkg_yay="yay base-devel"

    if [ -f "$state_file" ] || pacman -Q yay &>/dev/null; then
        if confirm "Yay detectado. Desinstalar?"; then
            echo "Desinstalando Yay..."
            pacman -Qq yay &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_yay || true
            cleanup_files "$state_file"
            echo "Yay desinstalado."
        fi
    else
        if confirm "Instalar Yay (AUR helper)?"; then
            echo "Instalando Yay..."
            sudo pacman -S --noconfirm $pkg_yay
            touch "$state_file"
            echo "Yay instalado."
        fi
    fi
}

yt_dlp_installer() {
    local state_file="$STATE_DIR/yt_dlp"
    local pkg_ytdlp="yt-dlp"

    if [ -f "$state_file" ] || pacman -Q yt-dlp &>/dev/null; then
        if confirm "yt-dlp detectado. Desinstalar?"; then
            echo "Desinstalando yt-dlp..."
            pacman -Qq yt-dlp &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_ytdlp || true
            cleanup_files "$state_file"
            echo "yt-dlp desinstalado."
        fi
    else
        if confirm "Instalar yt-dlp?"; then
            echo "Instalando yt-dlp..."
            sudo pacman -S --noconfirm $pkg_ytdlp
            touch "$state_file"
            echo "yt-dlp instalado."
        fi
    fi
}

zapzap_installer() {
    local state_file="$STATE_DIR/zapzap"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.rtosta.zapzap 2>/dev/null; then
        if confirm "ZapZap detectado. Desinstalar?"; then
            echo "Desinstalando ZapZap..."
            flatpak uninstall --user -y com.rtosta.zapzap 2>/dev/null || true
            cleanup_files "$state_file"
            echo "ZapZap desinstalado."
        fi
    else
        if confirm "Instalar ZapZap?"; then
            echo "Instalando ZapZap..."
            flatpak install --or-update --user --noninteractive flathub com.rtosta.zapzap
            touch "$state_file"
            echo "ZapZap instalado."
        fi
    fi
}

zed_installer() {
    local state_file="$STATE_DIR/zed"

    if [ -f "$state_file" ] || flatpak list --app | grep -q dev.zed.Zed 2>/dev/null; then
        if confirm "Zed detectado. Desinstalar?"; then
            echo "Desinstalando Zed..."
            flatpak uninstall --user -y dev.zed.Zed 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Zed desinstalado."
        fi
    else
        if confirm "Instalar Zed?"; then
            echo "Instalando Zed..."
            flatpak install --user --or-update --noninteractive flathub dev.zed.Zed
            touch "$state_file"
            echo "Zed instalado."
        fi
    fi
}

zen_browser_installer() {
    local state_file="$STATE_DIR/zen_browser"

    if [ -f "$state_file" ] || flatpak list --app | grep -q com.github.casualsnek.zenbrowser 2>/dev/null; then
        if confirm "Zen Browser detectado. Desinstalar?"; then
            echo "Desinstalando Zen Browser..."
            flatpak uninstall --user -y com.github.casualsnek.zenbrowser 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Zen Browser desinstalado."
        fi
    else
        if confirm "Instalar Zen Browser?"; then
            echo "Instalando Zen Browser..."
            flatpak install --or-update --user --noninteractive flathub com.github.casualsnek.zenbrowser
            touch "$state_file"
            echo "Zen Browser instalado."
        fi
    fi
}

zerotier_installer() {
    local state_file="$STATE_DIR/zerotier"
    local pkg_zerotier="zerotier-one"

    if [ -f "$state_file" ] || pacman -Q zerotier-one &>/dev/null; then
        if confirm "ZeroTier detectado. Desinstalar?"; then
            echo "Desinstalando ZeroTier..."
            sudo systemctl stop zerotier-one 2>/dev/null || true
            sudo systemctl disable zerotier-one 2>/dev/null || true
            pacman -Qq zerotier-one &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_zerotier || true
            cleanup_files "$state_file"
            echo "ZeroTier desinstalado."
        fi
    else
        if confirm "Instalar ZeroTier?"; then
            echo "Instalando ZeroTier..."
            sudo pacman -S --noconfirm $pkg_zerotier
            sudo systemctl enable --now zerotier-one
            touch "$state_file"
            echo "ZeroTier instalado."
        fi
    fi
}

zsh_menu() {
    while true; do
        clear
        echo "=== Zsh Shell ==="
        echo "1) Zsh"
        echo "2) Oh My Zsh"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; zsh_installer ;;
            2) clear; oh_my_zsh_installer ;;
            3) return ;;
            *) ;;
        esac

        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

zsh_installer() {
    local state_file="$STATE_DIR/zsh"
    local pkg_zsh="zsh"

    if [ -f "$state_file" ] || pacman -Q zsh &>/dev/null; then
        if confirm "Zsh detectado. Desinstalar?"; then
            echo "Desinstalando Zsh..."
            pacman -Qq zsh &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_zsh || true
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Zsh desinstalado."
        fi
    else
        if confirm "Instalar Zsh?"; then
            echo "Instalando Zsh..."
            sudo pacman -S --noconfirm $pkg_zsh
            sudo chsh -s "$(which zsh)" "$USER"
            touch "$state_file"
            echo "Zsh instalado."
        fi
    fi
}

oh_my_zsh_installer() {
    local state_file="$STATE_DIR/oh_my_zsh"
    local ohmyzsh_dir="$HOME/.oh-my-zsh"

    if [ -f "$state_file" ] || [ -d "$ohmyzsh_dir" ]; then
        if confirm "Oh My Zsh detectado. Desinstalar?"; then
            echo "Desinstalando Oh My Zsh..."
            [ -d "$ohmyzsh_dir" ] && yes | "$ohmyzsh_dir"/tools/uninstall.sh 2>/dev/null || true
            cleanup_files "$state_file"
            echo "Oh My Zsh desinstalado."
        fi
    else
        if confirm "Instalar Oh My Zsh?"; then
            echo "Instalando Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            touch "$state_file"
            echo "Oh My Zsh instalado."
        fi
    fi
}

distrobox_installer() {
    local state_file="$STATE_DIR/distrobox"
    local pkg_distrobox="distrobox"

    if [ -f "$state_file" ] || pacman -Q distrobox &>/dev/null; then
        if confirm "distrobox detectado. Desinstalar?"; then
            echo "Desinstalando distrobox..."
            pacman -Qq distrobox &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_distrobox || true
            cleanup_files "$state_file"
            echo "distrobox desinstalado."
        fi
    else
        if confirm "Instalar distrobox?"; then
            echo "Instalando distrobox..."
            sudo pacman -S --noconfirm $pkg_distrobox
            touch "$state_file"
            echo "distrobox instalado."
        fi
    fi
}

main_menu() {
    while true; do
        clear
        echo "=== Menu Principal ==="
        echo "1) Admin"
        echo "2) Devs"
        echo "3) Drivers"
        echo "4) Educação"
        echo "5) Extras"
        echo "6) IDEs"
        echo "7) Jogos"
        echo "8) Office"
        echo "9) Periféricos"
        echo "10) Pessoal"
        echo "11) Privacidade"
        echo "12) Repositórios"
        echo "13) Social"
        echo "14) Utilidades"
        echo "15) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) admin_menu ;;
            2) devs_menu ;;
            3) drivers_menu ;;
            4) educacao_menu ;;
            5) extras_menu ;;
            6) ides_menu ;;
            7) jogos_menu ;;
            8) office_menu ;;
            9) perifericos_menu ;;
            10) pessoal_menu ;;
            11) privacidade_menu ;;
            12) repositorios_menu ;;
            13) social_menu ;;
            14) utilidades_menu ;;
            15) echo "Até logo!"; exit 0 ;;
            *) ;;
        esac
    done
}

main_menu
