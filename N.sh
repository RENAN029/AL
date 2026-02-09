#!/usr/bin/env bash

# NixOS Minimal Installer
# Inspirado no archinstall, mas para NixOS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis globais
TARGET_DISK=""
BOOT_MODE=""
SWAP_SIZE="2GB"
HOSTNAME="nixos"
USERNAME=""
DESKTOP_ENV=""
STATE_DIR="/tmp/nixos-installer-state"
CONFIG_FILE="/mnt/etc/nixos/configuration.nix"

# Funções auxiliares
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

cleanup() {
    print_warning "Limpando..."
    umount -R /mnt 2>/dev/null || true
    swapoff /mnt/.swapfile 2>/dev/null || true
}

trap cleanup EXIT

# Funções principais
detect_boot_mode() {
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
        print_info "Modo de boot detectado: UEFI"
    else
        BOOT_MODE="BIOS"
        print_info "Modo de boot detectado: BIOS"
    fi
}

select_disk() {
    print_info "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,TYPE,MODEL
    
    while true; do
        read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk
        if [ -b "/dev/$disk" ]; then
            TARGET_DISK="/dev/$disk"
            print_info "Disco selecionado: $TARGET_DISK"
            
            if confirm "Todos os dados em $TARGET_DISK serão apagados. Continuar?"; then
                break
            fi
        else
            print_error "Disco inválido!"
        fi
    done
}

partition_disk() {
    print_info "Particionando disco $TARGET_DISK..."
    
    # Limpar tabela de partições
    wipefs -a "$TARGET_DISK"
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        # GPT para UEFI
        parted "$TARGET_DISK" --script mklabel gpt
        
        # Partição de boot EFI
        parted "$TARGET_DISK" --script mkpart primary fat32 1MiB 512MiB
        parted "$TARGET_DISK" --script set 1 esp on
        
        # Partição raiz
        parted "$TARGET_DISK" --script mkpart primary ext4 512MiB 100%
        
        BOOT_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
    else
        # MBR para BIOS
        parted "$TARGET_DISK" --script mklabel msdos
        
        # Partição de boot
        parted "$TARGET_DISK" --script mkpart primary ext4 1MiB 512MiB
        parted "$TARGET_DISK" --script set 1 boot on
        
        # Partição raiz
        parted "$TARGET_DISK" --script mkpart primary ext4 512MiB 100%
        
        BOOT_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
    fi
    
    # Sincronizar
    sync
    sleep 2
    
    # Formatar partições
    print_info "Formatando partições..."
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkfs.fat -F 32 "$BOOT_PART"
        fatlabel "$BOOT_PART" NIXBOOT
    else
        mkfs.ext4 "$BOOT_PART"
        e2label "$BOOT_PART" NIXBOOT
    fi
    
    mkfs.ext4 "$ROOT_PART"
    e2label "$ROOT_PART" NIXROOT
    
    # Montar
    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot
    mount "$BOOT_PART" /mnt/boot
    
    print_success "Disco particionado e montado"
}

create_swap() {
    if confirm "Criar arquivo swap de $SWAP_SIZE?"; then
        print_info "Criando arquivo swap..."
        
        # Calcular tamanho em MB
        if [[ "$SWAP_SIZE" == *GB ]]; then
            size_gb=${SWAP_SIZE%GB}
            size_mb=$((size_gb * 1024))
        else
            size_mb=${SWAP_SIZE%MB}
        fi
        
        dd if=/dev/zero of=/mnt/.swapfile bs=1M count="$size_mb" status=progress
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
        
        print_success "Swap criado"
    fi
}

get_user_info() {
    while [ -z "$HOSTNAME" ]; do
        read -p "Digite o hostname: " HOSTNAME
    done
    
    while [ -z "$USERNAME" ]; do
        read -p "Digite o nome de usuário: " USERNAME
    done
    
    read -sp "Digite a senha para $USERNAME: " USER_PASSWORD
    echo
    read -sp "Confirme a senha: " USER_PASSWORD_CONFIRM
    echo
    
    if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
        print_error "Senhas não coincidem!"
        return 1
    fi
}

select_desktop() {
    clear
    echo "=== Ambiente Desktop ==="
    echo "1) Nenhum (apenas terminal)"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) XFCE"
    echo "5) Sway (Wayland)"
    echo "6) Hyprland (Wayland compositor)"
    echo "7) Cinnamon"
    echo
    
    read -p "Selecione uma opção (1-7): " choice
    
    case $choice in
        1) DESKTOP_ENV="none" ;;
        2) DESKTOP_ENV="gnome" ;;
        3) DESKTOP_ENV="plasma" ;;
        4) DESKTOP_ENV="xfce" ;;
        5) DESKTOP_ENV="sway" ;;
        6) DESKTOP_ENV="hyprland" ;;
        7) DESKTOP_ENV="cinnamon" ;;
        *) DESKTOP_ENV="none" ;;
    esac
    
    print_info "Desktop selecionado: $DESKTOP_ENV"
}

generate_base_config() {
    print_info "Gerando configuração base..."
    
    # Gerar configuração inicial
    nixos-generate-config --root /mnt
    
    # Configuração básica
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Network
  networking.hostName = "$HOSTNAME";
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "America/Sao_Paulo";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Console
  console.keyMap = "br-abnt2";

  # User
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "$USER_PASSWORD";
  };

  # Sudo
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];

  # Swap file
  swapDevices = [ { device = "/.swapfile"; } ];

  # Esta opção permite substituições de pacotes não assinados
  nixpkgs.config.allowUnfree = true;

  # Habilitar o serviço OpenSSH se necessário
  # services.openssh.enable = true;

  # Esta opção define a versão do canal NixOS
  system.stateVersion = "23.11"; # Não mude esta linha
}
EOF
}

add_desktop_config() {
    case $DESKTOP_ENV in
        gnome)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  # GNOME Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # GNOME extras
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
  ];
  
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome-extension-manager
  ];
EOF
            ;;
        plasma)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  # KDE Plasma
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  # KDE applications
  environment.systemPackages = with pkgs; [
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.ark
    kdeconnect
  ];
EOF
            ;;
        xfce)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  # XFCE
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  
  environment.systemPackages = with pkgs; [
    xfce.xfce4-terminal
    xfce.thunar
    xfce.ristretto
  ];
EOF
            ;;
        sway)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  # Sway (Wayland)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  
  environment.systemPackages = with pkgs; [
    sway
    swaylock
    swayidle
    waybar
    wofi
    alacritty
  ];
  
  # Enable necessary services
  security.polkit.enable = true;
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
EOF
            ;;
        hyprland)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  # Hyprland
  programs.hyprland = {
    enable = true;
    nvidiaPatches = false;
    xwayland.enable = true;
  };
  
  environment.systemPackages = with pkgs; [
    hyprland
    waybar
    rofi-wayland
    alacritty
    swaylock-effects
  ];
  
  # Required for Hyprland
  security.polkit.enable = true;
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
EOF
            ;;
        cinnamon)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  # Cinnamon
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;
  
  environment.systemPackages = with pkgs; [
    cinnamon.nemo
    cinnamon.xed
  ];
EOF
            ;;
    esac
}

install_system() {
    print_info "Instalando NixOS..."
    
    # Adicionar configuração do desktop
    add_desktop_config
    
    # Instalar
    nixos-install --no-root-passwd
    
    print_success "NixOS instalado com sucesso!"
}

post_install() {
    print_info "Configurações pós-instalação..."
    
    # Habilitar serviços comuns
    if [ "$DESKTOP_ENV" != "none" ]; then
        print_info "Habilitando NetworkManager..."
        chroot /mnt systemctl enable NetworkManager
    fi
    
    print_success "Instalação completa!"
    echo
    echo "=========================================="
    echo "Hostname: $HOSTNAME"
    echo "Usuário: $USERNAME"
    echo "Desktop: $DESKTOP_ENV"
    echo "Modo de boot: $BOOT_MODE"
    echo "=========================================="
    echo
    echo "Comandos úteis após o primeiro boot:"
    echo "  sudo nixos-rebuild switch  # Aplicar mudanças"
    echo "  sudo nixos-rebuild boot    # Aplicar para próximo boot"
    echo "  nix-shell -p <pacote>      # Testar pacote temporariamente"
    echo
}

main_menu() {
    clear
    echo "=========================================="
    echo "    INSTALADOR NIXOS MINIMAL"
    echo "=========================================="
    echo
    echo "Este script irá:"
    echo "1. Detectar modo de boot (UEFI/BIOS)"
    echo "2. Particionar disco automaticamente"
    echo "3. Configurar sistema base"
    echo "4. Instalar ambiente desktop opcional"
    echo "5. Criar usuário"
    echo
    echo "ATENÇÃO: Todos os dados no disco serão perdidos!"
    echo
    
    if ! confirm "Deseja continuar?"; then
        exit 0
    fi
    
    # Executar etapas
    detect_boot_mode
    select_disk
    partition_disk
    create_swap
    get_user_info
    select_desktop
    generate_base_config
    install_system
    post_install
}

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    print_error "Execute como root: sudo $0"
    exit 1
fi

# Verificar se estamos no ambiente de instalação
if ! mount | grep -q "/mnt"; then
    print_warning "Certifique-se de estar no ambiente de instalação do NixOS"
    if confirm "Continuar mesmo assim?"; then
        main_menu
    fi
else
    main_menu
fi
