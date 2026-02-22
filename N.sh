#!/bin/bash
set -e

STATE_DIR="/tmp/nixos_install_state"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

select_language() {
    while true; do
        clear
        echo "=== IDIOMA DO SISTEMA / SYSTEM LANGUAGE ==="
        echo "1) Português Brasileiro (pt_BR.UTF-8)"
        echo "2) English US (en_US.UTF-8)"
        read -p "Opção: " lang_opt
        case $lang_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
    esac
}

select_keyboard() {
    while true; do
        clear
        echo "=== LAYOUT DO TECLADO / KEYBOARD LAYOUT ==="
        echo "1) Português Brasileiro (br-abnt2)"
        echo "2) English US (us)"
        read -p "Opção: " kb_opt
        case $kb_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $kb_opt in
        1)
            echo "br-abnt2" > "$STATE_DIR/console_keymap"
            echo "br" > "$STATE_DIR/xkb_layout"
            echo "abnt2" > "$STATE_DIR/xkb_variant"
            ;;
        2)
            echo "us" > "$STATE_DIR/console_keymap"
            echo "us" > "$STATE_DIR/xkb_layout"
            echo "" > "$STATE_DIR/xkb_variant"
            ;;
    esac
}

select_timezone() {
    while true; do
        clear
        echo "=== FUSO HORÁRIO / TIMEZONE ==="
        echo "1) America/Sao_Paulo"
        echo "2) America/New_York"
        read -p "Opção: " tz_opt
        case $tz_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $tz_opt in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) echo "America/New_York" > "$STATE_DIR/timezone" ;;
    esac
}

select_hostname() {
    clear
    read -p "Digite o nome do computador [nixos]: " hostname
    if [ -z "$hostname" ]; then
        echo "nixos" > "$STATE_DIR/hostname"
    else
        echo "$hostname" > "$STATE_DIR/hostname"
    fi
}

select_device_type() {
    while true; do
        clear
        echo "=== TIPO DE DISPOSITIVO / DEVICE TYPE ==="
        echo "1) Laptop (economia de energia)"
        echo "2) Desktop (desempenho máximo)"
        read -p "Opção: " device_opt
        case $device_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $device_opt in
        1) echo "laptop" > "$STATE_DIR/device_type" ;;
        2) echo "desktop" > "$STATE_DIR/device_type" ;;
    esac
}

select_filesystem() {
    while true; do
        clear
        echo "=== SISTEMA DE ARQUIVOS / FILESYSTEM ==="
        echo "1) ext4 (estável, simples)"
        echo "2) btrfs (com snapshots e compressão zstd)"
        read -p "Opção: " fs_opt
        case $fs_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $fs_opt in
        1) echo "ext4" > "$STATE_DIR/filesystem" ;;
        2) echo "btrfs" > "$STATE_DIR/filesystem" ;;
    esac
}

select_bootloader() {
    while true; do
        clear
        echo "=== BOOTLOADER ==="
        echo "1) systemd-boot (recomendado para UEFI)"
        echo "2) GRUB (compatível com BIOS e UEFI)"
        read -p "Opção: " bl_opt
        case $bl_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $bl_opt in
        1) echo "systemd-boot" > "$STATE_DIR/bootloader" ;;
        2) echo "grub" > "$STATE_DIR/bootloader" ;;
    esac
}

select_kernel() {
    while true; do
        clear
        echo "=== KERNEL / KERNEL ==="
        echo "1) Linux Latest (padrão, versão mais recente)"
        echo "2) Linux Liquorix (otimizado para desempenho, lqx)"
        read -p "Opção: " kernel_opt
        case $kernel_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $kernel_opt in
        1) echo "latest" > "$STATE_DIR/kernel" ;;
        2) echo "lqx" > "$STATE_DIR/kernel" ;;
    esac
}

select_gpu_drivers() {
    while true; do
        clear
        echo "=== DRIVERS DE GPU / GPU DRIVERS ==="
        echo "1) NVIDIA (proprietário - módulos open para Turing+)"
        echo "2) Intel/AMD (open source - padrão)"
        read -p "Opção: " gpu_opt
        case $gpu_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $gpu_opt in
        1) echo "nvidia" > "$STATE_DIR/gpu_driver" ;;
        2) echo "intel-amd" > "$STATE_DIR/gpu_driver" ;;
    esac
}

select_desktop() {
    while true; do
        clear
        echo "=== AMBIENTE DESKTOP / DESKTOP ENVIRONMENT ==="
        echo "1) COSMIC (minimal, Wayland nativo)"
        echo "2) GNOME (minimal, Wayland)"
        echo "3) KDE Plasma (minimal, Wayland)"
        echo "4) Hyprland (Wayland tiling)"
        echo "5) Nenhum (apenas terminal)"
        read -p "Opção: " de_opt
        case $de_opt in
            1|2|3|4|5) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "hyprland" > "$STATE_DIR/desktop" ;;
        5) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_bluetooth() {
    clear
    echo "=== BLUETOOTH ==="
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    clear
    echo "=== IMPRESSÃO (CUPS) / PRINTING (CUPS) ==="
    if confirm "Habilitar suporte a impressão?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_ssd_trim() {
    clear
    echo "=== TRIM PARA SSD ==="
    if confirm "Habilitar TRIM para SSD?"; then
        echo "yes" > "$STATE_DIR/trim"
    else
        echo "no" > "$STATE_DIR/trim"
    fi
}

select_encryption() {
    clear
    echo "=== CRIPTOGRAFIA / ENCRYPTION ==="
    if confirm "Criptografar disco com LUKS?"; then
        echo "yes" > "$STATE_DIR/encryption"
    else
        echo "no" > "$STATE_DIR/encryption"
    fi
}

select_firewall() {
    clear
    echo "=== FIREWALL ==="
    echo "Habilitar firewall? (recomendado para segurança)"
    echo "- Com firewall ativado, portas e serviços ficam restritos"
    echo "- É possível liberar portas específicas depois na configuração"
    echo
    if confirm "Habilitar firewall?"; then
        echo "true" > "$STATE_DIR/firewall"
    else
        echo "false" > "$STATE_DIR/firewall"
    fi
}

select_recommended_config() {
    clear
    echo "=== CONFIGURAÇÕES RECOMENDADAS / RECOMMENDED SETTINGS ==="
    echo "Aplicar configurações otimizadas de desempenho e sistema?"
    echo "- Kernel otimizado (BBR, sysctl, parâmetros)"
    echo "- earlyOOM para evitar travamentos"
    echo "- ananicy para priorização de processos"
    echo "- Gerenciamento de memória otimizado"
    echo "- Regras udev para dispositivos"
    echo
    if confirm "Aplicar configurações recomendadas?"; then
        echo "yes" > "$STATE_DIR/recommended"
    else
        echo "no" > "$STATE_DIR/recommended"
    fi
}

toggle_all_packages() {
    local page=$1
    local action=$2
    local packages_file="$STATE_DIR/packages"
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    if [ "$action" = "select" ]; then
        case $page in
            1)
                for num in {1..15}; do
                    case $num in
                        1) pkg="org.mozilla.firefox"; type="flatpak" ;;
                        2) pkg="org.libreoffice.LibreOffice"; type="flatpak" ;;
                        3) pkg="org.gimp.GIMP"; type="flatpak" ;;
                        4) pkg="org.inkscape.Inkscape"; type="flatpak" ;;
                        5) pkg="org.blender.Blender"; type="flatpak" ;;
                        6) pkg="org.kde.kdenlive"; type="flatpak" ;;
                        7) pkg="org.kde.krita"; type="flatpak" ;;
                        8) pkg="org.audacityteam.Audacity"; type="flatpak" ;;
                        9) pkg="fr.handbrake.ghb"; type="flatpak" ;;
                        10) pkg="com.obsproject.Studio"; type="flatpak" ;;
                        11) pkg="org.godotengine.Godot"; type="flatpak" ;;
                        12) pkg="org.kicad.KiCad"; type="flatpak" ;;
                        13) pkg="org.freecad.FreeCAD"; type="flatpak" ;;
                        14) pkg="org.darktable.Darktable"; type="flatpak" ;;
                        15) pkg="org.stellarium.Stellarium"; type="flatpak" ;;
                    esac
                    
                    if [ "$type" = "flatpak" ] && ! grep -q "$pkg" "$packages_file" 2>/dev/null; then
                        echo "$pkg" >> "$packages_file"
                    fi
                done
                
                for num in {16..30}; do
                    case $num in
                        16) pkg="vim"; type="nixpkgs" ;;
                        17) pkg="git"; type="nixpkgs" ;;
                        18) pkg="curl"; type="nixpkgs" ;;
                        19) pkg="wget"; type="nixpkgs" ;;
                        20) pkg="htop"; type="nixpkgs" ;;
                        21) pkg="btop"; type="nixpkgs" ;;
                        22) pkg="fastfetch"; type="nixpkgs" ;;
                        23) pkg="neofetch"; type="nixpkgs" ;;
                        24) pkg="bat"; type="nixpkgs" ;;
                        25) pkg="eza"; type="nixpkgs" ;;
                        26) pkg="fd"; type="nixpkgs" ;;
                        27) pkg="ripgrep"; type="nixpkgs" ;;
                        28) pkg="jq"; type="nixpkgs" ;;
                        29) pkg="fzf"; type="nixpkgs" ;;
                        30) pkg="zoxide"; type="nixpkgs" ;;
                    esac
                    
                    if [ "$type" = "nixpkgs" ] && ! grep -q "$pkg" "$nixpkgs_file" 2>/dev/null; then
                        echo "$pkg" >> "$nixpkgs_file"
                    fi
                done
                ;;
            2)
                for num in {1..15}; do
                    case $num in
                        1) pkg="org.telegram.desktop"; type="flatpak" ;;
                        2) pkg="org.signal.Signal"; type="flatpak" ;;
                        3) pkg="com.discordapp.Discord"; type="flatpak" ;;
                        4) pkg="com.slack.Slack"; type="flatpak" ;;
                        5) pkg="com.rtosta.zapzap"; type="flatpak" ;;
                        6) pkg="com.github.IsmaelMartinez.teams_for_linux"; type="flatpak" ;;
                        7) pkg="com.visualstudio.code"; type="flatpak" ;;
                        8) pkg="com.vscodium.codium"; type="flatpak" ;;
                        9) pkg="dev.zed.Zed"; type="flatpak" ;;
                        10) pkg="com.sublimehq.SublimeText"; type="flatpak" ;;
                        11) pkg="md.obsidian.Obsidian"; type="flatpak" ;;
                        12) pkg="org.onlyoffice.desktopeditors"; type="flatpak" ;;
                        13) pkg="com.google.Chrome"; type="flatpak" ;;
                        14) pkg="app.zen_browser.zen"; type="flatpak" ;;
                        15) pkg="com.bitwarden.desktop"; type="flatpak" ;;
                    esac
                    
                    if [ "$type" = "flatpak" ] && ! grep -q "$pkg" "$packages_file" 2>/dev/null; then
                        echo "$pkg" >> "$packages_file"
                    fi
                done
                
                for num in {16..30}; do
                    case $num in
                        16) pkg="fish"; type="nixpkgs" ;;
                        17) pkg="zsh"; type="nixpkgs" ;;
                        18) pkg="starship"; type="nixpkgs" ;;
                        19) pkg="tealdeer"; type="nixpkgs" ;;
                        20) pkg="openssh"; type="nixpkgs" ;;
                        21) pkg="openvpn"; type="nixpkgs" ;;
                        22) pkg="wireguard-tools"; type="nixpkgs" ;;
                        23) pkg="tailscale"; type="nixpkgs" ;;
                        24) pkg="zerotierone"; type="nixpkgs" ;;
                        25) pkg="podman"; type="nixpkgs" ;;
                        26) pkg="distrobox"; type="nixpkgs" ;;
                        27) pkg="gamemode"; type="nixpkgs" ;;
                        28) pkg="gamescope"; type="nixpkgs" ;;
                        29) pkg="mangohud"; type="nixpkgs" ;;
                        30) pkg="goverlay"; type="nixpkgs" ;;
                    esac
                    
                    if [ "$type" = "nixpkgs" ] && ! grep -q "$pkg" "$nixpkgs_file" 2>/dev/null; then
                        echo "$pkg" >> "$nixpkgs_file"
                    fi
                done
                ;;
            3)
                for num in {1..15}; do
                    case $num in
                        1) pkg="org.gnome.Boxes"; type="flatpak" ;;
                        2) pkg="org.cockpit_project.CockpitClient"; type="flatpak" ;;
                        3) pkg="com.mattjakeman.ExtensionManager"; type="flatpak" ;;
                        4) pkg="org.gnome.World.PikaBackup"; type="flatpak" ;;
                        5) pkg="org.localsend.localsend_app"; type="flatpak" ;;
                        6) pkg="io.github.peazip.PeaZip"; type="flatpak" ;;
                        7) pkg="it.mijorus.gearlever"; type="flatpak" ;;
                        8) pkg="com.github.johnfactotum.Foliate"; type="flatpak" ;;
                        9) pkg="org.endlessos.Key"; type="flatpak" ;;
                        10) pkg="org.kde.gcompris"; type="flatpak" ;;
                        11) pkg="org.geogebra.GeoGebra"; type="flatpak" ;;
                        12) pkg="org.kde.kalzium"; type="flatpak" ;;
                        13) pkg="org.learningequality.Kolibri"; type="flatpak" ;;
                        14) pkg="com.google.AndroidStudio"; type="flatpak" ;;
                        15) pkg="com.termius.Termius"; type="flatpak" ;;
                    esac
                    
                    if [ "$type" = "flatpak" ] && ! grep -q "$pkg" "$packages_file" 2>/dev/null; then
                        echo "$pkg" >> "$packages_file"
                    fi
                done
                
                for num in {16..30}; do
                    case $num in
                        16) pkg="ollama"; type="nixpkgs" ;;
                        17) pkg="n8n"; type="nixpkgs" ;;
                        18) pkg="cockpit"; type="nixpkgs" ;;
                        19) pkg="forgejo"; type="nixpkgs" ;;
                        20) pkg="maven"; type="nixpkgs" ;;
                        21) pkg="timeshift"; type="nixpkgs" ;;
                        22) pkg="snapper"; type="nixpkgs" ;;
                        23) pkg="alacritty"; type="nixpkgs" ;;
                        24) pkg="pyenv"; type="nixpkgs" ;;
                        25) pkg="davinci-resolve"; type="nixpkgs" ;;
                        26) pkg="stirling-pdf"; type="nixpkgs" ;;
                        27) pkg="figma-linux"; type="nixpkgs" ;;
                        28) pkg="smartmontools"; type="nixpkgs" ;;
                        29) pkg="f3"; type="nixpkgs" ;;
                        30) pkg="rustup"; type="nixpkgs" ;;
                    esac
                    
                    if [ "$type" = "nixpkgs" ] && ! grep -q "$pkg" "$nixpkgs_file" 2>/dev/null; then
                        echo "$pkg" >> "$nixpkgs_file"
                    fi
                done
                ;;
            4)
                for num in {1..15}; do
                    case $num in
                        1) pkg="org.kde.kalendar"; type="flatpak" ;;
                        2) pkg="com.github.Matoking.protontricks"; type="flatpak" ;;
                        3) pkg="net.lutris.Lutris"; type="flatpak" ;;
                        4) pkg="org.prismlauncher.PrismLauncher"; type="flatpak" ;;
                        5) pkg="com.heroicgameslauncher.hgl"; type="flatpak" ;;
                        6) pkg="net.shadps4.shadPS4"; type="flatpak" ;;
                        7) pkg="sh.ppy.osu"; type="flatpak" ;;
                        8) pkg="org.vinegarhq.Sober"; type="flatpak" ;;
                        9) pkg="org.vinegarhq.Vinegar"; type="flatpak" ;;
                        10) pkg="io.github.Faugus.faugus-launcher"; type="flatpak" ;;
                        11) pkg="com.dec05eba.gpu_screen_recorder"; type="flatpak" ;;
                        12) pkg="com.moonlight_stream.Moonlight"; type="flatpak" ;;
                        13) pkg="io.github.hmlendea.geforcenow-electron"; type="flatpak" ;;
                        14) pkg="io.github.unknownskl.greenlight"; type="flatpak" ;;
                        15) pkg="io.github.wivrn.wivrn"; type="flatpak" ;;
                    esac
                    
                    if [ "$type" = "flatpak" ] && ! grep -q "$pkg" "$packages_file" 2>/dev/null; then
                        echo "$pkg" >> "$packages_file"
                    fi
                done
                
                for num in {16..30}; do
                    case $num in
                        16) pkg="waydroid"; type="nixpkgs" ;;
                        17) pkg="winboat"; type="nixpkgs" ;;
                        18) pkg="ryubing"; type="nixpkgs" ;;
                        19) pkg="yt-dlp"; type="nixpkgs" ;;
                        20) pkg="aria2"; type="nixpkgs" ;;
                        21) pkg="ffmpegthumbnailer"; type="nixpkgs" ;;
                        22) pkg="btrfs-assistant"; type="nixpkgs" ;;
                        23) pkg="dnsmasq"; type="nixpkgs" ;;
                        24) pkg="neovim"; type="nixpkgs" ;;
                        25) pkg="vimPlugins.LazyVim"; type="nixpkgs" ;;
                        26) pkg="p7zip"; type="nixpkgs" ;;
                        27) pkg="gnutar"; type="nixpkgs" ;;
                        28) pkg="libarchive"; type="nixpkgs" ;;
                        29) pkg="unrar"; type="nixpkgs" ;;
                        30) pkg="unar"; type="nixpkgs" ;;
                    esac
                    
                    if [ "$type" = "nixpkgs" ] && ! grep -q "$pkg" "$nixpkgs_file" 2>/dev/null; then
                        echo "$pkg" >> "$nixpkgs_file"
                    fi
                done
                ;;
        esac
    fi
}

select_packages_page1() {
    local packages_file="$STATE_DIR/packages"
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    while true; do
        clear
        echo "=== SELEÇÃO DE PACOTES - PÁGINA 1/4 ==="
        echo "Digite o número do pacote para marcar/desmarcar, N próxima, T selecionar todos, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (15):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.mozilla.firefox"; then echo "[X]"; else echo "[ ]"; fi) Firefox (Navegador web)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.libreoffice.LibreOffice"; then echo "[X]"; else echo "[ ]"; fi) LibreOffice (Suíte de escritório)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.gimp.GIMP"; then echo "[X]"; else echo "[ ]"; fi) GIMP (Editor de imagens)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.inkscape.Inkscape"; then echo "[X]"; else echo "[ ]"; fi) Inkscape (Vetorial)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.blender.Blender"; then echo "[X]"; else echo "[ ]"; fi) Blender (Modelagem 3D)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.kdenlive"; then echo "[X]"; else echo "[ ]"; fi) Kdenlive (Editor de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.krita"; then echo "[X]"; else echo "[ ]"; fi) Krita (Pintura digital)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.audacityteam.Audacity"; then echo "[X]"; else echo "[ ]"; fi) Audacity (Editor de áudio)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "fr.handbrake.ghb"; then echo "[X]"; else echo "[ ]"; fi) HandBrake (Conversor de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.obsproject.Studio"; then echo "[X]"; else echo "[ ]"; fi) OBS Studio (Captura e transmissão)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.godotengine.Godot"; then echo "[X]"; else echo "[ ]"; fi) Godot Engine (Game engine)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kicad.KiCad"; then echo "[X]"; else echo "[ ]"; fi) KiCad (EDA)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.freecad.FreeCAD"; then echo "[X]"; else echo "[ ]"; fi) FreeCAD (Modelagem CAD)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.darktable.Darktable"; then echo "[X]"; else echo "[ ]"; fi) Darktable (Revelação RAW)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.stellarium.Stellarium"; then echo "[X]"; else echo "[ ]"; fi) Stellarium (Planetário)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (15):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "vim"; then echo "[X]"; else echo "[ ]"; fi) Vim (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "git"; then echo "[X]"; else echo "[ ]"; fi) Git (Controle de versão)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "curl"; then echo "[X]"; else echo "[ ]"; fi) Curl (Transferência de dados)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "wget"; then echo "[X]"; else echo "[ ]"; fi) Wget (Download)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "htop"; then echo "[X]"; else echo "[ ]"; fi) Htop (Monitor do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "btop"; then echo "[X]"; else echo "[ ]"; fi) Btop (Monitor do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "fastfetch"; then echo "[X]"; else echo "[ ]"; fi) Fastfetch (Info do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "neofetch"; then echo "[X]"; else echo "[ ]"; fi) Neofetch (Info do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "bat"; then echo "[X]"; else echo "[ ]"; fi) Bat (Visualizador de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "eza"; then echo "[X]"; else echo "[ ]"; fi) Eza (Listagem de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "fd"; then echo "[X]"; else echo "[ ]"; fi) Fd (Busca de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ripgrep"; then echo "[X]"; else echo "[ ]"; fi) Ripgrep (Busca em arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "jq"; then echo "[X]"; else echo "[ ]"; fi) Jq (Processador JSON)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "fzf"; then echo "[X]"; else echo "[ ]"; fi) Fzf (Buscador fuzzy)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "zoxide"; then echo "[X]"; else echo "[ ]"; fi) Zoxide (Navegação por diretórios)"
        i=$((i+1))
        
        echo
        read -p "Opção: " choice
        
        if [ "$choice" = "0" ]; then
            return 0
        elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
            select_packages_page2
            return $?
        elif [ "$choice" = "T" ] || [ "$choice" = "t" ]; then
            toggle_all_packages 1 "select"
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="org.mozilla.firefox"; type="flatpak" ;;
                2) pkg="org.libreoffice.LibreOffice"; type="flatpak" ;;
                3) pkg="org.gimp.GIMP"; type="flatpak" ;;
                4) pkg="org.inkscape.Inkscape"; type="flatpak" ;;
                5) pkg="org.blender.Blender"; type="flatpak" ;;
                6) pkg="org.kde.kdenlive"; type="flatpak" ;;
                7) pkg="org.kde.krita"; type="flatpak" ;;
                8) pkg="org.audacityteam.Audacity"; type="flatpak" ;;
                9) pkg="fr.handbrake.ghb"; type="flatpak" ;;
                10) pkg="com.obsproject.Studio"; type="flatpak" ;;
                11) pkg="org.godotengine.Godot"; type="flatpak" ;;
                12) pkg="org.kicad.KiCad"; type="flatpak" ;;
                13) pkg="org.freecad.FreeCAD"; type="flatpak" ;;
                14) pkg="org.darktable.Darktable"; type="flatpak" ;;
                15) pkg="org.stellarium.Stellarium"; type="flatpak" ;;
                16) pkg="vim"; type="nixpkgs" ;;
                17) pkg="git"; type="nixpkgs" ;;
                18) pkg="curl"; type="nixpkgs" ;;
                19) pkg="wget"; type="nixpkgs" ;;
                20) pkg="htop"; type="nixpkgs" ;;
                21) pkg="btop"; type="nixpkgs" ;;
                22) pkg="fastfetch"; type="nixpkgs" ;;
                23) pkg="neofetch"; type="nixpkgs" ;;
                24) pkg="bat"; type="nixpkgs" ;;
                25) pkg="eza"; type="nixpkgs" ;;
                26) pkg="fd"; type="nixpkgs" ;;
                27) pkg="ripgrep"; type="nixpkgs" ;;
                28) pkg="jq"; type="nixpkgs" ;;
                29) pkg="fzf"; type="nixpkgs" ;;
                30) pkg="zoxide"; type="nixpkgs" ;;
                *) continue ;;
            esac
            
            local temp_file=$(mktemp)
            
            if [ "$type" = "flatpak" ]; then
                if cat "$packages_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$packages_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$packages_file"
                else
                    echo "$pkg" >> "$packages_file"
                fi
            else
                if cat "$nixpkgs_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$nixpkgs_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$nixpkgs_file"
                else
                    echo "$pkg" >> "$nixpkgs_file"
                fi
            fi
            rm -f "$temp_file"
        fi
    done
}

select_packages_page2() {
    local packages_file="$STATE_DIR/packages"
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    while true; do
        clear
        echo "=== SELEÇÃO DE PACOTES - PÁGINA 2/4 ==="
        echo "Digite o número do pacote para marcar/desmarcar, P anterior, N próxima, T selecionar todos, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (15):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.telegram.desktop"; then echo "[X]"; else echo "[ ]"; fi) Telegram (Mensageiro)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.signal.Signal"; then echo "[X]"; else echo "[ ]"; fi) Signal (Mensageiro seguro)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.discordapp.Discord"; then echo "[X]"; else echo "[ ]"; fi) Discord (Chat e voz)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.slack.Slack"; then echo "[X]"; else echo "[ ]"; fi) Slack (Comunicação)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.rtosta.zapzap"; then echo "[X]"; else echo "[ ]"; fi) ZapZap (WhatsApp desktop)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.github.IsmaelMartinez.teams_for_linux"; then echo "[X]"; else echo "[ ]"; fi) Teams for Linux (Comunicação)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.visualstudio.code"; then echo "[X]"; else echo "[ ]"; fi) VS Code (Editor de código)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.vscodium.codium"; then echo "[X]"; else echo "[ ]"; fi) VSCodium (Editor de código open-source)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "dev.zed.Zed"; then echo "[X]"; else echo "[ ]"; fi) Zed (Editor de código)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.sublimehq.SublimeText"; then echo "[X]"; else echo "[ ]"; fi) Sublime Text (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "md.obsidian.Obsidian"; then echo "[X]"; else echo "[ ]"; fi) Obsidian (Editor de notas)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.onlyoffice.desktopeditors"; then echo "[X]"; else echo "[ ]"; fi) OnlyOffice (Suíte de escritório)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.google.Chrome"; then echo "[X]"; else echo "[ ]"; fi) Google Chrome (Navegador web)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "app.zen_browser.zen"; then echo "[X]"; else echo "[ ]"; fi) Zen Browser (Navegador web)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.bitwarden.desktop"; then echo "[X]"; else echo "[ ]"; fi) Bitwarden (Gerenciador de senhas)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (15):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "fish"; then echo "[X]"; else echo "[ ]"; fi) Fish (Shell)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "zsh"; then echo "[X]"; else echo "[ ]"; fi) Zsh (Shell)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "starship"; then echo "[X]"; else echo "[ ]"; fi) Starship (Prompt personalizável)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "tealdeer"; then echo "[X]"; else echo "[ ]"; fi) Tealdeer (Man pages simplificadas)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "openssh"; then echo "[X]"; else echo "[ ]"; fi) OpenSSH (Servidor SSH)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "openvpn"; then echo "[X]"; else echo "[ ]"; fi) OpenVPN (VPN)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "wireguard-tools"; then echo "[X]"; else echo "[ ]"; fi) WireGuard Tools (VPN)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "tailscale"; then echo "[X]"; else echo "[ ]"; fi) Tailscale (VPN mesh)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "zerotierone"; then echo "[X]"; else echo "[ ]"; fi) ZeroTier One (VPN)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "podman"; then echo "[X]"; else echo "[ ]"; fi) Podman (Gerenciador de containers)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "distrobox"; then echo "[X]"; else echo "[ ]"; fi) Distrobox (Containers de distribuições)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "gamemode"; then echo "[X]"; else echo "[ ]"; fi) Gamemode (Otimização de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "gamescope"; then echo "[X]"; else echo "[ ]"; fi) Gamescope (Micro-compositor para jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "mangohud"; then echo "[X]"; else echo "[ ]"; fi) MangoHud (Overlay de desempenho)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "goverlay"; then echo "[X]"; else echo "[ ]"; fi) GOverlay (Configuração do MangoHud)"
        i=$((i+1))
        
        echo
        read -p "Opção: " choice
        
        if [ "$choice" = "0" ]; then
            return 0
        elif [ "$choice" = "P" ] || [ "$choice" = "p" ]; then
            select_packages_page1
            return $?
        elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
            select_packages_page3
            return $?
        elif [ "$choice" = "T" ] || [ "$choice" = "t" ]; then
            toggle_all_packages 2 "select"
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="org.telegram.desktop"; type="flatpak" ;;
                2) pkg="org.signal.Signal"; type="flatpak" ;;
                3) pkg="com.discordapp.Discord"; type="flatpak" ;;
                4) pkg="com.slack.Slack"; type="flatpak" ;;
                5) pkg="com.rtosta.zapzap"; type="flatpak" ;;
                6) pkg="com.github.IsmaelMartinez.teams_for_linux"; type="flatpak" ;;
                7) pkg="com.visualstudio.code"; type="flatpak" ;;
                8) pkg="com.vscodium.codium"; type="flatpak" ;;
                9) pkg="dev.zed.Zed"; type="flatpak" ;;
                10) pkg="com.sublimehq.SublimeText"; type="flatpak" ;;
                11) pkg="md.obsidian.Obsidian"; type="flatpak" ;;
                12) pkg="org.onlyoffice.desktopeditors"; type="flatpak" ;;
                13) pkg="com.google.Chrome"; type="flatpak" ;;
                14) pkg="app.zen_browser.zen"; type="flatpak" ;;
                15) pkg="com.bitwarden.desktop"; type="flatpak" ;;
                16) pkg="fish"; type="nixpkgs" ;;
                17) pkg="zsh"; type="nixpkgs" ;;
                18) pkg="starship"; type="nixpkgs" ;;
                19) pkg="tealdeer"; type="nixpkgs" ;;
                20) pkg="openssh"; type="nixpkgs" ;;
                21) pkg="openvpn"; type="nixpkgs" ;;
                22) pkg="wireguard-tools"; type="nixpkgs" ;;
                23) pkg="tailscale"; type="nixpkgs" ;;
                24) pkg="zerotierone"; type="nixpkgs" ;;
                25) pkg="podman"; type="nixpkgs" ;;
                26) pkg="distrobox"; type="nixpkgs" ;;
                27) pkg="gamemode"; type="nixpkgs" ;;
                28) pkg="gamescope"; type="nixpkgs" ;;
                29) pkg="mangohud"; type="nixpkgs" ;;
                30) pkg="goverlay"; type="nixpkgs" ;;
                *) continue ;;
            esac
            
            local temp_file=$(mktemp)
            
            if [ "$type" = "flatpak" ]; then
                if cat "$packages_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$packages_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$packages_file"
                else
                    echo "$pkg" >> "$packages_file"
                fi
            else
                if cat "$nixpkgs_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$nixpkgs_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$nixpkgs_file"
                else
                    echo "$pkg" >> "$nixpkgs_file"
                fi
            fi
            rm -f "$temp_file"
        fi
    done
}

select_packages_page3() {
    local packages_file="$STATE_DIR/packages"
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    while true; do
        clear
        echo "=== SELEÇÃO DE PACOTES - PÁGINA 3/4 ==="
        echo "Digite o número do pacote para marcar/desmarcar, P anterior, N próxima, T selecionar todos, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (15):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.gnome.Boxes"; then echo "[X]"; else echo "[ ]"; fi) GNOME Boxes (Virtualização)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.cockpit_project.CockpitClient"; then echo "[X]"; else echo "[ ]"; fi) Cockpit Client (Gerenciamento de servidores)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.mattjakeman.ExtensionManager"; then echo "[X]"; else echo "[ ]"; fi) Extension Manager (GNOME)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.gnome.World.PikaBackup"; then echo "[X]"; else echo "[ ]"; fi) Pika Backup (Backups)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.localsend.localsend_app"; then echo "[X]"; else echo "[ ]"; fi) LocalSend (Compartilhamento de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.peazip.PeaZip"; then echo "[X]"; else echo "[ ]"; fi) PeaZip (Compactador de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "it.mijorus.gearlever"; then echo "[X]"; else echo "[ ]"; fi) Gear Lever (Gerenciador de AppImage)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.github.johnfactotum.Foliate"; then echo "[X]"; else echo "[ ]"; fi) Foliate (Leitor de e-books)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.endlessos.Key"; then echo "[X]"; else echo "[ ]"; fi) Endless Key (Educação offline)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.gcompris"; then echo "[X]"; else echo "[ ]"; fi) GCompris (Educação infantil)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.geogebra.GeoGebra"; then echo "[X]"; else echo "[ ]"; fi) GeoGebra (Matemática interativa)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.kalzium"; then echo "[X]"; else echo "[ ]"; fi) Kalzium (Química)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.learningequality.Kolibri"; then echo "[X]"; else echo "[ ]"; fi) Kolibri (Educação offline)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.google.AndroidStudio"; then echo "[X]"; else echo "[ ]"; fi) Android Studio (IDE Android)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.termius.Termius"; then echo "[X]"; else echo "[ ]"; fi) Termius (Cliente SSH)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (15):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ollama"; then echo "[X]"; else echo "[ ]"; fi) Ollama (Execução de modelos LLM)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "n8n"; then echo "[X]"; else echo "[ ]"; fi) n8n (Automação de workflows)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "cockpit"; then echo "[X]"; else echo "[ ]"; fi) Cockpit (Gerenciamento de servidores)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "forgejo"; then echo "[X]"; else echo "[ ]"; fi) Forgejo (Plataforma Git)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "maven"; then echo "[X]"; else echo "[ ]"; fi) Maven (Gerenciador de build Java)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "timeshift"; then echo "[X]"; else echo "[ ]"; fi) Timeshift (Backup do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "snapper"; then echo "[X]"; else echo "[ ]"; fi) Snapper (Gerenciador de snapshots)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "alacritty"; then echo "[X]"; else echo "[ ]"; fi) Alacritty (Terminal GPU)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "pyenv"; then echo "[X]"; else echo "[ ]"; fi) Pyenv (Gerenciador de versões Python)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "davinci-resolve"; then echo "[X]"; else echo "[ ]"; fi) DaVinci Resolve (Edição de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "stirling-pdf"; then echo "[X]"; else echo "[ ]"; fi) Stirling PDF (Manipulação de PDF)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "figma-linux"; then echo "[X]"; else echo "[ ]"; fi) Figma (Design de interface)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "smartmontools"; then echo "[X]"; else echo "[ ]"; fi) Smartmontools (Monitoramento de disco)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "f3"; then echo "[X]"; else echo "[ ]"; fi) F3 (Teste de integridade de flash)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "rustup"; then echo "[X]"; else echo "[ ]"; fi) Rustup (Gerenciador Rust)"
        i=$((i+1))
        
        echo
        read -p "Opção: " choice
        
        if [ "$choice" = "0" ]; then
            return 0
        elif [ "$choice" = "P" ] || [ "$choice" = "p" ]; then
            select_packages_page2
            return $?
        elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
            select_packages_page4
            return $?
        elif [ "$choice" = "T" ] || [ "$choice" = "t" ]; then
            toggle_all_packages 3 "select"
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="org.gnome.Boxes"; type="flatpak" ;;
                2) pkg="org.cockpit_project.CockpitClient"; type="flatpak" ;;
                3) pkg="com.mattjakeman.ExtensionManager"; type="flatpak" ;;
                4) pkg="org.gnome.World.PikaBackup"; type="flatpak" ;;
                5) pkg="org.localsend.localsend_app"; type="flatpak" ;;
                6) pkg="io.github.peazip.PeaZip"; type="flatpak" ;;
                7) pkg="it.mijorus.gearlever"; type="flatpak" ;;
                8) pkg="com.github.johnfactotum.Foliate"; type="flatpak" ;;
                9) pkg="org.endlessos.Key"; type="flatpak" ;;
                10) pkg="org.kde.gcompris"; type="flatpak" ;;
                11) pkg="org.geogebra.GeoGebra"; type="flatpak" ;;
                12) pkg="org.kde.kalzium"; type="flatpak" ;;
                13) pkg="org.learningequality.Kolibri"; type="flatpak" ;;
                14) pkg="com.google.AndroidStudio"; type="flatpak" ;;
                15) pkg="com.termius.Termius"; type="flatpak" ;;
                16) pkg="ollama"; type="nixpkgs" ;;
                17) pkg="n8n"; type="nixpkgs" ;;
                18) pkg="cockpit"; type="nixpkgs" ;;
                19) pkg="forgejo"; type="nixpkgs" ;;
                20) pkg="maven"; type="nixpkgs" ;;
                21) pkg="timeshift"; type="nixpkgs" ;;
                22) pkg="snapper"; type="nixpkgs" ;;
                23) pkg="alacritty"; type="nixpkgs" ;;
                24) pkg="pyenv"; type="nixpkgs" ;;
                25) pkg="davinci-resolve"; type="nixpkgs" ;;
                26) pkg="stirling-pdf"; type="nixpkgs" ;;
                27) pkg="figma-linux"; type="nixpkgs" ;;
                28) pkg="smartmontools"; type="nixpkgs" ;;
                29) pkg="f3"; type="nixpkgs" ;;
                30) pkg="rustup"; type="nixpkgs" ;;
                *) continue ;;
            esac
            
            local temp_file=$(mktemp)
            
            if [ "$type" = "flatpak" ]; then
                if cat "$packages_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$packages_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$packages_file"
                else
                    echo "$pkg" >> "$packages_file"
                fi
            else
                if cat "$nixpkgs_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$nixpkgs_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$nixpkgs_file"
                else
                    echo "$pkg" >> "$nixpkgs_file"
                fi
            fi
            rm -f "$temp_file"
        fi
    done
}

select_packages_page4() {
    local packages_file="$STATE_DIR/packages"
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    while true; do
        clear
        echo "=== SELEÇÃO DE PACOTES - PÁGINA 4/4 ==="
        echo "Digite o número do pacote para marcar/desmarcar, P anterior, T selecionar todos, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (15):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.kalendar"; then echo "[X]"; else echo "[ ]"; fi) Kalendar (Calendário)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.github.Matoking.protontricks"; then echo "[X]"; else echo "[ ]"; fi) Protontricks (Ferramentas Proton)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "net.lutris.Lutris"; then echo "[X]"; else echo "[ ]"; fi) Lutris (Gerenciador de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.prismlauncher.PrismLauncher"; then echo "[X]"; else echo "[ ]"; fi) Prism Launcher (Minecraft)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.heroicgameslauncher.hgl"; then echo "[X]"; else echo "[ ]"; fi) Heroic Games Launcher (Jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "net.shadps4.shadPS4"; then echo "[X]"; else echo "[ ]"; fi) shadPS4 (Emulador de PS4)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "sh.ppy.osu"; then echo "[X]"; else echo "[ ]"; fi) osu! (Jogo de ritmo)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.vinegarhq.Sober"; then echo "[X]"; else echo "[ ]"; fi) Sober (Inicializador de jogos Roblox)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.vinegarhq.Vinegar"; then echo "[X]"; else echo "[ ]"; fi) Vinegar (Roblox)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.Faugus.faugus-launcher"; then echo "[X]"; else echo "[ ]"; fi) Faugus Launcher (Gerenciador de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.dec05eba.gpu_screen_recorder"; then echo "[X]"; else echo "[ ]"; fi) GPU Screen Recorder (Captura de tela)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.moonlight_stream.Moonlight"; then echo "[X]"; else echo "[ ]"; fi) Moonlight (Streaming de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.hmlendea.geforcenow-electron"; then echo "[X]"; else echo "[ ]"; fi) GeForce NOW (Streaming de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.unknownskl.greenlight"; then echo "[X]"; else echo "[ ]"; fi) Greenlight (Cliente Xbox)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.wivrn.wivrn"; then echo "[X]"; else echo "[ ]"; fi) WiVRn (Streaming VR)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (15):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "waydroid"; then echo "[X]"; else echo "[ ]"; fi) Waydroid (Android em Wayland)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "winboat"; then echo "[X]"; else echo "[ ]"; fi) Winboat (Gerenciador de Wine)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ryubing"; then echo "[X]"; else echo "[ ]"; fi) Ryubing (Emulador de Switch)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "yt-dlp"; then echo "[X]"; else echo "[ ]"; fi) yt-dlp (Download de vídeos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "aria2"; then echo "[X]"; else echo "[ ]"; fi) Aria2 (Downloader)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ffmpegthumbnailer"; then echo "[X]"; else echo "[ ]"; fi) FFmpeg Thumbnailer (Miniaturas de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "btrfs-assistant"; then echo "[X]"; else echo "[ ]"; fi) BTRFS Assistant (Gerenciador BTRFS)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "dnsmasq"; then echo "[X]"; else echo "[ ]"; fi) Dnsmasq (Servidor DNS/DHCP)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "neovim"; then echo "[X]"; else echo "[ ]"; fi) Neovim (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "vimPlugins.LazyVim"; then echo "[X]"; else echo "[ ]"; fi) LazyVim (Framework para Neovim)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "p7zip"; then echo "[X]"; else echo "[ ]"; fi) p7zip (Compactador de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "gnutar"; then echo "[X]"; else echo "[ ]"; fi) GNU Tar (Arquivador)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "libarchive"; then echo "[X]"; else echo "[ ]"; fi) Libarchive (Arquivos multi-formato)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "unrar"; then echo "[X]"; else echo "[ ]"; fi) UnRAR (Extrator RAR)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "unar"; then echo "[X]"; else echo "[ ]"; fi) Unar (Extrator universal)"
        i=$((i+1))
        
        echo
        read -p "Opção: " choice
        
        if [ "$choice" = "0" ]; then
            return 0
        elif [ "$choice" = "P" ] || [ "$choice" = "p" ]; then
            select_packages_page3
            return $?
        elif [ "$choice" = "T" ] || [ "$choice" = "t" ]; then
            toggle_all_packages 4 "select"
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            local total_flatpak=15
            if [ "$choice" -le $total_flatpak ]; then
                case $choice in
                    1) pkg="org.kde.kalendar"; type="flatpak" ;;
                    2) pkg="com.github.Matoking.protontricks"; type="flatpak" ;;
                    3) pkg="net.lutris.Lutris"; type="flatpak" ;;
                    4) pkg="org.prismlauncher.PrismLauncher"; type="flatpak" ;;
                    5) pkg="com.heroicgameslauncher.hgl"; type="flatpak" ;;
                    6) pkg="net.shadps4.shadPS4"; type="flatpak" ;;
                    7) pkg="sh.ppy.osu"; type="flatpak" ;;
                    8) pkg="org.vinegarhq.Sober"; type="flatpak" ;;
                    9) pkg="org.vinegarhq.Vinegar"; type="flatpak" ;;
                    10) pkg="io.github.Faugus.faugus-launcher"; type="flatpak" ;;
                    11) pkg="com.dec05eba.gpu_screen_recorder"; type="flatpak" ;;
                    12) pkg="com.moonlight_stream.Moonlight"; type="flatpak" ;;
                    13) pkg="io.github.hmlendea.geforcenow-electron"; type="flatpak" ;;
                    14) pkg="io.github.unknownskl.greenlight"; type="flatpak" ;;
                    15) pkg="io.github.wivrn.wivrn"; type="flatpak" ;;
                esac
            else
                local nix_index=$((choice - total_flatpak))
                case $nix_index in
                    1) pkg="waydroid"; type="nixpkgs" ;;
                    2) pkg="winboat"; type="nixpkgs" ;;
                    3) pkg="ryubing"; type="nixpkgs" ;;
                    4) pkg="yt-dlp"; type="nixpkgs" ;;
                    5) pkg="aria2"; type="nixpkgs" ;;
                    6) pkg="ffmpegthumbnailer"; type="nixpkgs" ;;
                    7) pkg="btrfs-assistant"; type="nixpkgs" ;;
                    8) pkg="dnsmasq"; type="nixpkgs" ;;
                    9) pkg="neovim"; type="nixpkgs" ;;
                    10) pkg="vimPlugins.LazyVim"; type="nixpkgs" ;;
                    11) pkg="p7zip"; type="nixpkgs" ;;
                    12) pkg="gnutar"; type="nixpkgs" ;;
                    13) pkg="libarchive"; type="nixpkgs" ;;
                    14) pkg="unrar"; type="nixpkgs" ;;
                    15) pkg="unar"; type="nixpkgs" ;;
                esac
            fi
            
            local temp_file=$(mktemp)
            
            if [ "$type" = "flatpak" ]; then
                if cat "$packages_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$packages_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$packages_file"
                else
                    echo "$pkg" >> "$packages_file"
                fi
            else
                if cat "$nixpkgs_file" 2>/dev/null | grep -q "$pkg"; then
                    grep -v "$pkg" "$nixpkgs_file" 2>/dev/null > "$temp_file" || true
                    mv "$temp_file" "$nixpkgs_file"
                else
                    echo "$pkg" >> "$nixpkgs_file"
                fi
            fi
            rm -f "$temp_file"
        fi
    done
}

select_packages() {
    select_packages_page1
}

detect_disk() {
    while true; do
        clear
        echo "=== DISCOS DISPONÍVEIS / AVAILABLE DISKS ==="
        lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -v loop
        echo
        read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
        if [ -b "/dev/$disk_name" ]; then
            echo "/dev/$disk_name" > "$STATE_DIR/disk"
            break
        else
            echo "Disco inválido. Pressione Enter para tentar novamente."
            read
        fi
    done
}

select_username() {
    while true; do
        clear
        read -p "Digite o nome do usuário: " username
        if [ -n "$username" ]; then
            echo "$username" > "$STATE_DIR/username"
            break
        fi
    done
    while true; do
        read -s -p "Digite a senha: " userpass
        echo
        read -s -p "Confirme a senha: " userpass2
        echo
        if [ "$userpass" = "$userpass2" ] && [ -n "$userpass" ]; then
            echo "$(mkpasswd -m sha-512 "$userpass")" > "$STATE_DIR/pass_hash"
            break
        else
            echo "Senhas não conferem ou vazias. Pressione Enter para tentar novamente."
            read
        fi
    done
}

check_existing_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    if [ -n "$(lsblk -no NAME "$disk" | tail -n +2)" ]; then
        clear
        echo "=== AVISO: PARTIÇÕES EXISTENTES ==="
        echo "O disco $disk já possui partições:"
        lsblk "$disk"
        echo
        echo "Pressione Enter para abrir o cfdisk e remover as partições."
        read
        sudo cfdisk "$disk"
        if [ -n "$(lsblk -no NAME "$disk" | tail -n +2)" ]; then
            echo "Ainda existem partições. Remova todas antes de continuar."
            exit 1
        fi
    fi
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local encryption=$(cat "$STATE_DIR/encryption")
    clear
    echo "=== PARTICIONANDO $disk ==="
    check_existing_partitions
    if [ -d /sys/firmware/efi/efivars ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        sudo parted $disk -- mklabel gpt
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 esp on
        sudo parted $disk -- mkpart primary 512MB 100%
        sudo mkfs.fat -F 32 -n NIXBOOT ${disk}1
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        sudo parted $disk -- mklabel msdos
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 boot on
        sudo parted $disk -- mkpart primary 512MB 100%
        sudo mkfs.ext4 -F -L NIXBOOT ${disk}1
    fi
    
    if [ "$encryption" = "yes" ]; then
        echo "Configurando criptografia LUKS..."
        sudo cryptsetup luksFormat ${disk}2
        sudo cryptsetup open ${disk}2 cryptroot
        local uuid=$(sudo blkid -s UUID -o value ${disk}2)
        echo "$uuid" > "$STATE_DIR/luks_uuid"
        
        echo "aesni_intel" >> "$STATE_DIR/initrd_modules" 2>/dev/null || echo "aesni_intel" > "$STATE_DIR/initrd_modules"
        echo "cryptd" >> "$STATE_DIR/initrd_modules" 2>/dev/null || true
        
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f /dev/mapper/cryptroot
        else
            sudo mkfs.ext4 -F /dev/mapper/cryptroot
        fi
    else
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f -L NIXROOT ${disk}2
        else
            sudo mkfs.ext4 -F -L NIXROOT ${disk}2
        fi
    fi
    
    echo "Aguardando atualização dos dispositivos de bloco..."
    sleep 3
    sudo udevadm settle
    sudo partprobe || true
}

setup_btrfs_subvolumes() {
    local root_dev
    local encryption=$(cat "$STATE_DIR/encryption")
    
    if [ "$encryption" = "yes" ]; then
        root_dev="/dev/mapper/cryptroot"
    else
        for i in {1..10}; do
            if [ -e "/dev/disk/by-label/NIXROOT" ]; then
                root_dev="/dev/disk/by-label/NIXROOT"
                break
            fi
            echo "Aguardando label NIXROOT aparecer... ($i/10)"
            sleep 1
            sudo udevadm settle
        done
        if [ -z "$root_dev" ]; then
            root_dev="/dev/disk/by-label/NIXROOT"
        fi
    fi
    
    echo "Montando $root_dev para criar subvolumes..."
    sudo mount $root_dev /mnt
    
    echo "Criando subvolumes btrfs..."
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    
    sudo umount /mnt
    
    echo "Montando subvolumes com compressão zstd e noatime..."
    sudo mount -o compress=zstd,noatime,subvol=@ $root_dev /mnt
    sudo mkdir -p /mnt/{home,nix}
    sudo mount -o compress=zstd,noatime,subvol=@home $root_dev /mnt/home
    sudo mount -o compress=zstd,noatime,subvol=@nix $root_dev /mnt/nix
}

mount_partitions() {
    local encryption=$(cat "$STATE_DIR/encryption")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    echo "Preparando montagem das partições..."
    
    if [ "$encryption" = "yes" ]; then
        if [ "$fs" = "btrfs" ]; then
            setup_btrfs_subvolumes
        else
            sudo mount /dev/mapper/cryptroot /mnt
        fi
    else
        for i in {1..10}; do
            if [ -e "/dev/disk/by-label/NIXROOT" ]; then
                break
            fi
            echo "Aguardando label NIXROOT aparecer... ($i/10)"
            sleep 1
            sudo udevadm settle
        done
        
        if [ "$fs" = "btrfs" ]; then
            setup_btrfs_subvolumes
        else
            echo "Montando partição ext4 com noatime..."
            sudo mount -o noatime /dev/disk/by-label/NIXROOT /mnt
        fi
    fi
    
    for i in {1..10}; do
        if [ -e "/dev/disk/by-label/NIXBOOT" ]; then
            break
        fi
        echo "Aguardando label NIXBOOT aparecer... ($i/10)"
        sleep 1
        sudo udevadm settle
    done
    
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    echo "Partições montadas com sucesso!"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma/Language: $(cat "$STATE_DIR/lang")"
    echo "Teclado/Keyboard: $(cat "$STATE_DIR/console_keymap")"
    echo "Fuso/Timezone: $(cat "$STATE_DIR/timezone")"
    echo "Hostname: $(cat "$STATE_DIR/hostname")"
    echo "Tipo/Type: $(cat "$STATE_DIR/device_type")"
    echo "Filesystem: $(cat "$STATE_DIR/filesystem")"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Kernel: $(cat "$STATE_DIR/kernel")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "GPU Driver: $(cat "$STATE_DIR/gpu_driver")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "TRIM SSD: $(cat "$STATE_DIR/trim")"
    echo "Criptografia: $(cat "$STATE_DIR/encryption")"
    echo "Firewall: $(cat "$STATE_DIR/firewall")"
    echo "Configurações recomendadas: $(cat "$STATE_DIR/recommended")"
    echo "Pacotes Flatpak: $(cat "$STATE_DIR/packages" 2>/dev/null | wc -l | tr -d ' ') selecionados"
    echo "Pacotes Nixpkgs: $(cat "$STATE_DIR/nixpkgs_packages" 2>/dev/null | wc -l | tr -d ' ') selecionados"
    echo "Disco/Disk: $(cat "$STATE_DIR/disk")"
    echo "Usuário/User: $(cat "$STATE_DIR/username")"
    echo "================================="
    echo
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

generate_config() {
    clear
    echo "=== GERANDO CONFIGURAÇÃO ==="
    sudo nixos-generate-config --root /mnt
    local lang=$(cat "$STATE_DIR/lang")
    local console_keymap=$(cat "$STATE_DIR/console_keymap")
    local xkb_layout=$(cat "$STATE_DIR/xkb_layout")
    local xkb_variant=$(cat "$STATE_DIR/xkb_variant")
    local timezone=$(cat "$STATE_DIR/timezone")
    local hostname=$(cat "$STATE_DIR/hostname")
    local username=$(cat "$STATE_DIR/username")
    local pass_hash=$(cat "$STATE_DIR/pass_hash")
    local device_type=$(cat "$STATE_DIR/device_type")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local kernel=$(cat "$STATE_DIR/kernel")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local trim=$(cat "$STATE_DIR/trim")
    local encryption=$(cat "$STATE_DIR/encryption")
    local firewall=$(cat "$STATE_DIR/firewall")
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local luks_uuid=$(cat "$STATE_DIR/luks_uuid" 2>/dev/null || echo "")
    local initrd_modules=$(cat "$STATE_DIR/initrd_modules" 2>/dev/null || echo "")
    local recommended=$(cat "$STATE_DIR/recommended")
    local flatpak_packages=$(cat "$STATE_DIR/packages" 2>/dev/null | tr '\n' ' ')
    local nixpkgs_packages=$(cat "$STATE_DIR/nixpkgs_packages" 2>/dev/null | tr '\n' ' ')
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    if [ "$fs" = "btrfs" ]; then
        local hw_config="/mnt/etc/nixos/hardware-configuration.nix"
        if [ -f "$hw_config" ]; then
            sudo cp "$hw_config" "${hw_config}.backup"
            sudo sed -i '/fileSystems."\/".* = {/,/}/ s|\(options = \[\)|\1 "compress=zstd" "noatime"|' "$hw_config"
            sudo sed -i '/fileSystems."\/home".* = {/,/}/ s|\(options = \[\)|\1 "compress=zstd" "noatime"|' "$hw_config"
            sudo sed -i '/fileSystems."\/nix".* = {/,/}/ s|\(options = \[\)|\1 "compress=zstd" "noatime"|' "$hw_config"
        fi
    fi
    
    # Coletar parâmetros de kernel para evitar duplicação
    kernel_params=()
    if [ "$recommended" = "yes" ]; then
        kernel_params+=("quiet" "splash" "transparent_hugepage=always" "preempt=full")
    fi
    if [ "$gpu_driver" = "intel-amd" ]; then
        kernel_params+=("amdgpu.si_support=1" "radeon.si_support=0" "amdgpu.cik_support=1" "radeon.cik_support=0")
    fi

    sudo tee "$config_file" > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.config.allowUnfree = true;
EOF

    sudo tee -a "$config_file" > /dev/null << EOF
  boot = {
    loader = {
EOF

    if [ "$bootloader" = "systemd-boot" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
EOF
    else
        if [ "$boot_mode" = "uefi" ]; then
            sudo tee -a "$config_file" > /dev/null << EOF
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
      };
      efi.canTouchEfiVariables = true;
EOF
        else
            sudo tee -a "$config_file" > /dev/null << EOF
      grub = {
        enable = true;
        device = "$disk";
      };
EOF
        fi
    fi

    if [ "$kernel" = "latest" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    };
    kernelPackages = pkgs.linuxPackages_latest;
EOF
    else
        sudo tee -a "$config_file" > /dev/null << EOF
    };
    kernelPackages = pkgs.linuxPackages_lqx;
EOF
    fi

    if [ "$encryption" = "yes" ] && [ -n "$luks_uuid" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    initrd = {
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-uuid/$luks_uuid";
        preLVM = true;
      };
      availableKernelModules = [ "aesni_intel" "cryptd" ];
    };
EOF
    fi

    # Escrever kernelParams uma única vez
    if [ ${#kernel_params[@]} -gt 0 ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    kernelParams = [ $(printf '"%s" ' "${kernel_params[@]}") ];
EOF
    fi

    if [ "$recommended" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    loader.timeout = 2;
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      "kernel.split_lock_mitigate" = 0;
      "kernel.nmi_watchdog" = 0;
      "net.core.netdev_max_backlog" = 4096;
      "fs.file-max" = 2097152;
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  };
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    Network = {
      EnableIPv6 = true;
    };
    Settings = {
      AutoConnect = true;
    };
    General = {
      ControlPortOverNL80211 = false;
    };
  };
  networking.firewall = {
    enable = $firewall;
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };
  networking.timeServers = [
    "0.pool.ntp.org"
    "1.pool.ntp.org"
    "2.pool.ntp.org"
    "3.pool.ntp.org"
  ];
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  i18n.defaultLocale = "$lang";
EOF

    if [ "$lang" = "pt_BR.UTF-8" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  console.keyMap = "$console_keymap";
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "$xkb_layout";
EOF

    if [ -n "$xkb_variant" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    variant = "$xkb_variant";
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  };
EOF

    if [ "$desktop" != "none" ]; then
        case $desktop in
            gnome)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    totem
    epiphany
    geary
    gnome-music
    gnome-tour
    gnome-user-docs
  ];
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/mutter" = {
          experimental-features = [
            "scale-monitor-framebuffer"
            "variable-refresh-rate"
            "xwayland-native-scaling"
          ];
        };
      };
    }
  ];
EOF
                ;;
            plasma)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    settings.General.DisplayServer = "wayland";
  };
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    kate
    plasma-systemmonitor
  ];
EOF
                ;;
            cosmic)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-player
    cosmic-edit
  ];
EOF
                ;;
            hyprland)
                sudo tee -a "$config_file" > /dev/null << EOF
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
EOF
                ;;
        esac
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig = {
      pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 32;
        };
      };
      pipewire-pulse."92-low-latency" = {
        "context.properties" = [
          { name = "libpipewire-module-protocol-pulse"; args = { }; }
        ];
        "pulse.properties" = {
          "pulse.min.req" = "32/48000";
          "pulse.default.req" = "32/48000";
          "pulse.max.req" = "32/48000";
          "pulse.min.quantum" = "32/48000";
          "pulse.max.quantum" = "32/48000";
        };
        "stream.properties" = {
          "node.latency" = "32/48000";
          "resample.quality" = 1;
        };
      };
    };
    wireplumber.extraConfig."10-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
      };
    };
    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "~alsa_input.*"; }
            { "node.name" = "~alsa_output.*"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };
EOF

    if [ "$bluetooth" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;
EOF
    fi

    if [ "$cups" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint cups-filters cups-browsed ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };
EOF
    fi

    if [ "$trim" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
EOF

    if [ "$gpu_driver" = "nvidia" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = $([ "$device_type" = "laptop" ] && echo "true" || echo "false");
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
EOF
    elif [ "$gpu_driver" = "intel-amd" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      vpl-gpu-rt
      amdvlk
      mesa.opencl
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
  services.xserver.videoDrivers = [ "modesetting" ];
  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    LIBVA_DRIVER_NAME = "iHD";
  };
EOF
    fi

    if [ "$device_type" = "laptop" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = false;
EOF
    else
        sudo tee -a "$config_file" > /dev/null << EOF
  powerManagement.cpuFreqGovernor = "performance";
EOF
    fi

    if [ "$recommended" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
  services.earlyoom = {
    enable = true;
    freeSwapThreshold = 2;
    freeMemThreshold = 2;
    extraArgs = [
      "-g" "--avoid" "'^(X|plasma.*|konsole|kwin|wayland|gnome.*)$'"
    ];
  };
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", \
      ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", \
      ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", \
      ATTR{queue/scheduler}="none"
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';
EOF
    fi

    if [ "$fs" = "btrfs" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  boot.supportedFilesystems = [ "btrfs" ];
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 10;
  
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" "render" "lpadmin" ];
    hashedPassword = "$pass_hash";
    shell = pkgs.bash;
  };
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "ALL";
          options = [ "SETENV" ];
        }
      ];
    }
  ];
EOF

    sudo tee -a "$config_file" > /dev/null << EOF
  services.flatpak.enable = true;
  systemd.services.flatpak-install = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
EOF

    if [ -n "$flatpak_packages" ]; then
        for pkg in $flatpak_packages; do
            if [ -n "$pkg" ]; then
                sudo tee -a "$config_file" > /dev/null << EOF
      flatpak install --noninteractive -y flathub $pkg
EOF
            fi
        done
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
    '';
  };
EOF

    if echo "$nixpkgs_packages" | grep -q "podman"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "waydroid"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  virtualisation.waydroid.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "zerotierone"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.zerotierone.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "dnsmasq"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.dnsmasq.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "tailscale"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.tailscale.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "wireguard-tools"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  networking.wireguard.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "cockpit"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.cockpit.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "openssh"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.openssh.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "forgejo"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.forgejo.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "ollama"; then
        if [ "$gpu_driver" = "nvidia" ]; then
            sudo tee -a "$config_file" > /dev/null << EOF
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
EOF
        else
            sudo tee -a "$config_file" > /dev/null << EOF
  services.ollama = {
    enable = true;
  };
EOF
        fi
    fi

    if echo "$nixpkgs_packages" | grep -q "gamemode"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  programs.gamemode.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "gamescope"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  programs.gamescope.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "fish"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  programs.fish.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "zsh"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  programs.zsh.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "oh-my-zsh"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  programs.zsh.ohMyZsh.enable = true;
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    unzip
    zip
    openssl
    file
    clinfo
    wayland-utils
    pavucontrol
    pwvucontrol
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
EOF

    for pkg in $nixpkgs_packages; do
        if [ -n "$pkg" ] && [ "$pkg" != "podman" ] && [ "$pkg" != "waydroid" ] && [ "$pkg" != "zerotierone" ] && [ "$pkg" != "dnsmasq" ] && [ "$pkg" != "tailscale" ] && [ "$pkg" != "wireguard-tools" ] && [ "$pkg" != "cockpit" ] && [ "$pkg" != "openssh" ] && [ "$pkg" != "forgejo" ] && [ "$pkg" != "ollama" ] && [ "$pkg" != "gamemode" ] && [ "$pkg" != "gamescope" ] && [ "$pkg" != "fish" ] && [ "$pkg" != "zsh" ] && [ "$pkg" != "oh-my-zsh" ]; then
            sudo tee -a "$config_file" > /dev/null << EOF
    ${pkg}
EOF
        fi
    done

    sudo tee -a "$config_file" > /dev/null << EOF
  ];
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = 1;
    cores = 1;
    extra-sandbox-paths = [];
    min-free = 512000000;
    max-free = 1024000000;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };
  fonts.packages = with pkgs; [
    nerd-fonts.adwaita-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    cantarell-fonts
    poppins
  ];
  hardware.enableAllFirmware = true;
  system.stateVersion = "25.11";
}
EOF

    echo "Configuração gerada com sucesso!"
}

generate_flake() {
    local hostname=$(cat "$STATE_DIR/hostname")
    local flake_file="/mnt/etc/nixos/flake.nix"
    
    sudo tee "$flake_file" > /dev/null << EOF
{
  description = "Configuração NixOS com flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    preload-ng.url = "github:miguel-b-p/preload-ng";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, lanzaboote, nix-flatpak, preload-ng, hyprland, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
      {
        nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
          specialArgs = { 
            inherit inputs unstable;
          };
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            lanzaboote.nixosModules.lanzaboote
            nix-flatpak.nixosModules.nix-flatpak
            preload-ng.nixosModules.default
            { services.preload-ng.enable = true; }
          ];
        };
      };

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
EOF

    echo
    echo "============================================="
    echo "Arquivo flake.nix criado em /mnt/etc/nixos/"
    echo "============================================="
    echo
    echo "PARA ATIVAR O FLAKE APÓS A INSTALAÇÃO:"
    echo
    echo "1. Após reiniciar, edite o arquivo /etc/nixos/flake.nix"
    echo "2. Execute para ativar:"
    echo "   sudo nixos-rebuild switch --flake /etc/nixos#$hostname"
    echo "============================================="
}

review_configs() {
    clear
    echo "=== REVISAR ARQUIVOS DE CONFIGURAÇÃO ==="
    echo "Deseja revisar os arquivos de configuração gerados?"
    echo "Um editor será aberto para você visualizar e modificar se necessário."
    echo
    if confirm "Revisar configuration.nix e flake.nix?"; then
        if command -v nano >/dev/null 2>&1; then
            EDITOR=nano
        elif command -v vim >/dev/null 2>&1; then
            EDITOR=vim
        else
            EDITOR=vi
        fi
        
        echo "Abrindo configuration.nix..."
        sleep 2
        sudo $EDITOR /mnt/etc/nixos/configuration.nix
        
        echo "Abrindo flake.nix..."
        sleep 2
        sudo $EDITOR /mnt/etc/nixos/flake.nix
    fi
}

install_system() {
    clear
    echo "=== INSTALANDO SISTEMA ==="
    echo "A instalação pode levar alguns minutos..."
    echo
    cd /mnt
    
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    echo "RAM detectada: ${total_ram}MB"
    
    if [ "$total_ram" -lt 2048 ]; then
        echo "Pouca RAM detectada. Usando configuração otimizada para baixa memória..."
        export NIX_BUILD_CORES=1
        export NIX_REMOTE=""
        sudo -E nixos-install --no-root-passwd --max-jobs 1 --cores 1 --option substitute false
    elif [ "$total_ram" -lt 4096 ]; then
        echo "RAM moderada detectada. Usando configuração balanceada..."
        export NIX_BUILD_CORES=2
        sudo -E nixos-install --no-root-passwd --max-jobs 2
    else
        echo "RAM suficiente detectada. Usando configuração padrão..."
        sudo -E nixos-install --no-root-passwd
    fi
    
    echo
    echo "=== INSTALAÇÃO CONCLUÍDA ==="
    echo "Após reiniciar, faça login com usuário: $(cat "$STATE_DIR/username")"
    echo "Digite 'reboot' para reiniciar."
}

check_dependencies() {
    local missing_deps=()
    for cmd in parted mkfs.fat mkfs.ext4 mkfs.btrfs cryptsetup fallocate mkpasswd; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing_deps+=($cmd)
        fi
    done
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Aviso: Alguns comandos podem não estar disponíveis: ${missing_deps[*]}"
        sleep 3
    fi
}

main() {
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    check_dependencies
    select_language
    select_keyboard
    select_timezone
    select_hostname
    select_device_type
    select_filesystem
    select_bootloader
    select_kernel
    select_gpu_drivers
    select_desktop
    select_bluetooth
    select_cups
    select_ssd_trim
    select_encryption
    select_firewall
    select_recommended_config
    select_username
    detect_disk
    select_packages
    show_summary
    partition_disk
    mount_partitions
    generate_config
    generate_flake
    review_configs
    if confirm "Iniciar instalação do NixOS?"; then
        install_system
    else
        echo "Instalação cancelada."
        exit 1
    fi
}

set +e
trap 'echo "Erro detectado. Pressione Enter para continuar..."; read' ERR
set -e
main
