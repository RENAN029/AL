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

detect_disk() {
    local disks=($(lsblk -d -o NAME,TYPE,SIZE -n | grep disk | awk '{print $1}'))
    if [ ${#disks[@]} -eq 0 ]; then
        echo "Nenhum disco encontrado!"
        exit 1
    elif [ ${#disks[@]} -eq 1 ]; then
        echo "/dev/${disks[0]}"
    else
        echo "Discos disponíveis:"
        for i in "${!disks[@]}"; do
            echo "$i) /dev/${disks[$i]}"
        done
        read -p "Selecione o disco para instalação: " disk_idx
        echo "/dev/${disks[$disk_idx]}"
    fi
}

select_keyboard() {
    echo "Layouts de teclado disponíveis:"
    echo "1) us"
    echo "2) br"
    echo "3) de"
    echo "4) fr"
    echo "5) es"
    echo "6) it"
    read -p "Selecione o layout do teclado: " kb_opt
    case $kb_opt in
        1) echo "us" ;;
        2) echo "br" ;;
        3) echo "de" ;;
        4) echo "fr" ;;
        5) echo "es" ;;
        6) echo "it" ;;
        *) echo "us" ;;
    esac
}

select_language() {
    echo "Idiomas disponíveis:"
    echo "1) en_US.UTF-8"
    echo "2) pt_BR.UTF-8"
    echo "3) de_DE.UTF-8"
    echo "4) fr_FR.UTF-8"
    echo "5) es_ES.UTF-8"
    echo "6) it_IT.UTF-8"
    read -p "Selecione o idioma do sistema: " lang_opt
    case $lang_opt in
        1) echo "en_US.UTF-8" ;;
        2) echo "pt_BR.UTF-8" ;;
        3) echo "de_DE.UTF-8" ;;
        4) echo "fr_FR.UTF-8" ;;
        5) echo "es_ES.UTF-8" ;;
        6) echo "it_IT.UTF-8" ;;
        *) echo "en_US.UTF-8" ;;
    esac
}

select_desktop() {
    echo "Ambientes Desktop disponíveis:"
    echo "1) Cosmic"
    echo "2) Gnome"
    echo "3) Plasma"
    echo "4) Nenhum (console)"
    read -p "Selecione o ambiente desktop: " de_opt
    case $de_opt in
        1) echo "cosmic" ;;
        2) echo "gnome" ;;
        3) echo "plasma" ;;
        4) echo "none" ;;
        *) echo "none" ;;
    esac
}

partition_disk() {
    local disk=$1
    local efi_boot=false
    
    if [ -d /sys/firmware/efi ]; then
        efi_boot=true
    fi
    
    echo "Particionando $disk..."
    sudo wipefs -a "$disk"
    
    if [ "$efi_boot" = true ]; then
        sudo parted "$disk" -- mklabel gpt
        sudo parted "$disk" -- mkpart primary 1MB 512MB
        sudo parted "$disk" -- set 1 esp on
        sudo parted "$disk" -- mkpart primary 512MB 100%
    else
        sudo parted "$disk" -- mklabel msdos
        sudo parted "$disk" -- mkpart primary 1MB 512MB
        sudo parted "$disk" -- set 1 boot on
        sudo parted "$disk" -- mkpart primary 512MB 100%
    fi
    
    sleep 2
    sudo mkfs.fat -F 32 "${disk}1" -n NIXBOOT
    sudo mkfs.ext4 -F "${disk}2" -L NIXROOT
}

setup_swap() {
    local swap_size=$1
    echo "Criando arquivo swap de ${swap_size}GB..."
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count="$swap_size" status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
}

install_nixos() {
    local disk=$1
    local kb_layout=$2
    local system_locale=$3
    local username=$4
    local desktop=$5
    local swap_size=$6
    
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    setup_swap "$swap_size"
    
    sudo nixos-generate-config --root /mnt
    
    cat > /tmp/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  swapDevices = [{
    device = "/.swapfile";
    size = ${swap_size};
  }];

  time.timeZone = "UTC";
  services.automatic-timezoned.enable = true;
  services.geoclue2.enable = true;

  i18n.defaultLocale = "${system_locale}";
  console.keyMap = "${kb_layout}";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.wireless.enable = false;

  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
  services.printing = {
    enable = true;
    drivers = [ pkgs.cups-filters ];
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" ];
    shell = pkgs.bash;
    home = "/home/${username}";
    openssh.authorizedKeys.keys = [ ];
  };

  security.sudo.extraRules = [
    {
      users = [ "${username}" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    wget
    htop
    iwd
    networkmanager
    networkmanagerapplet
    bluez
    bluez-tools
    cups
  ];
EOF

    if [ -d /sys/firmware/efi ]; then
        cat >> /tmp/configuration.nix << EOF
  boot.loader.systemd-boot.enable = true;
EOF
    else
        cat >> /tmp/configuration.nix << EOF
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "${disk}";
EOF
    fi

    if [ "$desktop" = "cosmic" ]; then
        cat >> /tmp/configuration.nix << EOF
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
    cosmic-edit
    cosmic-applibrary
    cosmic-screenshot
  ];
EOF
    elif [ "$desktop" = "gnome" ]; then
        cat >> /tmp/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [ 
    gnome-tour 
    epiphany
    gnome-music
    gnome-contacts
  ];
EOF
    elif [ "$desktop" = "plasma" ]; then
        cat >> /tmp/configuration.nix << EOF
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.elisa
    kdePackages.konqueror
    kdePackages.khelpcenter
  ];
EOF
    fi

    echo "}" >> /tmp/configuration.nix
    
    sudo cp /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
    
    cd /mnt
    sudo nixos-install --no-root-passwd --option binary-caches "https://cache.nixos.org"
}

main() {
    clear
    echo "=== NixOS Installer ==="
    echo
    
    local disk=$(detect_disk)
    echo "Disco selecionado: $disk"
    echo
    
    local kb_layout=$(select_keyboard)
    echo "Layout do teclado: $kb_layout"
    echo
    
    local system_locale=$(select_language)
    echo "Idioma do sistema: $system_locale"
    echo
    
    local desktop=$(select_desktop)
    echo "Ambiente desktop: $desktop"
    echo
    
    read -p "Nome de usuário: " username
    while [ -z "$username" ]; do
        read -p "Nome de usuário (obrigatório): " username
    done
    
    read -sp "Senha do usuário: " userpass
    echo
    read -sp "Confirme a senha: " userpass2
    echo
    while [ "$userpass" != "$userpass2" ] || [ -z "$userpass" ]; do
        echo "Senhas não coincidem ou estão vazias. Tente novamente."
        read -sp "Senha do usuário: " userpass
        echo
        read -sp "Confirme a senha: " userpass2
        echo
    done
    
    read -p "Tamanho do swap em GB (ex: 2): " swap_size
    while ! [[ "$swap_size" =~ ^[0-9]+$ ]] || [ "$swap_size" -lt 1 ]; then
        read -p "Digite um número válido (mínimo 1): " swap_size
    done
    
    echo
    echo "Resumo da instalação:"
    echo "Disco: $disk"
    echo "Teclado: $kb_layout"
    echo "Idioma: $system_locale"
    echo "Usuário: $username"
    echo "Desktop: $desktop"
    echo "Swap: ${swap_size}GB"
    echo
    
    if confirm "Iniciar instalação do NixOS?"; then
        partition_disk "$disk"
        install_nixos "$disk" "$kb_layout" "$system_locale" "$username" "$desktop" "$swap_size"
        
        echo "Definindo senha do usuário..."
        echo "$username:$userpass" | sudo chroot /mnt chpasswd
        
        echo
        echo "Instalação concluída!"
        if confirm "Reiniciar agora?"; then
            sudo umount -R /mnt
            sudo reboot
        fi
    else
        echo "Instalação cancelada."
        exit 0
    fi
}

main
