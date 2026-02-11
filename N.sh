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
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado / Select keyboard layout:"
    echo "1) Português Brasileiro (br-abnt2)"
    echo "2) English US (us)"
    read -p "Opção / Option: " kb_opt
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_disk() {
    echo "Discos disponíveis / Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda, nvme0n1) / Enter disk for installation: " disk
    echo "$disk" > "$STATE_DIR/disk"
}

select_swap() {
    echo "Tamanho do arquivo swap / Swap file size:"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap / No swap"
    read -p "Opção / Option: " swap_opt
    case $swap_opt in
        1) echo "2G" > "$STATE_DIR/swapsize" ;;
        2) echo "4G" > "$STATE_DIR/swapsize" ;;
        3) echo "8G" > "$STATE_DIR/swapsize" ;;
        4) echo "none" > "$STATE_DIR/swapsize" ;;
        *) echo "2G" > "$STATE_DIR/swapsize" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop / Select desktop environment:"
    echo "1) GNOME (gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds)"
    echo "2) KDE Plasma (konsole dolphin kdeconnect partitionmanager ark)"
    echo "3) COSMIC (cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers)"
    echo "4) Nenhum / None (instalação mínima)"
    read -p "Opção / Option: " de_opt
    case $de_opt in
        1) echo "gnome" > "$STATE_DIR/desktop" ;;
        2) echo "plasma" > "$STATE_DIR/desktop" ;;
        3) echo "cosmic" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_network() {
    echo "Configuração de rede / Network configuration:"
    echo "1) iwd (recomendado para WiFi)"
    echo "2) NetworkManager"
    echo "3) wpa_supplicant"
    read -p "Opção / Option: " net_opt
    case $net_opt in
        1) echo "iwd" > "$STATE_DIR/network" ;;
        2) echo "networkmanager" > "$STATE_DIR/network" ;;
        3) echo "wpa_supplicant" > "$STATE_DIR/network" ;;
        *) echo "networkmanager" > "$STATE_DIR/network" ;;
    esac
}

get_user_info() {
    read -p "Nome de usuário / Username: " username
    echo "$username" > "$STATE_DIR/username"
    read -sp "Senha / Password: " password
    echo
    read -sp "Confirme a senha / Confirm password: " password2
    echo
    if [ "$password" != "$password2" ]; then
        echo "Senhas não conferem / Passwords do not match"
        exit 1
    fi
    echo "$password" > "$STATE_DIR/password"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma / Language: $(cat $STATE_DIR/language)"
    echo "Teclado / Keyboard: $(cat $STATE_DIR/keyboard)"
    echo "Disco / Disk: $(cat $STATE_DIR/disk)"
    echo "Swap: $(cat $STATE_DIR/swapsize)"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Rede / Network: $(cat $STATE_DIR/network)"
    echo "Usuário / User: $(cat $STATE_DIR/username)"
    echo
    if ! confirm "Deseja continuar com a instalação? / Continue with installation?"; then
        echo "Instalação cancelada / Installation cancelled"
        exit 0
    fi
}

do_partition() {
    local disk="/dev/$(cat $STATE_DIR/disk)"
    
    if [ -d /sys/firmware/efi ]; then
        parted $disk -- mklabel gpt
        parted $disk -- mkpart primary 2048s 512MiB
        parted $disk -- mkpart primary 512MiB 100%
        parted $disk -- set 1 esp on
        mkfs.fat -F 32 ${disk}1
        fatlabel ${disk}1 NIXBOOT
        mkfs.ext4 -L NIXROOT ${disk}2
    else
        parted $disk -- mklabel msdos
        parted $disk -- mkpart primary 2048s 512MiB
        parted $disk -- set 1 boot on
        parted $disk -- mkpart primary 512MiB 100%
        mkfs.ext4 -L NIXBOOT ${disk}1
        mkfs.ext4 -L NIXROOT ${disk}2
    fi
    
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swapsize=$(cat $STATE_DIR/swapsize)
    if [ "$swapsize" != "none" ]; then
        dd if=/dev/zero of=/mnt/.swapfile bs=1G count=${swapsize%G} status=progress
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
    fi
}

generate_config() {
    nixos-generate-config --root /mnt
    
    local language=$(cat $STATE_DIR/language)
    local keyboard=$(cat $STATE_DIR/keyboard)
    local desktop=$(cat $STATE_DIR/desktop)
    local network=$(cat $STATE_DIR/network)
    local username=$(cat $STATE_DIR/username)
    local password=$(cat $STATE_DIR/password)
    local disk="/dev/$(cat $STATE_DIR/disk)"
    
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
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  services.printing = {
    enable = true;
    drivers = [ pkgs.cups-filters ];
  };
  
  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
EOF

    case $network in
        iwd)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = false;
  systemd.services.systemd-resolved.enable = false;
EOF
            ;;
        networkmanager)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = false;
EOF
            ;;
        wpa_supplicant)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  networking.wireless.enable = true;
  networking.networkmanager.enable = false;
  networking.wireless.iwd.enable = false;
EOF
            ;;
    esac

    cat >> /mnt/etc/nixos/configuration.nix << EOF

  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" ];
    shell = pkgs.bash;
    hashedPassword = lib.mkForce "$(mkpasswd -m sha-512 $password)";
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
  
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    wget
    htop
    file
    pciutils
    usbutils
    killall
    unzip
    zip
    openssl
EOF

    case $desktop in
        gnome)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
EOF
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
EOF
            ;;
        plasma)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
    konsole
    dolphin
    kdeconnect
    partitionmanager
    ark
EOF
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
EOF
            ;;
        cosmic)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
EOF
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.xserver.enable = false;
EOF
            ;;
        none)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  # Minimal installation
EOF
            ;;
    esac

    cat >> /mnt/etc/nixos/configuration.nix << EOF
  ];
  
  system.stateVersion = "25.11";
}
EOF

    local swapsize=$(cat $STATE_DIR/swapsize)
    if [ "$swapsize" != "none" ]; then
        echo "swapDevices = [ { device = \"/.swapfile\"; } ];" >> /mnt/etc/nixos/hardware-configuration.nix
    fi

    sed -i 's|/dev/disk/by-uuid/[^" ]*|/dev/disk/by-label/NIXROOT|g' /mnt/etc/nixos/hardware-configuration.nix
    sed -i 's|/dev/disk/by-uuid/[^" ]*|/dev/disk/by-label/NIXBOOT|g' /mnt/etc/nixos/hardware-configuration.nix
}

do_install() {
    echo "Iniciando instalação do NixOS..."
    nixos-install --no-root-passwd
    echo "Instalação concluída!"
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 ==="
    echo
    
    select_language
    select_keyboard
    select_disk
    select_swap
    select_desktop
    select_network
    get_user_info
    show_summary
    
    echo "Particionando disco..."
    do_partition
    
    echo "Criando arquivo swap..."
    create_swap
    
    echo "Gerando configuração..."
    generate_config
    
    echo "Instalando sistema..."
    do_install
    
    echo
    echo "Instalação completa! Remova o meio de instalação e reinicie."
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "Senha: (a que você definiu)"
}

main
