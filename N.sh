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

select_language() {
    clear
    echo "=== IDIOMA DO SISTEMA ==="
    echo "1) Português do Brasil (pt_BR.UTF-8)"
    echo "2) English US (en_US.UTF-8)"
    while true; do
        read -p "Opção: " lang_opcao
        case $lang_opcao in
            1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang"; break ;;
            2) echo "en_US.UTF-8" > "$STATE_DIR/lang"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_keyboard() {
    clear
    echo "=== LAYOUT DO TECLADO ==="
    echo "1) br (ABNT2 - Português Brasil)"
    echo "2) us (English US)"
    while true; do
        read -p "Opção: " kb_opcao
        case $kb_opcao in
            1) echo "br" > "$STATE_DIR/keyboard"; break ;;
            2) echo "us" > "$STATE_DIR/keyboard"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_timezone() {
    clear
    echo "=== FUSO HORÁRIO ==="
    echo "1) America/Sao_Paulo (Brasil)"
    echo "2) America/New_York (EUA)"
    while true; do
        read -p "Opção: " tz_opcao
        case $tz_opcao in
            1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone"; break ;;
            2) echo "America/New_York" > "$STATE_DIR/timezone"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_device_type() {
    clear
    echo "=== TIPO DE DISPOSITIVO ==="
    echo "1) Desktop (foco em desempenho máximo)"
    echo "2) Laptop/Notebook (foco em economia de energia)"
    while true; do
        read -p "Opção: " device_opcao
        case $device_opcao in
            1) echo "desktop" > "$STATE_DIR/device_type"; break ;;
            2) echo "laptop" > "$STATE_DIR/device_type"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_swap_size() {
    clear
    echo "=== TAMANHO DO SWAP ==="
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap"
    while true; do
        read -p "Opção: " swap_opcao
        case $swap_opcao in
            1) echo "2" > "$STATE_DIR/swap"; break ;;
            2) echo "4" > "$STATE_DIR/swap"; break ;;
            3) echo "8" > "$STATE_DIR/swap"; break ;;
            4) echo "0" > "$STATE_DIR/swap"; break ;;
            *) echo "Opção inválida. Escolha 1-4." ;;
        esac
    done
}

select_filesystem() {
    clear
    echo "=== SISTEMA DE ARQUIVOS ==="
    echo "1) ext4 (simples e estável)"
    echo "2) btrfs (com snapshots e compressão)"
    while true; do
        read -p "Opção: " fs_opcao
        case $fs_opcao in
            1) echo "ext4" > "$STATE_DIR/filesystem"; break ;;
            2) echo "btrfs" > "$STATE_DIR/filesystem"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_bootloader() {
    clear
    echo "=== BOOTLOADER ==="
    echo "1) systemd-boot (recomendado para UEFI)"
    echo "2) GRUB (compatível com BIOS e UEFI)"
    while true; do
        read -p "Opção: " boot_opcao
        case $boot_opcao in
            1) echo "systemd-boot" > "$STATE_DIR/bootloader"; break ;;
            2) echo "grub" > "$STATE_DIR/bootloader"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_desktop() {
    clear
    echo "=== AMBIENTE DESKTOP ==="
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) Nenhum (apenas terminal)"
    while true; do
        read -p "Opção: " de_opcao
        case $de_opcao in
            1) echo "cosmic" > "$STATE_DIR/desktop"; break ;;
            2) echo "gnome" > "$STATE_DIR/desktop"; break ;;
            3) echo "plasma" > "$STATE_DIR/desktop"; break ;;
            4) echo "none" > "$STATE_DIR/desktop"; break ;;
            *) echo "Opção inválida. Escolha 1-4." ;;
        esac
    done
}

select_bluetooth() {
    clear
    echo "=== BLUETOOTH ==="
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    clear
    echo "=== IMPRESSÃO (CUPS) ==="
    if confirm "Habilitar suporte a impressão?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_encryption() {
    clear
    echo "=== CRIPTOGRAFIA DE DISCO ==="
    if confirm "Criptografar o disco (LUKS)?"; then
        echo "yes" > "$STATE_DIR/encryption"
    else
        echo "no" > "$STATE_DIR/encryption"
    fi
}

select_gpu_driver() {
    clear
    echo "=== DRIVERS DE VÍDEO ==="
    echo "1) Intel/AMD (drivers open-source padrão)"
    echo "2) NVIDIA (drivers proprietários)"
    while true; do
        read -p "Opção: " gpu_opcao
        case $gpu_opcao in
            1) echo "intel-amd" > "$STATE_DIR/gpu_driver"; break ;;
            2) echo "nvidia" > "$STATE_DIR/gpu_driver"; break ;;
            *) echo "Opção inválida. Escolha 1 ou 2." ;;
        esac
    done
}

select_flakes() {
    clear
    echo "=== NIX FLAKES ==="
    if confirm "Habilitar flakes (recomendado)?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
}

detect_disk() {
    clear
    echo "=== SELEÇÃO DE DISCO ==="
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    
    while true; do
        read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
        if [ -b "/dev/$disk_name" ]; then
            echo "/dev/$disk_name" > "$STATE_DIR/disk"
            break
        else
            echo "Disco /dev/$disk_name não encontrado. Tente novamente."
        fi
    done
}

check_existing_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    
    if [ -n "$(lsblk -no NAME "$disk" | tail -n +2)" ]; then
        clear
        echo "=== AVISO: PARTIÇÕES EXISTENTES ==="
        echo "O disco $disk já possui partições:"
        lsblk "$disk"
        echo
        echo "Você precisa remover todas as partições manualmente."
        echo "Pressione Enter para abrir o cfdisk e remover as partições."
        read
        
        sudo cfdisk "$disk"
        
        # Verificar se ainda existem partições
        if [ -n "$(lsblk -no NAME "$disk" | tail -n +2)" ]; then
            echo "Ainda existem partições. Remova todas antes de continuar."
            exit 1
        fi
    fi
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    clear
    echo "=== PARTICIONANDO $disk ==="
    
    check_existing_partitions
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel gpt
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 esp on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
        
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f ${disk}2 -L NIXROOT
        else
            sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
        fi
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel msdos
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 boot on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.ext4 -F ${disk}1 -L NIXBOOT
        
        if [ "$fs" = "btrfs" ]; then
            sudo mkfs.btrfs -f ${disk}2 -L NIXROOT
        else
            sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
        fi
    fi
}

setup_encryption() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Configurando criptografia LUKS..."
    sudo cryptsetup luksFormat ${disk}2
    sudo cryptsetup open ${disk}2 cryptroot
    
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        sudo mkfs.btrfs /dev/mapper/cryptroot
        echo "/dev/mapper/cryptroot" > "$STATE_DIR/root_device"
    else
        sudo mkfs.ext4 /dev/mapper/cryptroot
        echo "/dev/mapper/cryptroot" > "$STATE_DIR/root_device"
    fi
}

setup_btrfs_subvolumes() {
    local root_dev
    
    if [ "$(cat "$STATE_DIR/encryption")" = "yes" ]; then
        root_dev=$(cat "$STATE_DIR/root_device")
    else
        root_dev="/dev/disk/by-label/NIXROOT"
    fi
    
    echo "Criando subvolumes btrfs..."
    
    sudo mount $root_dev /mnt
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    
    sudo umount /mnt
    
    sudo mount -o compress=zstd,subvol=@ $root_dev /mnt
    sudo mkdir -p /mnt/{home,nix}
    sudo mount -o compress=zstd,subvol=@home $root_dev /mnt/home
    sudo mount -o compress=zstd,noatime,subvol=@nix $root_dev /mnt/nix
}

mount_partitions() {
    local encryption=$(cat "$STATE_DIR/encryption")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    # Montar partição root
    if [ "$encryption" = "yes" ]; then
        if [ ! -e /dev/mapper/cryptroot ]; then
            setup_encryption
        fi
        sudo mount /dev/mapper/cryptroot /mnt
    else
        if [ "$fs" = "btrfs" ] && [ ! -d /mnt/home ]; then
            setup_btrfs_subvolumes
        else
            sudo mount /dev/disk/by-label/NIXROOT /mnt
        fi
    fi
    
    # Montar partição boot
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    
    if [ "$swap_size" = "0" ]; then
        echo "Nenhum swap será criado."
        return
    fi
    
    echo "Criando arquivo swap de ${swap_size}G..."
    
    # Criar arquivo de swap com fallocate (mais rápido e confiável)
    sudo fallocate -l ${swap_size}G /mnt/.swapfile
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    
    # Não ativar o swap agora para evitar o erro "invalid argument"
    # O swap será ativado pelo NixOS durante a instalação
    echo "Arquivo swap criado com sucesso em /mnt/.swapfile"
}

get_user_info() {
    clear
    echo "=== INFORMAÇÕES DO USUÁRIO ==="
    
    while true; do
        read -p "Nome do usuário: " username
        if [ -n "$username" ]; then
            echo "$username" > "$STATE_DIR/username"
            break
        else
            echo "Nome de usuário não pode ser vazio."
        fi
    done
    
    while true; do
        read -s -p "Senha do usuário: " userpass
        echo
        read -s -p "Confirme a senha: " userpass2
        echo
        
        if [ "$userpass" = "$userpass2" ] && [ -n "$userpass" ]; then
            # Verificar se mkpasswd está disponível
            if command -v mkpasswd >/dev/null 2>&1; then
                local pass_hash=$(mkpasswd -m sha-512 "$userpass")
            else
                # Fallback para openssl se mkpasswd não estiver disponível
                local pass_hash=$(openssl passwd -6 "$userpass")
            fi
            echo "$pass_hash" > "$STATE_DIR/pass_hash"
            break
        elif [ -z "$userpass" ]; then
            echo "Senha não pode ser vazia."
        else
            echo "Senhas não conferem. Tente novamente."
        fi
    done
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat "$STATE_DIR/lang")"
    echo "Teclado: $(cat "$STATE_DIR/keyboard")"
    echo "Fuso horário: $(cat "$STATE_DIR/timezone")"
    echo "Tipo de dispositivo: $(cat "$STATE_DIR/device_type")"
    
    local swap=$(cat "$STATE_DIR/swap")
    if [ "$swap" = "0" ]; then
        echo "Swap: Sem swap"
    else
        echo "Swap: ${swap}GB"
    fi
    
    echo "Sistema de arquivos: $(cat "$STATE_DIR/filesystem")"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "Criptografia: $(cat "$STATE_DIR/encryption")"
    echo "Driver GPU: $(cat "$STATE_DIR/gpu_driver")"
    echo "Flakes: $(cat "$STATE_DIR/flakes")"
    echo "Disco: $(cat "$STATE_DIR/disk")"
    echo "Usuário: $(cat "$STATE_DIR/username")"
    echo "================================="
    echo
    
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

generate_config() {
    clear
    echo "=== GERANDO CONFIGURAÇÃO ==="
    
    sudo nixos-generate-config --root /mnt
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local timezone=$(cat "$STATE_DIR/timezone")
    local device_type=$(cat "$STATE_DIR/device_type")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local encryption=$(cat "$STATE_DIR/encryption")
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local flakes=$(cat "$STATE_DIR/flakes")
    local username=$(cat "$STATE_DIR/username")
    local pass_hash=$(cat "$STATE_DIR/pass_hash")
    local disk=$(cat "$STATE_DIR/disk")
    local swap_size=$(cat "$STATE_DIR/swap")
    
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    sudo tee "$config_file" > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  $([ "$bootloader" = "systemd-boot" ] && echo 'boot.loader.systemd-boot.enable = true;' || echo 'boot.loader.grub.enable = true; boot.loader.grub.device = "'$disk'";')
  
  # Locale
  i18n.defaultLocale = "$lang";
  i18n.extraLocaleSettings = {
    LC_TIME = "$lang";
    LC_MONETARY = "$lang";
    LC_PAPER = "$lang";
    LC_MEASUREMENT = "$lang";
  };
  
  console.keyMap = "$keyboard";
  
  # X11/Keyboard (para compatibilidade)
  services.xserver.enable = true;
  services.xserver.xkb.layout = "$keyboard";
  
  # Wayland (padrão)
  services.xserver.displayManager.gdm.enable = $([ "$desktop" = "gnome" ] && echo "true" || echo "false");
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Network
  networking.networkmanager.enable = true;
  networking.hostName = "nixos";
  
  # Swap file
  $([ "$swap_size" != "0" ] && echo 'swapDevices = [ { device = "/.swapfile"; } ];')
  
  # PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Bluetooth
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  # CUPS
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  # GPU Drivers
  hardware.graphics.enable = true;
EOF

    # Configuração específica para NVIDIA
    if [ "$gpu_driver" = "nvidia" ]; then
        sudo tee -a "$config_file" << EOF
  
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = $([ "$device_type" = "laptop" ] && echo "true" || echo "false");
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
EOF
    else
        sudo tee -a "$config_file" << EOF
  
  services.xserver.videoDrivers = [ "modesetting" ];
EOF
    fi

    # Configuração específica para laptop/desktop
    if [ "$device_type" = "laptop" ]; then
        sudo tee -a "$config_file" << EOF
  
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;
  services.auto-cpufreq.enable = true;
EOF
    else
        sudo tee -a "$config_file" << EOF
  
  powerManagement.cpuFreqGovernor = "performance";
EOF
    fi

    # Configuração do usuário
    sudo tee -a "$config_file" << EOF
  
  # User
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "$pass_hash";
    shell = pkgs.bash;
  };
  
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "ALL";
          options = [ "SETENV" "NOPASSWD" ];
        }
      ];
    }
  ];
EOF

    # Configuração do desktop
    case $desktop in
        cosmic)
            sudo tee -a "$config_file" << EOF
  
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [ cosmic-edit ];
EOF
            ;;
        gnome)
            sudo tee -a "$config_file" << EOF
  
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    evince
    totem
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
  ];
EOF
            ;;
        plasma)
            sudo tee -a "$config_file" << EOF
  
  services.xserver.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];
EOF
            ;;
    esac

    # Pacotes básicos
    sudo tee -a "$config_file" << EOF
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    curl
    htop
    neofetch
    killall
    pciutils
    usbutils
  ]EOF

    # Pacotes específicos por desktop
    case $desktop in
        gnome)
            sudo tee -a "$config_file" << EOF
    ++ [ pkgs.gnome-tweaks pkgs.gnome-disk-utility pkgs.gnome-software ];
EOF
            ;;
        plasma)
            sudo tee -a "$config_file" << EOF
    ++ [ pkgs.kdePackages.dolphin pkgs.kdePackages.ark pkgs.kdePackages.kate ];
EOF
            ;;
        cosmic)
            sudo tee -a "$config_file" << EOF
    ++ [ pkgs.cosmic-term pkgs.cosmic-files pkgs.cosmic-store ];
EOF
            ;;
        *)
            sudo tee -a "$config_file" << EOF
    ;
EOF
            ;;
    esac

    # Flakes e criptografia
    sudo tee -a "$config_file" << EOF
  
  $([ "$flakes" = "yes" ] && echo 'nix.settings.experimental-features = [ "nix-command" "flakes" ];')
  
  $([ "$encryption" = "yes" ] && echo 'boot.initrd.luks.devices.cryptroot.device = "'$disk'2";')
  
  system.stateVersion = "25.11";
}
EOF

    echo "Configuração gerada com sucesso!"
}

install_system() {
    clear
    echo "=== INSTALANDO SISTEMA ==="
    echo "A instalação pode levar alguns minutos..."
    echo
    
    cd /mnt
    sudo nixos-install --no-root-passwd
    
    if [ "$flakes" = "yes" ]; then
        echo
        echo "=== FLAKES HABILITADOS ==="
        echo "Para usar flakes após a instalação:"
        echo "  cd /etc/nixos"
        echo "  sudo nix flake init -t templates#full"
        echo "  sudo nixos-rebuild switch --flake .#nixos"
    fi
    
    echo
    echo "=== INSTALAÇÃO CONCLUÍDA ==="
    echo "Após reiniciar, faça login com usuário: $(cat "$STATE_DIR/username")"
    echo "Digite 'reboot' para reiniciar."
}

# Função para verificar dependências
check_dependencies() {
    local missing_deps=()
    
    for cmd in parted mkfs.fat mkfs.ext4 mkfs.btrfs cryptsetup fallocate; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Aviso: Alguns comandos podem não estar disponíveis: ${missing_deps[*]}"
        echo "O script tentará continuar, mas pode falhar se algum comando for necessário."
        sleep 2
    fi
}

main() {
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    
    check_dependencies
    select_language
    select_keyboard
    select_timezone
    select_device_type
    select_swap_size
    select_filesystem
    select_bootloader
    select_desktop
    select_bluetooth
    select_cups
    select_encryption
    select_gpu_driver
    select_flakes
    detect_disk
    get_user_info
    
    show_summary
    
    partition_disk
    mount_partitions
    create_swap
    generate_config
    
    if confirm "Iniciar instalação do NixOS?"; then
        install_system
    else
        echo "Instalação cancelada."
        exit 1
    fi
}

# Tratamento de erros melhorado
set +e
trap 'echo "Erro detectado. Pressione Enter para continuar..."; read' ERR
set -e

main
