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
    echo "Selecione o idioma do sistema / Select system language:"
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) English US (en_US.UTF-8)"
    read -p "Opção: " lang_opt
    case $lang_opt in
        1) 
            echo "pt_BR.UTF-8" > "$STATE_DIR/lang"
            echo "pt_BR.UTF-8" > "$STATE_DIR/locale"
            ;;
        2) 
            echo "en_US.UTF-8" > "$STATE_DIR/lang"
            echo "en_US.UTF-8" > "$STATE_DIR/locale"
            ;;
        *) 
            echo "en_US.UTF-8" > "$STATE_DIR/lang"
            echo "en_US.UTF-8" > "$STATE_DIR/locale"
            ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado / Select keyboard layout:"
    echo "1) Português Brasileiro (br)"
    echo "2) English US (us)"
    read -p "Opção: " kb_opt
    case $kb_opt in
        1) 
            echo "br" > "$STATE_DIR/keyboard"
            echo "br" > "$STATE_DIR/xkb_layout"
            ;;
        2) 
            echo "us" > "$STATE_DIR/keyboard"
            echo "us" > "$STATE_DIR/xkb_layout"
            ;;
        *) 
            echo "us" > "$STATE_DIR/keyboard"
            echo "us" > "$STATE_DIR/xkb_layout"
            ;;
    esac
}

select_filesystem() {
    echo "Selecione o sistema de arquivos / Select filesystem:"
    echo "1) ext4 (padrão / default)"
    echo "2) btrfs (com suporte a snapshots)"
    read -p "Opção: " fs_opt
    case $fs_opt in
        1) echo "ext4" > "$STATE_DIR/filesystem" ;;
        2) echo "btrfs" > "$STATE_DIR/filesystem" ;;
        *) echo "ext4" > "$STATE_DIR/filesystem" ;;
    esac
}

select_bootloader() {
    echo "Selecione o bootloader / Select bootloader:"
    echo "1) systemd-boot (recomendado para UEFI)"
    echo "2) GRUB"
    echo "3) Detectar automaticamente"
    read -p "Opção: " bl_opt
    case $bl_opt in
        1) echo "systemd-boot" > "$STATE_DIR/bootloader" ;;
        2) echo "grub" > "$STATE_DIR/bootloader" ;;
        3) echo "auto" > "$STATE_DIR/bootloader" ;;
        *) echo "auto" > "$STATE_DIR/bootloader" ;;
    esac
}

select_swap_size() {
    echo "Selecione o tamanho do swap / Select swap size:"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) Sem swap / No swap"
    read -p "Opção: " swap_opt
    case $swap_opt in
        1) echo "2" > "$STATE_DIR/swap" ;;
        2) echo "4" > "$STATE_DIR/swap" ;;
        3) echo "8" > "$STATE_DIR/swap" ;;
        4) echo "0" > "$STATE_DIR/swap" ;;
        *) echo "2" > "$STATE_DIR/swap" ;;
    esac
}

select_encryption() {
    echo "Criptografar disco? / Encrypt disk?"
    echo "1) Sim (LUKS)"
    echo "2) Não"
    read -p "Opção: " enc_opt
    case $enc_opt in
        1) echo "yes" > "$STATE_DIR/encrypt" ;;
        2) echo "no" > "$STATE_DIR/encrypt" ;;
        *) echo "no" > "$STATE_DIR/encrypt" ;;
    esac
}

select_compression() {
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        echo "Habilitar compressão btrfs? / Enable btrfs compression?"
        echo "1) Sim (zstd)"
        echo "2) Não"
        read -p "Opção: " comp_opt
        case $comp_opt in
            1) echo "yes" > "$STATE_DIR/compress" ;;
            2) echo "no" > "$STATE_DIR/compress" ;;
            *) echo "no" > "$STATE_DIR/compress" ;;
        esac
    else
        echo "no" > "$STATE_DIR/compress"
    fi
}

select_desktop() {
    echo "Selecione o ambiente desktop / Select desktop environment:"
    echo "1) Cosmic (minimal)"
    echo "2) GNOME (minimal)"
    echo "3) KDE Plasma (minimal)"
    echo "4) Nenhum (apenas terminal)"
    read -p "Opção: " de_opt
    case $de_opt in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_network_backend() {
    echo "Selecione o backend de rede Wi-Fi / Select Wi-Fi backend:"
    echo "1) iwd (recomendado)"
    echo "2) wpa_supplicant"
    echo "3) Ambos"
    read -p "Opção: " net_opt
    case $net_opt in
        1) echo "iwd" > "$STATE_DIR/wifi_backend" ;;
        2) echo "wpa_supplicant" > "$STATE_DIR/wifi_backend" ;;
        3) echo "both" > "$STATE_DIR/wifi_backend" ;;
        *) echo "iwd" > "$STATE_DIR/wifi_backend" ;;
    esac
}

select_flakes() {
    echo "Habilitar flakes? / Enable flakes?"
    echo "1) Sim (recomendado)"
    echo "2) Não (configuração tradicional)"
    read -p "Opção: " flake_opt
    case $flake_opt in
        1) echo "yes" > "$STATE_DIR/flakes" ;;
        2) echo "no" > "$STATE_DIR/flakes" ;;
        *) echo "yes" > "$STATE_DIR/flakes" ;;
    esac
}

select_bluetooth() {
    if confirm "Habilitar Bluetooth? / Enable Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    if confirm "Habilitar suporte a impressão (CUPS)? / Enable printing support (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_pipewire() {
    if confirm "Habilitar PipeWire (áudio)? / Enable PipeWire (audio)?"; then
        echo "yes" > "$STATE_DIR/pipewire"
    else
        echo "no" > "$STATE_DIR/pipewire"
    fi
}

select_ssd_trim() {
    if confirm "Habilitar TRIM para SSD? / Enable TRIM for SSD?"; then
        echo "yes" > "$STATE_DIR/trim"
    else
        echo "no" > "$STATE_DIR/trim"
    fi
}

detect_disk() {
    echo "Discos disponíveis / Available disks:"
    lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda, nvme0n1, vda): " disk_name
    echo "/dev/$disk_name" > "$STATE_DIR/disk"
}

select_username() {
    read -p "Digite o nome do usuário / Enter username: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Digite a senha / Enter password: " userpass
    echo
    read -s -p "Confirme a senha / Confirm password: " userpass2
    echo
    if [ "$userpass" != "$userpass2" ]; then
        echo "Senhas não conferem / Passwords do not match!"
        exit 1
    fi
    echo "$userpass" > "$STATE_DIR/userpass"
}

select_hostname() {
    read -p "Digite o nome do computador / Enter hostname [renan-desktop]: " hostname
    if [ -z "$hostname" ]; then
        echo "renan-desktop" > "$STATE_DIR/hostname"
    else
        echo "$hostname" > "$STATE_DIR/hostname"
    fi
}

select_timezone() {
    echo "Selecione o fuso horário / Select timezone:"
    echo "1) America/Sao_Paulo"
    echo "2) America/New_York"
    echo "3) Europe/Lisbon"
    echo "4) Outro / Other"
    read -p "Opção: " tz_opt
    case $tz_opt in
        1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
        2) echo "America/New_York" > "$STATE_DIR/timezone" ;;
        3) echo "Europe/Lisbon" > "$STATE_DIR/timezone" ;;
        4) 
            read -p "Digite o fuso horário (ex: America/Sao_Paulo): " custom_tz
            echo "$custom_tz" > "$STATE_DIR/timezone"
            ;;
        *) echo "America/Sao_Paulo" > "$STATE_DIR/timezone" ;;
    esac
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma / Language: $(cat $STATE_DIR/lang 2>/dev/null)"
    echo "Teclado / Keyboard: $(cat $STATE_DIR/keyboard 2>/dev/null)"
    echo "Disco / Disk: $(cat $STATE_DIR/disk 2>/dev/null)"
    echo "Sistema de arquivos / Filesystem: $(cat $STATE_DIR/filesystem 2>/dev/null)"
    echo "Bootloader: $(cat $STATE_DIR/bootloader 2>/dev/null)"
    echo "Criptografia / Encryption: $(cat $STATE_DIR/encrypt 2>/dev/null)"
    echo "Compressão btrfs: $(cat $STATE_DIR/compress 2>/dev/null)"
    echo "Desktop: $(case $(cat $STATE_DIR/desktop 2>/dev/null) in cosmic) echo "Cosmic (minimal)";; gnome) echo "GNOME (minimal)";; plasma) echo "KDE Plasma (minimal)";; none) echo "Nenhum / None";; esac)"
    echo "Swap: $(cat $STATE_DIR/swap 2>/dev/null | sed 's/0/Sem swap\/No swap/g') GB"
    echo "Wi-Fi backend: $(cat $STATE_DIR/wifi_backend 2>/dev/null)"
    echo "Flakes: $(cat $STATE_DIR/flakes 2>/dev/null)"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth 2>/dev/null)"
    echo "CUPS: $(cat $STATE_DIR/cups 2>/dev/null)"
    echo "PipeWire: $(cat $STATE_DIR/pipewire 2>/dev/null)"
    echo "TRIM: $(cat $STATE_DIR/trim 2>/dev/null)"
    echo "Usuário / Username: $(cat $STATE_DIR/username 2>/dev/null)"
    echo "Hostname: $(cat $STATE_DIR/hostname 2>/dev/null)"
    echo "Fuso horário / Timezone: $(cat $STATE_DIR/timezone 2>/dev/null)"
    echo "============================================"
    echo
    if ! confirm "Continuar com a instalação? / Continue with installation?"; then
        echo "Instalação cancelada / Installation canceled."
        exit 0
    fi
}

force_unmount_all() {
    local disk=$(cat "$STATE_DIR/disk")
    local disk_base=$(basename "$disk")
    
    echo "Forçando desmontagem de todas as partições de $disk..."
    
    for partition in $(lsblk -l -o NAME,MOUNTPOINT | grep "^$disk_base" | awk '{print $1}' | grep -v "^$disk_base$"); do
        if mount | grep -q "/dev/$partition"; then
            echo "Desmontando /dev/$partition..."
            sudo umount -l "/dev/$partition" 2>/dev/null || true
        fi
    done
    
    for partition in $(swapon --show | grep "$disk" | awk '{print $1}'); do
        echo "Desativando swap em $partition..."
        sudo swapoff "$partition" 2>/dev/null || true
    done
    
    if command -v vgchange &>/dev/null; then
        sudo vgchange -an 2>/dev/null || true
    fi
    
    sleep 3
}

refresh_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Atualizando tabela de partições / Refreshing partition table..."
    
    sudo partprobe "$disk" 2>/dev/null || true
    sudo blockdev --rereadpt "$disk" 2>/dev/null || true
    sudo udevadm settle 2>/dev/null || true
    
    sleep 3
}

wipe_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "ATENÇÃO: O disco $disk será completamente apagado!"
    echo "Todos os dados serão perdidos / All data will be lost!"
    
    if confirm "Tem certeza que deseja continuar? / Are you sure you want to continue?"; then
        force_unmount_all
        
        echo "Apagando assinaturas do disco / Wiping disk signatures..."
        sudo wipefs -a -f "$disk" 2>/dev/null || true
        
        echo "Zerando início do disco / Zeroing beginning of disk..."
        sudo dd if=/dev/zero of="$disk" bs=1M count=100 status=progress 2>/dev/null || true
        
        sudo parted -s "$disk" mklabel gpt 2>/dev/null || true
        sudo parted -s "$disk" mklabel msdos 2>/dev/null || true
        
        refresh_partitions
        
        echo "Disco limpo com sucesso / Disk successfully wiped"
    else
        echo "Operação cancelada / Operation canceled"
        exit 1
    fi
}

partition_disk_ext4() {
    local disk=$(cat "$STATE_DIR/disk")
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel gpt
        sudo parted -s $disk mkpart primary fat32 1MB 512MB
        sudo parted -s $disk set 1 esp on
        sudo parted -s $disk mkpart primary ext4 512MB 100%
        
        refresh_partitions
        
        if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
            echo "Configurando criptografia LUKS..."
            sudo cryptsetup luksFormat --type luks2 ${disk}2
            sudo cryptsetup open ${disk}2 cryptroot
            sudo mkfs.ext4 -F /dev/mapper/cryptroot -L NIXROOT
        else
            sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
        fi
        
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel msdos
        sudo parted -s $disk mkpart primary ext4 1MB 512MB
        sudo parted -s $disk set 1 boot on
        sudo parted -s $disk mkpart primary ext4 512MB 100%
        
        refresh_partitions
        
        if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
            echo "Configurando criptografia LUKS..."
            sudo cryptsetup luksFormat --type luks2 ${disk}2
            sudo cryptsetup open ${disk}2 cryptroot
            sudo mkfs.ext4 -F /dev/mapper/cryptroot -L NIXROOT
        else
            sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
        fi
        
        sudo mkfs.ext4 -F ${disk}1 -L NIXBOOT
    fi
}

partition_disk_btrfs() {
    local disk=$(cat "$STATE_DIR/disk")
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel gpt
        sudo parted -s $disk mkpart primary fat32 1MB 512MB
        sudo parted -s $disk set 1 esp on
        sudo parted -s $disk mkpart primary btrfs 512MB 100%
        
        refresh_partitions
        
        if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
            echo "Configurando criptografia LUKS..."
            sudo cryptsetup luksFormat --type luks2 ${disk}2
            sudo cryptsetup open ${disk}2 cryptroot
            sudo mkfs.btrfs -f /dev/mapper/cryptroot
        else
            sudo mkfs.btrfs -f ${disk}2
        fi
        
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel msdos
        sudo parted -s $disk mkpart primary btrfs 1MB 512MB
        sudo parted -s $disk set 1 boot on
        sudo parted -s $disk mkpart primary btrfs 512MB 100%
        
        refresh_partitions
        
        if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
            echo "Configurando criptografia LUKS..."
            sudo cryptsetup luksFormat --type luks2 ${disk}2
            sudo cryptsetup open ${disk}2 cryptroot
            sudo mkfs.btrfs -f /dev/mapper/cryptroot
        else
            sudo mkfs.btrfs -f ${disk}2
        fi
        
        sudo mkfs.ext4 -F ${disk}1 -L NIXBOOT
    fi
    
    # Criar subvolumes btrfs
    local root_dev="/dev/disk/by-label/NIXROOT"
    if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
        root_dev="/dev/mapper/cryptroot"
    fi
    
    sudo mount $root_dev /mnt
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    sudo btrfs subvolume create /mnt/@log
    sudo umount /mnt
}

partition_disk() {
    local fs=$(cat "$STATE_DIR/filesystem")
    
    case $fs in
        ext4) partition_disk_ext4 ;;
        btrfs) partition_disk_btrfs ;;
        *) partition_disk_ext4 ;;
    esac
    
    refresh_partitions
}

mount_partitions() {
    local fs=$(cat "$STATE_DIR/filesystem")
    local encrypt=$(cat "$STATE_DIR/encrypt")
    local compress=$(cat "$STATE_DIR/compress")
    
    echo "Montando partições / Mounting partitions..."
    
    if mount | grep -q "/mnt"; then
        sudo umount -l /mnt 2>/dev/null || true
        sudo umount -l /mnt/boot 2>/dev/null || true
    fi
    
    if [ "$encrypt" = "yes" ] && [ ! -e /dev/mapper/cryptroot ]; then
        echo "Abrindo partição criptografada..."
        sudo cryptsetup open /dev/disk/by-label/NIXROOT cryptroot
    fi
    
    local root_dev="/dev/disk/by-label/NIXROOT"
    local boot_dev="/dev/disk/by-label/NIXBOOT"
    
    if [ "$encrypt" = "yes" ]; then
        root_dev="/dev/mapper/cryptroot"
    fi
    
    if [ "$fs" = "btrfs" ]; then
        local mount_opts="subvol=@"
        [ "$compress" = "yes" ] && mount_opts="$mount_opts,compress=zstd"
        
        sudo mount -o $mount_opts $root_dev /mnt
        
        sudo mkdir -p /mnt/{home,nix,var/log,boot}
        
        local home_opts="subvol=@home"
        [ "$compress" = "yes" ] && home_opts="$home_opts,compress=zstd"
        sudo mount -o $home_opts $root_dev /mnt/home
        
        local nix_opts="subvol=@nix,noatime"
        [ "$compress" = "yes" ] && nix_opts="$nix_opts,compress=zstd"
        sudo mount -o $nix_opts $root_dev /mnt/nix
        
        local log_opts="subvol=@log"
        [ "$compress" = "yes" ] && log_opts="$log_opts,compress=zstd"
        sudo mount -o $log_opts $root_dev /mnt/var/log
    else
        sudo mount $root_dev /mnt
        sudo mkdir -p /mnt/boot
    fi
    
    sudo mount $boot_dev /mnt/boot
    
    echo "Partições montadas com sucesso / Partitions mounted successfully"
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    
    if [ "$swap_size" != "0" ]; then
        echo "Criando arquivo swap de ${swap_size}GB..."
        
        if [ -f /mnt/.swapfile ]; then
            sudo rm -f /mnt/.swapfile
        fi
        
        sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$swap_size status=progress
        sudo chmod 600 /mnt/.swapfile
        sudo mkswap /mnt/.swapfile
        sudo swapon /mnt/.swapfile
        
        echo "Swap criado e ativado / Swap created and activated"
    else
        echo "Nenhum swap será criado / No swap will be created"
    fi
}

generate_configs() {
    echo "Gerando arquivos de configuração / Generating configuration files..."
    
    sudo mkdir -p /mnt/etc/nixos
    
    local lang=$(cat "$STATE_DIR/lang")
    local locale=$(cat "$STATE_DIR/locale")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local xkb_layout=$(cat "$STATE_DIR/xkb_layout")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local pipewire=$(cat "$STATE_DIR/pipewire")
    local trim=$(cat "$STATE_DIR/trim")
    local username=$(cat "$STATE_DIR/username")
    local userpass=$(cat "$STATE_DIR/userpass")
    local swap_size=$(cat "$STATE_DIR/swap")
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    local encrypt=$(cat "$STATE_DIR/encrypt")
    local compress=$(cat "$STATE_DIR/compress")
    local wifi_backend=$(cat "$STATE_DIR/wifi_backend")
    local flakes=$(cat "$STATE_DIR/flakes")
    local hostname=$(cat "$STATE_DIR/hostname")
    local timezone=$(cat "$STATE_DIR/timezone")
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    # Gerar hardware-configuration.nix
    sudo nixos-generate-config --root /mnt
    
    # Configurar hardware-configuration.nix para usar labels e opções específicas
    if [ "$encrypt" = "yes" ]; then
        sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/mapper/cryptroot|g" /mnt/etc/nixos/hardware-configuration.nix
        sudo tee -a /mnt/etc/nixos/hardware-configuration.nix > /dev/null << EOF

boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/$(sudo blkid -s UUID -o value ${disk}2)";
EOF
    else
        sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g" /mnt/etc/nixos/hardware-configuration.nix
    fi
    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g" /mnt/etc/nixos/hardware-configuration.nix
    
    if [ "$fs" = "btrfs" ]; then
        sudo sed -i '/fsType = "btrfs";/a \ \ \ \ options = [ "subvol=@" ];' /mnt/etc/nixos/hardware-configuration.nix
    fi
    
    # Criar configuration.nix
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  $([ "$flakes" = "yes" ] && echo 'nix.settings.experimental-features = [ "nix-command" "flakes" ];')

  # Bootloader
  $([ "$boot_mode" = "uefi" ] && [ "$bootloader" = "systemd-boot" ] && echo 'boot.loader.systemd-boot.enable = true;')
  $([ "$boot_mode" = "uefi" ] && [ "$bootloader" = "grub" ] && echo 'boot.loader.grub = { enable = true; efiSupport = true; device = "nodev"; };')
  $([ "$boot_mode" = "bios" ] && echo 'boot.loader.grub = { enable = true; device = "'$disk'"; };')

  $([ "$boot_mode" = "uefi" ] && [ "$bootloader" = "auto" ] && echo 'boot.loader.systemd-boot.enable = true;')

  # Filesystem options
  $([ "$fs" = "btrfs" ] && echo 'boot.supportedFilesystems = [ "btrfs" ];')
  $([ "$trim" = "yes" ] && echo 'services.fstrim.enable = true;')

  # Locale
  i18n.defaultLocale = "$lang";
  i18n.extraLocaleSettings = {
    LC_TIME = "$locale";
    LC_MONETARY = "$locale";
    LC_PAPER = "$locale";
    LC_MEASUREMENT = "$locale";
  };
  console.keyMap = "$keyboard";
  
  # X11 keyboard
  services.xserver = {
    enable = true;
    xkb.layout = "$xkb_layout";
  };
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Network
  networking.networkmanager.enable = true;
  networking.hostName = "$hostname";
  $([ "$wifi_backend" = "iwd" ] || [ "$wifi_backend" = "both" ] && echo 'networking.wireless.iwd.enable = true;')
  $([ "$wifi_backend" = "wpa_supplicant" ] || [ "$wifi_backend" = "both" ] && echo 'networking.wireless.enable = true;')
  
  # Swap
  $([ "$swap_size" != "0" ] && echo 'swapDevices = [{ device = "/.swapfile"; }];')
  
  # Audio
  $([ "$pipewire" = "yes" ] && echo '
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };')
  
  # Bluetooth
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  # Printing
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  # User
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "$pass_hash";
    shell = pkgs.bash;
  };
  
  security.sudo.extraRules = [{
    groups = [ "wheel" ];
    commands = [{
      command = "ALL";
      options = [ "SETENV" "NOPASSWD" ];
    }];
  }];
  
  # Desktop Environments (minimal)
  $([ "$desktop" = "cosmic" ] && echo '
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
    cosmic-screenshot
    cosmic-workspaces-epoch
  ];')
  
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
    gnome-software
    gnome-initial-setup
    simple-scan
    yelp
    gnome-clocks
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-calendar
  ];')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    elisa
    gwenview
    okular
    kate
    khelpcenter
    konsole
    kwrited
    ark
    dolphin
    kdenlive
    kate
    kcalc
    kmail
    kontact
    korganizer
    ksystemlog
    kwalletmanager
    spectacle
  ];')
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    firefox
    fastfetch
    neovim
    git
    curl
    wget
    htop
    $([ "$fs" = "btrfs" ] && echo "btrfs-progs")
  ];
  
  system.stateVersion = "25.11";
}
EOF

    # Criar flake.nix se solicitado
    if [ "$flakes" = "yes" ]; then
        sudo tee /mnt/etc/nixos/flake.nix > /dev/null << EOF
{
  description = "$hostname NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }@inputs: {
    nixosConfigurations.$hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        {
          nix.registry.nixpkgs.flake = nixpkgs;
          nixpkgs.config.allowUnfree = true;
        }
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
EOF
    fi
    
    echo "Arquivos de configuração gerados com sucesso / Configuration files generated successfully"
}

install_system() {
    cd /mnt
    
    if [ "$(cat "$STATE_DIR/flakes")" = "yes" ] && [ -f /mnt/etc/nixos/flake.nix ]; then
        echo "Instalando com flakes / Installing with flakes..."
        sudo nixos-install --flake /mnt/etc/nixos#$hostname --no-root-passwd
    else
        echo "Instalando com configuração tradicional / Installing with traditional configuration..."
        sudo nixos-install --no-root-passwd
    fi
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 / NIXOS 25.11 INSTALLER ==="
    echo
    
    select_language
    select_keyboard
    select_filesystem
    select_bootloader
    select_swap_size
    select_encryption
    select_compression
    select_desktop
    select_network_backend
    select_flakes
    select_bluetooth
    select_cups
    select_pipewire
    select_ssd_trim
    detect_disk
    select_username
    select_hostname
    select_timezone
    
    show_summary
    
    partition_disk
    mount_partitions
    create_swap
    generate_configs
    
    if confirm "Iniciar instalação do NixOS? / Start NixOS installation?"; then
        install_system
        echo "Instalação concluída! Reinicie o sistema. / Installation complete! Reboot the system."
        echo "Digite 'reboot' para reiniciar. / Type 'reboot' to restart."
        echo ""
        echo "Após reiniciar, faça login com o usuário $username"
        echo "After reboot, login with user $username"
    else
        echo "Instalação cancelada / Installation canceled."
        exit 1
    fi
}

main
