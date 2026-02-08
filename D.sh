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
    #Utilize o driver official da nvidia ao modificar para o debian, abaixo tem um exemplo de como instalado, depois o coloque no metodo acima, utilize curl em vez de wget:
#!/bin/bash
# name: Nvidia Drivers
# version: 1.0
# description: nv_desc
# icon: nvidia.svg
# compat: debian
# reboot: yes
# nocontainer
# gpu: Nvidia

# --- Start of the script code ---
#SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/libs/linuxtoys.lib"
# language
_lang_
source "$SCRIPT_DIR/libs/lang/${langfile}.lib"
cd $HOME
# add Nvidia repository for Debian
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sleep 1
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sleep 1
sudo apt-get update
sleep 1
sudo apt-get install -y cuda-drivers
sleep 1
sudo update-initramfs -u
sleep 1
sudo update-grub
zeninf "$msg036"
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

appimage_fuse_installer() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="fuse fuse3"

    if [ -f "$state_file" ] || pacman -Q fuse &>/dev/null; then
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

archiving_compression_installer() {
    local state_file="$STATE_DIR/pessoal_compactacao"
    local pkg_compactacao="tar 7zip unrar unzip gzip lrzip xz-utils zip lzop"

    if [ -f "$state_file" ] || pacman -Q 7zip &>/dev/null; then
        if confirm "Pacotes de Compactação detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes de Compactação..."
            pacman -Qq 7zip &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_compactacao || true
            cleanup_files "$state_file"
            echo "Pacotes de Compactação desinstalados."
        fi
    else
        if confirm "Instalar Pacotes de Compactação?"; then
            echo "Instalando Pacotes de Compactação..."
            sudo pacman -S --noconfirm $pkg_compactacao
            touch "$state_file"
            echo "Pacotes de Compactação instalados."
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

gamemode_installer() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode"

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

flatpak_flathub_installer() {
    local flatpak_state="$STATE_DIR/flatpak"
    local flathub_state="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"

    if [ -f "$flatpak_state" ] || pacman -Q flatpak &>/dev/null; then
        if confirm "Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando Flatpak..."
            pacman -Qq flatpak &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_flatpak || true
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            cleanup_files "$flatpak_state" "$flathub_state"
            echo "Flatpak desinstalado."
        fi
    elif confirm "Instalar Flatpak?"; then
        echo "Instalando Flatpak..."
        sudo pacman -S --noconfirm $pkg_flatpak
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

    if [ -f "$state_file" ] || pacman -Q neovim &>/dev/null; then
        if confirm "NeoVim detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim..."
            pacman -Qq neovim &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_neovim || true
            cleanup_files "$state_file"
            echo "NeoVim desinstalado."
        fi
    else
        if confirm "Instalar NeoVim?"; then
            echo "Instalando NeoVim..."
            sudo pacman -S --noconfirm $pkg_neovim
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

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-shell gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"

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

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="plasma-desktop konsole dolphin kdeconnect partitionmanager ark"

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

main_menu() {
    while true; do
        clear
        echo "=== Arch Scripts ==="
        echo "1) Admin"
        echo "2) Devs"
        echo "3) Drivers"
        echo "4) Educação"
        echo "5) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) admin_menu ;;
            2) devs_menu ;;
            3) drivers_menu ;;
            4) educacao_menu ;;
            5) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
