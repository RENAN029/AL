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
    echo "Selecione o idioma do sistema:"
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) Inglês Americano (en_US.UTF-8)"
    read -p "Opção: " lang_opcao
    case $lang_opcao in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
        *) select_language ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado:"
    echo "1) Português Brasileiro (br)"
    echo "2) Inglês Americano (us)"
    read -p "Opção: " kb_opcao
    case $kb_opcao in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) select_keyboard ;;
    esac
}

select_swap() {
    echo "Tamanho do arquivo swap (em GB):"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap"
    read -p "Opção: " swap_opcao
    case $swap_opcao in
        1) echo "2" > "$STATE_DIR/swap_size" ;;
        2) echo "4" > "$STATE_DIR/swap_size" ;;
        3) echo "8" > "$STATE_DIR/swap_size" ;;
        4) echo "0" > "$STATE_DIR/swap_size" ;;
        *) select_swap ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) Plasma"
    echo "4) Nenhum (minimal)"
    read -p "Opção: " desktop_opcao
    case $desktop_opcao in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) select_desktop ;;
    esac
}

get_username() {
    read -p "Digite o nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
}

get_password() {
    read -s -p "Digite a senha: " password1
    echo
    read -s -p "Confirme a senha: " password2
    echo
    if [ "$password1" != "$password2" ]; then
        echo "Senhas não coincidem!"
        get_password
    else
        echo "$password1" > "$STATE_DIR/password"
    fi
}

confirm_installation() {
    clear
    echo "=== Opções selecionadas ==="
    echo "Idioma: $(cat $STATE_DIR/language)"
    echo "Teclado: $(cat $STATE_DIR/keyboard)"
    echo "Swap: $(cat $STATE_DIR/swap_size)GB"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "==========================="
    if confirm "Deseja iniciar a instalação?"; then
        return 0
    else
        echo "Instalação cancelada."
        exit 0
    fi
}

detect_and_partition() {
    local disk=""
    
    for dev in /dev/sd* /dev/nvme*; do
        [ -e "$dev" ] || continue
        if [ ! -b "$dev" ]; then
            continue
        fi
        if [[ $dev == *"sd"* ]] || [[ $dev == *"nvme"* ]]; then
            if [ -z "$disk" ]; then
                disk="$dev"
            fi
        fi
    done
    
    if [ -z "$disk" ]; then
        echo "Nenhum disco encontrado!"
        exit 1
    fi
    
    echo "Usando disco: $disk"
    echo "$disk" > "$STATE_DIR/install_disk"
    
    if [ -d /sys/firmware/efi ]; then
        echo "efi" > "$STATE_DIR/boot_mode"
        sudo parted "$disk" -- mklabel gpt
        sudo parted "$disk" -- mkpart primary fat32 1MiB 1024MiB
        sudo parted "$disk" -- set 1 esp on
        sudo mkfs.fat -F 32 -n NIXBOOT "${disk}1"
        sudo parted "$disk" -- mkpart primary ext4 1024MiB 100%
        sudo mkfs.ext4 -L NIXROOT "${disk}2"
    else
        echo "bios" > "$STATE_DIR/boot_mode"
        sudo parted "$disk" -- mklabel msdos
        sudo parted "$disk" -- mkpart primary ext4 1MiB 100%
        sudo parted "$disk" -- set 1 boot on
        sudo mkfs.ext4 -L NIXROOT "${disk}1"
    fi
}

mount_partitions() {
    local disk=$(cat "$STATE_DIR/install_disk")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    
    if [ "$boot_mode" = "efi" ]; then
        sudo mount /dev/disk/by-label/NIXROOT /mnt
        sudo mkdir -p /mnt/boot
        sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    else
        sudo mount /dev/disk/by-label/NIXROOT /mnt
    fi
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap_size")
    
    if [ "$swap_size" != "0" ]; then
        local swap_blocks=$((swap_size * 1024 * 1024))
        sudo dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=$swap_blocks status=none
        sudo chmod 600 /mnt/.swapfile
        sudo mkswap /mnt/.swapfile
    fi
}

generate_config() {
    sudo nixos-generate-config --root /mnt
    
    local language=$(cat "$STATE_DIR/language")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local username=$(cat "$STATE_DIR/username")
    local password=$(cat "$STATE_DIR/password")
    local desktop=$(cat "$STATE_DIR/desktop")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local disk=$(cat "$STATE_DIR/install_disk")
    local swap_size=$(cat "$STATE_DIR/swap_size")
    
    local hashed_password=$(mkpasswd -m sha-512 "$password")
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.grub.enable = true;
EOF

    if [ "$boot_mode" = "efi" ]; then
        sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
EOF
    else
        sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  boot.loader.grub.device = "$disk";
EOF
    fi
    
    sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  
  i18n.defaultLocale = "$language";
  console.keyMap = "$keyboard";
  
  services.xserver.xkb.layout = "$keyboard";
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" "scanner" ];
    shell = pkgs.bash;
    hashedPassword = "$hashed_password";
  };
  
  security.sudo.extraRules = [
    { users = [ "$username" ]; commands = [
      { command = "ALL"; options = [ "NOPASSWD" ]; }
    ]; }
  ];
  
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  
  hardware.pulseaudio.enable = false;
  
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint pkgs.hplip ];
  
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    wget
    htop
    iwd
    networkmanagerapplet
    bluez
    bluez-tools
  ];
EOF

    if [ "$swap_size" != "0" ]; then
        sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  
  swapDevices = [ { device = "/.swapfile"; } ];
EOF
    fi

    case $desktop in
        cosmic)
            sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  
  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
    cosmic-edit
    cosmic-settings
    cosmic-applets
  ];
EOF
            ;;
        gnome)
            sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
  ];
  
  environment.systemPackages = with pkgs; [
    gnome-initial-setup
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
    gnome-terminal
    nautilus
    gedit
  ];
EOF
            ;;
        plasma)
            sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  environment.systemPackages = with pkgs; [
    kdeApplications.konsole
    kdeApplications.dolphin
    kdeApplications.ark
    kdeApplications.partitionmanager
    libsForQt5.kdeconnect-kde
    plasma5.plasma-meta
  ];
EOF
            ;;
        none)
            ;;
    esac
    
    sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
  
  system.stateVersion = "25.11";
}
EOF

    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g" /mnt/etc/nixos/hardware-configuration.nix
    
    if [ "$boot_mode" = "efi" ]; then
        sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g" /mnt/etc/nixos/hardware-configuration.nix
    fi
}

install_system() {
    cd /mnt
    sudo nixos-install --no-root-passwd
}

main() {
    clear
    echo "=== Instalador NixOS ==="
    
    select_language
    select_keyboard
    select_swap
    select_desktop
    get_username
    get_password
    
    confirm_installation
    
    echo "Particionando disco..."
    detect_and_partition
    
    echo "Montando partições..."
    mount_partitions
    
    echo "Criando swap..."
    create_swap
    
    echo "Gerando configuração..."
    generate_config
    
    echo "Instalando sistema..."
    install_system
    
    echo "Instalação concluída! Remova o meio de instalação e reinicie."
}

main
