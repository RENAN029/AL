#!/bin/bash
set -e

[ ! -f /etc/nixos/configuration.nix ] && [ ! -d /mnt/etc/nixos ] && { echo "Execute este script durante a instalação do NixOS com /mnt montado."; exit 1; }

MOUNT_POINT="/mnt"
[ ! -d "$MOUNT_POINT/etc/nixos" ] && { echo "Diretório $MOUNT_POINT/etc/nixos não encontrado. Monte a partição root primeiro."; exit 1; }

CONFIG_FILE="$MOUNT_POINT/etc/nixos/configuration.nix"
HARDWARE_FILE="$MOUNT_POINT/etc/nixos/hardware-configuration.nix"

select_language() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português do Brasil"
    echo "2) English"
    echo "3) Español"
    read -p "Opção: " lang_opt
    
    case $lang_opt in
        1) LOCALE="pt_BR.UTF-8"; KEYMAP="br-abnt2"; LANG="pt_BR.UTF-8";;
        2) LOCALE="en_US.UTF-8"; KEYMAP="us"; LANG="en_US.UTF-8";;
        3) LOCALE="es_ES.UTF-8"; KEYMAP="es"; LANG="es_ES.UTF-8";;
        *) LOCALE="en_US.UTF-8"; KEYMAP="us"; LANG="en_US.UTF-8";;
    esac
}

select_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    read -p "Digite o disco para instalação (ex: sda): " DISK
    DISK_DEV="/dev/$DISK"
    [ ! -b "$DISK_DEV" ] && { echo "Disco inválido."; exit 1; }
}

partition_disk() {
    echo "Particionando $DISK_DEV automaticamente..."
    
    if [ -d /sys/firmware/efi ]; then
        EFI_MODE=1
        echo "Modo UEFI detectado."
    else
        EFI_MODE=0
        echo "Modo Legacy BIOS detectado."
    fi
    
    read -p "Tamanho do swap (GB) [2]: " SWAP_SIZE
    SWAP_SIZE=${SWAP_SIZE:-2}
    
    sudo wipefs -a "$DISK_DEV"
    
    if [ $EFI_MODE -eq 1 ]; then
        echo "Criando tabela GPT..."
        sudo parted "$DISK_DEV" -- mklabel gpt
        
        echo "Criando partição EFI (500MB)..."
        sudo parted "$DISK_DEV" -- mkpart ESP fat32 1MiB 501MiB
        sudo parted "$DISK_DEV" -- set 1 esp on
        
        echo "Criando partição root..."
        sudo parted "$DISK_DEV" -- mkpart primary 501MiB 100%
        
        EFI_PART="${DISK_DEV}1"
        ROOT_PART="${DISK_DEV}2"
        
        sudo mkfs.fat -F 32 "$EFI_PART"
        sudo fatlabel "$EFI_PART" NIXBOOT
    else
        echo "Criando tabela MBR..."
        sudo parted "$DISK_DEV" -- mklabel msdos
        
        echo "Criando partição boot (500MB)..."
        sudo parted "$DISK_DEV" -- mkpart primary ext4 1MiB 501MiB
        sudo parted "$DISK_DEV" -- set 1 boot on
        
        echo "Criando partição root..."
        sudo parted "$DISK_DEV" -- mkpart primary 501MiB 100%
        
        BOOT_PART="${DISK_DEV}1"
        ROOT_PART="${DISK_DEV}2"
        
        sudo mkfs.ext4 -L NIXBOOT "$BOOT_PART"
    fi
    
    sudo mkfs.ext4 -L NIXROOT "$ROOT_PART"
    
    echo "Montando partições..."
    sudo mount /dev/disk/by-label/NIXROOT "$MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT/boot"
    sudo mount /dev/disk/by-label/NIXBOOT "$MOUNT_POINT/boot"
}

create_swap() {
    echo "Criando arquivo swap de ${SWAP_SIZE}GB..."
    SWAP_FILE="$MOUNT_POINT/.swapfile"
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((SWAP_SIZE * 1024)) status=progress
    sudo chmod 600 "$SWAP_FILE"
    sudo mkswap "$SWAP_FILE"
    sudo swapon "$SWAP_FILE"
}

configure_base() {
    echo "Gerando configuração base..."
    sudo nixos-generate-config --root "$MOUNT_POINT"
    
    read -p "Nome do usuário: " USERNAME
    while true; do
        read -s -p "Senha para $USERNAME: " PASSWORD1
        echo
        read -s -p "Confirme a senha: " PASSWORD2
        echo
        [ "$PASSWORD1" = "$PASSWORD2" ] && break
        echo "Senhas não coincidem."
    done
    
    PASSWORD_HASH=$(mkpasswd -m sha-512 "$PASSWORD1")
    
    read -p "Região (ex: America/Sao_Paulo) [America/Sao_Paulo]: " TIMEZONE
    TIMEZONE=${TIMEZONE:-America/Sao_Paulo}
    
    echo "Configurando systemd-boot como bootloader..."
    
    sudo tee "$CONFIG_FILE" > /dev/null <<EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  
  # Locale e teclado
  i18n.defaultLocale = "$LOCALE";
  services.xserver.layout = "$KEYMAP";
  console.keyMap = "$KEYMAP";
  
  # Timezone
  time.timeZone = "$TIMEZONE";
  services.ntp.enable = true;
  
  # Usuário com permissões de root (wheel)
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    password = "$PASSWORD_HASH";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
  };
  
  users.users.root.password = "$PASSWORD_HASH";
  
  # Sudo sem senha para wheel (opcional, remover se quiser senha)
  security.sudo.extraRules = [
    { groups = [ "wheel" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];
  
  # Rede - IWD e NetworkManager
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    General = {
      EnableNetworkConfiguration = true;
    };
  };
  
  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  
  # Áudio - PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Impressão - CUPS
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];
  
  # Swap file
  swapDevices = [ { device = "/.swapfile"; } ];
  
  # Pacotes essenciais
  environment.systemPackages = with pkgs; [
    nano
    vim
    git
    wget
    curl
    htop
    iwd
    networkmanager
    bluez
    bluez-tools
    pipewire
    wireplumber
    cups
    hplip
    mkpasswd
  ];
  
  # Habilitar firmware livre
  hardware.enableRedistributableFirmware = true;
  
  system.stateVersion = "23.11";
}
EOF
}

desktop_environment() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) Plasma (KDE)"
    echo "4) Nenhum (somente console)"
    read -p "Opção: " de_opt
    
    case $de_opt in
        1)
            sudo tee -a "$CONFIG_FILE" > /dev/null <<EOF
  
  # Cosmic Desktop
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
    cosmic-bg
  ];
EOF
            ;;
        2)
            sudo tee -a "$CONFIG_FILE" > /dev/null <<EOF
  
  # GNOME Desktop
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
    gnome-terminal
    nautilus
    gnome-control-center
  ];
EOF
            ;;
        3)
            sudo tee -a "$CONFIG_FILE" > /dev/null <<EOF
  
  # Plasma Desktop
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.systemPackages = with pkgs; [
    plasma6
    konsole
    dolphin
    kdeconnect
    partitionmanager
    ark
    kate
    plasma-browser-integration
  ];
EOF
            ;;
        *)
            echo "Nenhum desktop instalado."
            ;;
    esac
}

install_system() {
    echo "Iniciando instalação do NixOS..."
    cd "$MOUNT_POINT"
    sudo nixos-install --no-root-passwd
    
    echo "Instalação concluída."
    echo "Após reiniciar, faça login como $USERNAME."
    read -p "Deseja reiniciar agora? (s/n): " reboot_opt
    [[ "$reboot_opt" = "s" || "$reboot_opt" = "S" ]] && sudo reboot
}

main() {
    clear
    echo "=== Instalador Automático do NixOS ==="
    echo
    
    select_language
    select_disk
    partition_disk
    create_swap
    configure_base
    desktop_environment
    
    echo "Configuração gerada em $CONFIG_FILE"
    echo "Revise as configurações antes de prosseguir."
    read -p "Pressione Enter para continuar com a instalação..."
    
    install_system
}

main
