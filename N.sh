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
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $lang_opt in
        1) 
            echo "pt_BR.UTF-8" > "$STATE_DIR/lang"
            echo "pt_BR.UTF-8" > "$STATE_DIR/locale"
            ;;
        2) 
            echo "en_US.UTF-8" > "$STATE_DIR/lang"
            echo "en_US.UTF-8" > "$STATE_DIR/locale"
            ;;
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
        1) 
            echo "br" > "$STATE_DIR/keyboard"
            echo "br" > "$STATE_DIR/xkb_layout"
            ;;
        2) 
            echo "us" > "$STATE_DIR/keyboard"
            echo "us" > "$STATE_DIR/xkb_layout"
            ;;
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
        echo "1) ext4 (padrão)"
        echo "2) btrfs (com suporte a snapshots)"
        read -p "Opção: " fs_opt
        case $fs_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $fs_opt in
        1) echo "ext4" > "$STATE_DIR/filesystem" ;;
        2) echo "btrfs" > "$STATE_DIR/filesystem" ;;
    esac
}

select_bootloader() {
    while true; do
        clear
        echo "=== BOOTLOADER ==="
        echo "1) systemd-boot (recomendado para UEFI)"
        echo "2) GRUB (para BIOS/Legacy ou UEFI)"
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
        echo "yes" > "$STATE_DIR/encrypt"
    else
        echo "no" > "$STATE_DIR/encrypt"
    fi
}

select_compression() {
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        clear
        echo "=== COMPRESSÃO BTRFS ==="
        if confirm "Habilitar compressão btrfs (zstd)?"; then
            echo "yes" > "$STATE_DIR/compress"
        else
            echo "no" > "$STATE_DIR/compress"
        fi
    else
        echo "no" > "$STATE_DIR/compress"
    fi
}

select_gpu_drivers() {
    while true; do
        clear
        echo "=== DRIVERS DE GPU / GPU DRIVERS ==="
        echo "1) NVIDIA (proprietário)"
        echo "2) Intel/AMD (open source)"
        read -p "Opção: " gpu_opt
        case $gpu_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $gpu_opt in
        1) 
            echo "nvidia" > "$STATE_DIR/gpu_driver"
            clear
            if confirm "Usar módulos open-source da NVIDIA (Turing+)?"; then
                echo "yes" > "$STATE_DIR/nvidia_open"
            else
                echo "no" > "$STATE_DIR/nvidia_open"
            fi
            clear
            if confirm "Habilitar modesetting (recomendado para Wayland)?"; then
                echo "yes" > "$STATE_DIR/nvidia_modeset"
            else
                echo "no" > "$STATE_DIR/nvidia_modeset"
            fi
            ;;
        2) 
            echo "intel-amd" > "$STATE_DIR/gpu_driver"
            echo "no" > "$STATE_DIR/nvidia_open"
            echo "no" > "$STATE_DIR/nvidia_modeset"
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
        echo "=== BACKEND DE REDE WI-FI / WI-FI BACKEND ==="
        echo "1) iwd (recomendado)"
        echo "2) wpa_supplicant (tradicional)"
        read -p "Opção: " net_opt
        case $net_opt in
            1|2) break ;;
            *) echo "Opção inválida / Invalid option"; sleep 2 ;;
        esac
    done
    
    case $net_opt in
        1) echo "iwd" > "$STATE_DIR/wifi_backend" ;;
        2) echo "wpa_supplicant" > "$STATE_DIR/wifi_backend" ;;
    esac
}

select_flakes() {
    clear
    echo "=== FLAKES ==="
    if confirm "Criar arquivo flake.nix (recomendado, não será executado agora)?"; then
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

select_pipewire() {
    clear
    echo "=== ÁUDIO (PIPEWIRE) ==="
    if confirm "Habilitar PipeWire (recomendado)?"; then
        echo "yes" > "$STATE_DIR/pipewire"
    else
        echo "no" > "$STATE_DIR/pipewire"
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
            echo "$userpass" > "$STATE_DIR/userpass"
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

check_disk_has_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    local partitions=$(lsblk -l -o NAME,TYPE | grep "^$(basename $disk)[0-9]" | wc -l)
    [ $partitions -gt 0 ]
}

check_disk_mounted() {
    local disk=$(cat "$STATE_DIR/disk")
    mount | grep -q "$disk"
}

check_disk_swap() {
    local disk=$(cat "$STATE_DIR/disk")
    swapon --show | grep -q "$disk"
}

handle_busy_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo ""
    echo "=================================================="
    echo "ATENÇÃO: O disco $disk está em uso!"
    echo "WARNING: Disk $disk is in use!"
    echo "=================================================="
    echo ""
    
    if check_disk_mounted; then
        echo "Partições montadas detectadas / Mounted partitions detected:"
        mount | grep "$disk"
        echo ""
        if confirm "Tentar desmontar automaticamente? / Try to unmount automatically?"; then
            for part in $(mount | grep "$disk" | awk '{print $1}'); do
                echo "Desmontando $part..."
                sudo umount -l $part 2>/dev/null || true
            done
            sleep 2
        fi
    fi
    
    if check_disk_swap; then
        echo "Swap ativo detectado / Active swap detected"
        if confirm "Desativar swap automaticamente? / Disable swap automatically?"; then
            for part in $(swapon --show | grep "$disk" | awk '{print $1}'); do
                echo "Desativando swap em $part..."
                sudo swapoff $part 2>/dev/null || true
            done
            sleep 2
        fi
    fi
    
    if check_disk_has_partitions; then
        echo ""
        echo "O cfdisk será aberto para você remover as partições manualmente."
        echo "cfdisk will be opened for you to manually remove the partitions."
        echo ""
        echo "INSTRUÇÕES / INSTRUCTIONS:"
        echo "1) Use as setas para selecionar uma partição / Use arrows to select a partition"
        echo "2) Pressione 'Delete' para remover / Press 'Delete' to remove"
        echo "3) Repita para todas as partições / Repeat for all partitions"
        echo "4) Pressione 'Write' para salvar / Press 'Write' to save"
        echo "5) Pressione 'Quit' para sair / Press 'Quit' to exit"
        echo ""
        read -p "Pressione Enter para abrir o cfdisk... / Press Enter to open cfdisk..."
        
        sudo cfdisk $disk
        
        echo "Aguardando o kernel reconhecer as mudanças..."
        sudo partprobe $disk 2>/dev/null || true
        sleep 3
        sudo udevadm settle
        sleep 2
        
        if check_disk_has_partitions; then
            echo ""
            echo "AVISO: Ainda existem partições no disco."
            echo "WARNING: There are still partitions on the disk."
            if ! confirm "Continuar mesmo assim? (pode causar erros) / Continue anyway? (may cause errors)"; then
                echo "Instalação cancelada / Installation canceled"
                exit 1
            fi
        fi
    fi
}

wait_for_partitions() {
    echo "Aguardando partições ficarem disponíveis..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [ -e /dev/disk/by-label/NIXBOOT ] && [ -e /dev/disk/by-label/NIXROOT ]; then
            echo "Partições encontradas!"
            return 0
        fi
        echo "Tentativa $attempt/$max_attempts..."
        sudo partprobe 2>/dev/null || true
        sudo udevadm settle
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "AVISO: Partições não encontradas após formatação"
    ls -la /dev/disk/by-label/ 2>/dev/null || echo "Nenhuma partição encontrada"
    return 1
}

partition_disk_ext4() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Criando novas partições em $disk..."
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel gpt
        sudo parted -s $disk mkpart primary fat32 1MB 512MB
        sudo parted -s $disk set 1 esp on
        sudo parted -s $disk mkpart primary ext4 512MB 100%
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel msdos
        sudo parted -s $disk mkpart primary ext4 1MB 512MB
        sudo parted -s $disk set 1 boot on
        sudo parted -s $disk mkpart primary ext4 512MB 100%
    fi
    
    sudo partprobe $disk
    sudo udevadm settle
    sleep 3
    
    if [ -d /sys/firmware/efi ]; then
        echo "Formatando partição EFI..."
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
    else
        echo "Formatando partição boot..."
        sudo mkfs.ext4 -F ${disk}1 -L NIXBOOT
    fi
    
    if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
        echo "Configurando criptografia LUKS em ${disk}2..."
        sudo cryptsetup luksFormat --type luks2 ${disk}2
        sudo cryptsetup open ${disk}2 cryptroot
        sudo mkfs.ext4 -F /dev/mapper/cryptroot -L NIXROOT
    else
        echo "Formatando partição root..."
        sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
    fi
    
    sudo partprobe $disk
    sudo udevadm settle
    sleep 3
}

partition_disk_btrfs() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Criando novas partições em $disk..."
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel gpt
        sudo parted -s $disk mkpart primary fat32 1MB 512MB
        sudo parted -s $disk set 1 esp on
        sudo parted -s $disk mkpart primary btrfs 512MB 100%
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted -s $disk mklabel msdos
        sudo parted -s $disk mkpart primary btrfs 1MB 512MB
        sudo parted -s $disk set 1 boot on
        sudo parted -s $disk mkpart primary btrfs 512MB 100%
    fi
    
    sudo partprobe $disk
    sudo udevadm settle
    sleep 3
    
    if [ -d /sys/firmware/efi ]; then
        echo "Formatando partição EFI..."
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
    else
        echo "Formatando partição boot..."
        sudo mkfs.ext4 -F ${disk}1 -L NIXBOOT
    fi
    
    if [ "$(cat "$STATE_DIR/encrypt")" = "yes" ]; then
        echo "Configurando criptografia LUKS em ${disk}2..."
        sudo cryptsetup luksFormat --type luks2 ${disk}2
        sudo cryptsetup open ${disk}2 cryptroot
        sudo mkfs.btrfs -f /dev/mapper/cryptroot
        local root_dev="/dev/mapper/cryptroot"
    else
        echo "Formatando partição root como btrfs..."
        sudo mkfs.btrfs -f ${disk}2
        local root_dev="${disk}2"
    fi
    
    sudo partprobe $disk
    sudo udevadm settle
    sleep 3
    
    echo "Criando subvolumes btrfs..."
    sudo mount $root_dev /mnt
    
    sudo btrfs subvolume create /mnt/@
    sudo btrfs subvolume create /mnt/@home
    sudo btrfs subvolume create /mnt/@nix
    sudo btrfs subvolume create /mnt/@log
    
    sudo umount /mnt
    
    sudo e2label ${disk}1 NIXBOOT 2>/dev/null || sudo fatlabel ${disk}1 NIXBOOT
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    echo "Verificando se o disco $disk está pronto para particionamento..."
    
    if check_disk_mounted || check_disk_swap || check_disk_has_partitions; then
        handle_busy_disk
    fi
    
    echo "Iniciando particionamento automático..."
    
    case $fs in
        ext4) partition_disk_ext4 ;;
        btrfs) partition_disk_btrfs ;;
    esac
    
    wait_for_partitions || {
        echo "ERRO: Falha ao criar partições"
        exit 1
    }
    
    echo "Particionamento concluído com sucesso!"
}

mount_partitions() {
    local fs=$(cat "$STATE_DIR/filesystem")
    local encrypt=$(cat "$STATE_DIR/encrypt")
    local compress=$(cat "$STATE_DIR/compress")
    
    echo "Montando partições..."
    
    if mount | grep -q "/mnt"; then
        echo "Desmontando /mnt existente..."
        sudo umount -l /mnt 2>/dev/null || true
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
    
    for i in {1..5}; do
        if [ -e $root_dev ] && [ -e $boot_dev ]; then
            break
        fi
        echo "Aguardando partições... (tentativa $i/5)"
        sudo partprobe 2>/dev/null || true
        sudo udevadm settle
        sleep 2
    done
    
    if [ ! -e $root_dev ] || [ ! -e $boot_dev ]; then
        echo "ERRO: Partições não encontradas:"
        ls -la /dev/disk/by-label/ 2>/dev/null || echo "Nenhuma partição com label encontrada"
        exit 1
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
    
    echo "Partições montadas:"
    df -h /mnt /mnt/boot 2>/dev/null || mount | grep "/mnt"
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
        
        echo "Swap criado e ativado"
    else
        echo "Nenhum swap será criado"
    fi
}

generate_configs() {
    echo "Gerando arquivos de configuração..."
    
    sudo mkdir -p /mnt/etc/nixos
    
    local lang=$(cat "$STATE_DIR/lang")
    local locale=$(cat "$STATE_DIR/locale")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local xkb_layout=$(cat "$STATE_DIR/xkb_layout")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local device_type=$(cat "$STATE_DIR/device_type")
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
    local gpu_driver=$(cat "$STATE_DIR/gpu_driver")
    local nvidia_open=$(cat "$STATE_DIR/nvidia_open")
    local nvidia_modeset=$(cat "$STATE_DIR/nvidia_modeset")
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    sudo nixos-generate-config --root /mnt
    
    if [ "$encrypt" = "yes" ]; then
        sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/mapper/cryptroot|g" /mnt/etc/nixos/hardware-configuration.nix
        sudo tee -a /mnt/etc/nixos/hardware-configuration.nix > /dev/null << EOF

boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/$(sudo blkid -s UUID -o value ${disk}2)";
EOF
    else
        sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g" /mnt/etc/nixos/hardware-configuration.nix
    fi
    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g" /mnt/etc/nixos/hardware-configuration.nix
    
    if [ "$fs" = "btrfs" ] && [ "$compress" = "yes" ]; then
        sudo sed -i '/fsType = "btrfs";/a \ \ \ \ options = [ "subvol=@" "compress=zstd" ];' /mnt/etc/nixos/hardware-configuration.nix
    elif [ "$fs" = "btrfs" ]; then
        sudo sed -i '/fsType = "btrfs";/a \ \ \ \ options = [ "subvol=@" ];' /mnt/etc/nixos/hardware-configuration.nix
    fi
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.config.allowUnfree = true;
  
  $([ "$flakes" = "yes" ] && echo 'nix.settings.experimental-features = [ "nix-command" "flakes" ];')
  
  $([ "$device_type" = "laptop" ] && echo '
  powerManagement.cpuFreqGovernor = "powersave";
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };')
  
  $([ "$device_type" = "desktop" ] && echo '
  powerManagement.cpuFreqGovernor = "performance";
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    charger = {
      governor = "performance";
      turbo = "always";
    };
  };')

  $([ "$boot_mode" = "uefi" ] && [ "$bootloader" = "systemd-boot" ] && echo 'boot.loader.systemd-boot.enable = true;')
  $([ "$boot_mode" = "uefi" ] && [ "$bootloader" = "grub" ] && echo 'boot.loader.grub = { enable = true; efiSupport = true; device = "nodev"; };')
  $([ "$boot_mode" = "bios" ] && echo 'boot.loader.grub = { enable = true; device = "'$disk'"; };')

  $([ "$fs" = "btrfs" ] && echo 'boot.supportedFilesystems = [ "btrfs" ];')
  $([ "$trim" = "yes" ] && echo 'services.fstrim.enable = true;')

  i18n.defaultLocale = "$lang";
  i18n.extraLocaleSettings = {
    LC_TIME = "$locale";
    LC_MONETARY = "$locale";
    LC_PAPER = "$locale";
    LC_MEASUREMENT = "$locale";
  };
  console.keyMap = "$keyboard";
  
  services.xserver = {
    enable = true;
    xkb.layout = "$xkb_layout";
  };
  
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  networking.networkmanager.enable = true;
  networking.hostName = "$hostname";
  $([ "$wifi_backend" = "iwd" ] && echo 'networking.wireless.iwd.enable = true;')
  $([ "$wifi_backend" = "wpa_supplicant" ] && echo 'networking.wireless.enable = true;')
  
  $([ "$swap_size" != "0" ] && echo 'swapDevices = [{ device = "/.swapfile"; }];')
  
  $([ "$pipewire" = "yes" ] && echo '
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };')
  
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    $([ "$gpu_driver" = "nvidia" ] && echo 'extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];')
  };
  
  $([ "$gpu_driver" = "nvidia" ] && echo '
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = '${nvidia_modeset}';
    powerManagement.enable = false;
    open = '${nvidia_open}';
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };')
  
  $([ "$gpu_driver" = "intel-amd" ] && echo '
  services.xserver.videoDrivers = [ "modesetting" ];')
  
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "render" ];
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
    atomix cheese epiphany evince geary gedit
    gnome-characters gnome-music gnome-photos gnome-terminal gnome-tour
    hitori iagno tali totem gnome-software gnome-initial-setup
    simple-scan yelp gnome-clocks gnome-maps gnome-weather
    gnome-contacts gnome-calendar
  ];')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    elisa gwenview okular kate khelpcenter konsole kwrited
    ark dolphin kdenlive kate kcalc kmail kontact korganizer
    ksystemlog kwalletmanager spectacle
  ];')
  
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  
  environment.systemPackages = with pkgs; [
    firefox
    fastfetch
    neovim
    git
    curl
    wget
    htop
    pciutils
    usbutils
    $([ "$fs" = "btrfs" ] && echo "btrfs-progs")
    $([ "$gpu_driver" = "nvidia" ] && echo "nvidia-settings")
  ];
  
  system.stateVersion = "25.11";
}
EOF

    if [ "$flakes" = "yes" ]; then
        sudo tee /mnt/etc/nixos/flake.nix > /dev/null << EOF
{
  description = "$hostname NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }@inputs: {
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
        
        echo ""
        echo "Arquivo flake.nix criado em /mnt/etc/nixos/flake.nix"
    fi
}

install_system() {
    cd /mnt
    echo "Iniciando instalação do NixOS (pode levar alguns minutos)..."
    sudo nixos-install --no-root-passwd
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/lang)"
    echo "Teclado: $(cat $STATE_DIR/keyboard)"
    echo "Tipo: $(cat $STATE_DIR/device_type)"
    echo "Disco: $(cat $STATE_DIR/disk)"
    echo "FS: $(cat $STATE_DIR/filesystem)"
    echo "Bootloader: $(cat $STATE_DIR/bootloader)"
    echo "Criptografia: $(cat $STATE_DIR/encrypt)"
    if [ "$(cat $STATE_DIR/filesystem)" = "btrfs" ]; then
        echo "Compressão: $(cat $STATE_DIR/compress)"
    fi
    echo "GPU: $(cat $STATE_DIR/gpu_driver)"
    echo "Desktop: $(cat $STATE_DIR/desktop)"
    echo "Swap: $(cat $STATE_DIR/swap)GB"
    echo "Wi-Fi: $(cat $STATE_DIR/wifi_backend)"
    echo "Flakes: $(cat $STATE_DIR/flakes)"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth)"
    echo "CUPS: $(cat $STATE_DIR/cups)"
    echo "PipeWire: $(cat $STATE_DIR/pipewire)"
    echo "TRIM: $(cat $STATE_DIR/trim)"
    echo "Usuário: $(cat $STATE_DIR/username)"
    echo "Hostname: $(cat $STATE_DIR/hostname)"
    echo "Timezone: $(cat $STATE_DIR/timezone)"
    echo ""
}

show_final_instructions() {
    local username=$(cat "$STATE_DIR/username")
    local hostname=$(cat "$STATE_DIR/hostname")
    local flakes=$(cat "$STATE_DIR/flakes")
    
    echo ""
    echo "=================================================="
    echo "INSTALAÇÃO CONCLUÍDA / INSTALLATION COMPLETE"
    echo "=================================================="
    echo ""
    echo "1) Reinicie o sistema: reboot"
    echo "2) Faça login com o usuário: $username"
    echo "3) Após o login, você pode:"
    echo "   - Usar 'sudo -i' para acesso root"
    echo "   - Editar configurações em /etc/nixos/configuration.nix"
    echo ""
    
    if [ "$flakes" = "yes" ]; then
        echo "4) Para usar flakes (recomendado):"
        echo "   sudo nixos-rebuild switch --flake /etc/nixos#$hostname"
        echo ""
        echo "   Exemplo de comando após modificar a configuração:"
        echo "   sudo nixos-rebuild switch --flake /etc/nixos#$hostname"
        echo ""
    fi
    
    echo "O sistema está configurado para usar Wayland por padrão."
    echo "The system is configured to use Wayland by default."
    echo "=================================================="
}

main() {
    select_language
    select_keyboard
    select_device_type
    select_filesystem
    select_bootloader
    select_swap_size
    select_encryption
    select_compression
    select_gpu_drivers
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
    
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
    
    partition_disk
    mount_partitions
    create_swap
    generate_configs
    
    if confirm "Iniciar instalação do NixOS?"; then
        install_system
        show_final_instructions
    else
        echo "Instalação cancelada."
        exit 1
    fi
}

main
