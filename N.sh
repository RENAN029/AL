#!/usr/bin/env bash

# nixos-minimal-install.sh - Instalador minimalista do NixOS (versão root)
# Autor: Baseado no guia oficial do NixOS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de utilidade
print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║               Instalador NixOS Minimalista               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${CYAN}»${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-N}"
    
    if [[ "$default" == "Y" ]]; then
        read -p "$prompt (S/n): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        read -p "$prompt (s/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[SsYy]$ ]]
    fi
}

# Função para verificar se está no live environment
check_live_environment() {
    if [ ! -f /etc/NIXOS ] || [ ! -d /run/current-system ]; then
        print_error "Este script deve ser executado do live media do NixOS!"
        print_info "Por favor, boote do USB/DVD de instalação do NixOS."
        exit 1
    fi
    
    if [ "$(whoami)" != "nixos" ] && [ "$(whoami)" != "root" ]; then
        print_error "Execute como usuário 'nixos' ou 'root' do live environment"
        exit 1
    fi
    
    print_success "Live environment detectado"
}

# Função para detectar UEFI
detect_uefi() {
    if [ -d /sys/firmware/efi ]; then
        return 0
    else
        return 1
    fi
}

# Função para testar conexão com internet
test_internet() {
    print_info "Testando conexão com internet..."
    
    if ping -c 1 -W 2 google.com &> /dev/null || \
       ping -c 1 -W 2 8.8.8.8 &> /dev/null || \
       curl -s --connect-timeout 3 https://nixos.org > /dev/null; then
        print_success "Conexão com internet detectada"
        return 0
    else
        print_warning "Sem conexão com internet detectada"
        return 1
    fi
}

# Função para configurar WiFi
configure_wifi() {
    print_step "Configuração de WiFi"
    
    # Verificar se wifi está disponível
    if ! ip link show | grep -q "wl"; then
        print_warning "Nenhuma interface WiFi detectada"
        return 1
    fi
    
    if ! command -v nmtui &> /dev/null; then
        print_info "Instalando NetworkManager para nmtui..."
        nix-env -iA nixos.networkmanager
    fi
    
    print_info "Iniciando nmtui para configuração WiFi..."
    nmtui
    
    if test_internet; then
        print_success "WiFi configurado com sucesso"
        return 0
    else
        print_warning "WiFi configurado, mas sem internet"
        return 1
    fi
}

# Função para selecionar disco
select_disk() {
    print_step "Seleção de disco"
    
    echo -e "\n${CYAN}Discos disponíveis:${NC}"
    echo "----------------------------------------------------------------"
    lsblk -d -o NAME,SIZE,MODEL,TYPE,TRAN | grep -E '^(NAME|disk|nvme)'
    echo "----------------------------------------------------------------"
    
    while true; do
        read -p "Digite o disco para instalação (ex: /dev/sda, /dev/nvme0n1): " disk
        
        # Limpar entrada
        disk=$(echo "$disk" | tr -d '[:space:]')
        
        # Verificar se o disco existe
        if [ ! -b "$disk" ]; then
            print_error "Disco '$disk' não encontrado!"
            continue
        fi
        
        # Verificar se não é um dispositivo de leitura apenas (CD/DVD)
        if [[ "$(lsblk -d -o RO $disk | tail -1)" == "1" ]]; then
            print_error "Disco '$disk' é somente leitura!"
            continue
        fi
        
        # Mostrar informações do disco selecionado
        echo -e "\n${YELLOW}Disco selecionado:${NC}"
        lsblk "$disk" -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
        
        if confirm "Confirmar uso deste disco?" "N"; then
            echo "$disk"
            return 0
        fi
    done
}

# Função para particionamento UEFI
partition_uefi() {
    local disk="$1"
    
    print_step "Particionamento UEFI/GPT"
    
    # Limpar tabela de partições
    print_info "Limpando tabela de partições..."
    wipefs -a "$disk"
    
    # Criar tabela GPT
    print_info "Criando tabela GPT..."
    parted "$disk" --script mklabel gpt
    
    # Criar partição EFI (512MB)
    print_info "Criando partição EFI (512MB)..."
    parted "$disk" --script mkpart primary fat32 1MiB 513MiB
    parted "$disk" --script set 1 esp on
    
    # Criar partição swap (opcional)
    if confirm "Criar partição swap dedicada?" "N"; then
        read -p "Tamanho da swap (ex: 4G, 8192M): " swap_size
        swap_size=${swap_size:-4G}
        
        print_info "Criando partição swap ($swap_size)..."
        parted "$disk" --script mkpart primary linux-swap 513MiB ${swap_size}
        SWAP_PART="${disk}2"
        ROOT_PART_NUM="3"
    else
        ROOT_PART_NUM="2"
    fi
    
    # Criar partição raiz (restante do espaço)
    print_info "Criando partição raiz..."
    if [ -n "$SWAP_PART" ]; then
        parted "$disk" --script mkpart primary ext4 ${swap_size} 100%
    else
        parted "$disk" --script mkpart primary ext4 513MiB 100%
    fi
    
    # Formatar partições
    print_info "Formatando partições..."
    
    # EFI
    mkfs.fat -F 32 -n NIXBOOT "${disk}1"
    
    # Swap se criada
    if [ -n "$SWAP_PART" ]; then
        mkswap -L NIXSWAP "$SWAP_PART"
        swapon "$SWAP_PART"
    fi
    
    # Raiz
    mkfs.ext4 -L NIXROOT "${disk}${ROOT_PART_NUM}"
    
    print_success "Particionamento UEFI concluído"
    
    # Retornar números das partições
    if [ -n "$SWAP_PART" ]; then
        echo "1 ${disk}${ROOT_PART_NUM} ${disk}2"
    else
        echo "1 ${disk}${ROOT_PART_NUM}"
    fi
}

# Função para particionamento BIOS
partition_bios() {
    local disk="$1"
    
    print_step "Particionamento BIOS/MBR"
    
    # Limpar tabela de partições
    print_info "Limpando tabela de partições..."
    wipefs -a "$disk"
    
    # Criar tabela MBR
    print_info "Criando tabela MBR..."
    parted "$disk" --script mklabel msdos
    
    # Criar partição boot (500MB)
    print_info "Criando partição boot (500MB)..."
    parted "$disk" --script mkpart primary ext4 1MiB 501MiB
    parted "$disk" --script set 1 boot on
    
    # Criar partição swap (opcional)
    if confirm "Criar partição swap dedicada?" "N"; then
        read -p "Tamanho da swap (ex: 4G, 8192M): " swap_size
        swap_size=${swap_size:-4G}
        
        print_info "Criando partição swap ($swap_size)..."
        parted "$disk" --script mkpart primary linux-swap 501MiB ${swap_size}
        SWAP_PART="${disk}2"
        ROOT_PART_NUM="3"
    else
        ROOT_PART_NUM="2"
    fi
    
    # Criar partição raiz (restante do espaço)
    print_info "Criando partição raiz..."
    if [ -n "$SWAP_PART" ]; then
        parted "$disk" --script mkpart primary ext4 ${swap_size} 100%
    else
        parted "$disk" --script mkpart primary ext4 501MiB 100%
    fi
    
    # Formatar partições
    print_info "Formatando partições..."
    
    # Boot
    mkfs.ext4 -L NIXBOOT "${disk}1"
    
    # Swap se criada
    if [ -n "$SWAP_PART" ]; then
        mkswap -L NIXSWAP "$SWAP_PART"
        swapon "$SWAP_PART"
    fi
    
    # Raiz
    mkfs.ext4 -L NIXROOT "${disk}${ROOT_PART_NUM}"
    
    print_success "Particionamento BIOS concluído"
    
    # Retornar números das partições
    if [ -n "$SWAP_PART" ]; then
        echo "1 ${disk}${ROOT_PART_NUM} ${disk}2"
    else
        echo "1 ${disk}${ROOT_PART_NUM}"
    fi
}

# Função para montar partições
mount_partitions() {
    local disk="$1"
    local uefi="$2"
    local root_part="$3"
    local swap_part="$4"
    
    print_step "Montando partições"
    
    # Montar raiz
    print_info "Montando partição raiz..."
    mount "$root_part" /mnt
    
    # Criar diretórios necessários
    mkdir -p /mnt/boot /mnt/home
    
    # Montar boot/EFI
    if [ "$uefi" = true ]; then
        print_info "Montando partição EFI..."
        mount "${disk}1" /mnt/boot
    else
        print_info "Montando partição boot..."
        mount "${disk}1" /mnt/boot
    fi
    
    # Ativar swap se existir
    if [ -n "$swap_part" ]; then
        print_info "Ativando swap..."
        swapon "$swap_part"
    fi
    
    print_success "Partições montadas"
}

# Função para selecionar ambiente desktop
select_desktop_environment() {
    print_step "Seleção de ambiente desktop"
    
    echo -e "\n${CYAN}Ambientes Desktop Disponíveis:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1)  GNOME               ┆ 6)  Cinnamon"
    echo "2)  KDE Plasma          ┆ 7)  Mate"
    echo "3)  Xfce                ┆ 8)  Enlightenment"
    echo "4)  LXQt                ┆ 9)  Sway (Wayland)"
    echo "5)  Hyprland (Wayland)  ┆ 10) Nenhum (apenas terminal)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    read -p "Selecione uma opção (1-10): " choice
    
    case $choice in
        1)  # GNOME
            echo "GNOME"
            cat << 'EOF'
  # GNOME Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.core-utilities.enable = false;
  environment.gnome.excludePackages = with pkgs.gnome; [
    cheese epiphany geary gnome-music gnome-terminal
  ];
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];
EOF
            ;;
        2)  # KDE Plasma
            echo "Plasma"
            cat << 'EOF'
  # KDE Plasma Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.defaultSession = "plasmawayland";
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    elisa
    gwenview
    okular
    oxygen
  ];
  environment.systemPackages = with pkgs; [
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.kate
  ];
EOF
            ;;
        3)  # Xfce
            echo "Xfce"
            cat << 'EOF'
  # Xfce Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.defaultSession = "xfce";
  environment.systemPackages = with pkgs; [
    xfce.xfce4-terminal
    xfce.thunar
    xfce.ristretto
  ];
EOF
            ;;
        4)  # LXQt
            echo "LXQt"
            cat << 'EOF'
  # LXQt Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable = true;
  services.xserver.displayManager.defaultSession = "lxqt";
EOF
            ;;
        5)  # Hyprland
            echo "Hyprland"
            cat << 'EOF'
  # Hyprland (Wayland Compositor)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.defaultSession = "hyprland";
  environment.systemPackages = with pkgs; [
    waybar
    rofi-wayland
    kitty
    foot
  ];
EOF
            ;;
        6)  # Cinnamon
            echo "Cinnamon"
            cat << 'EOF'
  # Cinnamon Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;
  services.xserver.displayManager.defaultSession = "cinnamon";
EOF
            ;;
        7)  # Mate
            echo "Mate"
            cat << 'EOF'
  # Mate Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.mate.enable = true;
  services.xserver.displayManager.defaultSession = "mate";
EOF
            ;;
        8)  # Enlightenment
            echo "Enlightenment"
            cat << 'EOF'
  # Enlightenment Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.enlightenment.enable = true;
  services.xserver.displayManager.defaultSession = "enlightenment";
EOF
            ;;
        9)  # Sway
            echo "Sway"
            cat << 'EOF'
  # Sway (Wayland Compositor)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  security.polkit.enable = true;
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  environment.systemPackages = with pkgs; [
    waybar
    rofi-wayland
    alacritty
    swaylock
    swayidle
  ];
EOF
            ;;
        10|*) # Nenhum/terminal
            echo "Terminal"
            cat << 'EOF'
  # Apenas terminal
  # Nenhum ambiente desktop instalado
EOF
            ;;
    esac
}

# Função para configurar usuário
configure_user() {
    print_step "Configuração de usuário"
    
    read -p "Nome de usuário principal: " username
    username=$(echo "$username" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    if [ -z "$username" ]; then
        username="nixuser"
    fi
    
    read -sp "Senha para $username: " userpass
    echo
    if [ -z "$userpass" ]; then
        userpass="nixos"
        print_warning "Usando senha padrão: nixos"
    fi
    
    read -p "Nome completo (opcional): " fullname
    
    echo "$username"
    echo "$userpass"
    echo "$fullname"
}

# Função para configurar sistema
configure_system() {
    local hostname="$1"
    local username="$2"
    local userpass="$3"
    local fullname="$4"
    local uefi="$5"
    local disk="$6"
    local desktop_config="$7"
    local desktop_name="$8"
    
    print_step "Configuração do sistema"
    
    # Gerar configuração inicial
    print_info "Gerando configuração inicial..."
    nixos-generate-config --root /mnt
    
    # Arquivos de configuração
    CONFIG_FILE="/mnt/etc/nixos/configuration.nix"
    HARDWARE_FILE="/mnt/etc/nixos/hardware-configuration.nix"
    
    # Criar backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Gerar hash da senha
    print_info "Gerando hash da senha..."
    PASSWD_HASH=$(mkpasswd -m sha-512 "$userpass")
    
    # Determinar timezone automaticamente
    if command -v timedatectl &> /dev/null; then
        TIMEZONE=$(timedatectl show --property=Timezone --value)
    else
        TIMEZONE="America/Sao_Paulo"
    fi
    
    # Criar nova configuração
    cat > "$CONFIG_FILE" << EOF
# Generated by NixOS Minimal Installer
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Configurações básicas do sistema
  system.stateVersion = "$(nixos-version | cut -d. -f1-2)";
  
  # Bootloader
  boot.loader = {
EOF
    
    if [ "$uefi" = true ]; then
        cat >> "$CONFIG_FILE" << EOF
    systemd-boot = {
      enable = true;
      editor = false;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
EOF
    else
        cat >> "$CONFIG_FILE" << EOF
    grub = {
      enable = true;
      device = "$disk";
      useOSProber = true;
    };
EOF
    fi
    
    cat >> "$CONFIG_FILE" << EOF
  };
  
  # Network
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
  
  # Time e locale
  time.timeZone = "$TIMEZONE";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Console
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    packages = with pkgs; [ terminus_font ];
  };
  
  # Usuários
  users.users."$username" = {
    isNormalUser = true;
    description = "${fullname:-$username}";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "storage" ];
    initialHashedPassword = "$PASSWD_HASH";
  };
  
  # Sudo
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  
  # Pacotes essenciais
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    btop
    ncdu
    p7zip
    unzip
    file
    tree
    lsof
    pciutils
    usbutils
  ];
  
  # Serviços
  services = {
    openssh.enable = true;
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
    };
  };
  
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
  
  # Fontes
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
EOF
    
    # Adicionar configuração do desktop se não for "Terminal"
    if [ "$desktop_name" != "Terminal" ] && [ -n "$desktop_config" ]; then
        cat >> "$CONFIG_FILE" << EOF
  
  # Desktop Environment: $desktop_name
$desktop_config
EOF
    fi
    
    # Adicionar opções adicionais
    cat >> "$CONFIG_FILE" << EOF
  
  # Otimizações
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  
  # Kernel
  boot.kernelParams = [ "mitigations=off" ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
EOF
    
    print_success "Configuração do sistema gerada"
    
    # Mostrar preview
    if confirm "Deseja visualizar a configuração gerada?" "N"; then
        less "$CONFIG_FILE"
    fi
}

# Função para instalar sistema
install_system() {
    print_step "Instalação do sistema"
    
    print_info "Isso pode levar vários minutos..."
    
    # Instalar NixOS
    if nixos-install --no-root-passwd 2>&1 | tee /tmp/nixos-install.log; then
        print_success "Instalação concluída com sucesso!"
        
        # Verificar se houve erros
        if grep -q "error:" /tmp/nixos-install.log; then
            print_warning "Foram detectados erros durante a instalação"
            if confirm "Deseja ver o log de erros?" "N"; then
                grep -i error /tmp/nixos-install.log | head -20
            fi
        fi
        
        return 0
    else
        print_error "Falha na instalação"
        if confirm "Deseja ver o log completo?" "N"; then
            cat /tmp/nixos-install.log
        fi
        return 1
    fi
}

# Função de instalação guiada
guided_installation() {
    print_header
    
    # Verificar ambiente
    check_live_environment
    
    # Testar internet
    if ! test_internet; then
        print_warning "Conexão com internet necessária para instalação"
        if confirm "Configurar WiFi agora?" "Y"; then
            configure_wifi
        fi
    fi
    
    # Configurações básicas
    print_step "Configurações iniciais"
    
    read -p "Nome do host (hostname): " hostname
    hostname=$(echo "$hostname" | tr -d '[:space:]')
    if [ -z "$hostname" ]; then
        hostname="nixos"
    fi
    
    # Detectar UEFI/BIOS
    if detect_uefi; then
        uefi=true
        print_info "Modo UEFI detectado"
    else
        uefi=false
        print_info "Modo BIOS legado detectado"
    fi
    
    # Selecionar disco
    disk=$(select_disk)
    
    # Confirmar destruição de dados
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ATENÇÃO! PERIGO!                      ║${NC}"
    echo -e "${RED}║  Todos os dados em $disk serão PERDIDOS permanentemente! ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    
    if ! confirm "Continuar com a instalação?" "N"; then
        print_info "Instalação cancelada pelo usuário"
        exit 0
    fi
    
    # Particionamento
    if [ "$uefi" = true ]; then
        partition_info=$(partition_uefi "$disk")
    else
        partition_info=$(partition_bios "$disk")
    fi
    
    # Extrair informações das partições
    read -r boot_part_num root_part swap_part <<< "$partition_info"
    root_part="${disk}${root_part_num}"
    if [ -n "$swap_part" ]; then
        swap_part="${disk}${swap_part}"
    fi
    
    # Montar partições
    mount_partitions "$disk" "$uefi" "$root_part" "$swap_part"
    
    # Configurar usuário
    user_info=$(configure_user)
    read -r username userpass fullname <<< "$user_info"
    
    # Selecionar desktop
    desktop_info=$(select_desktop_environment)
    desktop_name=$(echo "$desktop_info" | head -1)
    desktop_config=$(echo "$desktop_info" | tail -n +2)
    
    # Configurar sistema
    configure_system "$hostname" "$username" "$userpass" "$fullname" "$uefi" "$disk" "$desktop_config" "$desktop_name"
    
    # Instalar sistema
    if install_system; then
        print_success "╔══════════════════════════════════════════════════════════╗"
        print_success "║           Instalação do NixOS concluída!                ║"
        print_success "╚══════════════════════════════════════════════════════════╝"
        
        echo -e "\n${GREEN}Informações da instalação:${NC}"
        echo "  Hostname: $hostname"
        echo "  Usuário: $username"
        echo "  Desktop: $desktop_name"
        echo "  Disco: $disk"
        echo -e "\n${YELLOW}Próximos passos:${NC}"
        echo "  1. Remova a mídia de instalação"
        echo "  2. Reinicie o sistema"
        echo "  3. Faça login com usuário '$username'"
        echo "  4. Execute 'sudo passwd' para alterar a senha se necessário"
        
        if confirm "Reiniciar agora?" "Y"; then
            print_info "Reiniciando em 5 segundos..."
            sleep 5
            reboot
        fi
    else
        print_error "Instalação falhou!"
        if confirm "Deseja tentar novamente?" "N"; then
            guided_installation
        fi
    fi
}

# Função de instalação rápida
quick_installation() {
    print_header
    
    print_info "Instalação rápida do NixOS"
    print_warning "Usando configurações padrão"
    
    # Configurações padrão
    hostname="nixos"
    username="nixuser"
    userpass="nixos"
    
    # Detectar UEFI
    if detect_uefi; then
        uefi=true
        disk="/dev/sda"
    else
        uefi=false
        disk="/dev/sda"
    fi
    
    # Verificar disco
    if [ ! -b "$disk" ]; then
        print_error "Disco padrão $disk não encontrado"
        disk=$(lsblk -d -o NAME | grep -E '^(sda|nvme0n1|vda)' | head -1)
        disk="/dev/$disk"
        print_info "Usando $disk"
    fi
    
    echo -e "\n${YELLOW}Configuração rápida:${NC}"
    echo "  Hostname: $hostname"
    echo "  Usuário: $username"
    echo "  Senha: $userpass"
    echo "  Disco: $disk"
    echo "  UEFI: $uefi"
    
    if ! confirm "Continuar com instalação rápida?" "N"; then
        return
    fi
    
    # Particionamento rápido
    print_info "Particionando $disk..."
    wipefs -a "$disk"
    
    if [ "$uefi" = true ]; then
        parted "$disk" --script mklabel gpt
        parted "$disk" --script mkpart primary fat32 1MiB 513MiB
        parted "$disk" --script set 1 esp on
        parted "$disk" --script mkpart primary ext4 513MiB 100%
        mkfs.fat -F 32 -n NIXBOOT "${disk}1"
        mkfs.ext4 -L NIXROOT "${disk}2"
        mount "${disk}2" /mnt
        mkdir -p /mnt/boot
        mount "${disk}1" /mnt/boot
    else
        parted "$disk" --script mklabel msdos
        parted "$disk" --script mkpart primary ext4 1MiB 501MiB
        parted "$disk" --script set 1 boot on
        parted "$disk" --script mkpart primary ext4 501MiB 100%
        mkfs.ext4 -L NIXBOOT "${disk}1"
        mkfs.ext4 -L NIXROOT "${disk}2"
        mount "${disk}2" /mnt
        mkdir -p /mnt/boot
        mount "${disk}1" /mnt/boot
    fi
    
    # Configuração mínima
    nixos-generate-config --root /mnt
    
    PASSWD_HASH=$(mkpasswd -m sha-512 "$userpass")
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  system.stateVersion = "$(nixos-version | cut -d. -f1-2)";
  
  boot.loader = {
EOF
    
    if [ "$uefi" = true ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
EOF
    else
        cat >> /mnt/etc/nixos/configuration.nix << EOF
    grub = {
      enable = true;
      device = "$disk";
    };
EOF
    fi
    
    cat >> /mnt/etc/nixos/configuration.nix << EOF
  };
  
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
  
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  
  users.users."$username" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialHashedPassword = "$PASSWD_HASH";
  };
  
  security.sudo.wheelNeedsPassword = false;
  
  environment.systemPackages = with pkgs; [
    vim wget curl git htop
  ];
}
EOF
    
    # Instalar
    print_info "Instalando NixOS..."
    if nixos-install --no-root-passwd; then
        print_success "Instalação rápida concluída!"
        echo -e "\n${GREEN}Login:${NC} $username"
        echo "${GREEN}Senha:${NC} $userpass"
    else
        print_error "Instalação rápida falhou!"
    fi
}

# Menu principal
main_menu() {
    while true; do
        print_header
        
        echo -e "${CYAN}Menu Principal:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "1) Instalação Guiada (Recomendado)"
        echo "2) Instalação Rápida"
        echo "3) Configurar WiFi"
        echo "4) Testar Conexão com Internet"
        echo "5) Sair do Instalador"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        read -p "Selecione uma opção (1-5): " choice
        
        case $choice in
            1)
                guided_installation
                break
                ;;
            2)
                quick_installation
                if confirm "Voltar ao menu?" "Y"; then
                    continue
                else
                    break
                fi
                ;;
            3)
                configure_wifi
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                test_internet
                read -p "Pressione Enter para continuar..."
                ;;
            5)
                print_info "Saindo do instalador..."
                exit 0
                ;;
            *)
                print_error "Opção inválida!"
                sleep 1
                ;;
        esac
    done
}

# Inicialização
print_header
print_info "NixOS Minimal Installer v1.0"
print_info "Execute este script apenas do live environment do NixOS"

# Verificar se está rodando como root/nixos
if [ "$(whoami)" != "nixos" ] && [ "$(whoami)" != "root" ]; then
    print_error "Este script deve ser executado como usuário 'nixos' ou 'root'"
    print_info "No live environment do NixOS, use:"
    print_info "  sudo su -"
    print_info "  ./nixos-installer.sh"
    exit 1
fi

# Iniciar menu principal
main_menu
