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

list_disks() {
    echo "Discos disponiveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    echo
}

select_language() {
    echo "Selecione o idioma do sistema:"
    echo "1) Portugues Brasileiro (pt_BR.UTF-8)"
    echo "2) Ingles Americano (en_US.UTF-8)"
    read -p "Opcao [1-2]: " lang_opt
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado:"
    echo "1) Portugues Brasileiro (br)"
    echo "2) Ingles Americano (us)"
    read -p "Opcao [1-2]: " kb_opt
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_disk() {
    list_disks
    read -p "Digite o disco para instalacao (ex: sda, nvme0n1): " disk
    echo "/dev/$disk" > "$STATE_DIR/disk"
}

select_swap() {
    echo "Tamanho do swap (recomendado: 2G, 4G, 8G):"
    read -p "Digite o tamanho (ex: 2G): " swap_size
    echo "$swap_size" > "$STATE_DIR/swap_size"
}

select_desktop() {
    echo "Selecione o ambiente desktop (apenas pacotes basicos):"
    echo "1) GNOME (gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds)"
    echo "2) KDE Plasma (konsole dolphin kdeconnect ark)"
    echo "3) Cosmic (cosmic-session cosmic-terminal cosmic-files cosmic-store)"
    echo "4) Nenhum (apenas console)"
    read -p "Opcao [1-4]: " de_opt
    echo "$de_opt" > "$STATE_DIR/desktop"
}

select_network() {
    echo "Metodo de rede:"
    echo "1) iwd (recomendado para wifi)"
    echo "2) NetworkManager"
    read -p "Opcao [1-2]: " net_opt
    echo "$net_opt" > "$STATE_DIR/network"
}

select_user() {
    read -p "Nome do usuario: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Senha do usuario: " password
    echo
    read -s -p "Confirme a senha: " password2
    echo
    if [ "$password" != "$password2" ]; then
        echo "Senhas nao conferem"
        exit 1
    fi
    echo "$password" > "$STATE_DIR/password"
}

select_region() {
    echo "Regiao (ex: America/Sao_Paulo, America/New_York):"
    read -p "Digite a regiao: " region
    echo "$region" > "$STATE_DIR/region"
}

show_summary() {
    echo "========================================="
    echo "RESUMO DA INSTALACAO"
    echo "========================================="
    echo "Idioma: $(cat $STATE_DIR/language 2>/dev/null || echo 'nao definido')"
    echo "Teclado: $(cat $STATE_DIR/keyboard 2>/dev/null || echo 'nao definido')"
    echo "Disco: $(cat $STATE_DIR/disk 2>/dev/null || echo 'nao definido')"
    echo "Swap: $(cat $STATE_DIR/swap_size 2>/dev/null || echo 'nao definido')"
    echo "Desktop: $(cat $STATE_DIR/desktop 2>/dev/null | sed 's/1/GNOME/;s/2/KDE/;s/3/Cosmic/;s/4/Nenhum/')"
    echo "Rede: $(cat $STATE_DIR/network 2>/dev/null | sed 's/1/iwd/;s/2/NetworkManager/')"
    echo "Usuario: $(cat $STATE_DIR/username 2>/dev/null || echo 'nao definido')"
    echo "Regiao: $(cat $STATE_DIR/region 2>/dev/null || echo 'nao definido')"
    echo "========================================="
}

configure_system() {
    local disk=$(cat $STATE_DIR/disk)
    local username=$(cat $STATE_DIR/username)
    local password=$(cat $STATE_DIR/password)
    local language=$(cat $STATE_DIR/language)
    local keyboard=$(cat $STATE_DIR/keyboard)
    local swap_size=$(cat $STATE_DIR/swap_size)
    local desktop=$(cat $STATE_DIR/desktop)
    local network=$(cat $STATE_DIR/network)
    local region=$(cat $STATE_DIR/region)

    echo "Iniciando particionamento..."
    
    if [[ "$disk" == *"nvme"* ]]; then
        local boot_part="${disk}p1"
        local root_part="${disk}p2"
    else
        local boot_part="${disk}1"
        local root_part="${disk}2"
    fi

    sudo parted $disk -- mklabel gpt
    sudo parted $disk -- mkpart primary 2048s 500MB
    sudo parted $disk -- mkpart primary 500MB 100%
    sudo parted $disk -- set 1 boot on
    sudo parted $disk -- set 1 esp on

    sudo mkfs.fat -F 32 -n NIXBOOT $boot_part
    sudo mkfs.ext4 -L NIXROOT $root_part

    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot

    echo "Criando arquivo swap..."
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1M count=${swap_size%G}000
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile

    echo "Gerando configuracao basica..."
    sudo nixos-generate-config --root /mnt

    echo "Configurando system.nix..."
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    grub = {
      enable = true;
      device = "$disk";
      efiSupport = true;
      enableCryptodisk = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
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
    size = $(echo $swap_size | sed 's/G//') * 1024;
  }];

  i18n = {
    defaultLocale = "$language";
    extraLocaleSettings = {
      LC_ADDRESS = "$language";
      LC_IDENTIFICATION = "$language";
      LC_MEASUREMENT = "$language";
      LC_MONETARY = "$language";
      LC_NAME = "$language";
      LC_NUMERIC = "$language";
      LC_PAPER = "$language";
      LC_TELEPHONE = "$language";
      LC_TIME = "$language";
    };
  };

  console.keyMap = "$keyboard";
  services.xserver.xkb.layout = "$keyboard";

  time.timeZone = "$region";
  services.ntp.enable = true;
  networking.timeServers = [ "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" "3.pool.ntp.org" ];

  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.bash;
    hashedPassword = lib.mkForce (lib.strings.hashString "sha256" "$password");
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint hplip ];
  };

EOF

    if [ "$network" = "1" ]; then
        sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = true;
      };
      Network = {
        EnableIPv6 = true;
      };
    };
  };
  systemd.services.iwd.wantedBy = [ "multi-user.target" ];
EOF
    else
        sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager.wantedBy = [ "multi-user.target" ];
EOF
    fi

    case $desktop in
        1)
            sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
  ];
EOF
            ;;
        2)
            sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages = with pkgs; [
    konsole
    dolphin
    kdeconnect-kde
    ark
  ];
EOF
            ;;
        3)
            sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  environment.systemPackages = with pkgs; [
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
  ];
EOF
            ;;
    esac

    sudo tee -a /mnt/etc/nixos/configuration.nix > /dev/null << 'EOF'
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    git
    cups
    bluez
    bluez-tools
    pipewire
    wireplumber
  ];

  system.stateVersion = "25.11";
}
EOF

    echo "Instalando NixOS..."
    cd /mnt
    sudo nixos-install --no-root-passwd --option binary-caches "" --option substitute false
    
    echo "Instalacao concluida. Reinicie o sistema."
}

main_menu() {
    echo "=== NixOS Arch Install Script ==="
    echo "NixOS versao 25.11"
    echo
    
    select_language
    select_keyboard
    select_disk
    select_swap
    select_desktop
    select_network
    select_user
    select_region
    
    show_summary
    
    if confirm "Deseja continuar com a instalacao?"; then
        configure_system
    else
        echo "Instalacao cancelada."
        exit 0
    fi
}

main_menu
