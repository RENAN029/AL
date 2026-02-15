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
    echo "Selecione o idioma do sistema:"
    echo "1) Português do Brasil (pt_BR.UTF-8)"
    echo "2) English US (en_US.UTF-8)"
    read -p "Opção: " lang_opt
    
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
        *) echo "Opção inválida"; select_language ;;
    esac
}

select_keyboard() {
    clear
    echo "Selecione o layout do teclado:"
    echo "1) br (ABNT2)"
    echo "2) us"
    read -p "Opção: " kb_opt
    
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "Opção inválida"; select_keyboard ;;
    esac
}

select_timezone() {
    clear
    echo "Selecione o fuso horário:"
    echo "1) America/Sao_Paulo"
    echo "2) America/New_York"
    read -p "Opção: " tz_opt
    
    case $tz_opt in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) echo "America/New_York" > "$STATE_DIR/timezone" ;;
        *) echo "Opção inválida"; select_timezone ;;
    esac
}

select_filesystem() {
    clear
    echo "Selecione o sistema de arquivos:"
    echo "1) ext4 (recomendado)"
    echo "2) btrfs (com subvolumes e compressão)"
    read -p "Opção: " fs_opt
    
    case $fs_opt in
        1) echo "ext4" > "$STATE_DIR/filesystem" ;;
        2) echo "btrfs" > "$STATE_DIR/filesystem" ;;
        *) echo "Opção inválida"; select_filesystem ;;
    esac
}

select_bootloader() {
    clear
    echo "Selecione o bootloader:"
    echo "1) systemd-boot (recomendado para UEFI)"
    echo "2) GRUB (compatível com BIOS e UEFI)"
    read -p "Opção: " bl_opt
    
    case $bl_opt in
        1) echo "systemd-boot" > "$STATE_DIR/bootloader" ;;
        2) echo "grub" > "$STATE_DIR/bootloader" ;;
        *) echo "Opção inválida"; select_bootloader ;;
    esac
}

select_encryption() {
    clear
    if confirm "Criptografar o disco (LUKS)?"; then
        echo "yes" > "$STATE_DIR/encryption"
    else
        echo "no" > "$STATE_DIR/encryption"
    fi
}

select_desktop() {
    clear
    echo "Selecione o ambiente desktop:"
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
        *) echo "Opção inválida"; select_desktop ;;
    esac
}

select_nvidia_drivers() {
    clear
    if confirm "Instalar drivers proprietários da NVIDIA?"; then
        echo "nvidia" > "$STATE_DIR/gpu_drivers"
    else
        echo "open" > "$STATE_DIR/gpu_drivers"
    fi
}

select_swap_size() {
    clear
    echo "Selecione o tamanho do swap:"
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
        *) echo "Opção inválida"; select_swap_size ;;
    esac
}

select_device_type() {
    clear
    echo "Selecione o tipo de dispositivo:"
    echo "1) Laptop (otimizado para economia de energia)"
    echo "2) Desktop (otimizado para desempenho máximo)"
    read -p "Opção: " dev_opt
    
    case $dev_opt in
        1) echo "laptop" > "$STATE_DIR/device_type" ;;
        2) echo "desktop" > "$STATE_DIR/device_type" ;;
        *) echo "Opção inválida"; select_device_type ;;
    esac
}

select_flakes() {
    clear
    if confirm "Habilitar flakes (experimental)?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
}

select_bluetooth() {
    clear
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    clear
    if confirm "Habilitar suporte a impressão (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

detect_disk() {
    clear
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    
    while true; do
        read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
        if [ -b "/dev/$disk_name" ]; then
            echo "/dev/$disk_name" > "$STATE_DIR/disk"
            break
        else
            echo "Disco inválido. Tente novamente."
        fi
    done
}

check_existing_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    
    if [ -n "$(lsblk -o NAME -n "$disk" | tail -n +2)" ]; then
        clear
        echo "ATENÇÃO: O disco possui partições existentes!"
        if confirm "Abrir cfdisk para remover partições manualmente?"; then
            cfdisk "$disk"
            # Verificar se ainda existem partições
            if [ -n "$(lsblk -o NAME -n "$disk" | tail -n +2)" ]; then
                echo "Ainda existem partições no disco."
                if ! confirm "Continuar mesmo assim?"; then
                    check_existing_partitions
                fi
            fi
        fi
    fi
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local encryption=$(cat "$STATE_DIR/encryption")
    
    echo "Particionando $disk..."
    
    # Limpar tabela de partições
    sudo wipefs -a "$disk"
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted "$disk" -- mklabel gpt
        sudo parted "$disk" -- mkpart primary 1MB 512MB
        sudo parted "$disk" -- set 1 esp on
        sudo parted "$disk" -- mkpart primary 512MB 100%
        
        sudo mkfs.fat -F 32 "${disk}1"
        sudo fatlabel "${disk}1" NIXBOOT
        
        if [ "$encryption" = "yes" ]; then
            echo "Criptografando partição root..."
            sudo cryptsetup luksFormat "${disk}2"
            sudo cryptsetup open "${disk}2" cryptroot
            if [ "$fs" = "btrfs" ]; then
                sudo mkfs.btrfs -L NIXROOT /dev/mapper/cryptroot
            else
                sudo mkfs.ext4 -L NIXROOT /dev/mapper/cryptroot
            fi
        else
            if [ "$fs" = "btrfs" ]; then
                sudo mkfs.btrfs -L NIXROOT "${disk}2"
            else
                sudo mkfs.ext4 -L NIXROOT "${disk}2"
            fi
        fi
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted "$disk" -- mklabel msdos
        sudo parted "$disk" -- mkpart primary 1MB 100%
        sudo parted "$disk" -- set 1 boot on
        
        if [ "$encryption" = "yes" ]; then
            echo "Criptografando partição..."
            sudo cryptsetup luksFormat "${disk}1"
            sudo cryptsetup open "${disk}1" cryptroot
            if [ "$fs" = "btrfs" ]; then
                sudo mkfs.btrfs -L NIXROOT /dev/mapper/cryptroot
            else
                sudo mkfs.ext4 -L NIXROOT /dev/mapper/cryptroot
            fi
        else
            if [ "$fs" = "btrfs" ]; then
                sudo mkfs.btrfs -L NIXROOT "${disk}1"
            else
                sudo mkfs.ext4 -L NIXROOT "${disk}1"
            fi
        fi
    fi
}

create_btrfs_subvolumes() {
    local mount_point="$1"
    
    sudo btrfs subvolume create "$mount_point/@"
    sudo btrfs subvolume create "$mount_point/@home"
    sudo btrfs subvolume create "$mount_point/@nix"
    sudo umount "$mount_point"
}

mount_partitions() {
    local fs=$(cat "$STATE_DIR/filesystem")
    local encryption=$(cat "$STATE_DIR/encryption")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    
    if [ "$encryption" = "yes" ]; then
        if [ ! -e /dev/mapper/cryptroot ]; then
            sudo cryptsetup open "$(cat "$STATE_DIR/disk")2" cryptroot
        fi
        local root_dev="/dev/mapper/cryptroot"
    else
        local root_dev="/dev/disk/by-label/NIXROOT"
    fi
    
    if [ "$fs" = "btrfs" ]; then
        sudo mount "$root_dev" /mnt
        create_btrfs_subvolumes /mnt
        sudo mount -o compress=zstd,subvol=@ "$root_dev" /mnt
        sudo mkdir -p /mnt/{home,nix}
        sudo mount -o compress=zstd,subvol=@home "$root_dev" /mnt/home
        sudo mount -o compress=zstd,noatime,subvol=@nix "$root_dev" /mnt/nix
    else
        sudo mount "$root_dev" /mnt
    fi
    
    if [ "$boot_mode" = "uefi" ]; then
        sudo mkdir -p /mnt/boot
        sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    fi
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap_size")
    
    if [ "$swap_size" != "0" ]; then
        echo "Criando arquivo swap de ${swap_size}GB..."
        sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count="$swap_size" status=progress
        sudo chmod 600 /mnt/.swapfile
        sudo mkswap /mnt/.swapfile
        sudo swapon /mnt/.swapfile
    fi
}

get_user_info() {
    clear
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    while true; do
        read -s -p "Senha do usuário: " userpass
        echo
        read -s -p "Confirme a senha: " userpass2
        echo
        
        if [ "$userpass" = "$userpass2" ] && [ -n "$userpass" ]; then
            local pass_hash=$(mkpasswd -m sha-512 "$userpass")
            echo "$pass_hash" > "$STATE_DIR/userpass_hash"
            break
        else
            echo "Senhas inválidas ou não conferem. Tente novamente."
        fi
    done
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat "$STATE_DIR/lang")"
    echo "Teclado: $(cat "$STATE_DIR/keyboard")"
    echo "Fuso horário: $(cat "$STATE_DIR/timezone")"
    echo "Sistema de arquivos: $(cat "$STATE_DIR/filesystem")"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Criptografia: $(cat "$STATE_DIR/encryption")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "Drivers GPU: $(cat "$STATE_DIR/gpu_drivers")"
    echo "Swap: $(cat "$STATE_DIR/swap_size" | sed 's/0/Sem swap/g')GB"
    echo "Tipo de dispositivo: $(cat "$STATE_DIR/device_type")"
    echo "Flakes: $(cat "$STATE_DIR/flakes")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "Disco: $(cat "$STATE_DIR/disk")"
    echo "Usuário: $(cat "$STATE_DIR/username")"
    echo "============================="
    echo
    
    if ! confirm "Iniciar instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

generate_config() {
    sudo nixos-generate-config --root /mnt
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local timezone=$(cat "$STATE_DIR/timezone")
    local fs=$(cat "$STATE_DIR/filesystem")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local encryption=$(cat "$STATE_DIR/encryption")
    local desktop=$(cat "$STATE_DIR/desktop")
    local gpu_drivers=$(cat "$STATE_DIR/gpu_drivers")
    local swap_size=$(cat "$STATE_DIR/swap_size")
    local device_type=$(cat "$STATE_DIR/device_type")
    local flakes=$(cat "$STATE_DIR/flakes")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local disk=$(cat "$STATE_DIR/disk")
    local username=$(cat "$STATE_DIR/username")
    local pass_hash=$(cat "$STATE_DIR/userpass_hash")
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  $([ "$bootloader" = "systemd-boot" ] && [ "$boot_mode" = "uefi" ] && echo 'boot.loader.systemd-boot.enable = true;')
  $([ "$bootloader" = "grub" ] && echo 'boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = $(if [ "$boot_mode" = "uefi" ]; then echo "true"; else echo "false"; fi);
  };')
  
  # Locale
  i18n.defaultLocale = "$lang";
  i18n.extraLocaleSettings = {
    LC_TIME = "$lang";
    LC_MONETARY = "$lang";
    LC_PAPER = "$lang";
    LC_MEASUREMENT = "$lang";
  };
  
  console.keyMap = "$keyboard";
  services.xserver.xkb.layout = "$keyboard";
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Network
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.hostName = "nixos";
  
  # Graphics
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  
  $([ "$gpu_drivers" = "nvidia" ] && echo '
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = '"$([ "$device_type" = "laptop" ] && echo "true" || echo "false")"';
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };' || echo '
  services.xserver.videoDrivers = [ "modesetting" ];')
  
  # Wayland
  services.xserver.enable = true;
  services.xserver.displayManager.sessionCommands = ''\${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource modesetting NVIDIA-0;'';
  
  # Swap
  $([ "$swap_size" != "0" ] && echo 'swapDevices = [ {
    device = "/.swapfile";
    size = $((swap_size * 1024));
  } ];')
  
  # Power management (device-specific)
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
  };' || echo '
  powerManagement.cpuFreqGovernor = "performance";')
  
  # PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  
  # Bluetooth
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  # CUPS
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  # User
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "render" ];
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
  
  # Desktop Environments (minimal packages)
  $([ "$desktop" = "cosmic" ] && echo '
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
    cosmic-term
  ];')
  
  $([ "$desktop" = "gnome" ] && echo '
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    evince
    totem
    gnome-tour
  ];')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];')
  
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
    btrfs-progs
    cryptsetup
  ];
  
  # Flakes
  $([ "$flakes" = "yes" ] && echo 'nix.settings.experimental-features = [ "nix-command" "flakes" ];')
  
  system.stateVersion = "25.11";
}
EOF

    # Atualizar hardware-configuration.nix para usar labels
    if [ "$encryption" = "yes" ]; then
        sudo sed -i 's|/dev/disk/by-uuid/[0-9a-f-]*|/dev/mapper/cryptroot|g' /mnt/etc/nixos/hardware-configuration.nix
    else
        sudo sed -i 's|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g' /mnt/etc/nixos/hardware-configuration.nix
    fi
    
    if [ "$boot_mode" = "uefi" ]; then
        sudo sed -i 's|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g' /mnt/etc/nixos/hardware-configuration.nix
    fi
}

install_system() {
    cd /mnt
    sudo nixos-install --no-root-passwd
    
    if [ "$flakes" = "yes" ]; then
        echo "Flakes habilitado. Para usar, adicione em /etc/nixos/configuration.nix:"
        echo "nix.settings.experimental-features = [ \"nix-command\" \"flakes\" ];"
    fi
}

main() {
    clear
    echo "=== Instalador Automático NixOS ==="
    echo
    
    select_language
    select_keyboard
    select_timezone
    select_filesystem
    select_bootloader
    select_encryption
    select_desktop
    select_nvidia_drivers
    select_swap_size
    select_device_type
    select_flakes
    select_bluetooth
    select_cups
    detect_disk
    check_existing_partitions
    get_user_info
    show_summary
    
    partition_disk
    mount_partitions
    create_swap
    generate_config
    
    if confirm "Iniciar instalação do NixOS?"; then
        install_system
        echo "Instalação concluída!"
        echo "Digite 'reboot' para reiniciar."
    else
        echo "Instalação cancelada."
        exit 1
    fi
}

main
