#!/bin/bash
set -e

# Configurações
STATE_DIR="/tmp/nixos-installer-state"
mkdir -p "$STATE_DIR"

confirm() {
    read -p "$1 (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

detect_disks() {
    lsblk -d -o NAME,SIZE,MODEL | grep -v "NAME"
}

partition_disk() {
    local disk="$1"
    
    echo "Formatando $disk..."
    
    if [ "$boot_mode" = "uefi" ]; then
        parted $disk --script mklabel gpt
        parted $disk --script mkpart primary fat32 1MB 512MB
        parted $disk --script set 1 esp on
        parted $disk --script mkpart primary ext4 512MB 100%
        
        mkfs.fat -F 32 ${disk}1
        fatlabel ${disk}1 NIXBOOT
        mkfs.ext4 ${disk}2 -L NIXROOT
    else
        parted $disk --script mklabel msdos
        parted $disk --script mkpart primary ext4 1MB 512MB
        parted $disk --script set 1 boot on
        parted $disk --script mkpart primary ext4 512MB 100%
        
        mkfs.ext4 ${disk}1 -L NIXBOOT
        mkfs.ext4 ${disk}2 -L NIXROOT
    fi
    
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

configure_basic() {
    echo "Configurando sistema básico..."
    
    nixos-generate-config --root /mnt
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.grub = {
    enable = true;
    device = "$disk";
  };
  
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
  
  time.timeZone = "$timezone";
  
  i18n.defaultLocale = "$locale";
  
  users.users.$username = {
    isNormalUser = true;
    description = "$fullname";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };
  
  environment.systemPackages = with pkgs; [
    vim wget curl git
  ];
  
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
  };
}
EOF
}

add_desktop() {
    local desktop="$1"
    
    case $desktop in
        "gnome")
            echo "Instalando GNOME..."
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs.gnome; [
    gnome-terminal
  ];
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
EOF
            ;;
        "plasma")
            echo "Instalando Plasma..."
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
EOF
            ;;
        "xfce")
            echo "Instalando XFCE..."
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
EOF
            ;;
        "hyprland")
            echo "Instalando Hyprland..."
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  programs.hyprland.enable = true;
  services.xserver.displayManager.sddm.enable = true;
EOF
            ;;
    esac
}

install_system() {
    echo "Instalando NixOS..."
    nixos-install --no-root-passwd
    
    echo "Configurando senha do usuário..."
    arch-chroot /mnt passwd $username
    
    echo "Instalação completa!"
    echo "Reinicie o sistema com: umount -R /mnt && reboot"
}

main() {
    clear
    echo "=== NixOS Minimal Installer ==="
    
    echo "Discos disponíveis:"
    detect_disks
    
    read -p "Disco para instalar (ex: /dev/sda): " disk
    [ -z "$disk" ] && exit 1
    
    read -p "Modo de boot (uefi/bios): " boot_mode
    [ -z "$boot_mode" ] && boot_mode="bios"
    
    read -p "Hostname: " hostname
    [ -z "$hostname" ] && hostname="nixos"
    
    read -p "Nome de usuário: " username
    [ -z "$username" ] && username="user"
    
    read -p "Nome completo: " fullname
    [ -z "$fullname" ] && fullname="$username"
    
    read -p "Timezone (ex: America/Sao_Paulo): " timezone
    [ -z "$timezone" ] && timezone="UTC"
    
    read -p "Locale (ex: en_US.UTF-8): " locale
    [ -z "$locale" ] && locale="en_US.UTF-8"
    
    clear
    echo "=== Ambientes Desktop ==="
    echo "1) GNOME"
    echo "2) Plasma (KDE)"
    echo "3) XFCE"
    echo "4) Hyprland"
    echo "5) Nenhum (apenas CLI)"
    
    read -p "Selecione (1-5): " de_choice
    
    partition_disk "$disk"
    configure_basic
    
    case $de_choice in
        1) add_desktop "gnome" ;;
        2) add_desktop "plasma" ;;
        3) add_desktop "xfce" ;;
        4) add_desktop "hyprland" ;;
        *) ;;
    esac
    
    if confirm "Iniciar instalação?"; then
        install_system
    else
        echo "Instalação cancelada."
    fi
}

main
