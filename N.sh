#!/usr/bin/env bash

# nixos-installer.sh - Instalador minimalista do NixOS
# Autor: Baseado no guia oficial do NixOS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de utilidade
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
    read -p "$1 (s/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[SsYy]$ ]]
}

# Função para detectar UEFI
detect_uefi() {
    if [ -d /sys/firmware/efi ]; then
        return 0
    else
        return 1
    fi
}

# Função para particionamento
partition_disk() {
    local disk="$1"
    local use_uefi="$2"
    
    print_info "Particionando $disk..."
    
    if [ "$use_uefi" = true ]; then
        print_info "Usando esquema GPT para UEFI"
        # Limpar tabela de partições existente
        sudo sgdisk -Z "$disk"
        # Criar partição EFI (500M)
        sudo sgdisk -n 1:2048:+500M -t 1:ef00 -c 1:"NIXBOOT" "$disk"
        # Criar partição raiz (restante do espaço)
        sudo sgdisk -n 2:0:0 -t 2:8304 -c 2:"NIXROOT" "$disk"
    else
        print_info "Usando esquema MBR para BIOS legado"
        # Limpar tabela de partições existente
        sudo dd if=/dev/zero of="$disk" bs=512 count=1 conv=notrunc
        # Criar partição boot (500M)
        echo -e "n\np\n1\n2048\n+500M\nn\np\n2\n\n\nw\n" | sudo fdisk "$disk"
        # Criar sistema de arquivos e rótulos
        sudo mkfs.ext4 -L NIXBOOT "${disk}1"
    fi
    
    # Formatar partições
    if [ "$use_uefi" = true ]; then
        sudo mkfs.fat -F 32 -n NIXBOOT "${disk}1"
        sudo mkfs.ext4 -L NIXROOT "${disk}2"
    else
        sudo mkfs.ext4 -L NIXROOT "${disk}2"
    fi
    
    print_success "Disco particionado com sucesso"
}

# Função para montar partições
mount_partitions() {
    local disk="$1"
    local use_uefi="$2"
    
    print_info "Montando partições..."
    
    if [ "$use_uefi" = true ]; then
        sudo mount /dev/disk/by-label/NIXROOT /mnt
        sudo mkdir -p /mnt/boot
        sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    else
        sudo mount /dev/disk/by-label/NIXROOT /mnt
        sudo mkdir -p /mnt/boot
        sudo mount "${disk}1" /mnt/boot
    fi
    
    print_success "Partições montadas"
}

# Função para criar swap file
create_swap() {
    local swap_size="$1"
    
    print_info "Criando arquivo swap de ${swap_size}GB..."
    
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count="$swap_size" status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
    
    print_success "Swap file criado"
}

# Função para configurar rede WiFi
configure_wifi() {
    print_info "Configurando WiFi..."
    
    read -p "SSID da rede WiFi: " wifi_ssid
    read -sp "Senha da rede WiFi: " wifi_pass
    echo
    
    if [ -n "$wifi_ssid" ] && [ -n "$wifi_pass" ]; then
        wpa_passphrase "$wifi_ssid" "$wifi_pass" | sudo tee /etc/wpa_supplicant.conf > /dev/null
        sudo systemctl restart wpa_supplicant
        print_success "WiFi configurado"
    else
        print_warning "WiFi não configurado"
    fi
}

# Função para selecionar ambiente desktop
select_desktop() {
    echo -e "\n${BLUE}=== Ambientes Desktop Disponíveis ===${NC}"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Xfce"
    echo "4) LXQt"
    echo "5) Cinnamon"
    echo "6) Mate"
    echo "7) Enlightenment"
    echo "8) Sem ambiente desktop (apenas terminal)"
    echo
    
    read -p "Selecione uma opção (1-8): " desktop_choice
    
    case $desktop_choice in
        1)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.gdm.enable = true;"
            echo "services.xserver.desktopManager.gnome.enable = true;"
            echo "environment.systemPackages = with pkgs; [ gnome.gnome-tweaks ];"
            ;;
        2)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.sddm.enable = true;"
            echo "services.xserver.desktopManager.plasma5.enable = true;"
            ;;
        3)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.lightdm.enable = true;"
            echo "services.xserver.desktopManager.xfce.enable = true;"
            ;;
        4)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.lightdm.enable = true;"
            echo "services.xserver.desktopManager.lxqt.enable = true;"
            ;;
        5)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.lightdm.enable = true;"
            echo "services.xserver.desktopManager.cinnamon.enable = true;"
            ;;
        6)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.lightdm.enable = true;"
            echo "services.xserver.desktopManager.mate.enable = true;"
            ;;
        7)
            echo "services.xserver.enable = true;"
            echo "services.xserver.displayManager.lightdm.enable = true;"
            echo "services.xserver.desktopManager.enlightenment.enable = true;"
            ;;
        8)
            echo "# Sem ambiente desktop"
            ;;
        *)
            echo "# Sem ambiente desktop"
            ;;
    esac
}

# Função para gerar configuração
generate_configuration() {
    local hostname="$1"
    local username="$2"
    local use_uefi="$3"
    local disk="$4"
    
    print_info "Gerando configuração do NixOS..."
    
    # Gerar configuração básica
    sudo nixos-generate-config --root /mnt
    
    # Configuração principal
    config_file="/mnt/etc/nixos/configuration.nix"
    hardware_file="/mnt/etc/nixos/hardware-configuration.nix"
    
    # Atualizar hardware-configuration.nix para usar labels
    if [ "$use_uefi" = true ]; then
        sudo sed -i 's|device = ".*/by-uuid/[^"]*"|device = "/dev/disk/by-label/NIXROOT"|' "$hardware_file"
        sudo sed -i 's|device = ".*/by-uuid/[^"]*"|device = "/dev/disk/by-label/NIXBOOT"|' "$hardware_file"
    fi
    
    # Criar backup da configuração original
    sudo cp "$config_file" "${config_file}.backup"
    
    # Construir nova configuração
    cat > /tmp/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Configuração do bootloader
  boot.loader.systemd-boot.enable = $use_uefi;
  boot.loader.efi.canTouchEfiVariables = $use_uefi;
  boot.loader.grub.enable = !$use_uefi;
  boot.loader.grub.device = "${disk}";
  
  # Swap file
  swapDevices = [ { device = "/.swapfile"; } ];
  
  # Networking
  networking.hostName = "${hostname}";
  networking.networkmanager.enable = true;
  
  # Timezone e localização
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONY = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };
  
  # Console
  console.keyMap = "br-abnt2";
  
  # Usuário
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "changeme";
  };
  
  # Sudo
  security.sudo.wheelNeedsPassword = false;
  
  # Pacotes do sistema
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];
  
  # Serviços
  services.openssh.enable = true;
  
  # Estado do sistema
  system.stateVersion = "$(nixos-version | cut -d. -f1-2)";
}
EOF
    
    # Adicionar configuração do desktop se selecionado
    echo -e "\n${BLUE}=== Configuração do Ambiente Desktop ===${NC}"
    desktop_config=$(select_desktop)
    
    # Adicionar configuração do desktop ao arquivo
    if [ -n "$desktop_config" ] && [ "$desktop_config" != "# Sem ambiente desktop" ]; then
        cat >> /tmp/configuration.nix << EOF
  
  # Configuração do Desktop
  $desktop_config
EOF
    fi
    
    # Substituir arquivo de configuração
    sudo mv /tmp/configuration.nix "$config_file"
    
    print_success "Configuração gerada"
}

# Função principal de instalação
main_installation() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}       Instalador Minimalista NixOS     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Verificar se está rodando do live media
    if [ ! -f /etc/NIXOS ]; then
        print_error "Este script deve ser executado do live media do NixOS"
        exit 1
    fi
    
    # Configuração básica
    read -p "Nome do host: " hostname
    read -p "Nome de usuário: " username
    
    # Detectar se é UEFI
    if detect_uefi; then
        use_uefi=true
        print_info "Sistema UEFI detectado"
    else
        use_uefi=false
        print_info "Sistema BIOS legado detectado"
    fi
    
    # Listar discos disponíveis
    print_info "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL
    echo
    
    read -p "Disco para instalação (ex: /dev/sda): " install_disk
    
    if [ ! -b "$install_disk" ]; then
        print_error "Disco $install_disk não encontrado"
        exit 1
    fi
    
    # Confirmar destruição de dados
    print_warning "ATENÇÃO: Todos os dados em $install_disk serão destruídos!"
    if ! confirm "Continuar?"; then
        print_info "Instalação cancelada"
        exit 0
    fi
    
    # Configurar WiFi
    if confirm "Configurar WiFi?"; then
        configure_wifi
    fi
    
    # Particionar disco
    partition_disk "$install_disk" "$use_uefi"
    
    # Montar partições
    mount_partitions "$install_disk" "$use_uefi"
    
    # Criar swap
    if confirm "Criar arquivo swap? (recomendado)"; then
        read -p "Tamanho do swap em GB (padrão: 2): " swap_size
        swap_size=${swap_size:-2}
        create_swap "$swap_size"
    fi
    
    # Gerar configuração
    generate_configuration "$hostname" "$username" "$use_uefi" "$install_disk"
    
    # Mostrar configuração
    if confirm "Deseja visualizar a configuração gerada?"; then
        sudo cat /mnt/etc/nixos/configuration.nix
        echo
    fi
    
    # Instalar NixOS
    print_info "Iniciando instalação do NixOS..."
    if confirm "Continuar com a instalação?"; then
        sudo nixos-install --no-root-passwd
        
        # Definir senha do usuário
        print_info "Definindo senha para o usuário $username..."
        sudo passwd "$username"
        
        print_success "Instalação completada com sucesso!"
        print_info "Reinicie o sistema e remova a mídia de instalação"
        
        if confirm "Reiniciar agora?"; then
            sudo reboot
        fi
    else
        print_info "Instalação cancelada"
    fi
}

# Função para instalação expressa
express_installation() {
    clear
    echo -e "${BLUE}=== Instalação Expressa NixOS ===${NC}"
    
    # Configurações padrão
    hostname="nixos"
    username="user"
    
    # Detectar UEFI
    if detect_uefi; then
        use_uefi=true
        bootloader="systemd-boot"
    else
        use_uefi=false
        bootloader="GRUB"
    fi
    
    # Usar primeiro disco não removível
    install_disk=$(lsblk -d -o NAME,ROTA,TYPE | grep -E 'disk.*1' | head -1 | awk '{print "/dev/"$1}')
    
    if [ -z "$install_disk" ]; then
        install_disk="/dev/sda"
    fi
    
    print_info "Configuração automática:"
    echo "  Hostname: $hostname"
    echo "  Usuário: $username"
    echo "  Bootloader: $bootloader"
    echo "  Disco: $install_disk"
    echo
    
    if ! confirm "Continuar com instalação expressa?"; then
        return
    fi
    
    # Particionar e instalar
    partition_disk "$install_disk" "$use_uefi"
    mount_partitions "$install_disk" "$use_uefi"
    create_swap 2
    
    # Gerar configuração mínima
    sudo nixos-generate-config --root /mnt
    
    # Configuração mínima
    config_file="/mnt/etc/nixos/configuration.nix"
    sudo cp "$config_file" "${config_file}.backup"
    
    cat > /tmp/express_config.nix << EOF
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.systemd-boot.enable = $use_uefi;
  boot.loader.efi.canTouchEfiVariables = $use_uefi;
  boot.loader.grub.enable = !$use_uefi;
  boot.loader.grub.device = "$install_disk";
  
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
  
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  
  users.users.$username = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };
  
  environment.systemPackages = with pkgs; [ vim wget git ];
  system.stateVersion = "$(nixos-version | cut -d. -f1-2)";
}
EOF
    
    sudo mv /tmp/express_config.nix "$config_file"
    
    # Instalar
    sudo nixos-install --no-root-passwd
    
    print_success "Instalação expressa completada!"
    print_info "Usuário: $username, Senha: nixos"
}

# Menu principal
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}       Instalador Minimalista NixOS     ${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo
        echo "1) Instalação Guiada (Recomendado)"
        echo "2) Instalação Expressa"
        echo "3) Configurar WiFi"
        echo "4) Sair"
        echo
        
        read -p "Selecione uma opção: " choice
        
        case $choice in
            1)
                main_installation
                break
                ;;
            2)
                express_installation
                break
                ;;
            3)
                configure_wifi
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                print_info "Saindo..."
                exit 0
                ;;
            *)
                print_error "Opção inválida"
                sleep 1
                ;;
        esac
    done
}

# Verificar se é root
if [ "$EUID" -eq 0 ]; then
    print_warning "Não execute este script como root!"
    print_info "Execute como usuário normal (nixos)"
    exit 1
fi

# Iniciar menu principal
main_menu
