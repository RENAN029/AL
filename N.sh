#!/usr/bin/env bash

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se estamos no ambiente de instalação do NixOS
check_environment() {
    echo -e "${BLUE}Verificando ambiente...${NC}"
    
    if [ ! -f /run/current-system/nixos-version ] && [ ! -f /etc/NIXOS ]; then
        echo -e "${YELLOW}Aviso: Este script deve ser executado no ambiente live do NixOS${NC}"
        echo "Execute: sudo bash nixos-minimal-install.sh"
        read -p "Continuar mesmo assim? (s/N): " -n 1 resposta
        echo
        [[ "$resposta" =~ ^[Ss]$ ]] || exit 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Execute com sudo!${NC}"
        echo "Exemplo: sudo bash $0"
        exit 1
    fi
}

# Mostrar informações do sistema
show_info() {
    echo -e "${GREEN}=== NixOS Minimal Installer ===${NC}"
    echo "Detectando hardware..."
    
    # Detectar UEFI/Legacy
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
        echo "Modo de boot: ${GREEN}UEFI${NC}"
    else
        BOOT_MODE="BIOS"
        echo "Modo de boot: ${GREEN}BIOS (Legacy)${NC}"
    fi
    
    # Listar discos
    echo -e "\n${BLUE}Discos disponíveis:${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
}

# Particionamento automático
partition_disk() {
    echo -e "\n${BLUE}=== Particionamento ===${NC}"
    
    # Selecionar disco
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " DISK
    
    # Confirmar
    read -p "ATENÇÃO: Todos os dados em /dev/$DISK serão apagados! Continuar? (s/N): " -n 1 resposta
    echo
    [[ "$resposta" =~ ^[Ss]$ ]] || exit 1
    
    # Limpar partições existentes
    echo "Limpando partições existentes..."
    wipefs -a /dev/$DISK
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        echo "Criando partições GPT (UEFI)..."
        parted /dev/$DISK -- mklabel gpt
        parted /dev/$DISK -- mkpart ESP fat32 1MiB 512MiB
        parted /dev/$DISK -- set 1 esp on
        parted /dev/$DISK -- mkpart primary 512MiB 100%
    else
        echo "Criando partições MBR (BIOS)..."
        parted /dev/$DISK -- mklabel msdos
        parted /dev/$DISK -- mkpart primary 1MiB 512MiB
        parted /dev/$DISK -- set 1 boot on
        parted /dev/$DISK -- mkpart primary 512MiB 100%
    fi
    
    # Formatar partições
    echo "Formatando partições..."
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkfs.fat -F 32 -n NIXBOOT /dev/${DISK}1
        mkfs.ext4 -L NIXROOT /dev/${DISK}2
        BOOT_PART="/dev/${DISK}1"
        ROOT_PART="/dev/${DISK}2"
    else
        mkfs.ext4 -L NIXBOOT /dev/${DISK}1
        mkfs.ext4 -L NIXROOT /dev/${DISK}2
        BOOT_PART="/dev/${DISK}1"
        ROOT_PART="/dev/${DISK}2"
    fi
    
    # Montar
    echo "Montando partições..."
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

# Criar arquivo swap
create_swap() {
    echo -e "\n${BLUE}=== Configurar swap ===${NC}"
    read -p "Criar arquivo swap de 2GB? (S/n): " resposta
    if [[ ! "$resposta" =~ ^[Nn]$ ]]; then
        echo "Criando swap file..."
        dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=2097152
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
    fi
}

# Configurar rede
configure_network() {
    echo -e "\n${BLUE}=== Configuração de rede ===${NC}"
    
    if command -v nmtui &> /dev/null; then
        read -p "Configurar rede via nmtui? (S/n): " resposta
        if [[ ! "$resposta" =~ ^[Nn]$ ]]; then
            nmtui
        fi
    else
        echo "Usando wpa_supplicant para WiFi..."
        read -p "SSID do WiFi: " SSID
        read -sp "Senha: " PASSWORD
        echo
        wpa_passphrase "$SSID" "$PASSWORD" > /etc/wpa_supplicant.conf
        systemctl restart wpa_supplicant
    fi
    
    # Testar conexão
    echo "Testando conexão..."
    if ping -c 3 nixos.org &> /dev/null; then
        echo -e "${GREEN}Conexão OK${NC}"
    else
        echo -e "${YELLOW}Aviso: Sem conexão com a internet${NC}"
        read -p "Continuar mesmo assim? (s/N): " resposta
        [[ "$resposta" =~ ^[Ss]$ ]] || exit 1
    fi
}

# Selecionar ambiente desktop
select_desktop() {
    echo -e "\n${BLUE}=== Ambiente Desktop ===${NC}"
    
    echo "1) GNOME (completo)"
    echo "2) Plasma (KDE)"
    echo "3) XFCE (leve)"
    echo "4) Sway (Wayland)"
    echo "5) Hyprland (Wayland moderno)"
    echo "6) Nenhum (apenas terminal)"
    read -p "Selecione (1-6): " DESKTOP_CHOICE
    
    case $DESKTOP_CHOICE in
        1) 
            DESKTOP_PKGS="gnome.gnome-core"
            DISPLAY_MANAGER="gdm"
            DESKTOP_NAME="GNOME"
            ;;
        2) 
            DESKTOP_PKGS="plasma5.plasma-desktop"
            DISPLAY_MANAGER="sddm"
            DESKTOP_NAME="KDE Plasma"
            ;;
        3) 
            DESKTOP_PKGS="xfce.xfce"
            DISPLAY_MANAGER="lightdm"
            DESKTOP_NAME="XFCE"
            ;;
        4) 
            DESKTOP_PKGS="sway"
            DISPLAY_MANAGER="none" # Sway usa swayidle
            DESKTOP_NAME="Sway"
            ;;
        5) 
            DESKTOP_PKGS="hyprland"
            DISPLAY_MANAGER="none"
            DESKTOP_NAME="Hyprland"
            ;;
        *) 
            DESKTOP_PKGS=""
            DISPLAY_MANAGER="none"
            DESKTOP_NAME="Nenhum"
            ;;
    esac
    
    echo -e "Selecionado: ${GREEN}$DESKTOP_NAME${NC}"
}

# Configurar usuário
configure_user() {
    echo -e "\n${BLUE}=== Configuração do usuário ===${NC}"
    
    read -p "Nome de usuário: " USERNAME
    read -sp "Senha para $USERNAME: " USERPASS
    echo
    read -sp "Confirmar senha: " USERPASS2
    echo
    
    if [ "$USERPASS" != "$USERPASS2" ]; then
        echo -e "${RED}Senhas não conferem!${NC}"
        exit 1
    fi
    
    read -p "Nome do hostname do sistema: " HOSTNAME
}

# Gerar configuração NixOS
generate_config() {
    echo -e "\n${BLUE}=== Gerando configuração NixOS ===${NC}"
    
    # Gerar configuração base
    nixos-generate-config --root /mnt
    
    CONFIG_FILE="/mnt/etc/nixos/configuration.nix"
    HARDWARE_FILE="/mnt/etc/nixos/hardware-configuration.nix"
    
    # Backup da configuração original
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    
    # Criar nova configuração
    cat > "$CONFIG_FILE" << EOF
{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
    ];

  # Kernel mais recente (opcional)
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "$HOSTNAME";
  networking.networkmanager.enable = true;

  # Timezone e locale
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";
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

  # Console keymap
  console.keyMap = "br-abnt2";

  # Usuário
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "$USERPASS";
  };

  # Permitir sudo para wheel
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Pacotes do sistema
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    htop
EOF

    # Adicionar pacotes do desktop se selecionado
    if [ -n "$DESKTOP_PKGS" ]; then
        cat >> "$CONFIG_FILE" << EOF
    # Desktop environment
    $DESKTOP_PKGS
EOF
        
        # Adicionar configurações específicas do desktop
        case $DESKTOP_CHOICE in
            1) # GNOME
                cat >> "$CONFIG_FILE" << EOF

  # GNOME
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.core-utilities.enable = false; # Desabilita apps padrão do GNOME
EOF
                ;;
            2) # KDE
                cat >> "$CONFIG_FILE" << EOF

  # KDE Plasma
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
EOF
                ;;
            3) # XFCE
                cat >> "$CONFIG_FILE" << EOF

  # XFCE
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
EOF
                ;;
            4) # Sway
                cat >> "$CONFIG_FILE" << EOF

  # Sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
EOF
                ;;
            5) # Hyprland
                cat >> "$CONFIG_FILE" << EOF

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
EOF
                ;;
        esac
    fi

    # Fechar a configuração
    cat >> "$CONFIG_FILE" << EOF

  # Som
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Printer
  services.printing.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  # SSH (opcional)
  # services.openssh.enable = true;

  # Garbage collection automático
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "23.11"; # Não mude isso
}
EOF

    # Atualizar hardware-configuration.nix para usar labels
    sed -i 's|device = ".*";|device = "/dev/disk/by-label/NIXROOT";|' "$HARDWARE_FILE"
    sed -i 's|device = ".*";|device = "/dev/disk/by-label/NIXBOOT";|' "$HARDWARE_FILE" 2>/dev/null || true
    
    echo -e "${GREEN}Configuração gerada em $CONFIG_FILE${NC}"
    
    # Mostrar preview
    read -p "Ver preview da configuração? (S/n): " resposta
    if [[ ! "$resposta" =~ ^[Nn]$ ]]; then
        less "$CONFIG_FILE"
    fi
}

# Instalar sistema
install_system() {
    echo -e "\n${BLUE}=== Instalando NixOS ===${NC}"
    echo "Isso pode demorar alguns minutos..."
    
    nixos-install --no-root-password
    
    echo -e "${GREEN}Instalação concluída!${NC}"
    
    # Configurar senha do usuário
    echo "Configurando senha para $USERNAME..."
    arch-chroot /mnt passwd "$USERNAME"
    
    echo -e "\n${GREEN}=== Instalação Finalizada ===${NC}"
    echo "1. Execute: umount -R /mnt"
    echo "2. Execute: reboot"
    echo "3. Remova a mídia de instalação"
    echo "4. Faça login com usuário: $USERNAME"
    
    if [ -n "$DESKTOP_PKGS" ]; then
        echo "5. Desktop: $DESKTOP_NAME"
    fi
}

# Menu principal
main_menu() {
    clear
    echo -e "${GREEN}=== NixOS Minimal Installer ===${NC}"
    
    PS3="Selecione uma opção: "
    options=(
        "1. Mostrar informações do sistema"
        "2. Configurar rede"
        "3. Particionar disco"
        "4. Criar swap"
        "5. Selecionar ambiente desktop"
        "6. Configurar usuário"
        "7. Gerar configuração e instalar"
        "8. Instalar apenas (após configuração)"
        "9. Sair"
    )
    
    select opt in "${options[@]}"; do
        case $REPLY in
            1) show_info ;;
            2) configure_network ;;
            3) partition_disk ;;
            4) create_swap ;;
            5) select_desktop ;;
            6) configure_user ;;
            7) 
                if [ ! -d /mnt/etc/nixos ]; then
                    generate_config
                fi
                install_system 
                ;;
            8) install_system ;;
            9) exit 0 ;;
            *) echo "Opção inválida" ;;
        esac
        echo
        read -p "Pressione Enter para continuar..."
        clear
        echo -e "${GREEN}=== NixOS Minimal Installer ===${NC}"
        for option in "${options[@]}"; do
            echo "$option"
        done
    done
}

# Execução direta (modo não-interativo)
if [[ "$1" == "--auto" ]]; then
    check_environment
    show_info
    configure_network
    partition_disk
    create_swap
    select_desktop
    configure_user
    generate_config
    install_system
else
    check_environment
    main_menu
fi
