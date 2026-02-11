Desejo que vc converta esse script criado originalmente para arch linux para funcionar no debian, existem algumas instrucoes sobre o que vc deve fazer, foque no minimalismo e simplicidade.
Crie um metodo que execute apt update e upgrade e instale o ntpsec, esse metodo deve sempre ser chamado ao usar algum metodo installer. Garanta boa consistencia e funcionamento.
Nao se deve utilizar wget e sim curl no lugar. Alguns scripts eu botei do linuxtoys para vc usar de referencia de como fazer esses metodos funcionarem no debian(prioridade), eles sao os que pussuem a 
#!/bin/bash, sequida por outros paremetros como nome e versao.
Crie um metodo isntaller que adicione o repositorio do debian non-free, debian multimidia, contrib e non-free-firmware, ele deve adicionar todos esses repositorios de uma vez so.

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

fish_fisher_installer() {
    local fish_state="$STATE_DIR/fish"
    local fisher_state="$STATE_DIR/fisher"
    local pkg_fish="fish"
    local pkg_fisher="fisher"

    if [ -f "$fish_state" ] || pacman -Q fish &>/dev/null; then
        if confirm "Fish Shell detectado. Desinstalar?"; then
            echo "Desinstalando Fish Shell..."
            if [ -f "$fisher_state" ] || pacman -Q fisher &>/dev/null; then
                pacman -Qq fisher &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fisher || true
                cleanup_files "$fisher_state"
            fi
            pacman -Qq fish &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fish || true
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            cleanup_files "$fish_state" "$HOME/.config/fish"
            echo "Fish Shell desinstalado."
        fi
    elif confirm "Instalar Fish Shell?"; then
        echo "Instalando Fish Shell..."
        sudo pacman -S --noconfirm $pkg_fish
        sudo chsh -s "$(which fish)" "$USER"
        mkdir -p ~/.config/fish
        echo "set fish_greeting" > ~/.config/fish/config.fish
        touch "$fish_state"
        echo "Fish Shell instalado."
    fi

    if [ -f "$fisher_state" ] || pacman -Q fisher &>/dev/null; then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            pacman -Qq fisher &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_fisher || true
            cleanup_files "$fisher_state"
            echo "Fisher desinstalado."
        fi
    elif confirm "Instalar Fisher (plugin manager)?"; then
        echo "Instalando Fisher..."
        sudo pacman -S --noconfirm $pkg_fisher
        fish -c "fisher install jorgebucaran/fisher" 2>/dev/null || true
        touch "$fisher_state"
        echo "Fisher instalado."
    fi
    #Utilize o script do fisher no lugar da instalacao do pacote como abaixo no debian, use curl:
#!/bin/bash
# name: Fisher
# version: 1.0
# description: fisher_desc
# icon: fish.svg
# repo: https://github.com/jorgebucaran/fisher

# --- Start of the script code ---
source "$SCRIPT_DIR/libs/linuxtoys.lib"
source "$SCRIPT_DIR/libs/helpers.lib"
_lang_
source "$SCRIPT_DIR/libs/lang/${langfile}.lib"

sudo_rq
_packages=(fish)
_install_

if command -v fish >/dev/null 2>&1; then
	sudo chsh -s "$(type -p fish)" "$USER"

	if fish -c "curl -sL https://git.io/fisher | source; fisher install jorgebucaran/fisher"; then
		zeninf "$msg018"
	else
		fatal "Fisher could not be installed."
	fi
else
	fatal "Unable to complete installation"
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
    #Utilize o script do mise no lugar da instalacao do pacote como abaixo no debian, use curl:
#!/bin/bash
# name: Mise
# version: 1.0
# description: mise_desc
# icon: mise.svg
# repo: https://github.com/jdx/mise

# --- Start of the script code ---
#SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/libs/linuxtoys.lib"
_lang_
source "$SCRIPT_DIR/libs/lang/${langfile}.lib"
if [ -f $HOME/.bashrc ]; then
    curl https://mise.run/bash | sh
    mise use -g usage
    mkdir -p ~/.local/share/bash-completion/
    mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
fi
if ! command -v rpm-ostree &>/dev/null; then
    # mise is not compatible with ZSH on ostree distros
    if [ -f $HOME/.zshrc ]; then
        curl https://mise.run/zsh | sh
        mise use -g usage
        mkdir -p /usr/local/share/zsh/site-functions
        mise completion zsh  > /usr/local/share/zsh/site-functions/_mise
    fi
fi
if [ -f $HOME/.config/fish/config.fish ]; then
    curl https://mise.run/fish | sh
    mise use -g usage
    mkdir -p ~/.config/fish/completions
    mise completion fish > ~/.config/fish/completions/mise.fish
fi
zeninf "$msg282"
xdg-open https://mise.jdx.dev/walkthrough.html
exit 0
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

snapd_installer() {
    local state_file="$STATE_DIR/snapd"
    local pkg_snapd="snapd"

    if [ -f "$state_file" ] || pacman -Q snapd &>/dev/null; then
        if confirm "Snapd detectado. Desinstalar?"; then
            echo "Desinstalando Snapd..."
            sudo systemctl stop snapd.socket 2>/dev/null || true
            sudo systemctl disable snapd.socket 2>/dev/null || true
            pacman -Qq snapd &>/dev/null && paru -Rsnu --noconfirm $pkg_snapd || true
            cleanup_files "$state_file"
            echo "Snapd desinstalado."
        fi
    else
        if confirm "Instalar Snapd?"; then
            echo "Instalando Snapd..."
            paru -S --noconfirm $pkg_snapd
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

    if [ -f "$state_file" ] || pacman -Q xdg-user-dirs &>/dev/null; then
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

pessoal_base_installer() {
    local state_file="$STATE_DIR/pessoal_base"
    local pkg_base="fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra fonts-noto-cjk-extra fonts-jetbrains-mono"

    if [ -f "$state_file" ] || pacman -Q fonts-jetbrains-mono &>/dev/null; then
        if confirm "Pacotes Base detectados. Desinstalar?"; then
            echo "Desinstalando Pacotes Base..."
            pacman -Qq fonts-noto &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_base || true
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
    local pkg_media="ffmpeg gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-alsa"

    if [ -f "$state_file" ] || pacman -Q gstreamer1.0-alsa &>/dev/null; then
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
            1) admin_installer ;;
            2) devs_installer ;;
            3) drivers_installer;;
            4) educacao_installer ;;
            5) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu

Aqui esta um exemplo do que fazer, esse e um roteiro criado por outro usuario:
reparação do Debian 13 Trixie

Nesta guia eu sugiro usar a Instalação Avançada do Debian para ativar os repositórios NON-FREE e NON-FREE-FIRMWARE já na instalação. Não são passos obrigatórios, mas já adiantam alguns processos.

    Ativar e configurar o firewall (UFW).
    Ativação de repositórios extras (DebMultimedia e NVIDIA).
    Instalação dos drivers de vídeo proprietários NVIDIA.
    Ativação do suporte a flatpaks.
    Ajustes básicos do sistema.
    Notas sobre problemas encontrados até o momento.


Instalação e configuração básica do Firewall

Ativar um firewall é um cuidado recomendado para diminuir as chances de expor seu computador online, é claro que, para ter realmente segurança online é necessário tomar outros cuidados.

Note

Os comandos abaixo liberam a comunicação nas portas indicadas para quaisquer equipamentos da rede, uma recomendação extra de segurança é liberar o acesso apenas para a sua rede local.

Instalar e habilitar o UFW no Debian 13

sudo apt install ufw
sudo ufw enable

Libera acesso na rede para o KDEConnect

sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp

Libera acesso na rede para o Touch Portal

sudo ufw allow 12135/tcp

Libera acesso na rede para o Warpinator

sudo ufw allow 42000:42001/udp
sudo ufw allow 42000:42001/tcp


Ativação de repositórios extras (DebMultimedia)

O repositório DebMultimedia é um projeto não oficial que disponibiliza alguns pacotes relacionados com codecs e ferramentas de multimídia que não podem ser distribuídos oficialmente no Debian por limitações de licença, como o FFMPEG com suporte a aceleração de hardware Nvidia, por exemplo.

Trata-se de um repositório de terceiros, então, esteja ciente disso. O projeto DebMultimedia não oferece o componente CONTRIB em seus servidores.

wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb
sudo dpkg -i deb-multimedia-keyring_2024.9.1_all.deb

Conforme o padrão DEB822, o formato correto do arquivo sources deverá ser salvo em "/etc/apt/sources.list.d/dmo.sources" com o conteúdo abaixo.

Types: deb
URIs: https://www.deb-multimedia.org
Suites: trixie
Components: main non-free
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp
Enabled: yes

Opcionalmente você pode executar o comando abaixo para conferir se todas as entradas para repositórios já estão corretamente formatadas.

apt modernize-sources


Instalação drivers de vídeo proprietários Nvidia

Para poder utilizar programas que usam vídeo acelerado por hardware, além do driver proprietário também é necessário instalar os pacotes CUDA e suas bibliotecas. No Debian 13 atualmente apenas o driver 550 está disponível e ele não oferece todas as dependências necessárias para utilizar o Davinci Resolve.

Por isso, iremos utilizar os pacotes gerados pela própria NVIDIA para instalar a versão mais recente do driver, do CUDA e também das bibliotecas auxiliares.

Dependências importantes: Para garantir que os módulos do kernel sejam corretamente compilados, é recomendável que os pacotes abaixo estejam instalados.

apt install --no-install-recommends dkms libdw-dev clang lld llvm build-essential linux-headers-amd64 pipewire-audio-client-libraries

Por enquanto existem repositórios oficiais apenas para o Debian 12, mas os pacotes funcionam sem problemas no Bookworm (12) e Trixie (13).

wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

Se você usa sua máquina apenas para jogos, consumo de mídia e/ou edição de vídeo, instalar o pacote nvidia-open cobre todo o setup básico.

sudo apt -y install nvidia-open

Se você desenvolve aplicações CUDA ou precisa de outros recursos avançados para IA - é recomendável instalar o pacote CUDA-DRIVERS.

sudo apt -y install cuda-drivers cuda-toolkit

Para evitar problemas com "disputas" entre os pacotes do Debian e do repositório da NVIDIA, sugiro aumentar prioridade do repositório da NVIDIA. Isso vai informar ao sistema que caso os mesmos pacotes existam nas duas fontes, o repositório da NVIDIA sempre terá prioridade para ser instalado.

Crie um arquivo de configuração em "/etc/apt/preferences.d" com o seguinte conteúdo:

vim /etc/apt/preferences.d/nvidia-repo

Package: *  
Pin: origin https://developer.download.nvidia.com  
Pin-Priority: 900


Ativação do suporte a Flatpak no sistema

Pacotes necessários para ativar o suporte a pacotes flatpak no Debian e adicionar o repositório Flathub.

sudo apt install flatpak plasma-discover-backend-flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo


Preparação do ambiente para produtividade

A seleção de programas escolhidos neste roteiro, é a que utilizo em minha rotina de trabalho atual, então, remova ou adicione programas de acordo com sua necessidade.

Ferramentas gráficas: Gimp, Inskcape, Shotcut.

Canivete suíço de criação de conteúdo, tratamento de imagens, desenho vetorial e edição de vídeo usando software livre.

flatpak install org.gimp.GIMP com.obsproject.Studio \
org.inkscape.Inkscape org.shotcut.Shotcut


Navegadores web: Google Chrome, Microsoft Edge, Zen Browser e Firefox.

Eu deixo os principais navegadores instalados para que possa fazer diversos tipos de testes em sites e aplicativos web. Apenas o Chromium é instalado usando as versões do repositório do Debian.

flatpak install com.google.Chrome com.microsoft.Edge org.mozilla.firefox app.zen_browser.zen


Programas diversos: Handbrake, Video Trimmer, Celluloid, Boxes e outros.

Aqui listo vários programas auxiliares que utilizo diariamente, sugiro que daqui para baixo, ajuste conforme suas preferências.

flatpak install md.obsidian.Obsidian org.onlyoffice.desktopeditors \
com.usebottles.bottles com.github.tchx84.Flatseal org.gnome.Boxes \
io.missioncenter.MissionCenter com.dec05eba.gpu_screen_recorder \
fr.handbrake.ghb io.github.celluloid_player.Celluloid

sudo apt install vim btop fish gpm yt-dlp fonts-bebas-neue chromium aria2 \
gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad tmux


Instalação do Davinci Resolve Gratuito / Studio

Faça o download da versão adequada do Davinci Resolve no site oficial da Black Magic Design, em meu uso diário não tenho enfrentado nenhum problema com o instalador padrão.

As soluções abaixo são um compilado de anotações que acumulei ao longo dos anos usando o Davinci Resolve em diversas distros.

Warning

OBSERVAÇÃO IMPORTANTE: O Davinci Resolve 20.x e mais recentes exigem que a versão mínima do CUDA seja a 12.8, que está disponível apenas à partir do driver 570 da Nvidia.

Contornar erro de instalação "do pacote" Mesmo instalando os pacotes o instalador não inicia, o comando abaixo contorna essa situação e não afeta o funcionamento normal do Davinci Resolve. Lembre de alterar o nome do arquivo de instalação de acordo com a versão que você estiver instalando.

SKIP_PACKAGE_CHECK=1 ./DaVinci_Resolve_Studio_20.0b2_Linux.run

Dependências para o Davinci Resolve Em algumas instalações o Davinci Resolve não inicia devido a falta de dependências no sistema, uma das formas de corrigir este problema é conferir os pacotes abaixo estão instalados no Debian 13.

sudo apt install libxcb-composite0 libxcb-cursor0 libxcb-xinerama0 libxcb-xinput0 pkexec

Corrigir o erro com instalador gráfico do Resolve "libfuse2" Caso o instalador gráfico do Davinci Resolve não abra, execute ele via terminal para ver qual é a mensagem de erro. Caso apareça algo similar a "libfuse.so.2: cannot open shared object file" - use o comando abaixo para solucionar o problema.

apt install -y libfuse2

Resolver problemas com libs do Davinci Resolve" O pacote do Davinci Resolve incorpora uma série de bibliotecas que podem conflitar com as versões disponíveis em algumas distros Linux.

Existem formas diferentes de contornar esta situação caso ocorra com você, nesta página da Arch Wiki existem dicas que podem ser úteis. Em minhas instalações, geralmente apagar as libs abaixo já soluciona o problema do Davinci Resolve.

Warning

Sugiro que você faça um backup dos arquivos antes de removê-los do sistema.

O comando abaixo cria uma cópia das bibliotecas dentro da home do usuário resolvendo links simbólicos.

tar -cvhzf ~/backup-libs-resolve.tar.gz /opt/resolve/libs/libgmodule-2.0.so* /opt/resolve/libs/libglib-2.0.so* /opt/resolve/libs/libgio-2.0.so*

Agora é só apagar as bibliotecas. Muita atenção ao executar estes comandos, qualquer erro de digitação pode gerar uma quebra severa do sistema.

sudo rm /opt/resolve/libs/libgmodule-2.0.so*
sudo rm /opt/resolve/libs/libglib-2.0.so*
sudo rm /opt/resolve/libs/libgio-2.0.so*


Configurações extras para Jogos

Instala os pacotes flatpak necessários para a Steam e Heroic Games Launcher.

flatpak install com.valvesoftware.Steam com.valvesoftware.Steam.Utility.vkBasalt \
com.heroicgameslauncher.hgl com.github.Matoking.protontricks com.github.tchx84.Flatseal \
io.github.radiolamp.mangojuice org.vinegarhq.Sober

Se for necessário, utilizando o FlatSeal libere as permissões do pacote flatpak do Steam para acessar outras unidades de disco.

Remoção de pacotes desnecessários

Limpeza de pacotes que são instalados por padrão e que não utilizo em minha rotina.

sudo apt autoremove libreoffice-common \
akregator kontrast kmouth dragonplayer \
kmail juk xterm firefox-esr konqueror


Configurações ainda em testes

Note

Aqui começa a parte experimental do roteiro, são mudanças em relação ao meu ambiente padrão que estou validando.
Ativar o ZSWAP

Ativar o ZSWAP ou o ZRAM pode impactar no desempenho de diversas formas, o uso do ZRAM parece ser um consenso entre a maioria das distros. Ainda estou fazendo testes com esse recurso, em meu ambiente atualmente uso SystemD-Boot com ZSWAP ativo.

Parâmetros

zswap.enabled=1 quiet

Adicionar os parâmetros nas chaves correspondentes em:

vim /boot/efi/loader/entries/

Depois atualize o sistema e reinicie o computador.

bootctl update
Por ultimo adicione esses metodos installer no script:
#!/bin/bash
# name: Nala
# description: nala_desc
# version: 1.0
# icon: terminal.svg
# compat: ubuntu, debian
# repo: https://gitlab.com/volian/nala

# --- Start of the script code ---
source "$SCRIPT_DIR/libs/linuxtoys.lib"
# language
_lang_
source "$SCRIPT_DIR/libs/lang/${langfile}.lib"
sudo_rq
sudo apt install -y nala
#!/bin/bash
# name: Pacstall
# version: 1.0
# description: pacstall_desc
# icon: pacstall.png
# repo: https://pacstall.dev
# compat: debian, ubuntu

# --- Start of the script code ---
source "$SCRIPT_DIR/libs/linuxtoys.lib"
# language
_lang_
source "$SCRIPT_DIR/libs/lang/${langfile}.lib"
sudo_rq
sudo bash -c "$(wget -q https://pacstall.dev/q/install -O -)"
zeninf "$msg018"
Vc pode se basear nesse metodo para escrever coisas em arquivos: 
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
