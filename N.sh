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

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

select_language() {
    echo "Selecione o idioma do sistema / Select system language:"
    echo "1) Português Brasileiro"
    echo "2) English US"
    read -p "Opção / Option: " lang_opt
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language"
           echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language"
           echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard"
           echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop / Select desktop environment:"
    echo "1) Nenhum / None (somente terminal)"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) Cosmic"
    read -p "Opção / Option: " desktop_opt
    case $desktop_opt in
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "cosmic" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_swap() {
    echo "Tamanho do arquivo swap / Swap file size:"
    echo "1) 1GB"
    echo "2) 2GB"
    echo "3) 4GB"
    echo "4) 8GB"
    read -p "Opção / Option: " swap_opt
    case $swap_opt in
        1) echo "1048576" > "$STATE_DIR/swapsize" ;;
        2) echo "2097152" > "$STATE_DIR/swapsize" ;;
        3) echo "4194304" > "$STATE_DIR/swapsize" ;;
        4) echo "8388608" > "$STATE_DIR/swapsize" ;;
        *) echo "2097152" > "$STATE_DIR/swapsize" ;;
    esac
}

select_disk() {
    echo "Discos disponíveis / Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    echo ""
    read -p "Digite o disco para instalação (ex: sda): " install_disk
    echo "/dev/$install_disk" > "$STATE_DIR/disk"
}

collect_user_info() {
    read -p "Nome do usuário / Username: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Senha / Password: " password
    echo ""
    read -s -p "Confirme a senha / Confirm password: " password2
    echo ""
    if [ "$password" != "$password2" ]; then
        echo "Senhas não coincidem / Passwords do not match"
        exit 1
    fi
    echo "$password" > "$STATE_DIR/password"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo ""
    echo "Idioma / Language: $(cat $STATE_DIR/language)"
    echo "Teclado / Keyboard: $(cat $STATE_DIR/keyboard)"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Swap: $(cat $STATE_DIR/swapsize) KB"
    echo "Disco / Disk: $(cat $STATE_DIR/disk)"
    echo "Usuário / User: $(cat $STATE_DIR/username)"
    echo ""
    if ! confirm "Continuar com a instalação? / Continue with installation?"; then
        echo "Instalação cancelada / Installation cancelled"
        exit 0
    fi
}

partition_disk() {
    local disk=$(cat $STATE_DIR/disk)
    
    if [ -d /sys/firmware/efi ]; then
        parted $disk -- mklabel gpt
        parted $disk -- mkpart primary 2048s 500MB
        parted $disk -- set 1 esp on
        parted $disk -- mkpart primary 500MB 100%
        mkfs.fat -F 32 ${disk}1
        fatlabel ${disk}1 NIXBOOT
        mkfs.ext4 -F ${disk}2 -L NIXROOT
    else
        parted $disk -- mklabel msdos
        parted $disk -- mkpart primary 2048s 500MB
        parted $disk -- set 1 boot on
        parted $disk -- mkpart primary 500MB 100%
        mkfs.ext4 -F ${disk}1 -L NIXBOOT
        mkfs.ext4 -F ${disk}2 -L NIXROOT
    fi
}

mount_partitions() {
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swapsize=$(cat $STATE_DIR/swapsize)
    dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=$swapsize status=none
    chmod 600 /mnt/.swapfile
    mkswap /mnt/.swapfile
    swapon /mnt/.swapfile
}

generate_config() {
    nixos-generate-config --root /mnt
    
    local language=$(cat $STATE_DIR/language)
    local keyboard=$(cat $STATE_DIR/keyboard)
    local desktop=$(cat $STATE_DIR/desktop)
    local username=$(cat $STATE_DIR/username)
    local password=$(cat $STATE_DIR/password)
    local disk=$(cat $STATE_DIR/disk)
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    grub = {
      enable = true;
      device = "$disk";
    };
  };

  i18n.defaultLocale = "$language";
  console.keyMap = "$keyboard";
  services.xserver.xkb.layout = "$keyboard";
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  networking.networkmanager.enable = true;
  services.bluetooth.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  
  swapDevices = [ { device = "/.swapfile"; } ];
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" ];
    password = "$password";
    shell = pkgs.bash;
    home = "/home/$username";
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
  
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    wget
    htop
    iwd
    bluez
    bluez-tools
    cups
    networkmanager
    networkmanagerapplet
  ];
  
EOF

    if [ "$desktop" = "gnome" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-maps
    gnome-music
    gnome-contacts
    gnome-weather
    epiphany
    geary
  ];
  environment.systemPackages = with pkgs; [
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
  ];
EOF
    elif [ "$desktop" = "plasma" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = with pkgs; [
    konsole
    dolphin
    kdeconnect
    partition-manager
    ark
  ];
EOF
    elif [ "$desktop" = "cosmic" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-term
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];
EOF
    fi
    
    echo "}" >> /mnt/etc/nixos/configuration.nix
    
    sed -i "s|device = \"/dev/disk/by-label/NIXROOT\";|device = \"/dev/disk/by-label/NIXROOT\";|" /mnt/etc/nixos/hardware-configuration.nix
    sed -i "s|device = \"/dev/disk/by-label/NIXBOOT\";|device = \"/dev/disk/by-label/NIXBOOT\";|" /mnt/etc/nixos/hardware-configuration.nix
}

install_system() {
    cd /mnt
    nixos-install --no-root-passwd --show-trace
}

main() {
    clear
    echo "Instalador NixOS 25.11"
    echo ""
    
    select_language
    select_desktop
    select_swap
    select_disk
    collect_user_info
    show_summary
    
    echo "Iniciando particionamento..."
    partition_disk
    echo "Montando partições..."
    mount_partitions
    echo "Criando swap..."
    create_swap
    echo "Gerando configuração..."
    generate_config
    echo "Instalando sistema..."
    install_system
    
    echo ""
    echo "Instalação concluída! / Installation complete!"
    echo "Reinicie o sistema. / Reboot the system."
}

main
