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

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Execute como root"
        exit 1
    fi
}

select_language() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português do Brasil"
    echo "2) English US"
    echo "3) Español"
    read -p "Opção: " lang_opt
    
    case $lang_opt in
        1) LANG="pt_BR.UTF-8"; KEYMAP="br-abnt2";;
        2) LANG="en_US.UTF-8"; KEYMAP="us";;
        3) LANG="es_ES.UTF-8"; KEYMAP="es";;
        *) LANG="en_US.UTF-8"; KEYMAP="us";;
    esac
    echo "$LANG" > "$STATE_DIR/language"
    echo "$KEYMAP" > "$STATE_DIR/keymap"
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) Plasma"
    echo "4) Nenhum (minimal)"
    read -p "Opção: " desktop_opt
    
    case $desktop_opt in
        1) DESKTOP="cosmic";;
        2) DESKTOP="gnome";;
        3) DESKTOP="plasma";;
        *) DESKTOP="none";;
    esac
    echo "$DESKTOP" > "$STATE_DIR/desktop"
}

select_swap() {
    echo "Tamanho do arquivo swap (GB):"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap"
    read -p "Opção: " swap_opt
    
    case $swap_opt in
        1) SWAP_SIZE="2048";;
        2) SWAP_SIZE="4096";;
        3) SWAP_SIZE="8192";;
        *) SWAP_SIZE="0";;
    esac
    echo "$SWAP_SIZE" > "$STATE_DIR/swap"
}

auto_partition() {
    echo "Identificando discos disponíveis..."
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    echo
    read -p "Digite o disco para instalação (ex: sda): " DISK
    
    DEVICE="/dev/$DISK"
    
    if [ ! -b "$DEVICE" ]; then
        echo "Dispositivo não encontrado"
        exit 1
    fi
    
    echo "Particionando automaticamente $DEVICE..."
    
    if [ -d /sys/firmware/efi ]; then
        parted "$DEVICE" -- mklabel gpt
        parted "$DEVICE" -- mkpart ESP fat32 1MB 512MB
        parted "$DEVICE" -- set 1 esp on
        parted "$DEVICE" -- mkpart primary 512MB 100%
        BOOT_PART="${DEVICE}1"
        ROOT_PART="${DEVICE}2"
    else
        parted "$DEVICE" -- mklabel msdos
        parted "$DEVICE" -- mkpart primary ext4 1MB 512MB
        parted "$DEVICE" -- set 1 boot on
        parted "$DEVICE" -- mkpart primary 512MB 100%
        BOOT_PART="${DEVICE}1"
        ROOT_PART="${DEVICE}2"
    fi
    
    mkfs.fat -F 32 "$BOOT_PART"
    fatlabel "$BOOT_PART" NIXBOOT
    mkfs.ext4 -F "$ROOT_PART" -L NIXROOT
    
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    echo "$DEVICE" > "$STATE_DIR/disk"
    echo "Particionamento concluído"
}

setup_swap() {
    SWAP_SIZE=$(cat "$STATE_DIR/swap")
    
    if [ "$SWAP_SIZE" != "0" ]; then
        echo "Criando arquivo swap de ${SWAP_SIZE}MB..."
        dd if=/dev/zero of=/mnt/.swapfile bs=1M count="$SWAP_SIZE" status=progress
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
    fi
}

get_user_info() {
    read -p "Nome do usuário: " USER_NAME
    echo "$USER_NAME" > "$STATE_DIR/username"
    
    while true; do
        read -sp "Senha do usuário: " USER_PASS
        echo
        read -sp "Confirme a senha: " USER_PASS2
        echo
        if [ "$USER_PASS" = "$USER_PASS2" ] && [ -n "$USER_PASS" ]; then
            echo "$USER_PASS" > "$STATE_DIR/userpass"
            break
        else
            echo "Senhas não conferem ou vazias. Tente novamente."
        fi
    done
}

generate_config() {
    nixos-generate-config --root /mnt
    
    LANG=$(cat "$STATE_DIR/language")
    KEYMAP=$(cat "$STATE_DIR/keymap")
    DESKTOP=$(cat "$STATE_DIR/desktop")
    USER_NAME=$(cat "$STATE_DIR/username")
    DEVICE=$(cat "$STATE_DIR/disk")
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    grub = {
      enable = true;
      devices = [ "$DEVICE" ];
      efiSupport = true;
      enableCryptodisk = true;
    };
  };

  # Locale
  time.timeZone = "America/Sao_Paulo";
  i18n = {
    defaultLocale = "$LANG";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "$LANG/UTF-8" ];
  };

  # Keyboard
  services.xserver = {
    enable = true;
    xkb.layout = "$KEYMAP";
  };
  console.keyMap = "$KEYMAP";

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd.enable = true;
  };

  # Sound with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Printing
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint pkgs.hplip ];
  };

  # NTP
  services.timesyncd.enable = true;

  # User
  users.users.$USER_NAME = {
    isNormalUser = true;
    description = "$USER_NAME";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
  };

  # Sudo without password for wheel
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Desktop Environment
EOF

    if [ "$DESKTOP" = "cosmic" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
EOF
    elif [ "$DESKTOP" = "gnome" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
EOF
    elif [ "$DESKTOP" = "plasma" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
EOF
    fi

    cat >> /mnt/etc/nixos/configuration.nix << EOF

  # Swap file
  swapDevices = [{
    device = "/.swapfile";
    size = $(cat "$STATE_DIR/swap");
  }];

  # System packages
  environment.systemPackages = with pkgs; [
    nano
    htop
    git
    curl
    wget
    firefox
    iwd
    networkmanager
    bluez
    bluez-tools
    pulseaudio
  ];

  # Open firewall for printing
  networking.firewall.allowedUDPPorts = [ 631 ];
  networking.firewall.allowedTCPPorts = [ 631 ];

  system.stateVersion = "25.11";
}
EOF

    chown -R 1000:100 /mnt/etc/nixos 2>/dev/null || true
}

setup_password() {
    USER_NAME=$(cat "$STATE_DIR/username")
    USER_PASS=$(cat "$STATE_DIR/userpass")
    
    echo "$USER_NAME:$USER_PASS" | chpasswd --root /mnt
}

main() {
    clear
    echo "=== Instalador NixOS 25.11 ==="
    echo
    
    check_root
    
    select_language
    select_desktop
    select_swap
    auto_partition
    setup_swap
    get_user_info
    
    echo "Gerando configuração..."
    generate_config
    
    echo "Iniciando instalação..."
    nixos-install --no-root-passwd --root /mnt
    
    echo "Configurando senha do usuário..."
    setup_password
    
    echo "Limpando..."
    umount -R /mnt 2>/dev/null || true
    
    echo "Instalação concluída! Reinicie o sistema."
}

main
