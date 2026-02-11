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

detect_disk() {
    local largest=""
    local largest_size=0
    while read disk size; do
        if [[ $disk =~ ^/dev/[sv]d[a-z]$ ]] || [[ $disk =~ ^/dev/nvme[0-9]n[0-9]$ ]]; then
            if [ $size -gt $largest_size ]; then
                largest_size=$size
                largest=$disk
            fi
        fi
    done < <(lsblk -d -o NAME,SIZE -b | tail -n +2 | awk '{print "/dev/"$1,$2}')
    echo "$largest"
}

partition_disk() {
    local disk=$1
    local efi_detected=false
    
    [ -d /sys/firmware/efi ] && efi_detected=true
    
    echo "Particionando $disk ..."
    sudo wipefs -a "$disk" 2>/dev/null || true
    
    if [ "$efi_detected" = true ]; then
        sudo parted "$disk" -- mklabel gpt
        sudo parted "$disk" -- mkpart ESP fat32 1MiB 1025MiB
        sudo parted "$disk" -- set 1 esp on
        sudo parted "$disk" -- mkpart primary ext4 1025MiB 100%
        sudo mkfs.fat -F 32 -n NIXBOOT "${disk}1"
        sudo mkfs.ext4 -L NIXROOT "${disk}2"
    else
        sudo parted "$disk" -- mklabel msdos
        sudo parted "$disk" -- mkpart primary ext4 1MiB 1025MiB
        sudo parted "$disk" -- set 1 boot on
        sudo parted "$disk" -- mkpart primary ext4 1025MiB 100%
        sudo mkfs.ext4 -L NIXBOOT "${disk}1"
        sudo mkfs.ext4 -L NIXROOT "${disk}2"
    fi
}

setup_swap() {
    local size=$1
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1M count=$size status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
}

setup_locale_keyboard() {
    local locale_file="$STATE_DIR/locale"
    local keymap_file="$STATE_DIR/keymap"
    
    if [ ! -f "$locale_file" ]; then
        echo "Selecione o idioma do sistema:"
        select locale in "pt_BR.UTF-8" "en_US.UTF-8" "es_ES.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8"; do
            if [ -n "$locale" ]; then
                echo "$locale" > "$locale_file"
                break
            fi
        done
    fi
    
    if [ ! -f "$keymap_file" ]; then
        echo "Selecione o layout do teclado:"
        select keymap in "br" "us" "es" "fr" "de"; do
            if [ -n "$keymap" ]; then
                echo "$keymap" > "$keymap_file"
                break
            fi
        done
    fi
    
    LANG=$(cat "$locale_file")
    KEYMAP=$(cat "$keymap_file")
}

setup_user() {
    local username_file="$STATE_DIR/username"
    local password_file="$STATE_DIR/password"
    
    if [ ! -f "$username_file" ]; then
        read -p "Digite o nome de usuário: " username
        echo "$username" > "$username_file"
    fi
    
    if [ ! -f "$password_file" ]; then
        read -s -p "Digite a senha: " password1
        echo
        read -s -p "Confirme a senha: " password2
        echo
        if [ "$password1" = "$password2" ]; then
            echo "$password1" > "$password_file"
        else
            echo "Senhas não conferem"
            exit 1
        fi
    fi
    
    USERNAME=$(cat "$username_file")
    PASSWORD=$(cat "$password_file")
}

setup_timezone() {
    local tz_file="$STATE_DIR/timezone"
    
    if [ ! -f "$tz_file" ]; then
        read -p "Digite seu fuso horário (ex: America/Sao_Paulo): " timezone
        echo "$timezone" > "$tz_file"
    fi
    
    TIMEZONE=$(cat "$tz_file")
}

de_cosmic_installer() {
    local state_file="$STATE_DIR/de_cosmic"
    local pkg_cosmic="cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers"
    
    if [ -f "$state_file" ]; then
        echo "Cosmic será instalado"
        echo "  services.desktopManager.cosmic.enable = true;" >> /mnt/etc/nixos/configuration.nix
        echo "  services.displayManager.cosmic-greeter.enable = true;" >> /mnt/etc/nixos/configuration.nix
    else
        touch "$state_file"
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    
    if [ -f "$state_file" ]; then
        echo "Gnome será instalado"
        echo "  services.xserver.desktopManager.gnome.enable = true;" >> /mnt/etc/nixos/configuration.nix
        echo "  services.xserver.displayManager.gdm.enable = true;" >> /mnt/etc/nixos/configuration.nix
    else
        touch "$state_file"
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    
    if [ -f "$state_file" ]; then
        echo "Plasma será instalado"
        echo "  services.xserver.desktopManager.plasma5.enable = true;" >> /mnt/etc/nixos/configuration.nix
        echo "  services.xserver.displayManager.sddm.enable = true;" >> /mnt/etc/nixos/configuration.nix
    else
        touch "$state_file"
    fi
}

generate_config() {
    local disk=$1
    local efi_detected=false
    
    [ -d /sys/firmware/efi ] && efi_detected=true
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  system.stateVersion = "25.11";
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  boot.loader = {
    grub = {
      enable = true;
      device = ${if [ "$efi_detected" = true ]; then "\"nodev\""; else "\"$disk\""; fi};
      efiSupport = ${if [ "$efi_detected" = true ]; then "true"; else "false"; fi};
      enableCryptodisk = false;
    };
    efi = {
      canTouchEfiVariables = ${if [ "$efi_detected" = true ]; then "true"; else "false"; fi};
      efiSysMountPoint = "/boot";
    };
  };
  
  time.timeZone = "$TIMEZONE";
  
  i18n = {
    defaultLocale = "$LANG";
    extraLocaleSettings = {
      LC_TIME = "$LANG";
      LC_MONETARY = "$LANG";
      LC_PAPER = "$LANG";
      LC_MEASUREMENT = "$LANG";
    };
  };
  
  console.keyMap = "$KEYMAP";
  
  services.xserver.xkb.layout = "$KEYMAP";
  
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    initialPassword = "$PASSWORD";
    shell = pkgs.bash;
  };
  
  security.sudo.wheelNeedsPassword = true;
  
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd.enable = true;
  };
  
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
  services.timesyncd.enable = true;
  
  swapDevices = [{
    device = "/.swapfile";
    size = $(cat /mnt/.swapfile_size 2>/dev/null || echo 2048);
  }];
  
  environment.systemPackages = with pkgs; [
    nano
    vim
    git
    curl
    wget
    htop
    neofetch
    pipewire
    wireplumber
    bluez
    bluez-tools
    networkmanagerapplet
    iwd
    cups
    system-config-printer
  ];
  
  programs.firefox.enable = true;
}
EOF

    if [ -f "$STATE_DIR/de_cosmic" ]; then
        de_cosmic_installer
    fi
    
    if [ -f "$STATE_DIR/de_gnome" ]; then
        de_gnome_installer
    fi
    
    if [ -f "$STATE_DIR/de_plasma" ]; then
        de_plasma_installer
    fi
    
    sudo sed -i "s|device = \"/dev/disk/by-label/NIXROOT\";|device = \"/dev/disk/by-label/NIXROOT\";|g" /mnt/etc/nixos/hardware-configuration.nix
    sudo sed -i "s|device = \"/dev/disk/by-label/NIXBOOT\";|device = \"/dev/disk/by-label/NIXBOOT\";|g" /mnt/etc/nixos/hardware-configuration.nix
}

main_menu() {
    while true; do
        clear
        echo "=== NixOS Minimal Installer ==="
        echo "1) Iniciar instalação"
        echo "2) Configurar idioma e teclado"
        echo "3) Configurar desktop environment"
        echo "4) Sair"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1)
                DISK=$(detect_disk)
                if [ -z "$DISK" ]; then
                    echo "Nenhum disco encontrado"
                    exit 1
                fi
                
                if confirm "Instalar NixOS em $DISK? TODO O CONTEÚDO SERÁ APAGADO"; then
                    partition_disk "$DISK"
                    
                    sudo mount /dev/disk/by-label/NIXROOT /mnt
                    sudo mkdir -p /mnt/boot
                    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
                    
                    read -p "Tamanho do swap em MB (ex: 2048): " swap_size
                    echo "$swap_size" > /mnt/.swapfile_size
                    setup_swap "$swap_size"
                    
                    setup_locale_keyboard
                    setup_user
                    setup_timezone
                    
                    sudo nixos-generate-config --root /mnt
                    
                    generate_config "$DISK"
                    
                    echo "Iniciando instalação do NixOS..."
                    cd /mnt
                    sudo nixos-install --no-root-passwd
                    
                    echo "Instalação concluída! Remova o disco de instalação e reinicie."
                    exit 0
                fi
                ;;
            2)
                rm -f "$STATE_DIR/locale" "$STATE_DIR/keymap"
                setup_locale_keyboard
                echo "Configurações salvas"
                ;;
            3)
                clear
                echo "Selecione o desktop environment:"
                echo "1) Cosmic"
                echo "2) GNOME"
                echo "3) Plasma"
                echo "4) Nenhum (instalação mínima)"
                read -p "Opção: " de_opcao
                
                rm -f "$STATE_DIR/de_cosmic" "$STATE_DIR/de_gnome" "$STATE_DIR/de_plasma"
                
                case $de_opcao in
                    1) touch "$STATE_DIR/de_cosmic" ;;
                    2) touch "$STATE_DIR/de_gnome" ;;
                    3) touch "$STATE_DIR/de_plasma" ;;
                    4) ;;
                esac
                ;;
            4) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
