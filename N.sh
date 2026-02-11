#!/bin/bash
set -e

[ ! -f /etc/nixos/configuration.nix ] && [ ! -d /mnt/etc/nixos ] && { echo "Este script deve ser executado no instalador do NixOS."; exit 1; }

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
}

select_keyboard() {
    echo "Selecione o layout do teclado:"
    echo "1) br-abnt2"
    echo "2) us"
    echo "3) es"
    read -p "Opção: " kb_opt
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        3) echo "es" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    read -p "Digite o nome do disco para instalação (ex: sda, nvme0n1): " disk_name
    echo "/dev/$disk_name" > "$STATE_DIR/install_disk"
}

configure_swap() {
    echo "Tamanho do swap (em GB):"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Personalizado"
    read -p "Opção: " swap_opt
    case $swap_opt in
        1) echo "2" > "$STATE_DIR/swap_size" ;;
        2) echo "4" > "$STATE_DIR/swap_size" ;;
        3) echo "8" > "$STATE_DIR/swap_size" ;;
        4) read -p "Tamanho em GB: " custom_swap; echo "$custom_swap" > "$STATE_DIR/swap_size" ;;
        *) echo "2" > "$STATE_DIR/swap_size" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
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

configure_user() {
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Senha do usuário: " userpass
    echo
    echo "$userpass" > "$STATE_DIR/userpass"
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/install_disk")
    
    if [ -d /sys/firmware/efi ]; then
        echo "Modo UEFI detectado"
        echo "efi" > "$STATE_DIR/boot_mode"
        
        sudo parted "$disk" -- mklabel gpt
        sudo parted "$disk" -- mkpart primary 1MiB 512MiB
        sudo parted "$disk" -- set 1 esp on
        sudo parted "$disk" -- mkpart primary 512MiB 100%
        
        sleep 2
        
        if [[ "$disk" == *"nvme"* ]]; then
            echo "${disk}p1" > "$STATE_DIR/boot_part"
            echo "${disk}p2" > "$STATE_DIR/root_part"
        else
            echo "${disk}1" > "$STATE_DIR/boot_part"
            echo "${disk}2" > "$STATE_DIR/root_part"
        fi
        
        sudo mkfs.fat -F 32 -n NIXBOOT $(cat "$STATE_DIR/boot_part")
    else
        echo "Modo BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted "$disk" -- mklabel msdos
        sudo parted "$disk" -- mkpart primary 1MiB 512MiB
        sudo parted "$disk" -- set 1 boot on
        sudo parted "$disk" -- mkpart primary 512MiB 100%
        
        sleep 2
        
        if [[ "$disk" == *"nvme"* ]]; then
            echo "${disk}p1" > "$STATE_DIR/boot_part"
            echo "${disk}p2" > "$STATE_DIR/root_part"
        else
            echo "${disk}1" > "$STATE_DIR/boot_part"
            echo "${disk}2" > "$STATE_DIR/root_part"
        fi
        
        sudo mkfs.ext4 -L NIXBOOT $(cat "$STATE_DIR/boot_part")
    fi
    
    sudo mkfs.ext4 -L NIXROOT $(cat "$STATE_DIR/root_part")
}

mount_partitions() {
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swap_gb=$(cat "$STATE_DIR/swap_size")
    local swap_blocks=$((swap_gb * 1024 * 1024))
    
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=$swap_blocks
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
    
    echo "$swap_gb" > "$STATE_DIR/swap_created"
}

generate_config() {
    sudo nixos-generate-config --root /mnt
    
    local locale=$(cat "$STATE_DIR/locale")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local username=$(cat "$STATE_DIR/username")
    local userpass=$(cat "$STATE_DIR/userpass")
    local desktop=$(cat "$STATE_DIR/desktop")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local disk=$(cat "$STATE_DIR/install_disk")
    
    local desktop_config=""
    
    case $desktop in
        cosmic)
            desktop_config='
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];'
            ;;
        gnome)
            desktop_config='
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  environment.systemPackages = with pkgs; [
    gnome-initial-setup
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
  ];'
            ;;
        plasma)
            desktop_config='
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
  environment.systemPackages = with pkgs; [
    plasma5Packages.plasma-meta
    konsole
    dolphin
    kdeconnect
    partitionmanager
    ark
  ];'
            ;;
        none)
            desktop_config=''
            ;;
    esac
    
    local bootloader_config=""
    if [ "$boot_mode" = "efi" ]; then
        bootloader_config='
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;'
    else
        bootloader_config="
  boot.loader.grub.enable = true;
  boot.loader.grub.device = \"$disk\";"
    fi
    
    local swap_config=""
    local swap_gb=$(cat "$STATE_DIR/swap_size")
    if [ -f /mnt/.swapfile ]; then
        swap_config='
  swapDevices = [{
    device = "/.swapfile";
    size = '"$((swap_gb * 1024))"';
  }];'
    fi
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null <<EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
  };
${bootloader_config}

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  services.resolved.enable = true;
  
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
    drivers = [ pkgs.cups-filters ];
  };
  
  services.ntp.enable = true;
  services.chrony.enable = true;
  time.timeZone = "America/Sao_Paulo";
  
  i18n.defaultLocale = "$locale";
  console.keyMap = "$keyboard";
  services.xserver.xkb.layout = "$keyboard";
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
    hashedPassword = lib.mkForce (builtins.readFile <(echo "$userpass" | mkpasswd -m sha-512 -s));
  };
  
  security.sudo.extraRules = [
    {
      users = [ "$username" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  
  services.openssh.enable = true;
  services.avahi.enable = true;
  
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    iwd
    bluez
    bluez-tools
    pulseaudio
    alsa-utils
    mako
    networkmanagerapplet
  ];
  
${desktop_config}
${swap_config}

  system.stateVersion = "23.11";
}
EOF
}

install_system() {
    cd /mnt
    sudo nixos-install --no-root-passwd
}

post_install() {
    local username=$(cat "$STATE_DIR/username")
    
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    echo "Instalação concluída!"
    echo "Remova a mídia de instalação e reinicie."
}

main() {
    clear
    echo "=== Instalador Automático do NixOS ==="
    echo
    
    select_language
    select_keyboard
    select_disk
    configure_swap
    configure_user
    select_desktop
    
    echo
    echo "Resumo da instalação:"
    echo "Disco: $(cat $STATE_DIR/install_disk)"
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Swap: $(cat $STATE_DIR/swap_size)GB"
    echo "Idioma: $(cat $STATE_DIR/locale)"
    echo "Teclado: $(cat $STATE_DIR/keyboard)"
    echo
    
    if confirm "Iniciar instalação?"; then
        partition_disk
        mount_partitions
        create_swap
        nixos-generate-config --root /mnt
        generate_config
        install_system
        post_install
    else
        echo "Instalação cancelada."
        exit 0
    fi
}

main
