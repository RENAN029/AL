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
        1) 
            echo "pt_BR.UTF-8" > "$STATE_DIR/lang"
            ;;
        2) 
            echo "en_US.UTF-8" > "$STATE_DIR/lang"
            ;;
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

select_swap_size() {
    while true; do
        clear
        echo "=== TAMANHO DO SWAP / SWAP SIZE ==="
        echo "1) 2GB"
        echo "2) 4GB"
        echo "3) 8GB"
        echo "4) Sem swap"
        read -p "Opção: " swap_opt
        case $swap_opt in
            1|2|3|4) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $swap_opt in
        1) echo "2" > "$STATE_DIR/swap" ;;
        2) echo "4" > "$STATE_DIR/swap" ;;
        3) echo "8" > "$STATE_DIR/swap" ;;
        4) echo "0" > "$STATE_DIR/swap" ;;
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
        echo "4) Hyprland (Dank Dots - Wayland tiling)"
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
    echo "- zram para compressão de memória"
    echo "- Gerenciamento de memória otimizado"
    echo "- Regras udev para dispositivos"
    echo
    if confirm "Aplicar configurações recomendadas?"; then
        echo "yes" > "$STATE_DIR/recommended"
    else
        echo "no" > "$STATE_DIR/recommended"
    fi
}

select_packages_page1() {
    local packages_file="$STATE_DIR/packages"
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    while true; do
        clear
        echo "=== SELEÇÃO DE PACOTES - PÁGINA 1/4 ==="
        echo "Digite o número do pacote para marcar/desmarcar, N próxima, P anterior, T todas, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (20):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "app.zen_browser.zen"; then echo "[X]"; else echo "[ ]"; fi) Zen Browser (Navegador web)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.bitwarden.desktop"; then echo "[X]"; else echo "[ ]"; fi) Bitwarden (Gerenciador de senhas)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.discordapp.Discord"; then echo "[X]"; else echo "[ ]"; fi) Discord (Chat e voz)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.heroicgameslauncher.hgl"; then echo "[X]"; else echo "[ ]"; fi) Heroic Games Launcher (Jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.jeffser.Alpaca"; then echo "[X]"; else echo "[ ]"; fi) Alpaca (Cliente de IA)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.mattjakeman.ExtensionManager"; then echo "[X]"; else echo "[ ]"; fi) Extension Manager (GNOME)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.obsproject.Studio"; then echo "[X]"; else echo "[ ]"; fi) OBS Studio (Captura e transmissão)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.vysp3r.ProtonPlus"; then echo "[X]"; else echo "[ ]"; fi) ProtonPlus (Gerenciador de compatibilidade)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "fr.handbrake.ghb"; then echo "[X]"; else echo "[ ]"; fi) HandBrake (Conversor de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.Faugus.faugus-launcher"; then echo "[X]"; else echo "[ ]"; fi) Faugus Launcher (Gerenciador de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.benjamimgois.goverlay"; then echo "[X]"; else echo "[ ]"; fi) GOverlay (Overlay para MangoHud)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.hmlendea.geforcenow-electron"; then echo "[X]"; else echo "[ ]"; fi) GeForce NOW (Streaming de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.unknownskl.greenlight"; then echo "[X]"; else echo "[ ]"; fi) Greenlight (Cliente Xbox)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.wivrn.wivrn"; then echo "[X]"; else echo "[ ]"; fi) WiVRn (Streaming VR)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.mrarm.mcpelauncher"; then echo "[X]"; else echo "[ ]"; fi) MCPE Launcher (Minecraft Pocket Edition)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.dec05eba.gpu_screen_recorder"; then echo "[X]"; else echo "[ ]"; fi) GPU Screen Recorder (Captura de tela)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.moonlight_stream.Moonlight"; then echo "[X]"; else echo "[ ]"; fi) Moonlight (Streaming de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "sh.ppy.osu"; then echo "[X]"; else echo "[ ]"; fi) osu! (Jogo de ritmo)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.prismlauncher.PrismLauncher"; then echo "[X]"; else echo "[ ]"; fi) Prism Launcher (Minecraft)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.github.Matoking.protontricks"; then echo "[X]"; else echo "[ ]"; fi) Protontricks (Ferramentas Proton)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (20):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "aria2"; then echo "[X]"; else echo "[ ]"; fi) Aria2 (Downloader)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "btop"; then echo "[X]"; else echo "[ ]"; fi) Btop (Monitor do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "curl"; then echo "[X]"; else echo "[ ]"; fi) Curl (Transferência de dados)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "davinci-resolve"; then echo "[X]"; else echo "[ ]"; fi) DaVinci Resolve (Edição de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "distrobox"; then echo "[X]"; else echo "[ ]"; fi) Distrobox (Containers de distribuições)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "fastfetch"; then echo "[X]"; else echo "[ ]"; fi) Fastfetch (Info do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "fish"; then echo "[X]"; else echo "[ ]"; fi) Fish (Shell)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "forgejo"; then echo "[X]"; else echo "[ ]"; fi) Forgejo (Plataforma Git)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "gamemode"; then echo "[X]"; else echo "[ ]"; fi) Gamemode (Otimização de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "gamescope"; then echo "[X]"; else echo "[ ]"; fi) Gamescope (Micro-compositor para jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "git"; then echo "[X]"; else echo "[ ]"; fi) Git (Controle de versão)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "htop"; then echo "[X]"; else echo "[ ]"; fi) Htop (Monitor do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "hydralauncher"; then echo "[X]"; else echo "[ ]"; fi) Hydra Launcher (Gerenciador de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "mangohud"; then echo "[X]"; else echo "[ ]"; fi) MangoHud (Overlay de desempenho)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "mise"; then echo "[X]"; else echo "[ ]"; fi) Mise (Gerenciador de versões)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "nano"; then echo "[X]"; else echo "[ ]"; fi) Nano (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "neofetch"; then echo "[X]"; else echo "[ ]"; fi) Neofetch (Info do sistema)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ollama"; then echo "[X]"; else echo "[ ]"; fi) Ollama (Execução de modelos LLM)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "opencode"; then echo "[X]"; else echo "[ ]"; fi) OpenCode (Editor de código)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "podman"; then echo "[X]"; else echo "[ ]"; fi) Podman (Gerenciador de containers)"
        i=$((i+1))
        
        echo
        read -p "Opção: " choice
        
        if [ "$choice" = "0" ]; then
            return 0
        elif [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
            select_packages_page2
            return $?
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="app.zen_browser.zen"; type="flatpak" ;;
                2) pkg="com.bitwarden.desktop"; type="flatpak" ;;
                3) pkg="com.discordapp.Discord"; type="flatpak" ;;
                4) pkg="com.heroicgameslauncher.hgl"; type="flatpak" ;;
                5) pkg="com.jeffser.Alpaca"; type="flatpak" ;;
                6) pkg="com.mattjakeman.ExtensionManager"; type="flatpak" ;;
                7) pkg="com.obsproject.Studio"; type="flatpak" ;;
                8) pkg="com.vysp3r.ProtonPlus"; type="flatpak" ;;
                9) pkg="fr.handbrake.ghb"; type="flatpak" ;;
                10) pkg="io.github.Faugus.faugus-launcher"; type="flatpak" ;;
                11) pkg="io.github.benjamimgois.goverlay"; type="flatpak" ;;
                12) pkg="io.github.hmlendea.geforcenow-electron"; type="flatpak" ;;
                13) pkg="io.github.unknownskl.greenlight"; type="flatpak" ;;
                14) pkg="io.github.wivrn.wivrn"; type="flatpak" ;;
                15) pkg="io.mrarm.mcpelauncher"; type="flatpak" ;;
                16) pkg="com.dec05eba.gpu_screen_recorder"; type="flatpak" ;;
                17) pkg="com.moonlight_stream.Moonlight"; type="flatpak" ;;
                18) pkg="sh.ppy.osu"; type="flatpak" ;;
                19) pkg="org.prismlauncher.PrismLauncher"; type="flatpak" ;;
                20) pkg="com.github.Matoking.protontricks"; type="flatpak" ;;
                21) pkg="aria2"; type="nixpkgs" ;;
                22) pkg="btop"; type="nixpkgs" ;;
                23) pkg="curl"; type="nixpkgs" ;;
                24) pkg="davinci-resolve"; type="nixpkgs" ;;
                25) pkg="distrobox"; type="nixpkgs" ;;
                26) pkg="fastfetch"; type="nixpkgs" ;;
                27) pkg="fish"; type="nixpkgs" ;;
                28) pkg="forgejo"; type="nixpkgs" ;;
                29) pkg="gamemode"; type="nixpkgs" ;;
                30) pkg="gamescope"; type="nixpkgs" ;;
                31) pkg="git"; type="nixpkgs" ;;
                32) pkg="htop"; type="nixpkgs" ;;
                33) pkg="hydralauncher"; type="nixpkgs" ;;
                34) pkg="mangohud"; type="nixpkgs" ;;
                35) pkg="mise"; type="nixpkgs" ;;
                36) pkg="nano"; type="nixpkgs" ;;
                37) pkg="neofetch"; type="nixpkgs" ;;
                38) pkg="ollama"; type="nixpkgs" ;;
                39) pkg="opencode"; type="nixpkgs" ;;
                40) pkg="podman"; type="nixpkgs" ;;
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
        echo "Digite o número do pacote para marcar/desmarcar, N próxima, P anterior, T todas, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (20):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.peazip.PeaZip"; then echo "[X]"; else echo "[ ]"; fi) PeaZip (Compactador de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.github.radiolamp.mangojuice"; then echo "[X]"; else echo "[ ]"; fi) MangoJuice (Player de música)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "it.mijorus.gearlever"; then echo "[X]"; else echo "[ ]"; fi) Gear Lever (Gerenciador de AppImage)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "md.obsidian.Obsidian"; then echo "[X]"; else echo "[ ]"; fi) Obsidian (Editor de notas)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "net.davidotek.pupgui2"; then echo "[X]"; else echo "[ ]"; fi) ProtonUp-Qt (Gerenciador de Proton)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "net.lutris.Lutris"; then echo "[X]"; else echo "[ ]"; fi) Lutris (Gerenciador de jogos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "net.shadps4.shadPS4"; then echo "[X]"; else echo "[ ]"; fi) shadPS4 (Emulador de PS4)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.audacityteam.Audacity"; then echo "[X]"; else echo "[ ]"; fi) Audacity (Editor de áudio)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.blender.Blender"; then echo "[X]"; else echo "[ ]"; fi) Blender (Modelagem 3D)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.cockpit_project.CockpitClient"; then echo "[X]"; else echo "[ ]"; fi) Cockpit Client (Gerenciamento de servidores)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.endlessos.Key"; then echo "[X]"; else echo "[ ]"; fi) Endless Key (Educação offline)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.geogebra.GeoGebra"; then echo "[X]"; else echo "[ ]"; fi) GeoGebra (Matemática interativa)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.gimp.GIMP"; then echo "[X]"; else echo "[ ]"; fi) GIMP (Editor de imagens)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.gnome.Boxes"; then echo "[X]"; else echo "[ ]"; fi) GNOME Boxes (Virtualização)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.gnome.World.PikaBackup"; then echo "[X]"; else echo "[ ]"; fi) Pika Backup (Backups)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.godotengine.Godot"; then echo "[X]"; else echo "[ ]"; fi) Godot Engine (Game engine)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.gcompris"; then echo "[X]"; else echo "[ ]"; fi) GCompris (Educação infantil)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.kalzium"; then echo "[X]"; else echo "[ ]"; fi) Kalzium (Química)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.kde.kdenlive"; then echo "[X]"; else echo "[ ]"; fi) Kdenlive (Editor de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.learningequality.Kolibri"; then echo "[X]"; else echo "[ ]"; fi) Kolibri (Educação offline)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (20):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ryubing"; then echo "[X]"; else echo "[ ]"; fi) Ryubing (Emulador de Switch)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "stirling-pdf"; then echo "[X]"; else echo "[ ]"; fi) Stirling PDF (Manipulação de PDF)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "tailscale"; then echo "[X]"; else echo "[ ]"; fi) Tailscale (VPN mesh)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "vimPlugins.LazyVim"; then echo "[X]"; else echo "[ ]"; fi) LazyVim (Framework para Neovim)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "waydroid"; then echo "[X]"; else echo "[ ]"; fi) Waydroid (Android em Wayland)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "winboat"; then echo "[X]"; else echo "[ ]"; fi) Winboat (Gerenciador de Wine)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "yt-dlp"; then echo "[X]"; else echo "[ ]"; fi) yt-dlp (Download de vídeos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "maven"; then echo "[X]"; else echo "[ ]"; fi) Maven (Gerenciador de build Java)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "javaPackages.compiler.openjdk25"; then echo "[X]"; else echo "[ ]"; fi) OpenJDK 25 (Java Development Kit)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "nodejs_24"; then echo "[X]"; else echo "[ ]"; fi) Node.js 24 (JavaScript runtime)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "oh-my-zsh"; then echo "[X]"; else echo "[ ]"; fi) Oh My Zsh (Framework para Zsh)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "zsh"; then echo "[X]"; else echo "[ ]"; fi) Zsh (Shell)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "pyenv"; then echo "[X]"; else echo "[ ]"; fi) Pyenv (Gerenciador de versões Python)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "zerotierone"; then echo "[X]"; else echo "[ ]"; fi) ZeroTier One (VPN)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "dnsmasq"; then echo "[X]"; else echo "[ ]"; fi) Dnsmasq (Servidor DNS/DHCP)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "ffmpegthumbnailer"; then echo "[X]"; else echo "[ ]"; fi) FFmpeg Thumbnailer (Miniaturas de vídeo)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "btrfs-assistant"; then echo "[X]"; else echo "[ ]"; fi) BTRFS Assistant (Gerenciador BTRFS)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "starship"; then echo "[X]"; else echo "[ ]"; fi) Starship (Prompt personalizável)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "neovim"; then echo "[X]"; else echo "[ ]"; fi) Neovim (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "smartmontools"; then echo "[X]"; else echo "[ ]"; fi) Smartmontools (Monitoramento de disco)"
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
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="io.github.peazip.PeaZip"; type="flatpak" ;;
                2) pkg="io.github.radiolamp.mangojuice"; type="flatpak" ;;
                3) pkg="it.mijorus.gearlever"; type="flatpak" ;;
                4) pkg="md.obsidian.Obsidian"; type="flatpak" ;;
                5) pkg="net.davidotek.pupgui2"; type="flatpak" ;;
                6) pkg="net.lutris.Lutris"; type="flatpak" ;;
                7) pkg="net.shadps4.shadPS4"; type="flatpak" ;;
                8) pkg="org.audacityteam.Audacity"; type="flatpak" ;;
                9) pkg="org.blender.Blender"; type="flatpak" ;;
                10) pkg="org.cockpit_project.CockpitClient"; type="flatpak" ;;
                11) pkg="org.endlessos.Key"; type="flatpak" ;;
                12) pkg="org.geogebra.GeoGebra"; type="flatpak" ;;
                13) pkg="org.gimp.GIMP"; type="flatpak" ;;
                14) pkg="org.gnome.Boxes"; type="flatpak" ;;
                15) pkg="org.gnome.World.PikaBackup"; type="flatpak" ;;
                16) pkg="org.godotengine.Godot"; type="flatpak" ;;
                17) pkg="org.kde.gcompris"; type="flatpak" ;;
                18) pkg="org.kde.kalzium"; type="flatpak" ;;
                19) pkg="org.kde.kdenlive"; type="flatpak" ;;
                20) pkg="org.learningequality.Kolibri"; type="flatpak" ;;
                21) pkg="ryubing"; type="nixpkgs" ;;
                22) pkg="stirling-pdf"; type="nixpkgs" ;;
                23) pkg="tailscale"; type="nixpkgs" ;;
                24) pkg="vimPlugins.LazyVim"; type="nixpkgs" ;;
                25) pkg="waydroid"; type="nixpkgs" ;;
                26) pkg="winboat"; type="nixpkgs" ;;
                27) pkg="yt-dlp"; type="nixpkgs" ;;
                28) pkg="maven"; type="nixpkgs" ;;
                29) pkg="javaPackages.compiler.openjdk25"; type="nixpkgs" ;;
                30) pkg="nodejs_24"; type="nixpkgs" ;;
                31) pkg="oh-my-zsh"; type="nixpkgs" ;;
                32) pkg="zsh"; type="nixpkgs" ;;
                33) pkg="pyenv"; type="nixpkgs" ;;
                34) pkg="zerotierone"; type="nixpkgs" ;;
                35) pkg="dnsmasq"; type="nixpkgs" ;;
                36) pkg="ffmpegthumbnailer"; type="nixpkgs" ;;
                37) pkg="btrfs-assistant"; type="nixpkgs" ;;
                38) pkg="starship"; type="nixpkgs" ;;
                39) pkg="neovim"; type="nixpkgs" ;;
                40) pkg="smartmontools"; type="nixpkgs" ;;
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
        echo "Digite o número do pacote para marcar/desmarcar, N próxima, P anterior, T todas, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local flatpak_selected=$(cat "$packages_file" 2>/dev/null || echo "")
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        
        echo "Pacotes Flatpak (16):"
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.localsend.localsend_app"; then echo "[X]"; else echo "[ ]"; fi) LocalSend (Compartilhamento de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.onlyoffice.desktopeditors"; then echo "[X]"; else echo "[ ]"; fi) OnlyOffice (Suíte de escritório)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.stellarium.Stellarium"; then echo "[X]"; else echo "[ ]"; fi) Stellarium (Planetário)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.vinegarhq.Sober"; then echo "[X]"; else echo "[ ]"; fi) Sober (Inicializador de jogos Roblox)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.google.AndroidStudio"; then echo "[X]"; else echo "[ ]"; fi) Android Studio (IDE Android)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.sublimehq.SublimeText"; then echo "[X]"; else echo "[ ]"; fi) Sublime Text (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.termius.Termius"; then echo "[X]"; else echo "[ ]"; fi) Termius (Cliente SSH)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.github.IsmaelMartinez.teams_for_linux"; then echo "[X]"; else echo "[ ]"; fi) Teams for Linux (Comunicação)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.signal.Signal"; then echo "[X]"; else echo "[ ]"; fi) Signal (Mensageiro seguro)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.slack.Slack"; then echo "[X]"; else echo "[ ]"; fi) Slack (Comunicação)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "org.telegram.desktop"; then echo "[X]"; else echo "[ ]"; fi) Telegram (Mensageiro)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.rtosta.zapzap"; then echo "[X]"; else echo "[ ]"; fi) ZapZap (WhatsApp desktop)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.visualstudio.code"; then echo "[X]"; else echo "[ ]"; fi) VS Code (Editor de código)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "com.vscodium.codium"; then echo "[X]"; else echo "[ ]"; fi) VSCodium (Editor de código open-source)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "dev.zed.Zed"; then echo "[X]"; else echo "[ ]"; fi) Zed (Editor de código)"
        i=$((i+1))
        echo "  $i) $(if echo "$flatpak_selected" | grep -q "io.httpie.Httpie"; then echo "[X]"; else echo "[ ]"; fi) HTTPie (Cliente HTTP)"
        i=$((i+1))
        
        echo
        echo "Pacotes Nixpkgs (4):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "superfile"; then echo "[X]"; else echo "[ ]"; fi) Superfile (Gerenciador de arquivos)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "vim"; then echo "[X]"; else echo "[ ]"; fi) Vim (Editor de texto)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "wget"; then echo "[X]"; else echo "[ ]"; fi) Wget (Download)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "wireguard-tools"; then echo "[X]"; else echo "[ ]"; fi) WireGuard Tools (VPN)"
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
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="org.localsend.localsend_app"; type="flatpak" ;;
                2) pkg="org.onlyoffice.desktopeditors"; type="flatpak" ;;
                3) pkg="org.stellarium.Stellarium"; type="flatpak" ;;
                4) pkg="org.vinegarhq.Sober"; type="flatpak" ;;
                5) pkg="com.google.AndroidStudio"; type="flatpak" ;;
                6) pkg="com.sublimehq.SublimeText"; type="flatpak" ;;
                7) pkg="com.termius.Termius"; type="flatpak" ;;
                8) pkg="com.github.IsmaelMartinez.teams_for_linux"; type="flatpak" ;;
                9) pkg="org.signal.Signal"; type="flatpak" ;;
                10) pkg="com.slack.Slack"; type="flatpak" ;;
                11) pkg="org.telegram.desktop"; type="flatpak" ;;
                12) pkg="com.rtosta.zapzap"; type="flatpak" ;;
                13) pkg="com.visualstudio.code"; type="flatpak" ;;
                14) pkg="com.vscodium.codium"; type="flatpak" ;;
                15) pkg="dev.zed.Zed"; type="flatpak" ;;
                16) pkg="io.httpie.Httpie"; type="flatpak" ;;
                17) pkg="superfile"; type="nixpkgs" ;;
                18) pkg="vim"; type="nixpkgs" ;;
                19) pkg="wget"; type="nixpkgs" ;;
                20) pkg="wireguard-tools"; type="nixpkgs" ;;
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
    local nixpkgs_file="$STATE_DIR/nixpkgs_packages"
    
    while true; do
        clear
        echo "=== SELEÇÃO DE PACOTES - PÁGINA 4/4 ==="
        echo "Digite o número do pacote para marcar/desmarcar, P anterior, T todas, 0 continuar"
        echo "================================================================================"
        echo
        
        local i=1
        local nixpkgs_selected=$(cat "$nixpkgs_file" 2>/dev/null || echo "")
        local kernel=$(cat "$STATE_DIR/kernel")
        local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
        
        echo "Pacotes Nixpkgs (Drivers e Ferramentas):"
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "rustup"; then echo "[X]"; else echo "[ ]"; fi) Rustup (Gerenciador Rust)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "openssl"; then echo "[X]"; else echo "[ ]"; fi) OpenSSL (Biblioteca criptográfica)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "n8n"; then echo "[X]"; else echo "[ ]"; fi) n8n (Automação de workflows)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "cockpit"; then echo "[X]"; else echo "[ ]"; fi) Cockpit (Gerenciamento de servidores)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "lunarvim"; then echo "[X]"; else echo "[ ]"; fi) LunarVim (IDE para Neovim)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "rest.insomnia.Insomnia"; then echo "[X]"; else echo "[ ]"; fi) Insomnia (Cliente API)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "f3"; then echo "[X]"; else echo "[ ]"; fi) F3 (Teste de integridade de flash)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "xpadneo"; then echo "[X]"; else echo "[ ]"; fi) xpadneo (Driver para controles Xbox)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "rtl88xxau-aircrack"; then echo "[X]"; else echo "[ ]"; fi) RTL88xxau (Driver Wi-Fi)"
        i=$((i+1))
        echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "broadcom_sta"; then echo "[X]"; else echo "[ ]"; fi) Broadcom STA (Driver Wi-Fi)"
        i=$((i+1))
        
        if [ "$gpu_driver" = "nvidia" ]; then
            echo "  $i) $(if echo "$nixpkgs_selected" | grep -q "nvidia_x11_legacy470"; then echo "[X]"; else echo "[ ]"; fi) NVIDIA Legacy 470 (Driver para GPUs antigas)"
            i=$((i+1))
        fi
        
        echo
        read -p "Opção: " choice
        
        if [ "$choice" = "0" ]; then
            return 0
        elif [ "$choice" = "P" ] || [ "$choice" = "p" ]; then
            select_packages_page3
            return $?
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "$((i-1))" ]; then
            case $choice in
                1) pkg="rustup"; type="nixpkgs" ;;
                2) pkg="openssl"; type="nixpkgs" ;;
                3) pkg="n8n"; type="nixpkgs" ;;
                4) pkg="cockpit"; type="nixpkgs" ;;
                5) pkg="lunarvim"; type="nixpkgs" ;;
                6) pkg="rest.insomnia.Insomnia"; type="nixpkgs" ;;
                7) pkg="f3"; type="nixpkgs" ;;
                8) pkg="xpadneo"; type="nixpkgs" ;;
                9) pkg="rtl88xxau-aircrack"; type="nixpkgs" ;;
                10) pkg="broadcom_sta"; type="nixpkgs" ;;
                11) pkg="nvidia_x11_legacy470"; type="nixpkgs" ;;
                *) continue ;;
            esac
            
            local temp_file=$(mktemp)
            
            if cat "$nixpkgs_file" 2>/dev/null | grep -q "$pkg"; then
                grep -v "$pkg" "$nixpkgs_file" 2>/dev/null > "$temp_file" || true
                mv "$temp_file" "$nixpkgs_file"
            else
                echo "$pkg" >> "$nixpkgs_file"
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
        sudo cryptsetup luksFormat ${disk}2
        sudo cryptsetup open ${disk}2 cryptroot
        local uuid=$(sudo blkid -s UUID -o value ${disk}2)
        echo "$uuid" > "$STATE_DIR/luks_uuid"
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs /dev/mapper/cryptroot
        else
            sudo mkfs.ext4 /dev/mapper/cryptroot
        fi
    else
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f -L NIXROOT ${disk}2
        else
            sudo mkfs.ext4 -F -L NIXROOT ${disk}2
        fi
    fi
}

setup_btrfs_subvolumes() {
    local root_dev
    local encryption=$(cat "$STATE_DIR/encryption")
    if [ "$encryption" = "yes" ]; then
        root_dev="/dev/mapper/cryptroot"
    else
        root_dev="/dev/disk/by-label/NIXROOT"
    fi
    echo "Criando subvolumes btrfs com compressão zstd..."
    sudo mount $root_dev /mnt
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    sudo umount /mnt
    sudo mount -o compress=zstd,subvol=@ $root_dev /mnt
    sudo mkdir -p /mnt/{home,nix}
    sudo mount -o compress=zstd,subvol=@home $root_dev /mnt/home
    sudo mount -o compress=zstd,noatime,subvol=@nix $root_dev /mnt/nix
}

mount_partitions() {
    local encryption=$(cat "$STATE_DIR/encryption")
    local fs=$(cat "$STATE_DIR/filesystem")
    if [ "$encryption" = "yes" ]; then
        if [ "$fs" = "btrfs" ]; then
            setup_btrfs_subvolumes
        else
            sudo mount /dev/mapper/cryptroot /mnt
        fi
    else
        if [ "$fs" = "btrfs" ]; then
            setup_btrfs_subvolumes
        else
            sudo mount /dev/disk/by-label/NIXROOT /mnt
        fi
    fi
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    if [ "$swap_size" = "0" ]; then
        return
    fi
    echo "Criando arquivo swap de ${swap_size}G..."
    if [ ! -f /mnt/.swapfile ]; then
        sudo dd if=/dev/zero of=/mnt/.swapfile bs=1M count=$((swap_size * 1024)) status=progress
        sudo chmod 600 /mnt/.swapfile
        sudo mkswap /mnt/.swapfile
    fi
    echo "Configurando swap no sistema..."
    sudo swapon /mnt/.swapfile 2>/dev/null || true
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma/Language: $(cat "$STATE_DIR/lang")"
    echo "Teclado/Keyboard: $(cat "$STATE_DIR/console_keymap")"
    echo "Fuso/Timezone: $(cat "$STATE_DIR/timezone")"
    echo "Hostname: $(cat "$STATE_DIR/hostname")"
    echo "Tipo/Type: $(cat "$STATE_DIR/device_type")"
    local swap=$(cat "$STATE_DIR/swap")
    if [ "$swap" = "0" ]; then
        echo "Swap: Sem swap"
    else
        echo "Swap: ${swap}GB (arquivo .swapfile)"
    fi
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
    local swap_size=$(cat "$STATE_DIR/swap")
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local luks_uuid=$(cat "$STATE_DIR/luks_uuid" 2>/dev/null || echo "")
    local recommended=$(cat "$STATE_DIR/recommended")
    local flatpak_packages=$(cat "$STATE_DIR/packages" 2>/dev/null | tr '\n' ' ')
    local nixpkgs_packages=$(cat "$STATE_DIR/nixpkgs_packages" 2>/dev/null | tr '\n' ' ')
    local config_file="/mnt/etc/nixos/configuration.nix"
    
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

    if [ "$recommended" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    loader.timeout = 2;
    kernelModules = [ "tcp_bbr" ];
    kernelParams = [
      "quiet"
      "splash"
      "transparent_hugepage=always"
      "preempt=full"
    ];
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
  networking.wireless.iwd.enable = true;
  networking.firewall.enable = $firewall;
  time.timeZone = "$timezone";
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
EOF
                ;;
            plasma)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
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
  programs.hyprland.enable = true;
  programs.dms-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
  };
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
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
  };
EOF

    if [ "$bluetooth" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
EOF
    fi

    if [ "$cups" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.printing.enable = true;
EOF
    fi

    if [ "$trim" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.fstrim.enable = true;
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  hardware.graphics.enable = true;
EOF

    if [ "$gpu_driver" = "nvidia" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
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
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics.extraPackages = with pkgs; [
    intel-compute-runtime
    intel-media-driver
    vpl-gpu-rt
  ];
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
  systemd.services.set-min-free-mem = {
    description = "Set vm.min_free_kbytes dynamically";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      User = "root";
      RemainAfterExit = true;
    };
    script = ''
      TOTAL_MEM=$(awk '/MemTotal/ {printf "%.0f", $2 * 0.01}' /proc/meminfo)
      if [ -z "$TOTAL_MEM" ] || [ "$TOTAL_MEM" -eq 0 ]; then
        echo "Failed to calculate memory size" >&2
        exit 1
      fi
      sysctl -w vm.min_free_kbytes=$TOTAL_MEM
    '';
  };
  zramSwap.enable = true;
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" "render" ];
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

    if [ "$swap_size" != "0" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  swapDevices = [ { device = "/.swapfile"; } ];
EOF
    fi

    if [ "$encryption" = "yes" ] && [ -n "$luks_uuid" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/$luks_uuid";
    preLVM = true;
  };
EOF
    fi

    if [ "$fs" = "btrfs" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  boot.supportedFilesystems = [ "btrfs" ];
EOF
    fi

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

    if echo "$nixpkgs_packages" | grep -q "forgejo"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.forgejo.enable = true;
EOF
    fi

    if echo "$nixpkgs_packages" | grep -q "ollama"; then
        sudo tee -a "$config_file" > /dev/null << EOF
  services.ollama = {
    enable = true;
    acceleration = "$(if [ "$gpu_driver" = "nvidia" ]; then echo "cuda"; else echo "false"; fi)";
  };
EOF
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
    vim
    nano
    git
    wget
    curl
    htop
    killall
    pciutils
    usbutils
    unzip
    zip
    openssl
    file
    clinfo
    wayland-utils
EOF

    for pkg in $nixpkgs_packages; do
        if [ -n "$pkg" ] && [ "$pkg" != "podman" ] && [ "$pkg" != "waydroid" ] && [ "$pkg" != "zerotierone" ] && [ "$pkg" != "dnsmasq" ] && [ "$pkg" != "tailscale" ] && [ "$pkg" != "wireguard-tools" ] && [ "$pkg" != "cockpit" ] && [ "$pkg" != "forgejo" ] && [ "$pkg" != "ollama" ] && [ "$pkg" != "gamemode" ] && [ "$pkg" != "gamescope" ] && [ "$pkg" != "fish" ] && [ "$pkg" != "zsh" ] && [ "$pkg" != "oh-my-zsh" ]; then
            sudo tee -a "$config_file" > /dev/null << EOF
    ${pkg}
EOF
        fi
    done

    case $desktop in
        gnome)
            sudo tee -a "$config_file" > /dev/null << EOF
EOF
            ;;
        plasma)
            sudo tee -a "$config_file" > /dev/null << EOF
EOF
            ;;
        cosmic)
            sudo tee -a "$config_file" > /dev/null << EOF
EOF
            ;;
        hyprland)
            sudo tee -a "$config_file" > /dev/null << EOF
EOF
            ;;
    esac

    if [ "$recommended" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  ];
  programs.firefox.enable = true;
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
  hardware.firmware = [ pkgs.linux-firmware ];
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
    
    # Opcionais - Descomente se quiser usar:
    # lanzaboote = {
    #   url = "github:nix-community/lanzaboote/v0.4.3";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nix-flatpak.url = "github:gmodena/nix-flatpak";
    # preload-ng.url = "github:miguel-b-p/preload-ng";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... } @ inputs:
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
            # Descomente os módulos abaixo se tiver descomentado os inputs correspondentes:
            # nix-flatpak.nixosModules.nix-flatpak
            # lanzaboote.nixosModules.lanzaboote
            # preload-ng.nixosModules.default
            # { services.preload-ng.enable = true; }
          ];
        };
      };

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
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
    echo "   e descomente as linhas dos inputs e módulos que deseja usar"
    echo
    echo "2. No arquivo /etc/nixos/configuration.nix, descomente as linhas"
    echo "   relacionadas aos módulos que você ativou no flake.nix"
    echo
    echo "3. Execute para ativar:"
    echo "   sudo nixos-rebuild switch --flake /etc/nixos#$hostname"
    echo
    echo "4. Para atualizar as entradas do flake:"
    echo "   sudo nix flake update --flake /etc/nixos"
    echo
    echo "NOTA: Os experimental-features 'nix-command' e 'flakes'"
    echo "já estão habilitados no configuration.nix gerado."
    echo "============================================="
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
    select_swap_size
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
    create_swap
    generate_config
    generate_flake
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
