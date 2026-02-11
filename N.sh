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

menu_language() {
    echo "Selecione o idioma do sistema / Select system language:"
    echo "1) Português do Brasil"
    echo "2) English (US)"
    read -p "Opção / Option: " lang_opt
    case $lang_opt in
        1) echo "pt_BR" > "$STATE_DIR/language" ;;
        2) echo "en_US" > "$STATE_DIR/language" ;;
        *) echo "pt_BR" > "$STATE_DIR/language" ;;
    esac
}

menu_keyboard() {
    echo "Selecione o layout do teclado / Select keyboard layout:"
    echo "1) Português do Brasil (br)"
    echo "2) English (US) (us)"
    read -p "Opção / Option: " key_opt
    case $key_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

menu_desktop() {
    echo "Selecione o ambiente desktop / Select desktop environment:"
    echo "1) GNOME (gnome-console, gnome-software, gnome-tweaks, gnome-disk-utility)"
    echo "2) KDE Plasma (konsole, dolphin, kdeconnect, ark, partitionmanager)"
    echo "3) COSMIC (cosmic-session, cosmic-terminal, cosmic-files, cosmic-store, cosmic-wallpapers)"
    echo "4) Nenhum / None (apenas terminal)"
    read -p "Opção / Option: " de_opt
    case $de_opt in
        1) echo "gnome" > "$STATE_DIR/desktop" ;;
        2) echo "plasma" > "$STATE_DIR/desktop" ;;
        3) echo "cosmic" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

menu_swap() {
    echo "Tamanho do arquivo swap / Swap file size:"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Nenhum / None"
    read -p "Opção / Option: " swap_opt
    case $swap_opt in
        1) echo "2G" > "$STATE_DIR/swap" ;;
        2) echo "4G" > "$STATE_DIR/swap" ;;
        3) echo "8G" > "$STATE_DIR/swap" ;;
        *) echo "none" > "$STATE_DIR/swap" ;;
    esac
}

menu_network() {
    echo "Configuração de rede / Network configuration:"
    echo "1) iwd (recomendado para WiFi)"
    echo "2) NetworkManager (gerenciamento completo)"
    read -p "Opção / Option: " net_opt
    case $net_opt in
        1) echo "iwd" > "$STATE_DIR/network" ;;
        2) echo "networkmanager" > "$STATE_DIR/network" ;;
        *) echo "networkmanager" > "$STATE_DIR/network" ;;
    esac
}

menu_bluetooth() {
    echo "Ativar suporte a Bluetooth? / Enable Bluetooth support?"
    echo "1) Sim"
    echo "2) Não"
    read -p "Opção / Option: " bt_opt
    case $bt_opt in
        1) echo "yes" > "$STATE_DIR/bluetooth" ;;
        *) echo "no" > "$STATE_DIR/bluetooth" ;;
    esac
}

menu_cups() {
    echo "Instalar suporte a impressão (CUPS)? / Install printing support (CUPS)?"
    echo "1) Sim"
    echo "2) Não"
    read -p "Opção / Option: " cups_opt
    case $cups_opt in
        1) echo "yes" > "$STATE_DIR/cups" ;;
        *) echo "no" > "$STATE_DIR/cups" ;;
    esac
}

menu_pipewire() {
    echo "Configurar áudio com PipeWire? / Configure audio with PipeWire?"
    echo "1) Sim"
    echo "2) Não"
    read -p "Opção / Option: " pw_opt
    case $pw_opt in
        1) echo "yes" > "$STATE_DIR/pipewire" ;;
        *) echo "no" > "$STATE_DIR/pipewire" ;;
    esac
}

menu_disk() {
    echo "Discos disponíveis / Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
    echo "$disk_name" > "$STATE_DIR/disk"
    
    echo "Modo de boot / Boot mode:"
    echo "1) UEFI (GPT)"
    echo "2) Legacy (DOS/MBR)"
    read -p "Opção / Option: " boot_opt
    case $boot_opt in
        1) echo "uefi" > "$STATE_DIR/bootmode" ;;
        2) echo "legacy" > "$STATE_DIR/bootmode" ;;
        *) echo "uefi" > "$STATE_DIR/bootmode" ;;
    esac
}

menu_user() {
    read -p "Nome de usuário / Username: " username
    echo "$username" > "$STATE_DIR/username"
    
    read -s -p "Senha / Password: " password
    echo
    read -s -p "Confirme a senha / Confirm password: " password2
    echo
    
    if [ "$password" != "$password2" ]; then
        echo "Senhas não coincidem / Passwords do not match"
        exit 1
    fi
    
    echo "$password" > "$STATE_DIR/password"
}

menu_timezone() {
    echo "Fuso horário / Timezone:"
    echo "1) America/Sao_Paulo"
    echo "2) America/New_York"
    echo "3) America/Chicago"
    echo "4) America/Denver"
    echo "5) America/Los_Angeles"
    echo "6) Outro / Other (especifique)"
    read -p "Opção / Option: " tz_opt
    
    case $tz_opt in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) echo "America/New_York" > "$STATE_DIR/timezone" ;;
        3) echo "America/Chicago" > "$STATE_DIR/timezone" ;;
        4) echo "America/Denver" > "$STATE_DIR/timezone" ;;
        5) echo "America/Los_Angeles" > "$STATE_DIR/timezone" ;;
        6) 
            read -p "Digite o fuso horário / Enter timezone: " custom_tz
            echo "$custom_tz" > "$STATE_DIR/timezone"
            ;;
        *) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
    esac
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo
    echo "Idioma / Language: $(cat $STATE_DIR/language)"
    echo "Teclado / Keyboard: $(cat $STATE_DIR/keyboard)"
    echo "Disco / Disk: /dev/$(cat $STATE_DIR/disk)"
    echo "Modo de boot / Boot mode: $(cat $STATE_DIR/bootmode)"
    echo "Swap: $(cat $STATE_DIR/swap)"
    echo "Rede / Network: $(cat $STATE_DIR/network)"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth)"
    echo "CUPS: $(cat $STATE_DIR/cups)"
    echo "PipeWire: $(cat $STATE_DIR/pipewire)"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Usuário / User: $(cat $STATE_DIR/username)"
    echo "Fuso horário / Timezone: $(cat $STATE_DIR/timezone)"
    echo
    echo "AVISO: Este script irá APAGAR TODOS OS DADOS DO DISCO /dev/$(cat $STATE_DIR/disk)"
    echo "WARNING: This script will ERASE ALL DATA ON DISK /dev/$(cat $STATE_DIR/disk)"
    echo
}

do_partition() {
    local disk="/dev/$(cat $STATE_DIR/disk)"
    local bootmode=$(cat $STATE_DIR/bootmode)
    
    echo "Particionando disco $disk..."
    
    if [ "$bootmode" = "uefi" ]; then
        parted $disk -- mklabel gpt
        parted $disk -- mkpart primary 2048s 500MiB
        parted $disk -- mkpart primary 500MiB 100%
        parted $disk -- set 1 esp on
        mkfs.fat -F 32 "${disk}1"
        fatlabel "${disk}1" NIXBOOT
        mkfs.ext4 -L NIXROOT "${disk}2"
    else
        parted $disk -- mklabel msdos
        parted $disk -- mkpart primary 2048s 500MiB
        parted $disk -- mkpart primary 500MiB 100%
        parted $disk -- set 1 boot on
        mkfs.ext4 -L NIXBOOT "${disk}1"
        mkfs.ext4 -L NIXROOT "${disk}2"
    fi
}

do_mount() {
    local disk="/dev/$(cat $STATE_DIR/disk)"
    
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

do_swap() {
    local swap_size=$(cat $STATE_DIR/swap)
    
    if [ "$swap_size" != "none" ]; then
        dd if=/dev/zero of=/mnt/.swapfile bs=1G count=${swap_size%G} status=progress
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
    fi
}

do_config() {
    local username=$(cat $STATE_DIR/username)
    local password=$(cat $STATE_DIR/password)
    local keyboard=$(cat $STATE_DIR/keyboard)
    local language=$(cat $STATE_DIR/language)
    local timezone=$(cat $STATE_DIR/timezone)
    local desktop=$(cat $STATE_DIR/desktop)
    local network=$(cat $STATE_DIR/network)
    local bluetooth=$(cat $STATE_DIR/bluetooth)
    local cups=$(cat $STATE_DIR/cups)
    local pipewire=$(cat $STATE_DIR/pipewire)
    local swap_size=$(cat $STATE_DIR/swap)
    local disk="/dev/$(cat $STATE_DIR/disk)"
    local bootmode=$(cat $STATE_DIR/bootmode)
    
    nixos-generate-config --root /mnt
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
EOF

    if [ "$bootmode" = "uefi" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";
EOF
    else
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  boot.loader.grub.device = "$disk";
EOF
    fi

    cat >> /mnt/etc/nixos/configuration.nix << EOF
  
  i18n.defaultLocale = "$language.UTF-8";
  console.keyMap = "$keyboard";
  
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
    hashedPassword = lib.mkForce "";
    password = "$password";
  };
  
  security.sudo.wheelNeedsPassword = false;
  
EOF

    if [ "$swap_size" != "none" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  swapDevices = [ { device = "/.swapfile"; } ];
  
EOF
    fi

    if [ "$network" = "iwd" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  networking.wireless.enable = true;
  networking.wireless.iwd.enable = true;
  
EOF
    else
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  networking.networkmanager.enable = true;
  
EOF
    fi

    if [ "$bluetooth" = "yes" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  
EOF
    fi

    if [ "$cups" = "yes" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.printing.enable = true;
  
EOF
    fi

    if [ "$pipewire" = "yes" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
EOF
    fi

    cat >> /mnt/etc/nixos/configuration.nix << EOF
  environment.systemPackages = with pkgs; [
    nano
    htop
    git
    curl
    wget
EOF

    if [ "$desktop" = "gnome" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
EOF
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  ];
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  
EOF
    elif [ "$desktop" = "plasma" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
    konsole
    dolphin
    kdeconnect
    ark
    partitionmanager
EOF
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  ];
  services.xserver.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  
EOF
    elif [ "$desktop" = "cosmic" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
EOF
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  ];
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  
EOF
    else
        cat >> /mnt/etc/nixos/configuration.nix << EOF
  ];
  
EOF
    fi

    cat >> /mnt/etc/nixos/configuration.nix << EOF
  system.stateVersion = "25.11";
}
EOF

    sed -i "s|/dev/.* /boot|/dev/disk/by-label/NIXBOOT /boot|g" /mnt/etc/nixos/hardware-configuration.nix
    sed -i "s|/dev/.* / |/dev/disk/by-label/NIXROOT / |g" /mnt/etc/nixos/hardware-configuration.nix
}

do_install() {
    nixos-install --no-root-passwd --root /mnt
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 ==="
    echo
    
    menu_language
    menu_keyboard
    menu_disk
    menu_swap
    menu_network
    menu_bluetooth
    menu_cups
    menu_pipewire
    menu_desktop
    menu_user
    menu_timezone
    
    show_summary
    
    if confirm "Deseja iniciar a instalação? / Start installation?"; then
        echo "Iniciando instalação / Starting installation..."
        
        do_partition
        do_mount
        do_swap
        do_config
        do_install
        
        echo
        echo "Instalação concluída! / Installation completed!"
        echo "Reinicie o sistema com: sudo reboot"
    else
        echo "Instalação cancelada / Installation cancelled"
        exit 0
    fi
}

main
