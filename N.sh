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

selecionar_idioma() {
    echo "Selecione o idioma do sistema:"
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) Inglês Americano (en_US.UTF-8)"
    read -p "Opção [1-2]: " idioma_opcao
    case $idioma_opcao in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
    esac
}

selecionar_teclado() {
    echo "Selecione o layout do teclado:"
    echo "1) Português Brasileiro (br)"
    echo "2) Inglês Americano (us)"
    read -p "Opção [1-2]: " teclado_opcao
    case $teclado_opcao in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

selecionar_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) COSMIC"
    echo "4) Nenhum (somente console)"
    read -p "Opção [1-4]: " desktop_opcao
    echo "$desktop_opcao" > "$STATE_DIR/desktop"
}

selecionar_disco() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disco
    echo "$disco" > "$STATE_DIR/disk"
}

configurar_swap() {
    echo "Tamanho do arquivo swap (em GB):"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap"
    read -p "Opção [1-4]: " swap_opcao
    echo "$swap_opcao" > "$STATE_DIR/swap_size"
}

resumo_instalacao() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo
    echo "Idioma: $(cat "$STATE_DIR/language")"
    echo "Teclado: $(cat "$STATE_DIR/keyboard")"
    echo "Disco: /dev/$(cat "$STATE_DIR/disk")"
    case $(cat "$STATE_DIR/swap_size") in
        1) echo "Swap: 2GB" ;;
        2) echo "Swap: 4GB" ;;
        3) echo "Swap: 8GB" ;;
        4) echo "Swap: Desabilitado" ;;
    esac
    case $(cat "$STATE_DIR/desktop") in
        1) echo "Desktop: GNOME" ;;
        2) echo "Desktop: KDE Plasma" ;;
        3) echo "Desktop: COSMIC" ;;
        4) echo "Desktop: Console apenas" ;;
    esac
    echo
    read -p "Digite o nome do usuário: " NOME_USUARIO
    echo "$NOME_USUARIO" > "$STATE_DIR/username"
    read -s -p "Digite a senha do usuário: " SENHA_USUARIO
    echo
    read -s -p "Confirme a senha: " SENHA_CONFIRM
    echo
    
    if [ "$SENHA_USUARIO" != "$SENHA_CONFIRM" ]; then
        echo "Senhas não conferem!"
        exit 1
    fi
    echo "$SENHA_USUARIO" > "$STATE_DIR/userpass"
    
    echo
    if ! confirm "Deseja iniciar a instalação com estas configurações?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

particionar_disco() {
    local DISCO="/dev/$(cat "$STATE_DIR/disk")"
    
    echo "Particionando $DISCO..."
    
    if [ -d /sys/firmware/efi ]; then
        parted $DISCO -- mklabel gpt
        parted $DISCO -- mkpart primary 512MiB -8GiB
        parted $DISCO -- mkpart primary linux-swap -8GiB 100%
        parted $DISCO -- mkpart ESP fat32 1MiB 512MiB
        parted $DISCO -- set 3 esp on
        export BOOT_PART="${DISCO}3"
        export ROOT_PART="${DISCO}1"
        export SWAP_PART="${DISCO}2"
    else
        parted $DISCO -- mklabel msdos
        parted $DISCO -- mkpart primary 1MiB -8GiB
        parted $DISCO -- mkpart primary linux-swap -8GiB 100%
        parted $DISCO -- set 1 boot on
        export BOOT_PART="${DISCO}1"
        export ROOT_PART="${DISCO}1"
        export SWAP_PART="${DISCO}2"
    fi
    
    mkfs.ext4 -L NIXROOT $ROOT_PART
    mount $ROOT_PART /mnt
    
    if [ -d /sys/firmware/efi ]; then
        mkfs.fat -F 32 -n NIXBOOT $BOOT_PART
        mkdir -p /mnt/boot
        mount $BOOT_PART /mnt/boot
    fi
    
    case $(cat "$STATE_DIR/swap_size") in
        1) mkswap -L NIXSWAP $SWAP_PART && swapon $SWAP_PART ;;
        2) mkswap -L NIXSWAP $SWAP_PART && swapon $SWAP_PART ;;
        3) mkswap -L NIXSWAP $SWAP_PART && swapon $SWAP_PART ;;
        4) echo "Swap não configurado" ;;
    esac
}

configurar_nixos() {
    nixos-generate-config --root /mnt
    
    local TECLADO=$(cat "$STATE_DIR/keyboard")
    local IDIOMA=$(cat "$STATE_DIR/language")
    local USUARIO=$(cat "$STATE_DIR/username")
    local SENHA=$(cat "$STATE_DIR/userpass")
    local SENHA_HASH=$(mkpasswd -m sha-512 "$SENHA")
    local DISCO="/dev/$(cat "$STATE_DIR/disk")"
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      device = "$DISCO";
      efiSupport = ${if [ -d /sys/firmware/efi ]; then "true"; else "false";};
      efiInstallAsRemovable = ${if [ -d /sys/firmware/efi ]; then "true"; else "false";};
    };
  };

  i18n.defaultLocale = "$IDIOMA";
  console.keyMap = "$TECLADO";
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd.enable = true;
  };
  
  services.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  
  services.printing = {
    enable = true;
    drivers = [ pkgs.cups-filters ];
  };
  
  users.users.$USUARIO = {
    isNormalUser = true;
    password = "$SENHA";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" "scanner" ];
  };
  
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  
  environment.systemPackages = with pkgs; [
    git
    vim
    nano
    htop
    firefox
    iwd
    networkmanager
    networkmanagerapplet
    bluez
    bluez-tools
    pulseaudio
    pavucontrol
    cups
    system-config-printer
  ];
EOF

    case $(cat "$STATE_DIR/desktop") in
        1)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    gnome-contacts
    gnome-maps
    gnome-weather
    epiphany
    geary
  ];
EOF
            ;;
        2)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  environment.plasma5.excludePackages = with pkgs; [
    elisa
    gwenview
    okular
    konversation
  ];
EOF
            ;;
        3)
            cat >> /mnt/etc/nixos/configuration.nix << EOF
  
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
EOF
            ;;
    esac

    echo "}" >> /mnt/etc/nixos/configuration.nix

    cat > /mnt/etc/nixos/hardware-configuration.nix << EOF
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };
EOF

    if [ -d /sys/firmware/efi ]; then
        cat >> /mnt/etc/nixos/hardware-configuration.nix << EOF
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };
EOF
    fi

    echo "}" >> /mnt/etc/nixos/hardware-configuration.nix
}

instalar_nixos() {
    echo "Iniciando instalação do NixOS..."
    nixos-install --no-root-passwd --root /mnt
    
    echo "Configuração concluída!"
    echo "Instalação finalizada. Remova a mídia de instalação e reinicie."
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 ==="
    echo
    
    selecionar_idioma
    selecionar_teclado
    selecionar_desktop
    selecionar_disco
    configurar_swap
    resumo_instalacao
    
    echo "Preparando disco..."
    particionar_disco
    
    echo "Configurando sistema..."
    configurar_nixos
    
    echo "Instalando..."
    instalar_nixos
}

main
