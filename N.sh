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
        echo "1) Português Brasileiro (br)"
        echo "2) English US (us)"
        read -p "Opção: " kb_opt
        case $kb_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $kb_opt in
        1)
            echo "br" > "$STATE_DIR/console_keymap"
            echo "br" > "$STATE_DIR/xkb_layout"
            echo "" > "$STATE_DIR/xkb_variant"
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
        echo "4) Nenhum (apenas terminal)"
        read -p "Opção: " de_opt
        case $de_opt in
            1|2|3|4) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_wireless_backend() {
    while true; do
        clear
        echo "=== BACKEND DE REDE SEM FIO / WIRELESS BACKEND ==="
        echo "1) iwd (mais leve, melhor performance)"
        echo "2) wpa_supplicant (padrão, maior compatibilidade)"
        read -p "Opção: " net_opt
        case $net_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $net_opt in
        1) echo "iwd" > "$STATE_DIR/wireless_backend" ;;
        2) echo "wpa_supplicant" > "$STATE_DIR/wireless_backend" ;;
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

select_flakes() {
    clear
    echo "=== FLAKES (EXPERIMENTAL) ==="
    if confirm "Criar arquivo flake.nix de exemplo?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
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
    echo "- Preload inteligente"
    echo "- Regras udev para dispositivos"
    echo
    if confirm "Aplicar configurações recomendadas?"; then
        echo "yes" > "$STATE_DIR/recommended"
    else
        echo "no" > "$STATE_DIR/recommended"
    fi
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
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1M count=$((swap_size * 1024)) status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
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
        echo "Swap: ${swap}GB"
    fi
    echo "Filesystem: $(cat "$STATE_DIR/filesystem")"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "GPU Driver: $(cat "$STATE_DIR/gpu_driver")"
    echo "Wireless: $(cat "$STATE_DIR/wireless_backend")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "TRIM SSD: $(cat "$STATE_DIR/trim")"
    echo "Criptografia: $(cat "$STATE_DIR/encryption")"
    echo "Flakes: $(cat "$STATE_DIR/flakes")"
    echo "Configurações recomendadas: $(cat "$STATE_DIR/recommended")"
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
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local trim=$(cat "$STATE_DIR/trim")
    local encryption=$(cat "$STATE_DIR/encryption")
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local wireless_backend=$(cat "$STATE_DIR/wireless_backend")
    local swap_size=$(cat "$STATE_DIR/swap")
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local luks_uuid=$(cat "$STATE_DIR/luks_uuid" 2>/dev/null || echo "")
    local recommended=$(cat "$STATE_DIR/recommended")
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    sudo tee "$config_file" > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];
EOF

    if [ "$gpu_driver" = "nvidia" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  nixpkgs.config.allowUnfree = true;
EOF
    fi

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

    if [ "$recommended" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    };
    loader.timeout = 2;
    kernelPackages = pkgs.linuxPackages_latest;
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
    else
        sudo tee -a "$config_file" > /dev/null << EOF
    };
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  };
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
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
            cosmic)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
  ];
EOF
                ;;
            gnome)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    evince
    totem
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-software
  ];
EOF
                ;;
            plasma)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];
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
    else
        sudo tee -a "$config_file" > /dev/null << EOF
  services.xserver.videoDrivers = [ "modesetting" ];
EOF
    fi

    if [ "$device_type" = "laptop" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;
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
  services.preload-ng = {
    enable = true;
    settings = {
      cycle = 15;
      memTotal = -5;
      memFree = 70;
      memCached = 10;
      memBuffers = 50;
      minSize = 1000000;
      processes = 60;
      sortStrategy = 0;
      autoSave = 1800;
      mapPrefix = "/nix/store/;/run/current-system/;!/";
      exePrefix = "/nix/store/;/run/current-system/;!/";
    };
  };
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
          options = [ "SETENV" "NOPASSWD" ];
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

    if [ "$wireless_backend" = "iwd" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  networking.wireless.iwd.enable = true;
EOF
    else
        sudo tee -a "$config_file" > /dev/null << EOF
  networking.wireless.enable = true;
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
    starship
EOF

    case $desktop in
        gnome)
            sudo tee -a "$config_file" > /dev/null << EOF
    refine
    gnome-tweaks
    gnome-disk-utility
    vanilla-dmz
    tela-icon-theme
    ffmpegthumbnailer
EOF
            ;;
        plasma)
            sudo tee -a "$config_file" > /dev/null << EOF
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
EOF
            ;;
        cosmic)
            sudo tee -a "$config_file" > /dev/null << EOF
    cosmic-term
    cosmic-files
    cosmic-store
EOF
            ;;
    esac

    if [ "$recommended" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
    lshw
    pciutils
    sbctl
    disfetch
    mission-center
EOF
    fi

    sudo tee -a "$config_file" > /dev/null << EOF
  ];
  programs.firefox.enable = true;
  programs.starship.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
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
    if [ "$(cat "$STATE_DIR/flakes")" != "yes" ]; then
        return
    fi
    local hostname=$(cat "$STATE_DIR/hostname")
    local flake_file="/mnt/etc/nixos/flake.nix"
    sudo tee "$flake_file" > /dev/null << EOF
{
  description = "Configuração NixOS";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  outputs = { self, nixpkgs }: {
    nixosConfigurations.$hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
EOF
    echo "Arquivo flake.nix criado em /mnt/etc/nixos/"
    echo "Para usar flakes:"
    echo "1. Adicione 'nix.settings.experimental-features = [ \"nix-command\" \"flakes\" ];' à configuration.nix"
    echo "2. Use 'nixos-rebuild switch --flake /mnt/etc/nixos#$hostname'"
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
        echo "Pouca RAM detectada. Usando configuração otimizada..."
        export NIX_BUILD_CORES=1
        export NIX_REMOTE=""
        sudo -E nixos-install --no-root-passwd --max-jobs 1 --option substitute false
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
    select_swap_size
    select_gpu_drivers
    select_desktop
    select_wireless_backend
    select_bluetooth
    select_cups
    select_ssd_trim
    select_encryption
    select_flakes
    select_recommended_config
    select_username
    detect_disk
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
