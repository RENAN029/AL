#!/bin/bash
set -e

STATE_DIR="/tmp/nixos_install_state"
mkdir -p "$STATE_DIR"

total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_gb=$((total_ram / 1024 / 1024))
if [ $total_ram_gb -le 4 ]; then
    low_memory=1
else
    low_memory=0
fi

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
        echo "1) Português Brasileiro (br)"
        echo "2) English US (us)"
        read -p "Opção: " kb_opt
        case $kb_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
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
        echo "2) btrfs (com snapshots e compressão zstd automática)"
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

select_encryption() {
    clear
    echo "=== CRIPTOGRAFIA / ENCRYPTION ==="
    if confirm "Criptografar disco com LUKS?"; then
        echo "yes" > "$STATE_DIR/encryption"
    else
        echo "no" > "$STATE_DIR/encryption"
    fi
}

select_gpu_drivers() {
    while true; do
        clear
        echo "=== DRIVERS DE GPU / GPU DRIVERS ==="
        echo "1) NVIDIA (proprietário - módulos open para Turing+)"
        echo "2) Intel/AMD (open source)"
        read -p "Opção: " gpu_opt
        case $gpu_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    case $gpu_opt in
        1) 
            echo "nvidia" > "$STATE_DIR/gpu_driver"
            echo "yes" > "$STATE_DIR/unfree"
            ;;
        2) 
            echo "intel-amd" > "$STATE_DIR/gpu_driver"
            echo "no" > "$STATE_DIR/unfree"
            ;;
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
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    clear
    if confirm "Habilitar suporte a impressão (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_ssd_trim() {
    clear
    if confirm "Habilitar TRIM para SSD?"; then
        echo "yes" > "$STATE_DIR/trim"
    else
        echo "no" > "$STATE_DIR/trim"
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

select_optimizations() {
    clear
    echo "=== OTIMIZAÇÕES RECOMENDADAS / RECOMMENDED OPTIMIZATIONS ==="
    echo "Aplicar configurações recomendadas de desempenho e estabilidade?"
    echo "Inclui: kernel parameters, sysctl tuning, ananicy, earlyoom, zram, udev rules"
    if confirm "Aplicar otimizações recomendadas?"; then
        echo "yes" > "$STATE_DIR/optimizations"
    else
        echo "no" > "$STATE_DIR/optimizations"
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
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f -L NIXROOT ${disk}2
        else
            sudo mkfs.ext4 -F -L NIXROOT ${disk}2
        fi
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        sudo parted $disk -- mklabel msdos
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 boot on
        sudo parted $disk -- mkpart primary 512MB 100%
        sudo mkfs.ext4 -F -L NIXBOOT ${disk}1
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f -L NIXROOT ${disk}2
        else
            sudo mkfs.ext4 -F -L NIXROOT ${disk}2
        fi
    fi
}

setup_encryption() {
    local disk=$(cat "$STATE_DIR/disk")
    echo "Configurando criptografia LUKS..."
    sudo cryptsetup luksFormat ${disk}2
    sudo cryptsetup open ${disk}2 cryptroot
    local uuid=$(sudo blkid -s UUID -o value ${disk}2)
    echo "$uuid" > "$STATE_DIR/luks_uuid"
    local fs=$(cat "$STATE_DIR/filesystem")
    if [ "$fs" = "btrfs" ]; then
        sudo mkfs.btrfs /dev/mapper/cryptroot
    else
        sudo mkfs.ext4 /dev/mapper/cryptroot
    fi
}

setup_btrfs_subvolumes() {
    local root_dev
    if [ "$(cat "$STATE_DIR/encryption")" = "yes" ]; then
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
        if [ ! -e /dev/mapper/cryptroot ]; then
            setup_encryption
        fi
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
    echo "Teclado/Keyboard: $(cat "$STATE_DIR/keyboard")"
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
    echo "Otimizações: $(cat "$STATE_DIR/optimizations")"
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
    local keyboard=$(cat "$STATE_DIR/keyboard")
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
    local optimizations=$(cat "$STATE_DIR/optimizations")
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

  boot.loader = {
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
    sudo tee -a "$config_file" > /dev/null << EOF
  };
EOF
    if [ "$optimizations" = "yes" ]; then
        sudo tee -a "$config_file" > /dev/null << EOF
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernelParams = [
    "quiet"
    "splash"
    "transparent_hugepage=always"
    "preempt=full"
  ];
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog" = 0;
    "net.core.netdev_max_backlog" = 4096;
    "fs.file-max" = 2097152;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
EOF
    fi
    sudo tee -a "$config_file" > /dev/null << EOF

  i18n.defaultLocale = "$lang";
  console.keyMap = "$keyboard";
  
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
EOF
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

  services.xserver.enable = true;
  services.xserver.xkb.layout = "$keyboard";
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
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    atomix
    cheese
    epiphany
    evince
    geary
    gedit
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori
    iagno
    tali
    totem
  ];
EOF
                ;;
            plasma)
                sudo tee -a "$config_file" > /dev/null << EOF
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
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
    if [ "$optimizations" = "yes" ]; then
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
    extraArgs = [ "-g" "--avoid" "'^(X|plasma.*|konsole|kwin|wayland|gnome.*)$'" ];
  };
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
  '';
  systemd.services.set-min-free-mem = {
    description = "Set vm.min_free_kbytes dynamically";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig.User = "root";
    serviceConfig.RemainAfterExit = true;
    script = ''
      TOTAL_MEM=''$(awk '/MemTotal/ {printf "%.0f", $2 * 0.01}' /proc/meminfo)
      if [ -n "''$TOTAL_MEM" ] && [ "''$TOTAL_MEM" -gt 0 ]; then
        sysctl -w vm.min_free_kbytes=''$TOTAL_MEM
      fi
    '';
  };
  zramSwap.enable = true;
EOF
    fi
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
    sudo tee -a "$config_file" > /dev/null << EOF

  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" ];
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
EOF
    case $desktop in
        gnome)
            sudo tee -a "$config_file" > /dev/null << EOF
    gnome-tweaks
    gnome-disk-utility
    gnome-software
EOF
            ;;
        plasma)
            sudo tee -a "$config_file" > /dev/null << EOF
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
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
    sudo tee -a "$config_file" > /dev/null << EOF
  ];
  
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
    if [ $low_memory -eq 1 ]; then
        export NIX_BUILD_CORES=1
        export NIX_REMOTE=""
        export NIX_CONF_DIR=/tmp/nix-conf
        mkdir -p $NIX_CONF_DIR
        echo "build-users-group =" > $NIX_CONF_DIR/nix.conf
        echo "cores = 1" >> $NIX_CONF_DIR/nix.conf
        echo "max-jobs = 1" >> $NIX_CONF_DIR/nix.conf
        sudo nixos-install --no-root-passwd --option cores 1 --option max-jobs 1 --option keep-going true --option substitute true
    else
        sudo nixos-install --no-root-passwd
    fi
    echo
    echo "=== INSTALAÇÃO CONCLUÍDA ==="
    echo "Após reiniciar, faça login com usuário: $(cat "$STATE_DIR/username")"
    echo "Digite 'reboot' para reiniciar."
}

main() {
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    select_language
    select_keyboard
    select_timezone
    select_hostname
    select_device_type
    select_filesystem
    select_bootloader
    select_swap_size
    select_encryption
    select_gpu_drivers
    select_desktop
    select_wireless_backend
    select_bluetooth
    select_cups
    select_ssd_trim
    select_flakes
    select_optimizations
    detect_disk
    select_username
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

trap 'echo "Erro detectado. Pressione Enter para continuar..."; read' ERR
main
