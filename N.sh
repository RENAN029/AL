#!/bin/bash
set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório para arquivos de estado
STATE_DIR="/tmp/nixos-installer-state"
mkdir -p "$STATE_DIR"

# Funções auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

# Verificar se estamos no instalador do NixOS
check_environment() {
    if [ ! -f /etc/os-release ] || ! grep -q "NixOS" /etc/os-release 2>/dev/null; then
        log_error "Este script deve ser executado no instalador do NixOS."
        exit 1
    fi
}

# Detectar hardware
detect_hardware() {
    log_info "Detectando hardware..."
    
    # Detectar modo de boot
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
        log_info "Modo de boot: UEFI"
    else
        BOOT_MODE="BIOS"
        log_info "Modo de boot: BIOS"
    fi
    
    # Listar discos disponíveis
    log_info "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "NAME"
    
    # Detectar WiFi
    if ip link show | grep -q "wl"; then
        HAS_WIFI=true
        log_info "WiFi detectado"
    else
        HAS_WIFI=false
        log_info "WiFi não detectado"
    fi
}

# Configurar rede
setup_network() {
    log_info "Configurando rede..."
    
    if $HAS_WIFI; then
        if confirm "Conectar a rede WiFi?"; then
            log_info "Iniciando nmtui para configuração WiFi..."
            nmtui
        fi
    fi
    
    # Testar conexão
    if ping -c 1 nixos.org >/dev/null 2>&1; then
        log_success "Conexão com internet estabelecida"
    else
        log_warn "Sem conexão com internet. Algumas funcionalidades podem não funcionar."
    fi
}

# Particionamento
partition_disk() {
    log_info "Selecionando disco para instalação..."
    
    # Listar discos
    echo -e "\nDiscos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -v "loop"
    
    read -p "Digite o nome do disco (ex: sda, nvme0n1): " DISK
    
    # Validar disco
    if [ ! -b "/dev/$DISK" ]; then
        log_error "Disco /dev/$DISK não encontrado!"
        exit 1
    fi
    
    DISK_PATH="/dev/$DISK"
    
    # Backup dos dados existentes
    if confirm "AVISO: Todos os dados em $DISK_PATH serão apagados. Continuar?"; then
        log_info "Particionando $DISK_PATH..."
        
        if [ "$BOOT_MODE" = "UEFI" ]; then
            partition_uefi
        else
            partition_bios
        fi
    else
        log_info "Instalação cancelada."
        exit 0
    fi
}

partition_uefi() {
    # Limpar tabela de partições
    wipefs -a "$DISK_PATH"
    
    # Criar partições GPT
    parted "$DISK_PATH" -- mklabel gpt
    parted "$DISK_PATH" -- mkpart ESP fat32 1MiB 512MiB
    parted "$DISK_PATH" -- set 1 esp on
    parted "$DISK_PATH" -- mkpart primary ext4 512MiB 100%
    
    # Formatar partições
    mkfs.fat -F 32 -n NIXBOOT "${DISK_PATH}1"
    mkfs.ext4 -L NIXROOT "${DISK_PATH}2"
    
    log_success "Partições UEFI criadas"
}

partition_bios() {
    # Limpar tabela de partições
    wipefs -a "$DISK_PATH"
    
    # Criar partições MBR
    parted "$DISK_PATH" -- mklabel msdos
    parted "$DISK_PATH" -- mkpart primary ext4 1MiB 512MiB
    parted "$DISK_PATH" -- set 1 boot on
    parted "$DISK_PATH" -- mkpart primary ext4 512MiB 100%
    
    # Formatar partições
    mkfs.ext4 -L NIXBOOT "${DISK_PATH}1"
    mkfs.ext4 -L NIXROOT "${DISK_PATH}2"
    
    log_success "Partições BIOS criadas"
}

# Montar partições
mount_partitions() {
    log_info "Montando partições..."
    
    mount /dev/disk/by-label/NIXROOT /mnt
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkdir -p /mnt/boot/efi
        mount /dev/disk/by-label/NIXBOOT /mnt/boot/efi
    else
        mkdir -p /mnt/boot
        mount /dev/disk/by-label/NIXBOOT /mnt/boot
    fi
    
    log_success "Partições montadas"
}

# Criar arquivo de swap
create_swap() {
    if confirm "Criar arquivo de swap (2GB)?"; then
        log_info "Criando arquivo de swap..."
        
        # 2GB swap file
        dd if=/dev/zero of=/mnt/.swapfile bs=1M count=2048
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
        
        log_success "Swap criado"
    fi
}

# Gerar configuração
generate_config() {
    log_info "Gerando configuração base..."
    
    nixos-generate-config --root /mnt
    
    # Copiar configuração para edição
    cp /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/configuration.nix.backup
    
    log_success "Configuração gerada"
}

# Selecionar ambiente desktop
select_desktop() {
    local config_file="/mnt/etc/nixos/configuration.nix"
    local desktop_packages=""
    local display_manager=""
    
    echo -e "\n${BLUE}=== Ambientes Desktop ===${NC}"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Xfce"
    echo "4) Cinnamon"
    echo "5) MATE"
    echo "6) Hyprland (Wayland compositor)"
    echo "7) Sway (Wayland compositor)"
    echo "8) Nenhum (somente console)"
    echo
    
    read -p "Selecione uma opção [1-8]: " choice
    
    case $choice in
        1)
            desktop_packages="pkgs.gnome.gnome-shell pkgs.gnome.gnome-terminal pkgs.gnome.gnome-control-center pkgs.gnome.gnome-tweaks"
            display_manager="gdm"
            DESKTOP_NAME="GNOME"
            ;;
        2)
            desktop_packages="pkgs.plasma5.plasma-desktop pkgs.konsole pkgs.dolphin"
            display_manager="sddm"
            DESKTOP_NAME="KDE Plasma"
            ;;
        3)
            desktop_packages="pkgs.xfce.xfce4"
            display_manager="lightdm"
            DESKTOP_NAME="Xfce"
            ;;
        4)
            desktop_packages="pkgs.cinnamon"
            display_manager="lightdm"
            DESKTOP_NAME="Cinnamon"
            ;;
        5)
            desktop_packages="pkgs.mate.mate-desktop"
            display_manager="lightdm"
            DESKTOP_NAME="MATE"
            ;;
        6)
            desktop_packages="pkgs.hyprland"
            display_manager=""
            DESKTOP_NAME="Hyprland"
            ;;
        7)
            desktop_packages="pkgs.sway"
            display_manager=""
            DESKTOP_NAME="Sway"
            ;;
        8)
            DESKTOP_NAME="Console"
            return
            ;;
        *)
            log_warn "Opção inválida, usando console apenas"
            DESKTOP_NAME="Console"
            return
            ;;
    esac
    
    # Adicionar pacotes ao arquivo de configuração
    sed -i '/environment.systemPackages = with pkgs; \[/a\'"  $desktop_packages" "$config_file"
    
    # Configurar display manager se necessário
    if [ -n "$display_manager" ]; then
        echo -e "\n  # Enable $DESKTOP_NAME display manager\n  services.$display_manager.enable = true;" >> "$config_file"
    fi
    
    # Habilitar X11/Wayland
    if [ "$choice" = "6" ] || [ "$choice" = "7" ]; then
        echo -e "\n  # Wayland configuration\n  services.xserver.enable = true;\n  services.xserver.displayManager.startx.enable = true;" >> "$config_file"
    elif [ "$choice" != "8" ]; then
        echo -e "\n  # X11 configuration\n  services.xserver.enable = true;\n  services.xserver.displayManager.lightdm.enable = true if using lightdm;\n  services.xserver.desktopManager.$DESKTOP_NAME.enable = true;" >> "$config_file"
    fi
    
    log_success "Ambiente $DESKTOP_NAME selecionado"
}

# Configurar usuário
setup_user() {
    log_info "Configurando usuário..."
    
    read -p "Nome de usuário: " USERNAME
    read -sp "Senha para $USERNAME: " PASSWORD
    echo
    
    # Adicionar configuração do usuário
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    cat >> "$config_file" << EOF

  # User configuration
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "$PASSWORD";
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
EOF
    
    log_success "Usuário $USERNAME configurado"
}

# Configurar localização
setup_localization() {
    log_info "Configurando localização..."
    
    read -p "Fuso horário (ex: America/Sao_Paulo, Europe/London): " TIMEZONE
    read -p "Layout de teclado (ex: us, br, fr): " KEYBOARD_LAYOUT
    
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    # Adicionar configuração de localização
    sed -i '/^}$/i\
  # Localization\
  time.timeZone = "'"$TIMEZONE"'";\
  i18n.defaultLocale = "en_US.UTF-8";\
  console.keyMap = "'"$KEYBOARD_LAYOUT"'";\
  services.xserver.xkb.layout = "'"$KEYBOARD_LAYOUT"'";' "$config_file"
    
    log_success "Localização configurada"
}

# Configurar rede no sistema instalado
setup_network_config() {
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    cat >> "$config_file" << EOF

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
EOF
    
    log_success "Configuração de rede adicionada"
}

# Configurar bootloader
setup_bootloader() {
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    if [ "$BOOT_MODE" = "UEFI" ]; then
        cat >> "$config_file" << EOF

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
EOF
    else
        cat >> "$config_file" << EOF

  # Bootloader (BIOS)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "$DISK_PATH";
  boot.loader.grub.useOSProber = true;
EOF
    fi
    
    log_success "Bootloader configurado"
}

# Configurar pacotes adicionais
setup_additional_packages() {
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    cat >> "$config_file" << EOF

  # Additional packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];
EOF
    
    log_success "Pacotes adicionais configurados"
}

# Instalar sistema
install_system() {
    log_info "Iniciando instalação do NixOS..."
    
    if confirm "Deseja prosseguir com a instalação?"; then
        log_info "Isso pode levar alguns minutos..."
        
        # Instalar NixOS
        nixos-install --no-root-passwd
        
        if [ $? -eq 0 ]; then
            log_success "Instalação concluída com sucesso!"
            
            if confirm "Deseja reiniciar o sistema agora?"; then
                log_info "Reiniciando..."
                reboot
            else
                log_info "Reinicialize manualmente quando estiver pronto."
            fi
        else
            log_error "Falha na instalação. Verifique os logs."
            exit 1
        fi
    else
        log_info "Instalação cancelada."
    fi
}

# Menu principal
main_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        Instalador NixOS Automatizado${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    check_environment
    detect_hardware
    
    echo
    if confirm "Iniciar instalação do NixOS?"; then
        setup_network
        partition_disk
        mount_partitions
        create_swap
        generate_config
        select_desktop
        setup_user
        setup_localization
        setup_network_config
        setup_bootloader
        setup_additional_packages
        install_system
    else
        log_info "Instalação cancelada."
        exit 0
    fi
}

# Executar menu principal
main_menu
