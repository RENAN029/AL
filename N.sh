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
    echo "Selecione o idioma do sistema / Select system language:"
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) English US (en_US.UTF-8)"
    read -p "Opção: " lang_opt
    case $lang_opt in
        1) echo "pt_BR.UTF-8" ;;
        2) echo "en_US.UTF-8" ;;
        *) echo "en_US.UTF-8" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado / Select keyboard layout:"
    echo "1) Português Brasileiro (br)"
    echo "2) English US (us)"
    read -p "Opção: " kb_opt
    case $kb_opt in
        1) echo "br" ;;
        2) echo "us" ;;
        *) echo "us" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop para instalar (opcional):"
    echo "1) Nenhum (instalação mínima)"
    echo "2) Cosmic"
    echo "3) GNOME"
    echo "4) Plasma"
    read -p "Opção: " de_opt
    echo "$de_opt"
}

setup_disk() {
    echo "Identificando discos disponíveis..."
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
    DISK="/dev/$disk_name"
    
    if [ ! -b "$DISK" ]; then
        echo "Disco inválido!"
        exit 1
    fi
    
    echo "ATENÇÃO: Todo o conteúdo de $DISK será apagado!"
    if ! confirm "Continuar?"; then
        exit 1
    fi
    
    echo "Particionando $DISK automaticamente..."
    
    if [ -d /sys/firmware/efi ]; then
        echo "Modo UEFI detectado"
        sudo parted $DISK -- mklabel gpt
        sudo parted $DISK -- mkpart ESP fat32 1MB 512MB
        sudo parted $DISK -- set 1 esp on
        sudo parted $DISK -- mkpart primary ext4 512MB 100%
        BOOT_PART="${DISK}1"
        ROOT_PART="${DISK}2"
        if [[ $DISK == *"nvme"* ]]; then
            BOOT_PART="${DISK}p1"
            ROOT_PART="${DISK}p2"
        fi
    else
        echo "Modo BIOS detectado"
        sudo parted $DISK -- mklabel msdos
        sudo parted $DISK -- mkpart primary ext4 1MB 512MB
        sudo parted $DISK -- set 1 boot on
        sudo parted $DISK -- mkpart primary ext4 512MB 100%
        BOOT_PART="${DISK}1"
        ROOT_PART="${DISK}2"
        if [[ $DISK == *"nvme"* ]]; then
            BOOT_PART="${DISK}p1"
            ROOT_PART="${DISK}p2"
        fi
    fi
    
    echo "Formatando partições..."
    if [ -d /sys/firmware/efi ]; then
        sudo mkfs.fat -F 32 $BOOT_PART -n NIXBOOT
    else
        sudo mkfs.ext4 $BOOT_PART -L NIXBOOT
    fi
    sudo mkfs.ext4 $ROOT_PART -L NIXROOT
    
    echo "Montando partições..."
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    echo "Criando arquivo swap..."
    read -p "Tamanho do swap em GB (ex: 2, 4, 8): " swap_size
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$swap_size status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
}

generate_config() {
    local lang="$1"
    local kb="$2"
    local desktop="$3"
    local username="$4"
    local password_hash="$5"
    
    echo "Gerando configuração do NixOS..."
    sudo nixos-generate-config --root /mnt
    
    cat > /tmp/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader = {
    grub = {
      enable = true;
      device = "$([ -d /sys/firmware/efi ] && echo "nodev" || echo "$DISK")";
      efiSupport = $([ -d /sys/firmware/efi ] && echo "true" || echo "false");
      enableCryptodisk = true;
    };
    efi = {
      canTouchEfiVariables = $([ -d /sys/firmware/efi ] && echo "true" || echo "false");
    };
  };

  # Filesystems
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "$([ -d /sys/firmware/efi ] && echo "vfat" || echo "ext4")";
  };

  # Swap
  swapDevices = [ { device = "/.swapfile"; } ];

  # Locale
  time.timeZone = "America/Sao_Paulo";
  i18n = {
    defaultLocale = "$lang";
    extraLocaleSettings = {
      LC_ADDRESS = "$lang";
      LC_IDENTIFICATION = "$lang";
      LC_MEASUREMENT = "$lang";
      LC_MONETARY = "$lang";
      LC_NAME = "$lang";
      LC_NUMERIC = "$lang";
      LC_PAPER = "$lang";
      LC_TELEPHONE = "$lang";
      LC_TIME = "$lang";
    };
    supportedLocales = [ "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
  };

  # Console
  console = {
    keyMap = "$kb";
    packages = with pkgs; [ terminus_font ];
    font = "ter-124n";
  };

  # User
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "lp" "scanner" ];
    shell = pkgs.bash;
    hashedPassword = "$password_hash";
    initialPassword = "$username";
  };
  
  security.sudo = {
    enable = true;
    extraRules = [{
      groups = [ "wheel" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];
  };

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = true;
          RoamThreshold = -70;
        };
      };
    };
  };

  # Audio
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
    browse = true;
    defaultShared = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  # NTP
  services.ntp.enable = true;
  networking.timeServers = [
    "a.st1.ntp.br"
    "b.st1.ntp.br"
    "c.st1.ntp.br"
    "pool.ntp.org"
  ];

  # Desktop Environment
EOF

    case $desktop in
        2)
            cat >> /tmp/configuration.nix << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = false;
  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];
EOF
            ;;
        3)
            cat >> /tmp/configuration.nix << EOF
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
  ];
EOF
            ;;
        4)
            cat >> /tmp/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = with pkgs; [
    kdePackages.plasma-meta
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.kdeconnect-kde
    kdePackages.partitionmanager
    ark
  ];
EOF
            ;;
    esac

    cat >> /tmp/configuration.nix << EOF

  # Basic packages
  environment.systemPackages = with pkgs; [
    nano
    vim
    git
    wget
    curl
    htop
    iwd
    networkmanager
    networkmanagerapplet
    bluez
    bluez-tools
    cups
    pipewire
    wireplumber
    pulseaudio
  ];

  # Services
  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
  };

  system.stateVersion = "25.11";
}
EOF

    sudo cp /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
}

main() {
    clear
    echo "=== Instalador Automático NixOS 25.11 ==="
    echo
    
    LANG=$(select_language)
    KEYBOARD=$(select_keyboard)
    DESKTOP=$(select_desktop)
    
    read -p "Nome do usuário: " USERNAME
    while true; do
        read -s -p "Senha: " PASSWORD1
        echo
        read -s -p "Confirme a senha: " PASSWORD2
        echo
        if [ "$PASSWORD1" = "$PASSWORD2" ] && [ -n "$PASSWORD1" ]; then
            break
        else
            echo "As senhas não coincidem ou estão vazias. Tente novamente."
        fi
    done
    
    PASSWORD_HASH=$(mkpasswd -m sha-512 "$PASSWORD1")
    
    setup_disk
    generate_config "$LANG" "$KEYBOARD" "$DESKTOP" "$USERNAME" "$PASSWORD_HASH"
    
    echo "Iniciando instalação do NixOS..."
    cd /mnt
    sudo nixos-install --no-root-passwd
    
    echo "Instalação concluída!"
    echo "Remova a mídia de instalação e reinicie o sistema."
    
    if confirm "Reiniciar agora?"; then
        sudo reboot
    fi
}

main
