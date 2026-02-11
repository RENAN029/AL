#!/bin/bash
set -e

STATE_DIR="/tmp/nixos_install"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

select_keyboard() {
    echo "Layouts disponíveis: us, br, fr, de, es, it, jp"
    read -p "Selecione o layout do teclado [us]: " kb_layout
    kb_layout=${kb_layout:-us}
    echo "$kb_layout" > "$STATE_DIR/keyboard"
}

select_language() {
    echo "Idiomas disponíveis: en_US, pt_BR, fr_FR, de_DE, es_ES, it_IT, ja_JP"
    read -p "Selecione o idioma do sistema [en_US]: " sys_lang
    sys_lang=${sys_lang:-en_US}
    echo "$sys_lang" > "$STATE_DIR/language"
}

partition_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    read -p "Digite o disco para instalar (ex: sda, nvme0n1): " disk
    
    if confirm "Isso irá APAGAR TODOS OS DADOS em /dev/$disk. Continuar?"; then
        disk="/dev/$disk"
        
        if [ -d /sys/firmware/efi ]; then
            echo "Modo UEFI detectado"
            parted $disk -- mklabel gpt
            parted $disk -- mkpart ESP fat32 1MiB 512MiB
            parted $disk -- set 1 esp on
            parted $disk -- mkpart primary 512MiB 100%
            
            mkfs.fat -F 32 -n NIXBOOT ${disk}1
            mkfs.ext4 -L NIXROOT ${disk}2
        else
            echo "Modo BIOS detectado"
            parted $disk -- mklabel msdos
            parted $disk -- mkpart primary ext4 1MiB 100%
            parted $disk -- set 1 boot on
            
            mkfs.ext4 -L NIXROOT ${disk}1
        fi
        
        mount /dev/disk/by-label/NIXROOT /mnt
        mkdir -p /mnt/boot
        [ -d /sys/firmware/efi ] && mount /dev/disk/by-label/NIXBOOT /mnt/boot
    fi
}

setup_swap() {
    read -p "Tamanho do swap em GB [2]: " swap_size
    swap_size=${swap_size:-2}
    
    dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$swap_size status=progress
    chmod 600 /mnt/.swapfile
    mkswap /mnt/.swapfile
    swapon /mnt/.swapfile
    echo "/.swapfile" > "$STATE_DIR/swapfile"
}

setup_network() {
    read -p "Nome do host: " hostname
    echo "$hostname" > "$STATE_DIR/hostname"
}

setup_user() {
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    read -s -p "Senha do usuário: " userpass
    echo
    read -s -p "Confirme a senha: " userpass2
    echo
    
    if [ "$userpass" != "$userpass2" ]; then
        echo "Senhas não conferem"
        exit 1
    fi
    
    mkpasswd -m sha-512 "$userpass" > "$STATE_DIR/userpass"
}

setup_region() {
    read -p "Fuso horário (ex: America/Sao_Paulo, Europe/London): " timezone
    echo "$timezone" > "$STATE_DIR/timezone"
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) Nenhum (mínimo)"
    read -p "Opção [4]: " desktop_choice
    echo "${desktop_choice:-4}" > "$STATE_DIR/desktop"
}

generate_config() {
    nixos-generate-config --root /mnt
    
    keyboard=$(cat "$STATE_DIR/keyboard")
    language=$(cat "$STATE_DIR/language")
    hostname=$(cat "$STATE_DIR/hostname")
    username=$(cat "$STATE_DIR/username")
    userpass=$(cat "$STATE_DIR/userpass")
    timezone=$(cat "$STATE_DIR/timezone")
    desktop=$(cat "$STATE_DIR/desktop")
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader = if [ -d /sys/firmware/efi ] then {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  } else {
    grub.enable = true;
    grub.device = "${disk}";
    grub.version = 2;
  };
  
  i18n.defaultLocale = "${language}.UTF-8";
  console.keyMap = "${keyboard}";
  time.timeZone = "${timezone}";
  services.ntp.enable = true;
  networking.hostName = "${hostname}";
  networking.networkmanager.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };
  
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" "scanner" ];
    shell = pkgs.bash;
    hashedPassword = "${userpass}";
  };
  
  security.sudo.wheelNeedsPassword = false;
  
  swapDevices = [{
    device = "/.swapfile";
  }];
  
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    htop
    iwd
    firefox
  ];
EOF

    case $desktop in
        1)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
    cosmic-edit
    cosmic-settings
  ];
EOF
            ;;
        2)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
    gnome-console
    gnome-software
  ];
EOF
            ;;
        3)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = with pkgs; [
    plasma5Packages.plasma-meta
    plasma5Packages.konsole
    plasma5Packages.dolphin
    plasma5Packages.kdeconnect-kde
    plasma5Packages.partitionmanager
    ark
  ];
EOF
            ;;
        4)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.getty.autologinUser = "${username}";
EOF
            ;;
    esac

    echo "}" >> /mnt/etc/nixos/configuration.nix
}

install_system() {
    echo "Iniciando instalação..."
    nixos-install --no-root-passwd
    
    echo "Instalação concluída. Remova a mídia de instalação e reinicie."
}

main() {
    clear
    echo "=== Instalador NixOS ==="
    
    select_keyboard
    select_language
    partition_disk
    setup_swap
    setup_network
    setup_user
    setup_region
    select_desktop
    generate_config
    
    if confirm "Iniciar instalação?"; then
        install_system
    else
        echo "Instalação cancelada"
        exit 0
    fi
}

main
