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
    read -p "Opção: " lang_opcao
    
    case $lang_opcao in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado / Select keyboard layout:"
    echo "1) Português Brasileiro (br)"
    echo "2) English US (us)"
    read -p "Opção: " kb_opcao
    
    case $kb_opcao in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_swap_size() {
    echo "Selecione o tamanho do swap:"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) 16GB"
    echo "5) 32GB"
    read -p "Opção: " swap_opcao
    
    case $swap_opcao in
        1) echo "2G" > "$STATE_DIR/swap" ;;
        2) echo "4G" > "$STATE_DIR/swap" ;;
        3) echo "8G" > "$STATE_DIR/swap" ;;
        4) echo "16G" > "$STATE_DIR/swap" ;;
        5) echo "32G" > "$STATE_DIR/swap" ;;
        *) echo "4G" > "$STATE_DIR/swap" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) Nenhum (apenas terminal)"
    read -p "Opção: " de_opcao
    
    case $de_opcao in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_bluetooth() {
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    if confirm "Habilitar suporte a impressão (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

detect_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda): " disk_name
    echo "/dev/$disk_name" > "$STATE_DIR/disk"
}

select_username() {
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    read -s -p "Senha do usuário: " userpass
    echo
    read -s -p "Confirme a senha: " userpass2
    echo
    
    if [ "$userpass" != "$userpass2" ]; then
        echo "Senhas não conferem!"
        exit 1
    fi
    
    echo "$userpass" > "$STATE_DIR/userpass"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/lang)"
    echo "Teclado: $(cat $STATE_DIR/keyboard)"
    echo "Disco: $(cat $STATE_DIR/disk)"
    echo "Desktop: $(case $(cat $STATE_DIR/desktop) in cosmic) echo 'Cosmic';; gnome) echo 'GNOME';; plasma) echo 'KDE Plasma';; none) echo 'Nenhum';; esac)"
    echo "Swap: $(cat $STATE_DIR/swap | sed 's/G//')GB"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth | sed 's/yes/Habilitado/; s/no/Desabilitado/')"
    echo "CUPS: $(cat $STATE_DIR/cups | sed 's/yes/Habilitado/; s/no/Desabilitado/')"
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "============================"
    echo
    
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Particionando $disk automaticamente..."
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel gpt
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 esp on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
        sudo mkfs.ext4 ${disk}2 -L NIXROOT
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel msdos
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 boot on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.ext4 ${disk}1 -L NIXBOOT
        sudo mkfs.ext4 ${disk}2 -L NIXROOT
    fi
}

mount_partitions() {
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    
    echo "Criando arquivo swap de $swap_size..."
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$(echo $swap_size | sed 's/G//') status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
}

generate_config() {
    sudo nixos-generate-config --root /mnt
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local username=$(cat "$STATE_DIR/username")
    local userpass=$(cat "$STATE_DIR/userpass")
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    $([ "$boot_mode" = "uefi" ] && echo 'systemd-boot.enable = true;' || echo 'grub.enable = true; grub.device = "'$(cat "$STATE_DIR/disk")'";')
  };

  i18n.defaultLocale = "$lang";
  console.keyMap = "$keyboard";
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd.enable = true;
  };
  
  swapDevices = [ {
    device = "/.swapfile";
    size = $(echo $(cat "$STATE_DIR/swap") | sed 's/G//' | awk '{print $1 * 1024}');
  } ];
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" ];
    hashedPassword = "$pass_hash";
    shell = pkgs.bash;
  };
  
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "ALL";
          options = [ "SETENV" "NOPASSWD" ];
        }
      ];
    }
  ];
  
  $([ "$desktop" = "cosmic" ] && echo '
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-term
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];')
  
  $([ "$desktop" = "gnome" ] && echo '
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
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
  ];')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
  environment.systemPackages = with pkgs; [
    konsole
    dolphin
    kdeconnect
    partition-manager
    ark
  ];')
  
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    curl
    htop
    neofetch
    firefox
    file
    unzip
    zip
    ntfs3g
    pciutils
    usbutils
    killall
  ];
  
  system.stateVersion = "25.11";
}
EOF

    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g" /mnt/etc/nixos/hardware-configuration.nix 2>/dev/null || true
    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g" /mnt/etc/nixos/hardware-configuration.nix 2>/dev/null || true
}

install_system() {
    cd /mnt
    sudo nixos-install --no-root-passwd
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 ==="
    echo
    
    select_language
    select_keyboard
    detect_disk
    select_desktop
    select_swap_size
    select_bluetooth
    select_cups
    select_username
    
    show_summary
    
    echo "Iniciando instalação..."
    
    partition_disk
    mount_partitions
    create_swap
    generate_config
    
    if confirm "Iniciar instalação do NixOS?"; then
        install_system
        echo "Instalação concluída! Reinicie o sistema."
    else
        echo "Instalação cancelada."
        exit 1
    fi
}

main
