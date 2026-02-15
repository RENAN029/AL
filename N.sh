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
    while true; do
        clear
        echo "=== IDIOMA DO SISTEMA / SYSTEM LANGUAGE ==="
        echo "1) Português Brasileiro (pt_BR.UTF-8)"
        echo "2) English US (en_US.UTF-8)"
        read -p "Opção: " lang_opt
        case $lang_opt in
            1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang"; break ;;
            2) echo "en_US.UTF-8" > "$STATE_DIR/lang"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
}

select_keyboard() {
    while true; do
        clear
        echo "=== LAYOUT DO TECLADO / KEYBOARD LAYOUT ==="
        echo "1) Português Brasileiro (br)"
        echo "2) English US (us)"
        read -p "Opção: " kb_opt
        case $kb_opt in
            1) echo "br" > "$STATE_DIR/keyboard"; break ;;
            2) echo "us" > "$STATE_DIR/keyboard"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
}

select_timezone() {
    while true; do
        clear
        echo "=== FUSO HORÁRIO / TIMEZONE ==="
        echo "1) America/Sao_Paulo"
        echo "2) America/New_York"
        read -p "Opção: " tz_opt
        case $tz_opt in
            1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone"; break ;;
            2) echo "America/New_York" > "$STATE_DIR/timezone"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
}

select_hostname() {
    clear
    echo "=== NOME DO COMPUTADOR / HOSTNAME ==="
    read -p "Digite o nome do computador [nixos]: " hostname
    if [ -z "$hostname" ]; then
        echo "nixos" > "$STATE_DIR/hostname"
    else
        echo "$hostname" > "$STATE_DIR/hostname"
    fi
}

select_device_type() {
    while true; do
        clear
        echo "=== TIPO DE DISPOSITIVO / DEVICE TYPE ==="
        echo "1) Laptop (foco em economia de energia)"
        echo "2) Desktop (foco em desempenho máximo)"
        read -p "Opção: " device_opt
        case $device_opt in
            1) echo "laptop" > "$STATE_DIR/device_type"; break ;;
            2) echo "desktop" > "$STATE_DIR/device_type"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
}

select_filesystem() {
    while true; do
        clear
        echo "=== SISTEMA DE ARQUIVOS / FILESYSTEM ==="
        echo "1) ext4 (padrão, estável)"
        echo "2) btrfs (com snapshots e compressão automática)"
        read -p "Opção: " fs_opt
        case $fs_opt in
            1) echo "ext4" > "$STATE_DIR/filesystem"; break ;;
            2) echo "btrfs" > "$STATE_DIR/filesystem"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        echo "yes" > "$STATE_DIR/compress"
    else
        echo "no" > "$STATE_DIR/compress"
    fi
}

select_bootloader() {
    while true; do
        clear
        echo "=== BOOTLOADER ==="
        echo "1) systemd-boot (recomendado para UEFI)"
        echo "2) GRUB (compatível com BIOS e UEFI)"
        read -p "Opção: " bl_opt
        case $bl_opt in
            1) echo "systemd-boot" > "$STATE_DIR/bootloader"; break ;;
            2) echo "grub" > "$STATE_DIR/bootloader"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
}

select_swap_size() {
    while true; do
        clear
        echo "=== TAMANHO DO SWAP / SWAP SIZE ==="
        echo "1) 2GB"
        echo "2) 4GB"
        echo "3) 8GB"
        echo "4) Sem swap"
        read -p "Opção: " swap_opt
        case $swap_opt in
            1) echo "2" > "$STATE_DIR/swap"; break ;;
            2) echo "4" > "$STATE_DIR/swap"; break ;;
            3) echo "8" > "$STATE_DIR/swap"; break ;;
            4) echo "0" > "$STATE_DIR/swap"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
}

select_encryption() {
    clear
    echo "=== CRIPTOGRAFIA / ENCRYPTION ==="
    if confirm "Criptografar disco com LUKS?"; then
        echo "yes" > "$STATE_DIR/encryption"
    else
        echo "no" > "$STATE_DIR/encryption"
    fi
}

select_gpu_drivers() {
    while true; do
        clear
        echo "=== DRIVERS DE GPU / GPU DRIVERS ==="
        echo "1) NVIDIA (proprietário - open modules para GPUs recentes)"
        echo "2) Intel/AMD (open source - padrão)"
        read -p "Opção: " gpu_opt
        case $gpu_opt in
            1|2) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    
    case $gpu_opt in
        1) 
            echo "nvidia" > "$STATE_DIR/gpu_driver"
            echo "yes" > "$STATE_DIR/unfree"
            echo "yes" > "$STATE_DIR/nvidia_open"
            echo "yes" > "$STATE_DIR/nvidia_modeset"
            ;;
        2) 
            echo "intel-amd" > "$STATE_DIR/gpu_driver"
            echo "no" > "$STATE_DIR/unfree"
            echo "no" > "$STATE_DIR/nvidia_open"
            echo "no" > "$STATE_DIR/nvidia_modeset"
            ;;
    esac
}

select_desktop() {
    while true; do
        clear
        echo "=== AMBIENTE DESKTOP / DESKTOP ENVIRONMENT ==="
        echo "1) COSMIC (minimal, Wayland nativo)"
        echo "2) GNOME (minimal, Wayland)"
        echo "3) KDE Plasma (minimal, Wayland)"
        echo "4) Nenhum (apenas terminal)"
        read -p "Opção: " de_opt
        case $de_opt in
            1|2|3|4) break ;;
            *) echo "Opção inválida"; sleep 2 ;;
        esac
    done
    
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
    esac
    
    if [ "$(cat "$STATE_DIR/desktop")" != "none" ]; then
        echo "yes" > "$STATE_DIR/pipewire"
    else
        echo "no" > "$STATE_DIR/pipewire"
    fi
}

select_networking() {
    while true; do
        clear
        echo "=== GERENCIADOR DE REDE / NETWORK MANAGER ==="
        echo "1) NetworkManager (recomendado para desktop)"
        echo "2) systemd-networkd (leve, para servidores)"
        read -p "Opção: " net_opt
        case $net_opt in
            1) echo "networkmanager" > "$STATE_DIR/networking"; break ;;
            2) echo "systemd-networkd" > "$STATE_DIR/networking"; break ;;
            *) echo "Opção inválida"; sleep 2 ;;
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
    echo "=== IMPRESSÃO (CUPS) / PRINTING (CUPS) ==="
    if confirm "Habilitar suporte a impressão?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_ssd_trim() {
    clear
    echo "=== TRIM PARA SSD ==="
    if confirm "Habilitar TRIM para SSD?"; then
        echo "yes" > "$STATE_DIR/trim"
    else
        echo "no" > "$STATE_DIR/trim"
    fi
}

select_flakes() {
    clear
    echo "=== FLAKES ==="
    if confirm "Criar arquivo flake.nix de exemplo? (pode ser usado após a instalação)"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
}

detect_disk() {
    while true; do
        clear
        echo "=== DISCOS DISPONÍVEIS / AVAILABLE DISKS ==="
        lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -v loop
        echo
        read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
        if [ -b "/dev/$disk_name" ]; then
            echo "/dev/$disk_name" > "$STATE_DIR/disk"
            break
        else
            echo "Disco inválido. Pressione Enter para tentar novamente."
            read
        fi
    done
}

select_username() {
    while true; do
        clear
        read -p "Digite o nome do usuário: " username
        if [ -n "$username" ]; then
            echo "$username" > "$STATE_DIR/username"
            break
        fi
    done
    
    while true; do
        read -s -p "Digite a senha: " userpass
        echo
        read -s -p "Confirme a senha: " userpass2
        echo
        if [ "$userpass" = "$userpass2" ] && [ -n "$userpass" ]; then
            if command -v mkpasswd >/dev/null 2>&1; then
                echo "$(mkpasswd -m sha-512 "$userpass")" > "$STATE_DIR/pass_hash"
            else
                echo "$(openssl passwd -6 "$userpass")" > "$STATE_DIR/pass_hash"
            fi
            break
        else
            echo "Senhas não conferem ou vazias. Pressione Enter para tentar novamente."
            read
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
    
    local uuid=$(sudo blkid -s UUID -o value ${disk}2)
    echo "$uuid" > "$STATE_DIR/luks_uuid"
    
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        sudo mkfs.btrfs /dev/mapper/cryptroot
    else
        sudo mkfs.ext4 /dev/mapper/cryptroot
    fi
}

setup_btrfs_subvolumes() {
    local root_dev
    
    if [ "$(cat "$STATE_DIR/encryption")" = "yes" ]; then
        root_dev="/dev/mapper/cryptroot"
    else
        root_dev="/dev/disk/by-label/NIXROOT"
    fi
    
    echo "Criando subvolumes btrfs..."
    
    sudo mount $root_dev /mnt
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    
    sudo umount /mnt
    
    local compress_opt="compress=zstd,"
    
    sudo mount -o ${compress_opt}subvol=@ $root_dev /mnt
    sudo mkdir -p /mnt/{home,nix}
    sudo mount -o ${compress_opt}subvol=@home $root_dev /mnt/home
    sudo mount -o ${compress_opt}subvol=@nix,noatime $root_dev /mnt/nix
}

mount_partitions() {
    local encryption=$(cat "$STATE_DIR/encryption")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    if [ "$encryption" = "yes" ]; then
        if [ ! -e /dev/mapper/cryptroot ]; then
            setup_encryption
        fi
        
        if [ "$fs" = "btrfs" ]; then
            setup_btrfs_subvolumes
        else
            sudo mount /dev/mapper/cryptroot /mnt
        fi
    else
        if [ "$fs" = "btrfs" ]; then
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
    
    if [ "$swap_size" = "0" ]; then
        return
    fi
    
    echo "Criando arquivo swap de ${swap_size}G..."
    sudo fallocate -l ${swap_size}G /mnt/.swapfile
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
}

generate_config() {
    clear
    echo "=== GERANDO CONFIGURAÇÃO ==="
    
    sudo nixos-generate-config --root /mnt
    
    sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix.bak
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local timezone=$(cat "$STATE_DIR/timezone")
    local hostname=$(cat "$STATE_DIR/hostname")
    local username=$(cat "$STATE_DIR/username")
    local pass_hash=$(cat "$STATE_DIR/pass_hash")
    local device_type=$(cat "$STATE_DIR/device_type")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local pipewire=$(cat "$STATE_DIR/pipewire")
    local trim=$(cat "$STATE_DIR/trim")
    local encryption=$(cat "$STATE_DIR/encryption")
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local nvidia_open=$(cat "$STATE_DIR/nvidia_open")
    local nvidia_modeset=$(cat "$STATE_DIR/nvidia_modeset")
    local swap_size=$(cat "$STATE_DIR/swap")
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local compress=$(cat "$STATE_DIR/compress")
    local networking=$(cat "$STATE_DIR/networking")
    local luks_uuid=$(cat "$STATE_DIR/luks_uuid" 2>/dev/null || echo "")
    
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    sudo tee "$config_file" > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  $(if [ "$gpu_driver" = "nvidia" ]; then echo "nixpkgs.config.allowUnfree = true;"; fi)
  
  $(if [ "$bootloader" = "systemd-boot" ]; then
    echo "boot.loader.systemd-boot.enable = true;"
    echo "boot.loader.efi.canTouchEfiVariables = true;"
  else
    if [ "$boot_mode" = "uefi" ]; then
      echo "boot.loader.grub = {"
      echo "  enable = true;"
      echo "  efiSupport = true;"
      echo "  device = \"nodev\";"
      echo "  efiInstallAsRemovable = true;"
      echo "};"
    else
      echo "boot.loader.grub = {"
      echo "  enable = true;"
      echo "  device = \"$disk\";"
      echo "};"
    fi
  fi)
  
  i18n.defaultLocale = "$lang";
  console.keyMap = "$keyboard";
  
  time.timeZone = "$timezone";
  
  networking.hostName = "$hostname";
  $(if [ "$networking" = "networkmanager" ]; then
    echo "networking.networkmanager.enable = true;"
  else
    echo "networking.useNetworkd = true;"
    echo "systemd.network.enable = true;"
  fi)
  
  services.xserver.enable = true;
  services.xserver.xkb.layout = "$keyboard";
  
  $(if [ "$pipewire" = "yes" ]; then
    echo "services.pipewire = {"
    echo "  enable = true;"
    echo "  alsa.enable = true;"
    echo "  alsa.support32Bit = true;"
    echo "  pulse.enable = true;"
    echo "};"
  else
    echo "services.pipewire.enable = false;"
  fi)
  
  $(if [ "$bluetooth" = "yes" ]; then
    echo "hardware.bluetooth.enable = true;"
    echo "services.blueman.enable = true;"
  fi)
  
  $(if [ "$cups" = "yes" ]; then echo "services.printing.enable = true;"; fi)
  
  $(if [ "$trim" = "yes" ]; then echo "services.fstrim.enable = true;"; fi)
  
  hardware.graphics.enable = true;
EOF

    if [ "$gpu_driver" = "nvidia" ]; then
        cat >> "$config_file" << EOF
  
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = $([ "$nvidia_modeset" = "yes" ] && echo "true" || echo "false");
    powerManagement.enable = $([ "$device_type" = "laptop" ] && echo "true" || echo "false");
    open = $([ "$nvidia_open" = "yes" ] && echo "true" || echo "false");
    nvidiaSettings = true;
  };
EOF
    else
        cat >> "$config_file" << EOF
  
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics.extraPackages = with pkgs; [
    mesa.drivers
  ];
EOF
    fi

    cat >> "$config_file" << EOF
  
  $(if [ "$device_type" = "laptop" ]; then
    echo "powerManagement.enable = true;"
    echo "services.thermald.enable = true;"
    echo "services.tlp.enable = true;"
  else
    echo "powerManagement.cpuFreqGovernor = \"performance\";"
  fi)
  
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
EOF

    if [ "$swap_size" != "0" ]; then
        cat >> "$config_file" << EOF
  
  swapDevices = [ { device = "/.swapfile"; } ];
EOF
    fi

    if [ "$encryption" = "yes" ] && [ -n "$luks_uuid" ]; then
        cat >> "$config_file" << EOF
  
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/$luks_uuid";
    preLVM = true;
  };
EOF
    fi

    if [ "$fs" = "btrfs" ] && [ "$compress" = "yes" ]; then
        cat >> "$config_file" << EOF
  
  fileSystems.\"/\".options = [ "compress=zstd" ];
  fileSystems.\"/home\".options = [ "compress=zstd" ];
  fileSystems.\"/nix\".options = [ "compress=zstd" "noatime" ];
EOF
    fi

    cat >> "$config_file" << EOF
  
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    neofetch
    pciutils
    usbutils
EOF

    case $desktop in
        cosmic)
            cat >> "$config_file" << EOF
    cosmic-session
    cosmic-terminal
    cosmic-files
    cosmic-store
    cosmic-edit
    cosmic-settings
EOF
            ;;
        gnome)
            cat >> "$config_file" << EOF
    gnome-tweaks
    gnome-disk-utility
    gnome-software
    dconf-editor
EOF
            ;;
        plasma)
            cat >> "$config_file" << EOF
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
    kdePackages.konsole
    kdePackages.kcalc
EOF
            ;;
    esac

    cat >> "$config_file" << EOF
  ];
EOF

    case $desktop in
        cosmic)
            cat >> "$config_file" << EOF
  
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
  ];
EOF
            ;;
        gnome)
            cat >> "$config_file" << EOF
  
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  environment.gnome.excludePackages = (with pkgs; [
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
    tali
    totem
  ]);
EOF
            ;;
        plasma)
            cat >> "$config_file" << EOF
  
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];
EOF
            ;;
    esac

    cat >> "$config_file" << EOF
  
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  
  system.stateVersion = "24.11";
}
EOF

    echo "Configuração gerada com sucesso!"
}

generate_flake() {
    if [ "$(cat "$STATE_DIR/flakes")" != "yes" ]; then
        return
    fi
    
    local hostname=$(cat "$STATE_DIR/hostname")
    local flake_file="/mnt/etc/nixos/flake.nix"
    
    sudo tee "$flake_file" > /dev/null << EOF
{
  description = "Configuração NixOS com flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.$hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}
EOF
    
    echo "Arquivo flake.nix de exemplo criado em /mnt/etc/nixos/"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma: $(cat "$STATE_DIR/lang")"
    echo "Teclado: $(cat "$STATE_DIR/keyboard")"
    echo "Fuso: $(cat "$STATE_DIR/timezone")"
    echo "Hostname: $(cat "$STATE_DIR/hostname")"
    echo "Dispositivo: $(cat "$STATE_DIR/device_type")"
    
    local swap=$(cat "$STATE_DIR/swap")
    if [ "$swap" = "0" ]; then
        echo "Swap: Sem swap"
    else
        echo "Swap: ${swap}GB"
    fi
    
    echo "Sistema de arquivos: $(cat "$STATE_DIR/filesystem")"
    [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ] && echo "Compressão btrfs: Sim"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "Rede: $(cat "$STATE_DIR/networking")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "PipeWire: $(cat "$STATE_DIR/pipewire")"
    echo "TRIM SSD: $(cat "$STATE_DIR/trim")"
    echo "Criptografia: $(cat "$STATE_DIR/encryption")"
    echo "GPU: $(cat "$STATE_DIR/gpu_driver")"
    echo "Flake exemplo: $(cat "$STATE_DIR/flakes")"
    echo "Disco: $(cat "$STATE_DIR/disk")"
    echo "Usuário: $(cat "$STATE_DIR/username")"
    echo "================================="
    echo
    
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

install_system() {
    clear
    echo "=== INSTALANDO SISTEMA ==="
    echo "A instalação pode levar alguns minutos..."
    echo
    
    cd /mnt
    sudo nixos-install --no-root-passwd
    
    echo
    echo "=== INSTALAÇÃO CONCLUÍDA ==="
    echo "Após reiniciar, faça login com usuário: $(cat "$STATE_DIR/username")"
    echo "Digite 'reboot' para reiniciar."
}

main() {
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    
    select_language
    select_keyboard
    select_timezone
    select_hostname
    select_device_type
    select_filesystem
    select_bootloader
    select_swap_size
    select_encryption
    select_gpu_drivers
    select_desktop
    select_networking
    select_bluetooth
    select_cups
    select_ssd_trim
    select_flakes
    detect_disk
    select_username
    
    show_summary
    
    partition_disk
    mount_partitions
    create_swap
    generate_config
    generate_flake
    
    if confirm "Iniciar instalação do NixOS?"; then
        install_system
    else
        echo "Instalação cancelada."
        exit 1
    fi
}

trap 'echo "Erro detectado. Pressione Enter para continuar..."; read' ERR

main
