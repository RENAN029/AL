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
    echo "1) Português Brasileiro"
    echo "2) English US"
    read -p "Opção: " lang_opt
    case $lang_opt in
        1) echo "pt_BR" > "$STATE_DIR/language"
           echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "en_US" > "$STATE_DIR/language"
           echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "Opção inválida, usando inglês"
           echo "en_US" > "$STATE_DIR/language"
           echo "us" > "$STATE_DIR/keyboard" ;;
    esac
    
    echo "Selecione o layout do teclado:"
    echo "1) Português Brasileiro"
    echo "2) English US"
    read -p "Opção: " kbd_opt
    case $kbd_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "Opção inválida, usando us" ;;
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
        *) echo "Opção inválida, usando none"
           echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_user() {
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Senha do usuário: " password
    echo
    read -s -p "Confirme a senha: " password2
    echo
    if [ "$password" != "$password2" ]; then
        echo "Senhas não conferem"
        exit 1
    fi
    echo "$password" > "$STATE_DIR/password"
}

select_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    read -p "Digite o disco para instalação (ex: sda): " disk
    echo "/dev/$disk" > "$STATE_DIR/disk"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/language)"
    echo "Teclado: $(cat $STATE_DIR/keyboard)"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "Disco: $(cat $STATE_DIR/disk)"
    echo "============================"
    if ! confirm "Iniciar instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

install_nixos() {
    local disk=$(cat $STATE_DIR/disk)
    local username=$(cat $STATE_DIR/username)
    local password=$(cat $STATE_DIR/password)
    local keyboard=$(cat $STATE_DIR/keyboard)
    local language=$(cat $STATE_DIR/language)
    local desktop=$(cat $STATE_DIR/desktop)
    
    echo "Particionando disco automaticamente..."
    sudo parted $disk -- mklabel gpt
    sudo parted $disk -- mkpart primary 2048s 512MB
    sudo parted $disk -- mkpart primary 512MB 100%
    sudo parted $disk -- set 1 esp on
    
    sleep 2
    sudo partprobe $disk
    sleep 2
    
    local boot_part="${disk}1"
    local root_part="${disk}2"
    
    if [[ $disk == *"nvme"* ]]; then
        boot_part="${disk}p1"
        root_part="${disk}p2"
    fi
    
    echo "Formatando partições..."
    sudo mkfs.fat -F 32 -n NIXBOOT $boot_part
    sudo mkfs.ext4 -L NIXROOT $root_part
    
    echo "Montando partições..."
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    echo "Criando swap file..."
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1M count=2048
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    
    echo "Gerando configuração inicial..."
    sudo nixos-generate-config --root /mnt
    
    echo "Configurando system..."
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
    size = 2048;
  }];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  
  i18n.defaultLocale = "$language.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
  
  console.keyMap = "$keyboard";
  services.xserver.xkb.layout = "$keyboard";
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
    initialPassword = "$password";
    home = "/home/$username";
  };
  
  security.sudo.extraRules = [{
    groups = [ "wheel" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
  
  environment.systemPackages = with pkgs; [
    vim
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
    firefox
  ] ++ lib.optionals (builtins.pathExists ./desktop-packages.nix) (import ./desktop-packages.nix);
  
  system.stateVersion = "25.11";
}
EOF

    if [ "$desktop" != "none" ]; then
        cat > /mnt/etc/nixos/desktop-packages.nix << EOF
with import <nixpkgs> {};

[
EOF
        case $desktop in
            cosmic)
                cat >> /mnt/etc/nixos/desktop-packages.nix << EOF
  cosmic-session
  cosmic-terminal
  cosmic-files
  cosmic-store
  cosmic-wallpapers
  cosmic-greeter
EOF
                echo "  services.displayManager.cosmic-greeter.enable = true;" >> /mnt/etc/nixos/configuration.nix
                echo "  services.desktopManager.cosmic.enable = true;" >> /mnt/etc/nixos/configuration.nix
                ;;
            gnome)
                cat >> /mnt/etc/nixos/desktop-packages.nix << EOF
  gnome-initial-setup
  gnome-console
  gnome-software
  gnome-tweaks
  gnome-disk-utility
  gnome-backgrounds
  gnome-shell
  gnome-terminal
  gdm
EOF
                echo "  services.xserver.enable = true;" >> /mnt/etc/nixos/configuration.nix
                echo "  services.xserver.displayManager.gdm.enable = true;" >> /mnt/etc/nixos/configuration.nix
                echo "  services.xserver.desktopManager.gnome.enable = true;" >> /mnt/etc/nixos/configuration.nix
                ;;
            plasma)
                cat >> /mnt/etc/nixos/desktop-packages.nix << EOF
  plasma5
  konsole
  dolphin
  kdeconnect
  partitionmanager
  ark
  sddm
EOF
                echo "  services.xserver.enable = true;" >> /mnt/etc/nixos/configuration.nix
                echo "  services.xserver.displayManager.sddm.enable = true;" >> /mnt/etc/nixos/configuration.nix
                echo "  services.xserver.desktopManager.plasma5.enable = true;" >> /mnt/etc/nixos/configuration.nix
                ;;
        esac
        echo "]" >> /mnt/etc/nixos/desktop-packages.nix
    fi
    
    echo "Instalando NixOS..."
    cd /mnt
    sudo nixos-install --no-root-passwd
    
    echo "Ativando swap..."
    sudo swapon /mnt/.swapfile
    
    echo "Instalação concluída!"
    echo "Remova a mídia de instalação e reinicie."
}

main() {
    clear
    echo "=== Instalador NixOS 25.11 ==="
    select_language
    select_desktop
    select_user
    select_disk
    show_summary
    install_nixos
}

main
