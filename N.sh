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

select_language() {
    while true; do
        clear
        echo "=== IDIOMA DO SISTEMA / SYSTEM LANGUAGE ==="
        echo "1) Português Brasileiro (pt_BR.UTF-8)"
        echo "2) English US (en_US.UTF-8)"
        read -p "Opção: " lang_opt
        case $lang_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
    esac
}

select_keyboard() {
    while true; do
        clear
        echo "=== LAYOUT DO TECLADO / KEYBOARD LAYOUT ==="
        echo "1) Português Brasileiro (br)"
        echo "2) English US (us)"
        read -p "Opção: " kb_opt
        case $kb_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_device_type() {
    while true; do
        clear
        echo "=== TIPO DE DISPOSITIVO / DEVICE TYPE ==="
        echo "1) Laptop (foco em economia de energia)"
        echo "2) Desktop (foco em desempenho máximo)"
        read -p "Opção: " device_opt
        case $device_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $device_opt in
        1) echo "laptop" > "$STATE_DIR/device_type" ;;
        2) echo "desktop" > "$STATE_DIR/device_type" ;;
    esac
}

select_filesystem() {
    while true; do
        clear
        echo "=== SISTEMA DE ARQUIVOS / FILESYSTEM ==="
        echo "1) ext4 (padrão, estável)"
        echo "2) btrfs (com snapshots e compressão automática)"
        read -p "Opção: " fs_opt
        case $fs_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $fs_opt in
        1) echo "ext4" > "$STATE_DIR/filesystem" ;;
        2) 
            echo "btrfs" > "$STATE_DIR/filesystem"
            # Compressão habilitada automaticamente para btrfs
            echo "yes" > "$STATE_DIR/compress"
            ;;
    esac
}

select_bootloader() {
    while true; do
        clear
        echo "=== BOOTLOADER ==="
        echo "1) systemd-boot (recomendado para UEFI)"
        echo "2) GRUB (compatível com BIOS e UEFI)"
        read -p "Opção: " bl_opt
        case $bl_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $bl_opt in
        1) echo "systemd-boot" > "$STATE_DIR/bootloader" ;;
        2) echo "grub" > "$STATE_DIR/bootloader" ;;
    esac
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
            1|2|3|4) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $swap_opt in
        1) echo "2" > "$STATE_DIR/swap" ;;
        2) echo "4" > "$STATE_DIR/swap" ;;
        3) echo "8" > "$STATE_DIR/swap" ;;
        4) echo "0" > "$STATE_DIR/swap" ;;
    esac
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
        echo "1) NVIDIA (drivers open-source por padrão)"
        echo "2) Intel/AMD (open source - drivers padrão)"
        read -p "Opção: " gpu_opt
        case $gpu_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $gpu_opt in
        1) 
            echo "nvidia" > "$STATE_DIR/gpu_driver"
            echo "yes" > "$STATE_DIR/unfree"
            # Drivers open NVIDIA habilitados automaticamente
            echo "yes" > "$STATE_DIR/nvidia_open"
            # Modesetting habilitado automaticamente (necessário para Wayland)
            echo "yes" > "$STATE_DIR/nvidia_modeset"
            clear
            if confirm "Habilitar power management para NVIDIA? (recomendado para laptops)"; then
                echo "yes" > "$STATE_DIR/nvidia_power"
            else
                echo "no" > "$STATE_DIR/nvidia_power"
            fi
            ;;
        2) 
            echo "intel-amd" > "$STATE_DIR/gpu_driver"
            echo "no" > "$STATE_DIR/unfree"
            echo "no" > "$STATE_DIR/nvidia_open"
            echo "no" > "$STATE_DIR/nvidia_modeset"
            echo "no" > "$STATE_DIR/nvidia_power"
            ;;
    esac
}

select_desktop() {
    while true; do
        clear
        echo "=== AMBIENTE DESKTOP / DESKTOP ENVIRONMENT ==="
        echo "1) Cosmic (minimal, Wayland nativo)"
        echo "2) GNOME (minimal, Wayland)"
        echo "3) KDE Plasma (minimal, Wayland)"
        echo "4) Nenhum (apenas terminal)"
        read -p "Opção: " de_opt
        case $de_opt in
            1|2|3|4) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_network_backend() {
    while true; do
        clear
        echo "=== BACKEND DE REDE SEM FIO / WIRELESS BACKEND ==="
        echo "1) iwd (mais leve, recomendado)"
        echo "2) wpa_supplicant (tradicional)"
        read -p "Opção: " net_opt
        case $net_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $net_opt in
        1) echo "iwd" > "$STATE_DIR/network_backend" ;;
        2) echo "wpa_supplicant" > "$STATE_DIR/network_backend" ;;
    esac
}

select_flakes() {
    clear
    echo "=== FLAKES ==="
    echo "Criar arquivo flake.nix de exemplo? (apenas exemplo, não será ativado)"
    if confirm "Criar flake.nix?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
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
            echo "Disco inválido / Invalid disk"
            sleep 2
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
            echo "Senhas não conferem ou vazias / Passwords do not match or empty"
        fi
    done
}

select_hostname() {
    clear
    read -p "Digite o nome do computador [nixos]: " hostname
    if [ -z "$hostname" ]; then
        echo "nixos" > "$STATE_DIR/hostname"
    else
        echo "$hostname" > "$STATE_DIR/hostname"
    fi
}

select_timezone() {
    while true; do
        clear
        echo "=== FUSO HORÁRIO / TIMEZONE ==="
        echo "1) America/Sao_Paulo"
        echo "2) America/New_York"
        read -p "Opção: " tz_opt
        case $tz_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $tz_opt in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) echo "America/New_York" > "$STATE_DIR/timezone" ;;
    esac
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
    
    # Compressão sempre habilitada para btrfs
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
        
        if [ "$fs" = "btrfs" ] && [ ! -d /mnt/home ]; then
            setup_btrfs_subvolumes
        else
            sudo mount /dev/mapper/cryptroot /mnt
        fi
    else
        if [ "$fs" = "btrfs" ] && [ ! -d /mnt/home ]; then
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
    
    # Backup do hardware-config original
    sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix.bak
    
    # Variáveis
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
    local trim=$(cat "$STATE_DIR/trim")
    local encryption=$(cat "$STATE_DIR/encryption")
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local nvidia_open=$(cat "$STATE_DIR/nvidia_open" 2>/dev/null || echo "no")
    local nvidia_modeset=$(cat "$STATE_DIR/nvidia_modeset" 2>/dev/null || echo "no")
    local nvidia_power=$(cat "$STATE_DIR/nvidia_power" 2>/dev/null || echo "no")
    local swap_size=$(cat "$STATE_DIR/swap")
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local compress=$(cat "$STATE_DIR/compress")
    local luks_uuid=$(cat "$STATE_DIR/luks_uuid" 2>/dev/null || echo "")
    local network_backend=$(cat "$STATE_DIR/network_backend")
    
    local config_file="/mnt/etc/nixos/configuration.nix"
    
    sudo tee "$config_file" > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Permitir software unfree (necessário para NVIDIA)
  $([ "$gpu_driver" = "nvidia" ] && echo 'nixpkgs.config.allowUnfree = true;')
  
  # Bootloader
  $([ "$bootloader" = "systemd-boot" ] && echo 'boot.loader.systemd-boot.enable = true;')
  $([ "$bootloader" = "grub" ] && [ "$boot_mode" = "uefi" ] && echo 'boot.loader.grub = { enable = true; efiSupport = true; device = "nodev"; };')
  $([ "$bootloader" = "grub" ] && [ "$boot_mode" = "bios" ] && echo 'boot.loader.grub = { enable = true; device = "'$disk'"; };')
  
  # Locale
  i18n.defaultLocale = "$lang";
  
  # Console
  console.keyMap = "$keyboard";
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Network
  networking.hostName = "$hostname";
  networking.networkmanager.enable = true;
EOF

    # Backend de rede sem fio
    if [ "$network_backend" = "iwd" ]; then
        cat >> "$config_file" << EOF
  networking.wireless.iwd.enable = true;
EOF
    else
        cat >> "$config_file" << EOF
  networking.wireless.enable = true;
  networking.wireless.networks = { }; # Configurar manualmente via wpa_passphrase
EOF
    fi

    # X11 (necessário para muitos aplicativos, mas usaremos Wayland como padrão)
    cat >> "$config_file" << EOF
  
  # X11 (necessário para compatibilidade)
  services.xserver.enable = true;
  services.xserver.xkb.layout = "$keyboard";
EOF

    # GPU Drivers
    cat >> "$config_file" << EOF
  
  # Graphics
  hardware.graphics.enable = true;
EOF

    # Configuração NVIDIA
    if [ "$gpu_driver" = "nvidia" ]; then
        cat >> "$config_file" << EOF
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = $([ "$nvidia_modeset" = "yes" ] && echo "true" || echo "false");
    powerManagement.enable = $([ "$nvidia_power" = "yes" ] && echo "true" || echo "false");
    open = $([ "$nvidia_open" = "yes" ] && echo "true" || echo "false");
    nvidiaSettings = true;
  };
EOF
    else
        cat >> "$config_file" << EOF
  services.xserver.videoDrivers = [ "modesetting" ];
  # Drivers Intel/AMD já inclusos no Mesa
EOF
    fi

    # PipeWire (habilitado automaticamente)
    cat >> "$config_file" << EOF
  
  # Audio (PipeWire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Bluetooth
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  # CUPS
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  # TRIM para SSD
  $([ "$trim" = "yes" ] && echo 'services.fstrim.enable = true;')
  
  # Otimizações por dispositivo
EOF

    if [ "$device_type" = "laptop" ]; then
        cat >> "$config_file" << EOF
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
EOF
    else
        cat >> "$config_file" << EOF
  powerManagement.cpuFreqGovernor = "performance";
EOF
    fi

    # Usuário
    cat >> "$config_file" << EOF
  
  # Usuário
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "$pass_hash";
    shell = pkgs.bash;
  };
  
  # Sudo sem senha para wheel
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

    # Swap
    if [ "$swap_size" != "0" ]; then
        cat >> "$config_file" << EOF
  
  # Swap file
  swapDevices = [ { device = "/.swapfile"; } ];
EOF
    fi

    # Criptografia
    if [ "$encryption" = "yes" ] && [ -n "$luks_uuid" ]; then
        cat >> "$config_file" << EOF
  
  # LUKS Encryption
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/$luks_uuid";
    preLVM = true;
  };
EOF
    fi

    # Configurações de compressão btrfs no filesystem
    if [ "$fs" = "btrfs" ] && [ "$compress" = "yes" ]; then
        cat >> "$config_file" << EOF
  
  # Opções de montagem com compressão para btrfs
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" ];
  };
  
  fileSystems."/home" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" ];
  };
  
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };
EOF
    fi

    # Desktop Environment
    cat >> "$config_file" << EOF
  
  # Desktop Environment
EOF

    case $desktop in
        cosmic)
            cat >> "$config_file" << EOF
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [ cosmic-edit ];
EOF
            ;;
        gnome)
            cat >> "$config_file" << EOF
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
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

    # Pacotes básicos (lista unificada)
    cat >> "$config_file" << EOF
  
  # Pacotes básicos
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
EOF

    # Adicionar pacotes específicos do desktop à mesma lista
    case $desktop in
        gnome)
            cat >> "$config_file" << EOF
    gnome-tweaks
    gnome-disk-utility
    gnome-software
EOF
            ;;
        plasma)
            cat >> "$config_file" << EOF
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
EOF
            ;;
        cosmic)
            cat >> "$config_file" << EOF
    cosmic-term
    cosmic-files
    cosmic-store
EOF
            ;;
    esac

    cat >> "$config_file" << EOF
  ];
  
  # Versão do sistema (usa a mais recente disponível)
  system.stateVersion = "25.11"; # Ajustado para compatibilidade
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
    echo "Para usar flakes, execute: nixos-rebuild switch --flake /mnt/etc/nixos#$hostname"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma/Language: $(cat "$STATE_DIR/lang")"
    echo "Teclado/Keyboard: $(cat "$STATE_DIR/keyboard")"
    echo "Fuso/Timezone: $(cat "$STATE_DIR/timezone")"
    echo "Hostname: $(cat "$STATE_DIR/hostname")"
    echo "Dispositivo/Device: $(cat "$STATE_DIR/device_type")"
    
    local swap=$(cat "$STATE_DIR/swap")
    if [ "$swap" = "0" ]; then
        echo "Swap: Sem swap"
    else
        echo "Swap: ${swap}GB"
    fi
    
    echo "Sistema de arquivos: $(cat "$STATE_DIR/filesystem")"
    [ "$(cat "$STATE_DIR/compress")" = "yes" ] && echo "Compressão btrfs: Sim (automático)"
    echo "Bootloader: $(cat "$STATE_DIR/bootloader")"
    echo "Desktop: $(cat "$STATE_DIR/desktop")"
    echo "Bluetooth: $(cat "$STATE_DIR/bluetooth")"
    echo "CUPS: $(cat "$STATE_DIR/cups")"
    echo "PipeWire: Sim (habilitado automaticamente)"
    echo "TRIM SSD: $(cat "$STATE_DIR/trim")"
    echo "Criptografia: $(cat "$STATE_DIR/encryption")"
    echo "GPU Driver: $(cat "$STATE_DIR/gpu_driver")"
    echo "Backend de rede: $(cat "$STATE_DIR/network_backend")"
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

check_dependencies() {
    local missing_deps=()
    
    for cmd in parted mkfs.fat mkfs.ext4 mkfs.btrfs cryptsetup fallocate mkpasswd; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Aviso: Alguns comandos podem não estar disponíveis: ${missing_deps[*]}"
        echo "O script tentará continuar, mas pode falhar se algum comando for necessário."
        sleep 3
    fi
}

main() {
    clear
    echo "=== INSTALADOR AUTOMÁTICO NIXOS ==="
    echo
    
    check_dependencies
    
    # Coletar todas as informações primeiro
    select_language
    select_keyboard
    select_timezone
    select_hostname
    select_device_type
    select_filesystem
    # Compressão é automática para btrfs, não precisa perguntar
    select_bootloader
    select_swap_size
    select_encryption
    select_gpu_drivers
    select_desktop
    select_network_backend
    select_bluetooth
    select_cups
    select_ssd_trim
    select_flakes
    detect_disk
    select_username
    
    show_summary
    
    # Executar instalação
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

# Tratamento de erros
set +e
trap 'echo "Erro detectado. Pressione Enter para continuar..."; read' ERR
set -e

main
