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

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

selecionar_idioma() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português Brasileiro (pt_BR)"
    echo "2) Inglês Americano (en_US)"
    read -p "Opção: " idioma_opcao
    case $idioma_opcao in
        1) echo "pt_BR" > "$STATE_DIR/language" ;;
        2) echo "en_US" > "$STATE_DIR/language" ;;
        *) echo "en_US" > "$STATE_DIR/language" ;;
    esac
}

selecionar_teclado() {
    echo "Selecione o layout do teclado:"
    echo "1) Português Brasileiro (br)"
    echo "2) Inglês Americano (us)"
    read -p "Opção: " teclado_opcao
    case $teclado_opcao in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

selecionar_swap() {
    echo "Selecione o tamanho do arquivo swap (GB):"
    echo "1) 1GB"
    echo "2) 2GB"
    echo "3) 4GB"
    echo "4) 8GB"
    read -p "Opção: " swap_opcao
    case $swap_opcao in
        1) echo "1048576" > "$STATE_DIR/swapsize" ;;
        2) echo "2097152" > "$STATE_DIR/swapsize" ;;
        3) echo "4194304" > "$STATE_DIR/swapsize" ;;
        4) echo "8388608" > "$STATE_DIR/swapsize" ;;
        *) echo "2097152" > "$STATE_DIR/swapsize" ;;
    esac
}

selecionar_desktop() {
    echo "Selecione o ambiente desktop (apenas um):"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Cosmic"
    echo "4) Nenhum (apenas console)"
    read -p "Opção: " desktop_opcao
    case $desktop_opcao in
        1) echo "gnome" > "$STATE_DIR/desktop" ;;
        2) echo "plasma" > "$STATE_DIR/desktop" ;;
        3) echo "cosmic" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

selecionar_bluetooth() {
    echo "Instalar suporte a Bluetooth?"
    echo "1) Sim"
    echo "2) Não"
    read -p "Opção: " bt_opcao
    case $bt_opcao in
        1) echo "true" > "$STATE_DIR/bluetooth" ;;
        2) echo "false" > "$STATE_DIR/bluetooth" ;;
        *) echo "false" > "$STATE_DIR/bluetooth" ;;
    esac
}

selecionar_impressao() {
    echo "Instalar suporte a impressão (CUPS)?"
    echo "1) Sim"
    echo "2) Não"
    read -p "Opção: " cups_opcao
    case $cups_opcao in
        1) echo "true" > "$STATE_DIR/cups" ;;
        2) echo "false" > "$STATE_DIR/cups" ;;
        *) echo "false" > "$STATE_DIR/cups" ;;
    esac
}

listar_discos() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop" | tail -n +2
}

particionar_disco() {
    listar_discos
    read -p "Digite o disco para instalação (ex: sda): " disco
    DISCO="/dev/$disco"
    echo "$DISCO" > "$STATE_DIR/disk"
    
    if confirm "AVISO: TODO O CONTEÚDO DE $DISCO SERÁ APAGADO. Continuar?"; then
        return 0
    else
        exit 1
    fi
}

coletar_dados_usuario() {
    read -p "Digite o nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    read -s -p "Digite a senha: " password1
    echo
    read -s -p "Confirme a senha: " password2
    echo
    
    if [ "$password1" != "$password2" ]; then
        echo "Senhas não coincidem!"
        exit 1
    fi
    
    echo "$password1" > "$STATE_DIR/password"
}

mostrar_resumo() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/language 2>/dev/null || echo 'en_US')"
    echo "Teclado: $(cat $STATE_DIR/keyboard 2>/dev/null || echo 'us')"
    echo "Disco: $(cat $STATE_DIR/disk 2>/dev/null || echo 'Não definido')"
    echo "Swap: $(cat $STATE_DIR/swapsize 2>/dev/null || echo '2097152') blocos"
    echo "Desktop: $(cat $STATE_DIR/desktop 2>/dev/null || echo 'none')"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth 2>/dev/null || echo 'false')"
    echo "CUPS: $(cat $STATE_DIR/cups 2>/dev/null || echo 'false')"
    echo "Usuário: $(cat $STATE_DIR/username 2>/dev/null || echo 'Não definido')"
    echo "============================"
    
    if ! confirm "Deseja iniciar a instalação?"; then
        echo "Instalação cancelada."
        cleanup_files "$STATE_DIR"/*
        exit 0
    fi
}

executar_instalacao() {
    LANGUAGE=$(cat "$STATE_DIR/language")
    KEYBOARD=$(cat "$STATE_DIR/keyboard")
    DISCO=$(cat "$STATE_DIR/disk")
    SWAPSIZE=$(cat "$STATE_DIR/swapsize")
    DESKTOP=$(cat "$STATE_DIR/desktop")
    BLUETOOTH=$(cat "$STATE_DIR/bluetooth")
    CUPS=$(cat "$STATE_DIR/cups")
    USERNAME=$(cat "$STATE_DIR/username")
    PASSWORD=$(cat "$STATE_DIR/password")
    
    echo "Iniciando particionamento..."
    
    if [ -d /sys/firmware/efi ]; then
        parted $DISCO -- mklabel gpt
        parted $DISCO -- mkpart primary 1MB 512MB
        parted $DISCO -- set 1 esp on
        parted $DISCO -- mkpart primary 512MB 100%
        BOOT_PART="${DISCO}1"
        ROOT_PART="${DISCO}2"
    else
        parted $DISCO -- mklabel msdos
        parted $DISCO -- mkpart primary 1MB 512MB
        parted $DISCO -- set 1 boot on
        parted $DISCO -- mkpart primary 512MB 100%
        BOOT_PART="${DISCO}1"
        ROOT_PART="${DISCO}2"
    fi
    
    mkfs.fat -F 32 $BOOT_PART
    fatlabel $BOOT_PART NIXBOOT
    mkfs.ext4 $ROOT_PART -L NIXROOT
    
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=$SWAPSIZE
    chmod 600 /mnt/.swapfile
    mkswap /mnt/.swapfile
    swapon /mnt/.swapfile
    
    nixos-generate-config --root /mnt
    
    sed -i "s|device = \"/dev/disk/by-uuid/[^\"]*\"|device = \"/dev/disk/by-label/NIXROOT\"|g" /mnt/etc/nixos/hardware-configuration.nix
    sed -i "s|device = \"/dev/disk/by-uuid/[^\"]*\"|device = \"/dev/disk/by-label/NIXBOOT\"|g" /mnt/etc/nixos/hardware-configuration.nix
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
EOF

if [ -d /sys/firmware/efi ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";
EOF
else
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  boot.loader.grub.device = "$DISCO";
EOF
fi

cat >> /mnt/etc/nixos/configuration.nix << EOF

  swapDevices = [ { device = "/.swapfile"; } ];
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  i18n.defaultLocale = "$LANGUAGE.UTF-8";
  console.keyMap = "$KEYBOARD";
  
  services.xserver.xkb.layout = "$KEYBOARD";
  
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  hardware.pulseaudio.enable = false;
  
EOF

if [ "$BLUETOOTH" = "true" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  
EOF
fi

if [ "$CUPS" = "true" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint pkgs.hplip ];
  
EOF
fi

if [ "$DESKTOP" = "gnome" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-contacts
    gnome-maps
    gnome-weather
    gnome-music
    epiphany
    geary
  ];
  
EOF
elif [ "$DESKTOP" = "plasma" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    elisa
    gwenview
    okular
    kate
    khelpcenter
    konversation
  ];
  
EOF
elif [ "$DESKTOP" = "cosmic" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.desktopManager.cosmic.enable = true;
  
EOF
fi

cat >> /mnt/etc/nixos/configuration.nix << EOF
  system.stateVersion = "25.11";
  
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "$PASSWORD";
    shell = pkgs.bash;
  };
  
  security.sudo.wheelNeedsPassword = true;
  
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    neofetch
    firefox
EOF

if [ "$DESKTOP" = "gnome" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
    gnome-initial-setup
EOF
elif [ "$DESKTOP" = "plasma" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
    konsole
    dolphin
    ark
    partitionmanager
EOF
elif [ "$DESKTOP" = "cosmic" ]; then
    cat >> /mnt/etc/nixos/configuration.nix << EOF
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-wallpapers
EOF
fi

cat >> /mnt/etc/nixos/configuration.nix << EOF
  ];
}
EOF

    cd /mnt
    nixos-install --no-root-passwd
    
    echo "Instalação concluída!"
    echo "Remova a mídia de instalação e reinicie."
}

main() {
    echo "=== INSTALADOR NIXOS 25.11 ==="
    echo "Coletando configurações..."
    
    selecionar_idioma
    selecionar_teclado
    particionar_disco
    selecionar_swap
    selecionar_desktop
    selecionar_bluetooth
    selecionar_impressao
    coletar_dados_usuario
    mostrar_resumo
    executar_instalacao
}

main
