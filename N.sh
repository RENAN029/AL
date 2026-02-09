#!/usr/bin/env bash
set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de utilidade
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar se está rodando no NixOS Live
check_environment() {
    if [ ! -f /etc/os-release ] || ! grep -q "NixOS" /etc/os-release; then
        print_error "Este script deve ser executado no NixOS Live USB"
        exit 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        print_error "Por favor, execute como root (sudo)"
        exit 1
    fi
}

# Menu principal
main_menu() {
    clear
    cat << EOF
${BLUE}
╔══════════════════════════════════════╗
║      NixOS Minimal Installer         ║
║      (Inspirado no archinstall)      ║
╚══════════════════════════════════════╝
${NC}
EOF
    
    PS3="Selecione uma opção: "
    options=(
        "Instalação Completa (Guiada)"
        "Configurar Disco e Partições"
        "Selecionar Desktop Environment"
        "Instalar NixOS"
        "Sair"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "Instalação Completa (Guiada)")
                guided_installation
                ;;
            "Configurar Disco e Partições")
                disk_partition_menu
                ;;
            "Selecionar Desktop Environment")
                desktop_environment_menu
                ;;
            "Instalar NixOS")
                install_nixos
                ;;
            "Sair")
                exit 0
                ;;
            *)
                print_error "Opção inválida"
                ;;
        esac
    done
}

# Detectar discos disponíveis
detect_disks() {
    print_info "Detectando discos disponíveis..."
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -E '^sd|^nvme|^vd'
}

# Menu de particionamento
disk_partition_menu() {
    clear
    print_info "Discos disponíveis:"
    detect_disks
    
    read -p "Digite o disco para instalação (ex: /dev/sda, /dev/nvme0n1): " DISK
    
    if [ ! -b "$DISK" ]; then
        print_error "Disco $DISK não encontrado!"
        return 1
    fi
    
    print_warning "ATENÇÃO: Todos os dados em $DISK serão apagados!"
    read -p "Continuar? (s/N): " confirm
    [[ "$confirm" != "s" && "$confirm" != "S" ]] && return
    
    # Detectar se é UEFI ou BIOS
    if [ -d /sys/firmware/efi ]; then
        print_info "Sistema UEFI detectado"
        partition_uefi "$DISK"
    else
        print_info "Sistema BIOS detectado"
        partition_bios "$DISK"
    fi
}

# Particionamento UEFI
partition_uefi() {
    local disk="$1"
    
    print_info "Criando partições GPT para UEFI..."
    
    # Limpar tabela de partições
    wipefs -a "$disk"
    
    # Criar partições usando parted
    parted "$disk" --script mklabel gpt
    parted "$disk" --script mkpart primary fat32 1MiB 512MiB
    parted "$disk" --script set 1 esp on
    parted "$disk" --script mkpart primary ext4 512MiB 100%
    
    # Formatar partições
    mkfs.fat -F 32 "${disk}1"
    mkfs.ext4 -F "${disk}2"
    
    # Criar labels
    fatlabel "${disk}1" NIXBOOT
    e2label "${disk}2" NIXROOT
    
    # Montar partições
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    print_success "Partições UEFI criadas e montadas!"
}

# Particionamento BIOS
partition_bios() {
    local disk="$1"
    
    print_info "Criando partições MBR para BIOS..."
    
    # Limpar tabela de partições
    wipefs -a "$disk"
    
    # Criar partições usando parted
    parted "$disk" --script mklabel msdos
    parted "$disk" --script mkpart primary 1MiB 512MiB
    parted "$disk" --script set 1 boot on
    parted "$disk" --script mkpart primary 512MiB 100%
    
    # Formatar partições
    mkfs.ext4 -F "${disk}1"
    mkfs.ext4 -F "${disk}2"
    
    # Criar labels
    e2label "${disk}1" NIXBOOT
    e2label "${disk}2" NIXROOT
    
    # Montar partições
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    print_success "Partições BIOS criadas e montadas!"
}

# Criar arquivo swap
create_swap() {
    read -p "Criar arquivo swap de 2GB? (s/N): " create_swap
    
    if [[ "$create_swap" == "s" || "$create_swap" == "S" ]]; then
        print_info "Criando arquivo swap..."
        dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=2097152
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
        print_success "Arquivo swap criado!"
    fi
}

# Menu de Desktop Environments
desktop_environment_menu() {
    clear
    print_info "Seleção de Desktop Environment"
    
    PS3="Selecione o Desktop Environment: "
    options=(
        "GNOME"
        "KDE Plasma"
        "XFCE"
        "Hyprland (Wayland Compositor)"
        "i3wm"
        "Nenhum (Apenas terminal)"
        "Voltar"
    )
    
    select de_choice in "${options[@]}"; do
        case $de_choice in
            "GNOME")
                DESKTOP_ENV="gnome"
                desktop_packages="gnome.gnome-shell gnome.gnome-terminal gnome.nautilus"
                display_manager="gdm"
                ;;
            "KDE Plasma")
                DESKTOP_ENV="plasma"
                desktop_packages="plasma.plasma-desktop plasma.konsole dolphin"
                display_manager="sddm"
                ;;
            "XFCE")
                DESKTOP_ENV="xfce"
                desktop_packages="xfce.xfce4 xfce.xfce4-terminal thunar"
                display_manager="lightdm"
                ;;
            "Hyprland (Wayland Compositor)")
                DESKTOP_ENV="hyprland"
                desktop_packages="hyprland waybar rofi alacritty"
                display_manager="none"
                ;;
            "i3wm")
                DESKTOP_ENV="i3"
                desktop_packages="i3 i3status dmenu alacritty"
                display_manager="none"
                ;;
            "Nenhum (Apenas terminal)")
                DESKTOP_ENV="none"
                desktop_packages=""
                display_manager="none"
                ;;
            "Voltar")
                return
                ;;
            *)
                print_error "Opção inválida"
                continue
                ;;
        esac
        print_success "Desktop Environment selecionado: $de_choice"
        break
    done
}

# Configurar rede
configure_network() {
    print_info "Configurando rede..."
    
    if systemctl is-active --quiet NetworkManager; then
        print_info "NetworkManager ativo. Use nmtui para configurar Wi-Fi."
        read -p "Configurar Wi-Fi agora? (s/N): " config_wifi
        
        if [[ "$config_wifi" == "s" || "$config_wifi" == "S" ]]; then
            nmtui
        fi
    else
        print_warning "NetworkManager não está ativo. Configurando wpa_supplicant..."
        read -p "SSID da rede Wi-Fi: " wifi_ssid
        read -sp "Senha da rede Wi-Fi: " wifi_pass
        echo
        
        wpa_passphrase "$wifi_ssid" "$wifi_pass" > /tmp/wpa.conf
        wpa_supplicant -B -i wlan0 -c /tmp/wpa.conf
        dhcpcd wlan0
    fi
    
    # Testar conexão
    if ping -c 3 google.com &>/dev/null; then
        print_success "Conexão com internet estabelecida!"
    else
        print_warning "Sem conexão com internet. Alguns pacotes podem não ser instalados."
    fi
}

# Configurar usuário
configure_user() {
    print_info "Configurando usuário..."
    
    read -p "Nome do usuário principal: " username
    read -sp "Senha para $username: " userpass
    echo
    read -sp "Confirmar senha: " userpass_confirm
    echo
    
    if [ "$userpass" != "$userpass_confirm" ]; then
        print_error "Senhas não coincidem!"
        return 1
    fi
    
    USERNAME="$username"
    USERPASS="$userpass"
    
    # Senha de root
    read -sp "Senha para root (deixe em branco para mesma senha do usuário): " rootpass
    echo
    ROOTPASS="${rootpass:-$userpass}"
    
    print_success "Usuário configurado!"
}

# Gerar configuração NixOS
generate_configuration() {
    print_info "Gerando configuração do NixOS..."
    
    # Gerar configuração inicial
    nixos-generate-config --root /mnt
    
    # Backup do arquivo original
    cp /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/configuration.nix.backup
    
    # Criar nova configuração
    cat > /tmp/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Timezone e locale
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
  };

  # Console keymap
  console.keyMap = "br-abnt2";

  # Usuário
  users.users.${USERNAME} = {
    isNormalUser = true;
    description = "${USERNAME}";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "${USERPASS}";
  };

  # Senha de root
  users.users.root.initialPassword = "${ROOTPASS}";

  # Permitir sudo para wheel
  security.sudo.extraRules = [
    {
      users = [ "${USERNAME}" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ]
    }
  ];

  # Sistema de arquivos
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  # Swap file
  swapDevices = [ { device = "/.swapfile"; } ];

  # Pacotes do sistema
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];

  # Serviços
  services = {
    # Display Manager
    $([ "$display_manager" != "none" ] && echo "$display_manager.enable = true;")
    
    # Desktop Environment
    $([ "$DESKTOP_ENV" = "gnome" ] && echo "gnome.gnome-keyring.enable = true;")
    $([ "$DESKTOP_ENV" = "plasma" ] && echo "plasma5.enable = true;")
    $([ "$DESKTOP_ENV" = "xfce" ] && echo "xfce.enable = true;")
    $([ "$DESKTOP_ENV" = "hyprland" ] && echo "programs.hyprland.enable = true;")
    $([ "$DESKTOP_ENV" = "i3" ] && echo "services.xserver.windowManager.i3.enable = true;")
  };

  # X11/Wayland
  $([ "$DESKTOP_ENV" != "none" ] && [ "$DESKTOP_ENV" != "hyprland" ] && echo '
  services.xserver = {
    enable = true;
    layout = "br";
    xkbVariant = "abnt2";
    '$([ "$DESKTOP_ENV" = "gnome" ] && echo "desktopManager.gnome.enable = true;")'
    '$([ "$DESKTOP_ENV" = "plasma" ] && echo "desktopManager.plasma5.enable = true;")'
    '$([ "$DESKTOP_ENV" = "xfce" ] && echo "desktopManager.xfce.enable = true;")'
    '$([ "$DESKTOP_ENV" = "i3" ] && echo "windowManager.i3.enable = true;")'
  };')

  # Pacotes do Desktop
  environment.systemPackages = with pkgs; environment.systemPackages ++ [
    $([ -n "$desktop_packages" ] && echo "$desktop_packages")
  ];

  # State Version - NÃO ALTERE ISSO
  system.stateVersion = "$(nixos-version | cut -d. -f1-2)";
}
EOF
    
    # Copiar configuração
    cp /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
    
    print_success "Configuração gerada!"
}

# Instalação do NixOS
install_nixos() {
    if ! mountpoint -q /mnt; then
        print_error "Nenhum sistema de arquivos montado em /mnt!"
        print_info "Execute 'Configurar Disco e Partições' primeiro"
        return 1
    fi
    
    print_warning "Iniciando instalação do NixOS..."
    print_warning "Esta operação pode demorar vários minutos."
    
    read -p "Continuar? (s/N): " confirm
    [[ "$confirm" != "s" && "$confirm" != "S" ]] && return
    
    # Configurar usuário se não configurado
    if [ -z "${USERNAME:-}" ]; then
        configure_user || return 1
    fi
    
    # Gerar configuração
    generate_configuration
    
    # Instalar NixOS
    print_info "Instalando NixOS (isso pode demorar)..."
    nixos-install --no-root-passwd
    
    if [ $? -eq 0 ]; then
        print_success "NixOS instalado com sucesso!"
        
        cat << EOF

╔══════════════════════════════════════════════════════════╗
║                   INSTALAÇÃO COMPLETA                    ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  • NixOS foi instalado com sucesso!                     ║
║  • Usuário: ${USERNAME}                                ║
║  • Desktop: ${DESKTOP_ENV:-none}                       ║
║                                                          ║
║  Para reiniciar no sistema instalado:                   ║
║    1. Desmonte as partições:                            ║
║       umount -R /mnt                                    ║
║    2. Reinicie:                                         ║
║       reboot                                            ║
║                                                          ║
║  Após reiniciar, faça login com seu usuário e senha.    ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    else
        print_error "Falha na instalação do NixOS"
        return 1
    fi
}

# Instalação guiada completa
guided_installation() {
    clear
    print_info "Iniciando instalação guiada do NixOS"
    echo
    
    # Passo 1: Configurar disco
    disk_partition_menu || return
    
    # Passo 2: Criar swap
    create_swap
    
    # Passo 3: Configurar rede
    configure_network
    
    # Passo 4: Selecionar DE
    desktop_environment_menu
    
    # Passo 5: Configurar usuário
    configure_user || return
    
    # Passo 6: Instalar
    install_nixos
}

# Função principal
main() {
    check_environment
    
    # Verificar dependências
    for cmd in lsblk parted mkfs.fat mkfs.ext4 mount nixos-generate-config nixos-install; do
        if ! command -v $cmd &>/dev/null; then
            print_error "Comando $cmd não encontrado!"
            exit 1
        fi
    done
    
    # Iniciar menu
    main_menu
}

# Executar
trap 'print_error "Script interrompido!"; exit 1' INT
main
