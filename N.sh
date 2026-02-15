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
    echo "2) English (en_US.UTF-8)"
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
    echo "1) br (ABNT2)"
    echo "2) us"
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
    while true; do
        read -p "Opção: " swap_opcao
        case $swap_opcao in
            1) echo "2G" > "$STATE_DIR/swap"; break ;;
            2) echo "4G" > "$STATE_DIR/swap"; break ;;
            3) echo "8G" > "$STATE_DIR/swap"; break ;;
            *) echo "Opção inválida. Escolha 1, 2 ou 3." ;;
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

select_nvidia() {
    clear
    echo "=== DRIVERS NVIDIA ==="
    if confirm "Instalar drivers proprietários NVIDIA?"; then
        echo "nvidia" > "$STATE_DIR/gpu_driver"
    else
        echo "intel-amd" > "$STATE_DIR/gpu_driver"
    fi
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
        sudo mount /dev/mapper/cryptroot /mnt
    else
        sudo mkfs.ext4 /dev/mapper/cryptroot
        sudo mount /dev/mapper/cryptroot /mnt
    fi
    
    echo "/dev/mapper/cryptroot" > "$STATE_DIR/root_device"
}

setup_btrfs_subvolumes() {
    echo "Criando subvolumes btrfs..."
    
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    
    sudo umount /mnt
    
    sudo mount -o compress=zstd,subvol=@ /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/{home,nix}
    sudo mount -o compress=zstd,subvol=@home /dev/disk/by-label/NIXROOT /mnt/home
    sudo mount -o compress=zstd,noatime,subvol=@nix /dev/disk/by-label/NIXROOT /mnt/nix
}

mount_partitions() {
    local encryption=$(cat "$STATE_DIR/encryption")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    if [ "$encryption" = "yes" ]; then
        if [ ! -d /mnt/home ]; then
            setup_encryption
        fi
    else
        if [ "$fs" = "btrfs" ] && [ ! -d /mnt/home ]; then
            sudo mount /dev/disk/by-label/NIXROOT /mnt
            setup_btrfs_subvolumes
        else
            sudo mount /dev/disk/by-label/NIXROOT /mnt
        fi
    fi
    
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    local size_num=$(echo $swap_size | sed 's/G//')
    
    echo "Criando arquivo swap de $swap_size..."
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$size_num status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
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
            local pass_hash=$(mkpasswd -m sha-512 "$userpass")
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
    echo "Swap: $(cat "$STATE_DIR/swap")"
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
    local swap_size=$(cat "$STATE_DIR/swap" | sed 's/G//')
    
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
  
  # X11/Keyboard
  services.xserver.enable = true;
  services.xserver.xkb.layout = "$keyboard";
  
  # Wayland (padrão)
  services.xserver.displayManager.gdm.enable = $([ "$desktop" = "gnome" ] && echo "true" || echo "false");
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Network
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.hostName = "nixos";
  
  # Swap
  swapDevices = [ {
    device = "/.swapfile";
    size = $((swap_size * 1024));
  } ];
  
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
  $([ "$gpu_driver" = "nvidia" ] && echo '
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = '$(if [ "$device_type" = "laptop" ]; then echo "true"; else echo "false"; fi)';
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };' || echo '
  services.xserver.videoDrivers = [ "modesetting" ];
  ')
  
  # Device-specific optimizations
  $([ "$device_type" = "laptop" ] && echo '
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;
  ' || echo '
  powerManagement.cpuFreqGovernor = "performance";
  ')
  
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
  
  # Desktop Environments
  $([ "$desktop" = "cosmic" ] && echo '
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [ cosmic-edit ];
  ')
  
  $([ "$desktop" = "gnome" ] && echo '
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
  ')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];
  ')
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    curl
    htop
    neofetch
  ] ++ $([ "$desktop" = "gnome" ] && echo '[ pkgs.gnome-tweaks pkgs.gnome-disk-utility ]' || echo '[]')
    ++ $([ "$desktop" = "plasma" ] && echo '[ pkgs.kdePackages.dolphin pkgs.kdePackages.ark ]' || echo '[]')
    ++ $([ "$desktop" = "cosmic" ] && echo '[ pkgs.cosmic-term pkgs.cosmic-files ]' || echo '[]');
  
  # Flakes
  $([ "$flakes" = "yes" ] && echo '
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  ')
  
  # Encryption
  $([ "$encryption" = "yes" ] && echo '
  boot.initrd.luks.devices.cryptroot.device = "'$disk'2";
  ')
  
  system.stateVersion = "25.11";
}
EOF

    # Ajustar hardware-configuration.nix para usar labels se não estiver criptografado
    if [ "$encryption" != "yes" ]; then
        sudo sed -i 's|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g' /mnt/etc/nixos/hardware-configuration.nix
        sudo sed -i 's|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g' /mnt/etc/nixos/hardware-configuration.nix
    fi
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
        echo "Para usar flakes após a instalação, execute:"
        echo "  sudo nix flake init -t templates#full"
        echo "  sudo nixos-rebuild switch --flake .#nixos"
    fi
    
    echo
    echo "Instalação concluída!"
    echo "Digite 'reboot' para reiniciar."
}

main() {
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    
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
    select_nvidia
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

# Tratamento de erros para não sair do script
set +e
trap 'echo "Erro detectado. Pressione Enter para continuar..."; read' ERR
set -e

main
