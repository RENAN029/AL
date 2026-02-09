#!/bin/bash
set -e

# Verifica se é root
if [ "$EUID" -ne 0 ]; then 
    echo "Por favor, execute como root"
    exit 1
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funções auxiliares
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    read -p "$1 (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

# Detecção de sistema
detect_system() {
    print_status "Detectando sistema..."
    
    # Verifica se estamos no instalador
    if [ -f /etc/os-release ] && grep -q "NixOS" /etc/os-release; then
        IS_INSTALLER=true
    else
        IS_INSTALLER=false
    fi
    
    # Detecta UEFI/BIOS
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
        print_status "Modo de boot: UEFI"
    else
        BOOT_MODE="BIOS"
        print_status "Modo de boot: BIOS/Legacy"
    fi
}

# Lista discos disponíveis
list_disks() {
    print_status "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E '^(NAME|disk|nvme)'
    echo
}

# Particionamento
partition_disk() {
    local disk=$1
    
    print_status "Particionando $disk..."
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        # GPT para UEFI
        parted $disk -- mklabel gpt
        parted $disk -- mkpart primary 512MiB -8GiB
        parted $disk -- mkpart ESP fat32 1MiB 512MiB
        parted $disk -- set 2 esp on
        
        BOOT_PART="${disk}2"
        ROOT_PART="${disk}1"
    else
        # MBR para BIOS
        parted $disk -- mklabel msdos
        parted $disk -- mkpart primary 1MiB -8GiB
        parted $disk -- mkpart primary -8GiB 100%
        parted $disk -- set 1 boot on
        
        ROOT_PART="${disk}1"
        SWAP_PART="${disk}2"
    fi
}

# Formatação
format_partitions() {
    print_status "Formatando partições..."
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkfs.fat -F 32 -n boot $BOOT_PART
        mkfs.ext4 -L nixos $ROOT_PART
    else
        mkfs.ext4 -L nixos $ROOT_PART
        mkswap -L swap $SWAP_PART
        swapon $SWAP_PART
    fi
}

# Montagem
mount_filesystems() {
    print_status "Montando sistemas de arquivos..."
    
    mount /dev/disk/by-label/nixos /mnt
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkdir -p /mnt/boot
        mount /dev/disk/by-label/boot /mnt/boot
    fi
}

# Configuração básica do sistema
generate_base_config() {
    print_status "Gerando configuração base..."
    
    nixos-generate-config --root /mnt
    
    # Configuração básica
    local config_file="/mnt/etc/nixos/configuration.nix"
    local hardware_file="/mnt/etc/nixos/hardware-configuration.nix"
    
    # Backup do arquivo original
    cp "$config_file" "${config_file}.backup"
}

# Configuração de usuário
configure_users() {
    print_status "Configurando usuários..."
    
    read -p "Nome de usuário principal: " USERNAME
    read -s -p "Senha para $USERNAME: " USER_PASS
    echo
    read -s -p "Senha root: " ROOT_PASS
    echo
    
    # Criar configuração de usuário
    cat > /tmp/user_config.nix << EOF
{ config, pkgs, ... }:

{
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "$USER_PASS";
  };

  users.users.root.initialPassword = "$ROOT_PASS";

  security.sudo.wheelNeedsPassword = false;
}
EOF
}

# Configuração de rede
configure_network() {
    print_status "Configurando rede..."
    
    if confirm "Usar NetworkManager para gerenciamento de rede?"; then
        cat > /tmp/network_config.nix << EOF
{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.hostName = "nixos";
}
EOF
    else
        cat > /tmp/network_config.nix << EOF
{ config, pkgs, ... }:

{
  networking.useDHCP = true;
  networking.hostName = "nixos";
}
EOF
    fi
}

# Ambientes Desktop
select_desktop() {
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    while true; do
        clear
        echo "=== Seleção de Ambiente Desktop ==="
        echo "1) GNOME"
        echo "2) KDE Plasma"
        echo "3) Xfce"
        echo "4) None (apenas terminal)"
        echo "5) Sair"
        echo
        
        read -p "Selecione uma opção: " desktop_choice
        
        case $desktop_choice in
            1)
                cat > /tmp/desktop_config.nix << 'EOF'
{ config, pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
  ];
}
EOF
                DESKTOP_SELECTED="GNOME"
                break
                ;;
            2)
                cat > /tmp/desktop_config.nix << 'EOF'
{ config, pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  environment.systemPackages = with pkgs; [
    kdeApplications.konsole
    kdeApplications.dolphin
    kdeApplications.kate
  ];
}
EOF
                DESKTOP_SELECTED="KDE Plasma"
                break
                ;;
            3)
                cat > /tmp/desktop_config.nix << 'EOF'
{ config, pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  
  environment.systemPackages = with pkgs; [
    xfce.thunar
    xfce.ristretto
    xfce.xfce4-terminal
  ];
}
EOF
                DESKTOP_SELECTED="Xfce"
                break
                ;;
            4)
                cat > /tmp/desktop_config.nix << 'EOF'
{ config, pkgs, ... }:

{
  # Sem desktop, apenas terminal
  services.getty.autologinUser = "$USERNAME";
}
EOF
                DESKTOP_SELECTED="None"
                break
                ;;
            5)
                echo "Instalação cancelada."
                exit 0
                ;;
            *)
                echo "Opção inválida!"
                sleep 1
                ;;
        esac
    done
}

# Configuração de bootloader
configure_bootloader() {
    print_status "Configurando bootloader..."
    
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        # Systemd-boot para UEFI
        cat > /tmp/bootloader_config.nix << EOF
{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
EOF
    else
        # GRUB para BIOS
        cat > /tmp/bootloader_config.nix << EOF
{ config, pkks, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "$INSTALL_DISK";
  boot.loader.grub.useOSProber = true;
}
EOF
    fi
}

# Pacotes básicos
add_base_packages() {
    cat > /tmp/packages_config.nix << 'EOF'
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    neofetch
  ];
}
EOF
}

# Mescla todas as configurações
merge_configurations() {
    print_status "Mesclando configurações..."
    
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    # Cria um novo arquivo de configuração
    cat > "$config_file" << 'EOF'
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

EOF
    
    # Adiciona configurações geradas
    if [ -f /tmp/bootloader_config.nix ]; then
        tail -n +3 /tmp/bootloader_config.nix | head -n -1 >> "$config_file"
    fi
    
    if [ -f /tmp/network_config.nix ]; then
        tail -n +3 /tmp/network_config.nix | head -n -1 >> "$config_file"
    fi
    
    if [ -f /tmp/user_config.nix ]; then
        tail -n +3 /tmp/user_config.nix | head -n -1 >> "$config_file"
    fi
    
    if [ -f /tmp/desktop_config.nix ]; then
        tail -n +3 /tmp/desktop_config.nix | head -n -1 >> "$config_file"
    fi
    
    if [ -f /tmp/packages_config.nix ]; then
        tail -n +3 /tmp/packages_config.nix | head -n -1 >> "$config_file"
    fi
    
    # Fecha o bloco
    echo "}" >> "$config_file"
    
    print_status "Configuração final gerada em $config_file"
}

# Instalação
install_system() {
    print_status "Iniciando instalação do NixOS..."
    
    if confirm "Deseja revisar a configuração antes da instalação?"; then
        vim /mnt/etc/nixos/configuration.nix
    fi
    
    print_status "Executando nixos-install..."
    nixos-install --no-root-passwd
    
    print_status "Instalação concluída!"
    print_warning "Lembre-se de remover a mídia de instalação antes de reiniciar"
    
    if confirm "Deseja reiniciar agora?"; then
        reboot
    fi
}

# Fluxo principal
main() {
    clear
    echo "=== Instalador Minimalista do NixOS ==="
    echo
    
    # Detecção inicial
    detect_system
    
    # Seleção de disco
    list_disks
    read -p "Digite o disco para instalação (ex: /dev/sda): " INSTALL_DISK
    
    if [ ! -b "$INSTALL_DISK" ]; then
        print_error "Disco $INSTALL_DISK não encontrado!"
        exit 1
    fi
    
    # Confirmação
    print_warning "ATENÇÃO: Todos os dados em $INSTALL_DISK serão apagados!"
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
    
    # Executa os passos
    partition_disk "$INSTALL_DISK"
    format_partitions
    mount_filesystems
    generate_base_config
    configure_users
    configure_network
    select_desktop
    configure_bootloader
    add_base_packages
    merge_configurations
    install_system
}

# Limpeza de arquivos temporários
cleanup() {
    rm -f /tmp/*_config.nix
}

# Tratamento de erros
trap cleanup EXIT

# Executa o main
main "$@"
