#!/bin/bash
set -e

STATE_DIR="/tmp/nixos_installer"
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

select_language() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) Inglês Americano (en_US.UTF-8)"
    read -p "Opção: " lang_opt
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado:"
    echo "1) Português Brasileiro (br)"
    echo "2) Inglês Americano (us)"
    read -p "Opção: " kb_opt
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_swap() {
    echo "Tamanho do arquivo swap (GB):"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    read -p "Opção: " swap_opt
    case $swap_opt in
        1) echo "2" > "$STATE_DIR/swap" ;;
        2) echo "4" > "$STATE_DIR/swap" ;;
        3) echo "8" > "$STATE_DIR/swap" ;;
        *) echo "2" > "$STATE_DIR/swap" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop (apenas um):"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) Plasma"
    echo "4) Nenhum (minimal)"
    read -p "Opção: " de_opt
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

get_user_input() {
    read -p "Nome de usuário: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Senha: " password
    echo
    read -s -p "Confirme a senha: " password2
    echo
    if [ "$password" != "$password2" ]; then
        echo "Senhas não coincidem"
        exit 1
    fi
    echo "$password" > "$STATE_DIR/password"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/language)"
    echo "Teclado: $(cat $STATE_DIR/keyboard)"
    echo "Swap: $(cat $STATE_DIR/swap)GB"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "=============================="
    if ! confirm "Iniciar instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

find_largest_free_space() {
    local disk
    disk=$(lsblk -b -n -o NAME,SIZE,TYPE | grep disk | sort -k2 -rn | head -1 | awk '{print $1}')
    echo "/dev/$disk"
}

partition_disk() {
    local disk=$1
    local efi_part="${disk}1"
    local root_part="${disk}2"
    
    if [ -d /sys/firmware/efi ]; then
        parted $disk -- mklabel gpt
        parted $disk -- mkpart primary fat32 1MiB 512MiB
        parted $disk -- set 1 esp on
        parted $disk -- mkpart primary ext4 512MiB 100%
        mkfs.fat -F 32 "$efi_part"
        fatlabel "$efi_part" NIXBOOT
    else
        parted $disk -- mklabel msdos
        parted $disk -- mkpart primary ext4 1MiB 512MiB
        parted $disk -- set 1 boot on
        parted $disk -- mkpart primary ext4 512MiB 100%
        mkfs.ext4 -L NIXBOOT "$efi_part"
    fi
    
    mkfs.ext4 -F -L NIXROOT "$root_part"
}

create_swap() {
    local swap_size=$(cat $STATE_DIR/swap)
    local swap_blocks=$((swap_size * 1024 * 1024))
    dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=$swap_blocks status=progress
    chmod 600 /mnt/.swapfile
    mkswap /mnt/.swapfile
    swapon /mnt/.swapfile
}

generate_config() {
    local language=$(cat $STATE_DIR/language)
    local keyboard=$(cat $STATE_DIR/keyboard)
    local desktop=$(cat $STATE_DIR/desktop)
    local username=$(cat $STATE_DIR/username)
    local disk=$(cat $STATE_DIR/disk)
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader = {
    grub = {
      enable = true;
      device = "$disk";
      efiSupport = ${if [ -d /sys/firmware/efi ]; then "true"; else "false"; fi};
      enableCryptodisk = false;
    };
    efi = {
      canTouchEfiVariables = ${if [ -d /sys/firmware/efi ]; then "true"; else "false"; fi};
    };
  };

  # Locale
  i18n = {
    defaultLocale = "$language";
    extraLocaleSettings = {
      LC_TIME = "$language";
      LC_MONETARY = "$language";
      LC_PAPER = "$language";
      LC_MEASUREMENT = "$language";
    };
    supportedLocales = [ "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
  };

  # Console
  console = {
    font = "Lat2-Terminus16";
    keyMap = "$keyboard";
    useXkbConfig = true;
  };

  services.xserver.xkb.layout = "$keyboard";

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Printing
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
  };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # NTP
  services.timesyncd.enable = true;
  time.timeZone = "America/Sao_Paulo";

  # User
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "bluetooth" "lp" ];
    shell = pkgs.bash;
    initialPassword = "$(cat $STATE_DIR/password)";
  };
  
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Swap
  swapDevices = [{
    device = "/.swapfile";
  }];

  # Packages
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    curl
    wget
    htop
    firefox
    iwd
    networkmanagerapplet
    bluez
    bluez-tools
    cups
    system-config-printer
  ];

  # Desktop Environment
EOF

    case $desktop in
        cosmic)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];
EOF
            ;;
        gnome)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.systemPackages = with pkgs; [
    gnome-initial-setup
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
  ];
EOF
            ;;
        plasma)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.systemPackages = with pkgs; [
    plasma6.plasma-meta
    konsole
    dolphin
    kdeconnect-kde
    partition-manager
    ark
  ];
EOF
            ;;
        none)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = false;
EOF
            ;;
    esac

    cat >> /mnt/etc/nixos/configuration.nix << EOF

  # System version
  system.stateVersion = "25.11";
}
EOF
}

update_hardware_config() {
    cat > /mnt/etc/nixos/hardware-configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "${if [ -d /sys/firmware/efi ]; then "vfat"; else "ext4"; fi}";
  };
}
EOF
}

main() {
    clear
    echo "=== Instalador Automático NixOS ==="
    
    select_language
    select_keyboard
    select_swap
    select_desktop
    get_user_input
    
    local disk=$(find_largest_free_space)
    echo "$disk" > "$STATE_DIR/disk"
    
    show_summary
    
    echo "Particionando disco $disk..."
    partition_disk "$disk"
    
    echo "Montando partições..."
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    echo "Criando arquivo swap..."
    create_swap
    
    echo "Gerando configuração básica..."
    nixos-generate-config --root /mnt
    
    echo "Configurando sistema..."
    generate_config
    update_hardware_config
    
    echo "Iniciando instalação do NixOS..."
    cd /mnt
    nixos-install --no-root-passwd --option substitute false
    
    echo "Instalação concluída!"
    echo "Remova o meio de instalação e reinicie."
}

main "$@"
