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
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) English US (en_US.UTF-8)"
    read -p "Opção: " lang_opt
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
        *) select_language ;;
    esac
}

select_keyboard() {
    clear
    echo "=== LAYOUT DO TECLADO ==="
    echo "1) Português Brasileiro (br)"
    echo "2) English US (us)"
    read -p "Opção: " kb_opt
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) select_keyboard ;;
    esac
}

select_timezone() {
    clear
    echo "=== FUSO HORÁRIO ==="
    echo "1) América/Sao_Paulo"
    echo "2) Outro (especificar)"
    read -p "Opção: " tz_opt
    case $tz_opt in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) 
            read -p "Digite o fuso horário (ex: Europe/Lisbon): " custom_tz
            echo "$custom_tz" > "$STATE_DIR/timezone"
            ;;
        *) select_timezone ;;
    esac
}

select_disk() {
    clear
    echo "=== DISCOS DISPONÍVEIS ==="
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk
    if [ -z "$disk" ] || [ ! -e "/dev/$disk" ]; then
        echo "Disco inválido. Tente novamente."
        read -p "Pressione Enter para continuar..."
        select_disk
        return
    fi
    echo "/dev/$disk" > "$STATE_DIR/disk"
}

select_bootloader() {
    clear
    echo "=== BOOTLOADER ==="
    echo "1) systemd-boot (recomendado para UEFI)"
    echo "2) GRUB"
    read -p "Opção: " bl_opt
    case $bl_opt in
        1) echo "systemd-boot" > "$STATE_DIR/bootloader" ;;
        2) echo "grub" > "$STATE_DIR/bootloader" ;;
        *) select_bootloader ;;
    esac
}

select_filesystem() {
    clear
    echo "=== SISTEMA DE ARQUIVOS ==="
    echo "1) ext4 (simples e estável)"
    echo "2) btrfs (com suporte a snapshots)"
    read -p "Opção: " fs_opt
    case $fs_opt in
        1) echo "ext4" > "$STATE_DIR/filesystem" ;;
        2) echo "btrfs" > "$STATE_DIR/filesystem" ;;
        *) select_filesystem ;;
    esac
}

select_encryption() {
    clear
    if confirm "Criptografar o disco (LUKS)?"; then
        echo "yes" > "$STATE_DIR/encrypt"
    else
        echo "no" > "$STATE_DIR/encrypt"
    fi
}

select_compression() {
    clear
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        echo "=== COMPRESSÃO BTRFS ==="
        echo "1) zstd (recomendado)"
        echo "2) Nenhuma"
        read -p "Opção: " comp_opt
        case $comp_opt in
            1) echo "zstd" > "$STATE_DIR/compression" ;;
            2) echo "none" > "$STATE_DIR/compression" ;;
            *) select_compression ;;
        esac
    fi
}

select_swap() {
    clear
    echo "=== TAMANHO DO SWAP ==="
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap"
    read -p "Opção: " swap_opt
    case $swap_opt in
        1) echo "2" > "$STATE_DIR/swap_size" ;;
        2) echo "4" > "$STATE_DIR/swap_size" ;;
        3) echo "8" > "$STATE_DIR/swap_size" ;;
        4) echo "0" > "$STATE_DIR/swap_size" ;;
        *) select_swap ;;
    esac
}

select_device_type() {
    clear
    echo "=== TIPO DE DISPOSITIVO ==="
    echo "1) Desktop (foco em desempenho)"
    echo "2) Laptop (foco em economia de energia)"
    read -p "Opção: " dev_opt
    case $dev_opt in
        1) echo "desktop" > "$STATE_DIR/device_type" ;;
        2) echo "laptop" > "$STATE_DIR/device_type" ;;
        *) select_device_type ;;
    esac
}

select_desktop() {
    clear
    echo "=== AMBIENTE DESKTOP ==="
    echo "1) COSMIC"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) Nenhum (apenas terminal)"
    read -p "Opção: " de_opt
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) select_desktop ;;
    esac
}

select_bluetooth() {
    clear
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_printing() {
    clear
    if confirm "Habilitar suporte a impressão (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_nvidia() {
    clear
    if confirm "Instalar drivers proprietários da NVIDIA?"; then
        echo "nvidia" > "$STATE_DIR/gpu_driver"
    else
        echo " Mesa drivers (Intel/AMD) por padrão"
    fi
}

select_flakes() {
    clear
    if confirm "Habilitar flakes na instalação?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
}

select_username() {
    clear
    read -p "Nome do usuário: " username
    if [ -z "$username" ]; then
        echo "Nome inválido. Tente novamente."
        select_username
        return
    fi
    echo "$username" > "$STATE_DIR/username"
    
    read -s -p "Senha do usuário: " userpass
    echo
    read -s -p "Confirme a senha: " userpass2
    echo
    
    if [ "$userpass" != "$userpass2" ]; then
        echo "Senhas não conferem!"
        select_username
        return
    fi
    echo "$userpass" > "$STATE_DIR/userpass"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat "$STATE_DIR/lang")"
    echo "Teclado: $(cat "$STATE_DIR/keyboard")"
    echo "Fuso horário: $(cat "$STATE_DIR/timezone")"
    echo "Disco: $(cat "$STATE_DIR/disk")"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Sistema de arquivos: $(cat "$STATE_DIR/filesystem")"
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        echo "Compressão: $(cat "$STATE_DIR/compression")"
    fi
    echo "Criptografia: $(cat "$STATE_DIR/encrypt")"
    echo "Swap: $(cat "$STATE_DIR/swap_size")GB"
    echo "Tipo: $(cat "$STATE_DIR/device_type")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "GPU: $(cat "$STATE_DIR/gpu_driver")"
    echo "Flakes: $(cat "$STATE_DIR/flakes")"
    echo "Usuário: $(cat "$STATE_DIR/username")"
    echo "============================"
    echo
    
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

check_existing_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    
    if parted -s "$disk" print 2>/dev/null | grep -q "Partition Table"; then
        echo "AVISO: O disco $disk já possui uma tabela de partições."
        if confirm "Deseja executar o cfdisk para remover partições manualmente?"; then
            cfdisk "$disk"
        fi
    fi
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local encrypt=$(cat "$STATE_DIR/encrypt")
    
    echo "Particionando $disk..."
    
    # Verificar modo de boot (UEFI ou BIOS)
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        # Criar tabela GPT
        parted -s "$disk" mklabel gpt
        
        # Partição EFI (512MB)
        parted -s "$disk" mkpart primary fat32 1MB 512MB
        parted -s "$disk" set 1 esp on
        
        # Partição principal
        parted -s "$disk" mkpart primary 512MB 100%
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        # Criar tabela MBR
        parted -s "$disk" mklabel msdos
        
        # Partição boot (512MB)
        parted -s "$disk" mkpart primary ext4 1MB 512MB
        parted -s "$disk" set 1 boot on
        
        # Partição principal
        parted -s "$disk" mkpart primary 512MB 100%
    fi
    
    # Formatar partições
    local boot_part="${disk}1"
    local root_part="${disk}2"
    
    # Formatar partição de boot
    if [ -d /sys/firmware/efi ]; then
        mkfs.fat -F 32 "$boot_part"
        fatlabel "$boot_part" NIXBOOT
    else
        mkfs.ext4 "$boot_part"
        e2label "$boot_part" NIXBOOT
    fi
    
    # Configurar criptografia se selecionada
    if [ "$encrypt" = "yes" ]; then
        echo "Configurando criptografia LUKS..."
        cryptsetup luksFormat "$root_part"
        cryptsetup open "$root_part" cryptroot
        root_device="/dev/mapper/cryptroot"
    else
        root_device="$root_part"
    fi
    
    # Formatar partição root conforme sistema de arquivos escolhido
    if [ "$fs" = "btrfs" ]; then
        mkfs.btrfs -f "$root_device"
        
        # Montar e criar subvolumes
        mount "$root_device" /mnt
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        btrfs subvolume create /mnt/@nix
        umount /mnt
    else
        mkfs.ext4 -F "$root_device"
        e2label "$root_device" NIXROOT
    fi
    
    echo "$boot_part" > "$STATE_DIR/boot_part"
    echo "$root_device" > "$STATE_DIR/root_device"
}

mount_partitions() {
    local boot_part=$(cat "$STATE_DIR/boot_part")
    local root_device=$(cat "$STATE_DIR/root_device")
    local fs=$(cat "$STATE_DIR/filesystem")
    local compression=$(cat "$STATE_DIR/compression" 2>/dev/null || echo "none")
    
    echo "Montando partições..."
    
    if [ "$fs" = "btrfs" ]; then
        # Montar subvolumes btrfs
        local mount_opts="defaults"
        [ "$compression" != "none" ] && mount_opts="$mount_opts,compress=$compression"
        
        mount -o subvol=@,$mount_opts "$root_device" /mnt
        mkdir -p /mnt/{home,nix,boot}
        mount -o subvol=@home,$mount_opts "$root_device" /mnt/home
        mount -o subvol=@nix,$mount_opts "$root_device" /mnt/nix
    else
        # Montar ext4
        mount "$root_device" /mnt
        mkdir -p /mnt/boot
    fi
    
    # Montar partição de boot
    mount "$boot_part" /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap_size")
    
    if [ "$swap_size" != "0" ]; then
        echo "Criando arquivo swap de ${swap_size}GB..."
        dd if=/dev/zero of=/mnt/.swapfile bs=1G count="$swap_size" status=progress
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
    fi
}

generate_config() {
    echo "Gerando configuração do NixOS..."
    
    nixos-generate-config --root /mnt
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local timezone=$(cat "$STATE_DIR/timezone")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local fs=$(cat "$STATE_DIR/filesystem")
    local encryption=$(cat "$STATE_DIR/encrypt")
    local swap_size=$(cat "$STATE_DIR/swap_size")
    local device_type=$(cat "$STATE_DIR/device_type")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local flakes=$(cat "$STATE_DIR/flakes")
    local username=$(cat "$STATE_DIR/username")
    local userpass=$(cat "$STATE_DIR/userpass")
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    # Criar arquivo de configuração
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  $([ "$bootloader" = "systemd-boot" ] && echo 'boot.loader.systemd-boot.enable = true;' || echo 'boot.loader.grub.enable = true; boot.loader.grub.device = "'$(cat "$STATE_DIR/disk")'";')
  
  # Locale
  i18n.defaultLocale = "$lang";
  i18n.extraLocaleSettings = {
    LC_TIME = "$lang";
    LC_MONETARY = "$lang";
    LC_PAPER = "$lang";
    LC_MEASUREMENT = "$lang";
  };
  
  # Console
  console.keyMap = "$keyboard";
  services.xserver.xkb.layout = "$keyboard";
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Network
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.hostName = "nixos";
  
  # Swap
  $([ "$swap_size" != "0" ] && echo "swapDevices = [ { device = \"/.swapfile\"; size = $((swap_size * 1024)); } ];")
  
  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Bluetooth
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  # Printing
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  # GPU Drivers
  hardware.graphics.enable = true;
  $([ "$gpu_driver" = "nvidia" ] && echo '
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  ')
  
  # Energy management
  $([ "$device_type" = "laptop" ] && echo '
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
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
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
  ];
  ')
  
  $([ "$desktop" = "gnome" ] && echo '
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    atomix
    cheese
    epiphany
    evince
    geary
    gedit
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori
    iagno
    tali
    totem
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
    firefox
  ];
  
  # Flakes (if enabled)
  $([ "$flakes" = "yes" ] && echo '
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  ')
  
  system.stateVersion = "24.11";
}
EOF
}

install_system() {
    cd /mnt
    nixos-install --no-root-passwd
    
    echo "Instalação concluída!"
    echo "Após reiniciar, faça login com usuário: $(cat "$STATE_DIR/username")"
    echo "Digite 'reboot' para reiniciar."
}

cleanup() {
    rm -rf "$STATE_DIR" 2>/dev/null || true
}

main() {
    trap cleanup EXIT
    
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    
    select_language
    select_keyboard
    select_timezone
    select_device_type
    select_disk
    select_bootloader
    select_filesystem
    select_compression
    select_encryption
    select_swap
    select_desktop
    select_bluetooth
    select_printing
    select_nvidia
    select_flakes
    select_username
    
    show_summary
    
    check_existing_partitions
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

main "$@"
