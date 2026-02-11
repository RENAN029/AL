#!/bin/bash
set -e

[ ! -f /etc/nixos/.skip-check ] && { echo "Este script é exclusivo para NixOS."; exit 1; }

STATE_DIR="/tmp/nixos-install-state"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

select_language() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português do Brasil"
    echo "2) English US"
    echo "3) Español"
    read -p "Opção: " lang_opt
    
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/locale" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/locale" ;;
        3) echo "es_ES.UTF-8" > "$STATE_DIR/locale" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/locale" ;;
    esac
    
    echo "Selecione o layout do teclado:"
    echo "1) br-abnt2"
    echo "2) us"
    echo "3) es"
    read -p "Opção: " kb_opt
    
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keymap" ;;
        2) echo "us" > "$STATE_DIR/keymap" ;;
        3) echo "es" > "$STATE_DIR/keymap" ;;
        *) echo "us" > "$STATE_DIR/keymap" ;;
    esac
}

select_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
    echo "/dev/$disk_name" > "$STATE_DIR/disk"
}

setup_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    
    if [ -d /sys/firmware/efi ]; then
        echo "efi" > "$STATE_DIR/bootmode"
        parted "$disk" -- mklabel gpt
        parted "$disk" -- mkpart primary 1MiB 512MiB
        parted "$disk" -- set 1 esp on
        parted "$disk" -- mkpart primary 512MiB 100%
        mkfs.fat -F 32 "${disk}1" -n NIXBOOT
        mkfs.ext4 -L NIXROOT "${disk}2"
    else
        echo "bios" > "$STATE_DIR/bootmode"
        parted "$disk" -- mklabel msdos
        parted "$disk" -- mkpart primary 1MiB 512MiB
        parted "$disk" -- set 1 boot on
        parted "$disk" -- mkpart primary 512MiB 100%
        mkfs.ext4 -L NIXBOOT "${disk}1"
        mkfs.ext4 -L NIXROOT "${disk}2"
    fi
    
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

setup_swap() {
    read -p "Tamanho do swap em GB (ex: 2, 4, 8): " swap_size
    dd if=/dev/zero of=/mnt/.swapfile bs=1G count="$swap_size" status=progress
    chmod 600 /mnt/.swapfile
    mkswap /mnt/.swapfile
    swapon /mnt/.swapfile
    echo "$swap_size" > "$STATE_DIR/swapsize"
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) Plasma"
    read -p "Opção: " de_opt
    echo "$de_opt" > "$STATE_DIR/desktop"
}

setup_user() {
    read -p "Nome de usuário: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Senha para $username: " password1
    echo
    read -s -p "Confirme a senha: " password2
    echo
    
    if [ "$password1" != "$password2" ]; then
        echo "Senhas não conferem."
        exit 1
    fi
    
    echo "$password1" > "$STATE_DIR/userpass"
}

generate_config() {
    nixos-generate-config --root /mnt
    
    local locale=$(cat "$STATE_DIR/locale")
    local keymap=$(cat "$STATE_DIR/keymap")
    local username=$(cat "$STATE_DIR/username")
    local userpass=$(cat "$STATE_DIR/userpass")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bootmode=$(cat "$STATE_DIR/bootmode")
    local disk=$(cat "$STATE_DIR/disk")
    local swapsize=$(cat "$STATE_DIR/swapsize")
    
    local hashed_password=$(mkpasswd -m sha-512 "$userpass")
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = 
    if "$bootmode" == "efi" then {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    } else {
      grub.enable = true;
      grub.device = "$disk";
      grub.version = 2;
    };
  
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  services.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  i18n.defaultLocale = "$locale";
  console.keyMap = "$keymap";
  
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  
  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];
  
  users.users."$username" = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" "scanner" ];
    shell = pkgs.bash;
    hashedPassword = "$hashed_password";
  };
  
  security.sudo.extraRules = [
    { groups = [ "wheel" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];
  
  swapDevices = [ { device = "/.swapfile"; size = $((swapsize * 1024)); } ];
  
EOF

    case $desktop in
        1)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers
    firefox
  ];
EOF
            ;;
        2)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.systemPackages = with pkgs; [
    gnome-initial-setup gnome-console gnome-software gnome-tweaks
    gnome-disk-utility gnome-backgrounds firefox
  ];
EOF
            ;;
        3)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = with pkgs; [
    konsole dolphin kdeconnect partitionmanager ark firefox
  ];
EOF
            ;;
    esac
    
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  system.stateVersion = "23.11";
}
EOF

    sed -i "s|device = \"/dev/sda1\"|device = \"/dev/disk/by-label/NIXBOOT\"|g" /mnt/etc/nixos/hardware-configuration.nix
    sed -i "s|device = \"/dev/sda2\"|device = \"/dev/disk/by-label/NIXROOT\"|g" /mnt/etc/nixos/hardware-configuration.nix
}

main() {
    clear
    echo "=== Instalador NixOS ==="
    
    select_language
    select_disk
    confirm "Particionar e formatar $disk? TODOS OS DADOS SERÃO PERDIDOS" && setup_partitions || exit 1
    setup_swap
    select_desktop
    setup_user
    generate_config
    
    echo "Iniciando instalação..."
    nixos-install --root /mnt --no-root-passwd
    
    echo "Instalação concluída! Reinicie o sistema."
}

main
