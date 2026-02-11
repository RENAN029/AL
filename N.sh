#!/bin/bash
set -e

STATE_DIR="/tmp/nixos_install_state"
mkdir -p "$STATE_DIR"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

error_exit() {
    echo -e "${COLOR_RED}[ERRO] $1${COLOR_RESET}" >&2
    exit 1
}

info() {
    echo -e "${COLOR_BLUE}[INFO] $1${COLOR_RESET}"
}

success() {
    echo -e "${COLOR_GREEN}[SUCESSO] $1${COLOR_RESET}"
}

warning() {
    echo -e "${COLOR_YELLOW}[AVISO] $1${COLOR_RESET}"
}

confirm() {
    local prompt="$1"
    local resposta
    read -p "$prompt (s/N): " resposta
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "Este script deve ser executado como root"
    fi
}

detect_disk() {
    local disks=($(lsblk -d -o NAME,TYPE,SIZE,MODEL | grep disk | awk '{print $1}'))
    
    if [ ${#disks[@]} -eq 0 ]; then
        error_exit "Nenhum disco encontrado"
    fi
    
    echo "Discos disponíveis:"
    for i in "${!disks[@]}"; do
        local disk="/dev/${disks[$i]}"
        local size=$(lsblk -d -o SIZE "$disk" | tail -n1)
        local model=$(lsblk -d -o MODEL "$disk" | tail -n1)
        echo "$((i+1))) $disk - $size - $model"
    done
    
    local choice
    read -p "Selecione o disco para instalação (1-${#disks[@]}): " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#disks[@]}" ]; then
        error_exit "Opção inválida"
    fi
    
    echo "/dev/${disks[$((choice-1))]}"
}

select_language() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português do Brasil"
    echo "2) English US"
    echo "3) Español"
    
    local choice
    read -p "Opção (1-3): " choice
    
    case $choice in
        1)
            echo "pt_BR.UTF-8" > "$STATE_DIR/locale"
            echo "br" > "$STATE_DIR/keyboard"
            ;;
        2)
            echo "en_US.UTF-8" > "$STATE_DIR/locale"
            echo "us" > "$STATE_DIR/keyboard"
            ;;
        3)
            echo "es_ES.UTF-8" > "$STATE_DIR/locale"
            echo "es" > "$STATE_DIR/keyboard"
            ;;
        *)
            warning "Opção inválida, usando inglês US"
            echo "en_US.UTF-8" > "$STATE_DIR/locale"
            echo "us" > "$STATE_DIR/keyboard"
            ;;
    esac
}

select_timezone() {
    echo "Selecione a região:"
    echo "1) America/Sao_Paulo"
    echo "2) America/New_York"
    echo "3) Europe/Lisbon"
    echo "4) Europe/Madrid"
    echo "5) Outro"
    
    local choice
    read -p "Opção (1-5): " choice
    
    case $choice in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) echo "America/New_York" > "$STATE_DIR/timezone" ;;
        3) echo "Europe/Lisbon" > "$STATE_DIR/timezone" ;;
        4) echo "Europe/Madrid" > "$STATE_DIR/timezone" ;;
        5)
            read -p "Digite o fuso horário (ex: America/Sao_Paulo): " tz
            echo "$tz" > "$STATE_DIR/timezone"
            ;;
        *)
            warning "Opção inválida, usando America/Sao_Paulo"
            echo "America/Sao_Paulo" > "$STATE_DIR/timezone"
            ;;
    esac
}

select_swap_size() {
    local mem_total=$(free -g | awk '/^Mem:/ {print $2}')
    
    if [ "$mem_total" -lt 2 ]; then
        echo "2G" > "$STATE_DIR/swap_size"
    elif [ "$mem_total" -lt 4 ]; then
        echo "4G" > "$STATE_DIR/swap_size"
    elif [ "$mem_total" -lt 8 ]; then
        echo "8G" > "$STATE_DIR/swap_size"
    else
        echo "16G" > "$STATE_DIR/swap_size"
    fi
    
    warning "Tamanho do swap sugerido: $(cat "$STATE_DIR/swap_size")"
    if confirm "Usar tamanho sugerido?"; then
        return
    fi
    
    read -p "Digite o tamanho do swap (ex: 4G, 2G): " swap_size
    echo "$swap_size" > "$STATE_DIR/swap_size"
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) Plasma (KDE)"
    echo "4) Instalação mínima (sem desktop)"
    
    local choice
    read -p "Opção (1-4): " choice
    
    case $choice in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "minimal" > "$STATE_DIR/desktop" ;;
        *)
            warning "Opção inválida, usando instalação mínima"
            echo "minimal" > "$STATE_DIR/desktop"
            ;;
    esac
}

partition_disk() {
    local disk="$1"
    local is_efi=false
    
    [ -d /sys/firmware/efi ] && is_efi=true
    
    info "Particionando disco $disk"
    
    sgdisk -Z "$disk"
    
    if $is_efi; then
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:NIXBOOT "$disk"
        sgdisk -n 2:0:0 -t 2:8300 -c 2:NIXROOT "$disk"
    else
        sgdisk -n 1:0:+512M -t 1:8300 -c 1:NIXBOOT "$disk"
        sgdisk -n 2:0:0 -t 2:8300 -c 2:NIXROOT "$disk"
    fi
    
    partprobe "$disk"
    sleep 2
    
    local boot_part="${disk}1"
    local root_part="${disk}2"
    
    info "Formatando partições"
    
    if $is_efi; then
        mkfs.fat -F 32 -n NIXBOOT "$boot_part"
    else
        mkfs.ext4 -L NIXBOOT "$boot_part"
    fi
    
    mkfs.ext4 -L NIXROOT "$root_part"
    
    echo "$boot_part" > "$STATE_DIR/boot_part"
    echo "$root_part" > "$STATE_DIR/root_part"
    echo "$is_efi" > "$STATE_DIR/efi_mode"
}

mount_partitions() {
    local root_part=$(cat "$STATE_DIR/root_part")
    local boot_part=$(cat "$STATE_DIR/boot_part")
    
    info "Montando partições"
    
    mount "$root_part" /mnt
    mkdir -p /mnt/boot
    mount "$boot_part" /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap_size")
    
    info "Criando arquivo de swap ($swap_size)"
    
    dd if=/dev/zero of=/mnt/.swapfile bs=1G count=${swap_size%G} status=progress
    chmod 600 /mnt/.swapfile
    mkswap /mnt/.swapfile
}

generate_nix_config() {
    local username="$1"
    local desktop=$(cat "$STATE_DIR/desktop")
    local locale=$(cat "$STATE_DIR/locale")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local timezone=$(cat "$STATE_DIR/timezone")
    local is_efi=$(cat "$STATE_DIR/efi_mode")
    local boot_device=$(cat "$STATE_DIR/root_part" | sed 's/[0-9]\+$//')
    
    info "Gerando configuração do NixOS"
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader = {
    efi = {
      canTouchEfiVariables = lib.mkIf ${is_efi} true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      device = ${if is_efi then ''"nodev"'' else ''"${boot_device}"''};
      efiSupport = ${is_efi};
      useOSProber = false;
    };
  };

  # Locale
  i18n = {
    defaultLocale = "${locale}";
    extraLocaleSettings = {
      LC_ADDRESS = "${locale}";
      LC_IDENTIFICATION = "${locale}";
      LC_MEASUREMENT = "${locale}";
      LC_MONETARY = "${locale}";
      LC_NAME = "${locale}";
      LC_NUMERIC = "${locale}";
      LC_PAPER = "${locale}";
      LC_TELEPHONE = "${locale}";
      LC_TIME = "${locale}";
    };
  };

  # Console keyboard
  console.keyMap = "${keyboard}";

  # X11 keyboard
  services.xserver = {
    enable = true;
    xkb = {
      layout = "${keyboard}";
      variant = "";
    };
  };

  # Time
  time = {
    timeZone = "${timezone}";
    hardwareClockInLocalTime = false;
  };

  # Network
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };
  services.iwd.enable = true;
  services.resolved.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Printing
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint pkgs.hplip ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # NTP
  services.timesyncd.enable = true;
  networking.timeServers = [ "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" "3.pool.ntp.org" ];

  # Swap file
  swapDevices = [ { device = "/.swapfile"; } ];

  # User
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "bluetooth" "lp" "scanner" ];
    shell = pkgs.bash;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Desktop environment
  ${if desktop == "cosmic" then ''
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];
  '' else if desktop == "gnome" then ''
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  environment.systemPackages = with pkgs; [
    gnome.gnome-initial-setup
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
  ];
  '' else if desktop == "plasma" then ''
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
  environment.systemPackages = with pkgs; [
    konsole
    dolphin
    kdeconnect
    partition-manager
    ark
  ];
  '' else ""}

  # Essential packages
  environment.systemPackages = with pkgs; [
    nano
    vim
    git
    curl
    wget
    htop
    ntfs3g
    exfat
    unzip
    zip
    pciutils
    usbutils
  ];

  # Zram
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Firmware
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "25.11";
}
EOF
}

setup_user_password() {
    local username="$1"
    
    info "Defina a senha para o usuário $username"
    nixos-enter --root /mnt -c "passwd $username"
}

install_system() {
    local username="$1"
    
    info "Iniciando instalação do NixOS"
    
    nixos-generate-config --root /mnt
    
    generate_nix_config "$username"
    
    info "Configurando senha do root"
    nixos-enter --root /mnt -c "passwd"
    
    cd /mnt
    nixos-install --no-root-passwd
    cd -
    
    setup_user_password "$username"
}

main() {
    clear
    echo "=== Instalador NixOS 25.11 ==="
    echo
    
    check_root
    
    if [ -f /mnt/etc/NIXOS ]; then
        if confirm "Sistema detectado em /mnt. Deseja sobrescrever?"; then
            umount -R /mnt 2>/dev/null || true
        else
            error_exit "Instalação cancelada"
        fi
    fi
    
    local disk=$(detect_disk)
    echo "$disk" > "$STATE_DIR/disk"
    
    select_language
    select_timezone
    select_swap_size
    select_desktop
    
    read -p "Nome de usuário: " username
    while [ -z "$username" ]; do
        read -p "Nome de usuário não pode ser vazio: " username
    done
    
    echo "=== Resumo da instalação ==="
    echo "Disco: $disk"
    echo "Idioma: $(cat "$STATE_DIR/locale")"
    echo "Teclado: $(cat "$STATE_DIR/keyboard")"
    echo "Fuso horário: $(cat "$STATE_DIR/timezone")"
    echo "Swap: $(cat "$STATE_DIR/swap_size")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "Usuário: $username"
    
    if ! confirm "Iniciar instalação?"; then
        error_exit "Instalação cancelada"
    fi
    
    partition_disk "$disk"
    mount_partitions
    create_swap
    
    install_system "$username"
    
    success "Instalação concluída!"
    warning "Remova a mídia de instalação e reinicie o sistema"
    
    if confirm "Reiniciar agora?"; then
        reboot
    fi
}

main
