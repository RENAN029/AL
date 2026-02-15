#!/bin/bash
set -e

STATE_DIR="/tmp/nixos_install_state"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    while true; do
        read -p "$prompt (s/n): " -n 1 resposta
        echo
        if [[ "$resposta" = "s" || "$resposta" = "S" ]]; then
            return 0
        elif [[ "$resposta" = "n" || "$resposta" = "N" ]]; then
            return 1
        else
            echo "Por favor, responda s ou n / Please answer y or n"
        fi
    done
}

select_language() {
    while true; do
        clear
        echo "=== IDIOMA DO SISTEMA / SYSTEM LANGUAGE ==="
        echo "1) Português Brasileiro (pt_BR.UTF-8)"
        echo "2) English US (en_US.UTF-8)"
        read -p "Opção: " lang_opt
        case $lang_opt in
            1) 
                echo "pt_BR.UTF-8" > "$STATE_DIR/lang"
                echo "pt_BR.UTF-8" > "$STATE_DIR/locale"
                return 0
                ;;
            2) 
                echo "en_US.UTF-8" > "$STATE_DIR/lang"
                echo "en_US.UTF-8" > "$STATE_DIR/locale"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
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
            1) 
                echo "br" > "$STATE_DIR/keyboard"
                echo "br" > "$STATE_DIR/xkb_layout"
                return 0
                ;;
            2) 
                echo "us" > "$STATE_DIR/keyboard"
                echo "us" > "$STATE_DIR/xkb_layout"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_device_type() {
    while true; do
        clear
        echo "=== TIPO DE DISPOSITIVO / DEVICE TYPE ==="
        echo "1) Laptop (foco em economia de energia / power saving focus)"
        echo "2) Desktop (foco em desempenho máximo / maximum performance focus)"
        read -p "Opção: " device_opt
        case $device_opt in
            1) 
                echo "laptop" > "$STATE_DIR/device_type"
                return 0
                ;;
            2) 
                echo "desktop" > "$STATE_DIR/device_type"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_filesystem() {
    while true; do
        clear
        echo "=== SISTEMA DE ARQUIVOS / FILESYSTEM ==="
        echo "1) ext4 (padrão / default)"
        echo "2) btrfs (com suporte a snapshots)"
        read -p "Opção: " fs_opt
        case $fs_opt in
            1) 
                echo "ext4" > "$STATE_DIR/filesystem"
                return 0
                ;;
            2) 
                echo "btrfs" > "$STATE_DIR/filesystem"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_bootloader() {
    while true; do
        clear
        echo "=== BOOTLOADER ==="
        echo "1) systemd-boot (recomendado para UEFI)"
        echo "2) GRUB (para BIOS/Legacy ou UEFI)"
        read -p "Opção: " bl_opt
        case $bl_opt in
            1) 
                echo "systemd-boot" > "$STATE_DIR/bootloader"
                return 0
                ;;
            2) 
                echo "grub" > "$STATE_DIR/bootloader"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
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
        echo "4) Sem swap / No swap"
        read -p "Opção: " swap_opt
        case $swap_opt in
            1) 
                echo "2" > "$STATE_DIR/swap"
                return 0
                ;;
            2) 
                echo "4" > "$STATE_DIR/swap"
                return 0
                ;;
            3) 
                echo "8" > "$STATE_DIR/swap"
                return 0
                ;;
            4) 
                echo "0" > "$STATE_DIR/swap"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_encryption() {
    clear
    echo "=== CRIPTOGRAFIA / ENCRYPTION ==="
    if confirm "Criptografar disco com LUKS? / Encrypt disk with LUKS?"; then
        echo "yes" > "$STATE_DIR/encrypt"
    else
        echo "no" > "$STATE_DIR/encrypt"
    fi
}

select_compression() {
    if [ "$(cat "$STATE_DIR/filesystem")" = "btrfs" ]; then
        clear
        echo "=== COMPRESSÃO BTRFS / BTRFS COMPRESSION ==="
        if confirm "Habilitar compressão btrfs (zstd)? / Enable btrfs compression (zstd)?"; then
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
        echo "1) NVIDIA (proprietário, melhor performance)"
        echo "2) Intel/AMD (open source, padrão)"
        read -p "Opção: " gpu_opt
        case $gpu_opt in
            1) 
                echo "nvidia" > "$STATE_DIR/gpu_driver"
                clear
                if confirm "Usar módulos open-source da NVIDIA (Turing+)? / Use NVIDIA open-source modules (Turing+)?"; then
                    echo "yes" > "$STATE_DIR/nvidia_open"
                else
                    echo "no" > "$STATE_DIR/nvidia_open"
                fi
                clear
                if confirm "Habilitar modesetting (recomendado para Wayland)? / Enable modesetting (recommended for Wayland)?"; then
                    echo "yes" > "$STATE_DIR/nvidia_modeset"
                else
                    echo "no" > "$STATE_DIR/nvidia_modeset"
                fi
                return 0
                ;;
            2) 
                echo "intel-amd" > "$STATE_DIR/gpu_driver"
                echo "no" > "$STATE_DIR/nvidia_open"
                echo "no" > "$STATE_DIR/nvidia_modeset"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_desktop() {
    while true; do
        clear
        echo "=== AMBIENTE DESKTOP / DESKTOP ENVIRONMENT ==="
        echo "1) Cosmic (minimal, Wayland nativo)"
        echo "2) GNOME (minimal, Wayland por padrão)"
        echo "3) KDE Plasma (minimal, Wayland por padrão)"
        echo "4) Nenhum (apenas terminal)"
        read -p "Opção: " de_opt
        case $de_opt in
            1) 
                echo "cosmic" > "$STATE_DIR/desktop"
                return 0
                ;;
            2) 
                echo "gnome" > "$STATE_DIR/desktop"
                return 0
                ;;
            3) 
                echo "plasma" > "$STATE_DIR/desktop"
                return 0
                ;;
            4) 
                echo "none" > "$STATE_DIR/desktop"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_network_backend() {
    while true; do
        clear
        echo "=== BACKEND DE REDE WI-FI / WI-FI BACKEND ==="
        echo "1) iwd (recomendado, moderno)"
        echo "2) wpa_supplicant (tradicional)"
        read -p "Opção: " net_opt
        case $net_opt in
            1) 
                echo "iwd" > "$STATE_DIR/wifi_backend"
                return 0
                ;;
            2) 
                echo "wpa_supplicant" > "$STATE_DIR/wifi_backend"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

select_flakes() {
    clear
    echo "=== FLAKES ==="
    if confirm "Habilitar flakes (recomendado)? / Enable flakes (recommended)?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
}

select_bluetooth() {
    clear
    echo "=== BLUETOOTH ==="
    if confirm "Habilitar Bluetooth? / Enable Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    clear
    echo "=== IMPRESSÃO (CUPS) / PRINTING (CUPS) ==="
    if confirm "Habilitar suporte a impressão (CUPS)? / Enable printing support (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

select_pipewire() {
    clear
    echo "=== ÁUDIO (PIPEWIRE) / AUDIO (PIPEWIRE) ==="
    if confirm "Habilitar PipeWire (áudio, recomendado)? / Enable PipeWire (audio, recommended)?"; then
        echo "yes" > "$STATE_DIR/pipewire"
    else
        echo "no" > "$STATE_DIR/pipewire"
    fi
}

select_ssd_trim() {
    clear
    echo "=== TRIM PARA SSD / TRIM FOR SSD ==="
    if confirm "Habilitar TRIM para SSD? / Enable TRIM for SSD?"; then
        echo "yes" > "$STATE_DIR/trim"
    else
        echo "no" > "$STATE_DIR/trim"
    fi
}

detect_disk() {
    while true; do
        clear
        echo "=== SELEÇÃO DE DISCO / DISK SELECTION ==="
        echo "Discos disponíveis / Available disks:"
        lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -v loop
        echo
        read -p "Digite o disco para instalação (ex: sda, nvme0n1, vda): " disk_name
        
        if [ -z "$disk_name" ]; then
            echo "Nome do disco não pode estar vazio / Disk name cannot be empty"
            sleep 2
            continue
        fi
        
        if [ ! -e "/dev/$disk_name" ]; then
            echo "Disco /dev/$disk_name não encontrado / Disk not found"
            sleep 2
            continue
        fi
        
        echo "/dev/$disk_name" > "$STATE_DIR/disk"
        return 0
    done
}

select_username() {
    while true; do
        clear
        echo "=== NOME DO USUÁRIO / USERNAME ==="
        read -p "Digite o nome do usuário / Enter username: " username
        
        if [ -z "$username" ]; then
            echo "Nome do usuário não pode estar vazio / Username cannot be empty"
            sleep 2
            continue
        fi
        
        echo "$username" > "$STATE_DIR/username"
        
        while true; do
            read -s -p "Digite a senha / Enter password: " userpass
            echo
            read -s -p "Confirme a senha / Confirm password: " userpass2
            echo
            
            if [ "$userpass" != "$userpass2" ]; then
                echo "Senhas não conferem / Passwords do not match!"
                sleep 2
                continue
            fi
            
            if [ -z "$userpass" ]; then
                echo "Senha não pode estar vazia / Password cannot be empty"
                sleep 2
                continue
            fi
            
            echo "$userpass" > "$STATE_DIR/userpass"
            return 0
        done
    done
}

select_hostname() {
    clear
    echo "=== NOME DO COMPUTADOR / HOSTNAME ==="
    read -p "Digite o nome do computador / Enter hostname [nixos]: " hostname
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
            1) 
                echo "America/Sao_Paulo" > "$STATE_DIR/timezone"
                return 0
                ;;
            2) 
                echo "America/New_York" > "$STATE_DIR/timezone"
                return 0
                ;;
            *) 
                echo "Opção inválida / Invalid option"
                sleep 2
                ;;
        esac
    done
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma / Language: $(cat $STATE_DIR/lang 2>/dev/null)"
    echo "Teclado / Keyboard: $(cat $STATE_DIR/keyboard 2>/dev/null)"
    echo "Tipo de dispositivo / Device type: $(cat $STATE_DIR/device_type 2>/dev/null)"
    echo "Disco / Disk: $(cat $STATE_DIR/disk 2>/dev/null)"
    echo "Sistema de arquivos / Filesystem: $(cat $STATE_DIR/filesystem 2>/dev/null)"
    echo "Bootloader: $(cat $STATE_DIR/bootloader 2>/dev/null)"
    echo "Criptografia / Encryption: $(cat $STATE_DIR/encrypt 2>/dev/null)"
    echo "Compressão btrfs: $(cat $STATE_DIR/compress 2>/dev/null)"
    echo "Drivers GPU: $(case $(cat $STATE_DIR/gpu_driver 2>/dev/null) in nvidia) echo "NVIDIA";; intel-amd) echo "Intel/AMD";; esac)"
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
    
    while true; do
        if confirm "Continuar com a instalação? / Continue with installation?"; then
            return 0
        else
            if confirm "Deseja reiniciar o processo de seleção? / Do you want to restart the selection process?"; then
                return 1
            else
                echo "Instalação cancelada / Installation canceled."
                exit 0
            fi
        fi
    done
}

check_disk_busy() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Verificando se o disco $disk está em uso / Checking if disk $disk is in use..."
    
    # Verificar partições montadas
    if mount | grep -q "$disk"; then
        echo "O disco possui partições montadas / The disk has mounted partitions"
        return 0
    fi
    
    # Verificar swap ativo
    if swapon --show | grep -q "$disk"; then
        echo "O disco possui swap ativo / The disk has active swap"
        return 0
    fi
    
    # Verificar se há processos usando o disco
    if command -v lsof &>/dev/null; then
        if lsof "$disk" 2>/dev/null | grep -q "$disk"; then
            echo "Existem processos usando o disco / There are processes using the disk"
            return 0
        fi
    fi
    
    return 1
}

manual_partition_cleanup() {
    local disk=$(cat "$STATE_DIR/disk")
    
    clear
    echo "=== LIMPEZA MANUAL DE PARTIÇÕES / MANUAL PARTITION CLEANUP ==="
    echo "O disco $disk está ocupado / The disk $disk is busy"
    echo "O GParted será aberto para você limpar as partições manualmente"
    echo "GParted will be opened for you to clean the partitions manually"
    echo ""
    echo "Instruções / Instructions:"
    echo "1. No GParted, selecione o disco $disk no canto superior direito"
    echo "2. Desmonte todas as partições (clique com direito > Unmount)"
    echo "3. Delete todas as partições (clique com direito > Delete)"
    echo "4. Clique em Apply (✓) para aplicar as alterações"
    echo "5. Feche o GParted quando terminar"
    echo ""
    echo "Após fechar o GParted, o particionamento automático continuará"
    echo "After closing GParted, automatic partitioning will continue"
    echo ""
    read -p "Pressione Enter para abrir o GParted / Press Enter to open GParted"
    
    # Abrir GParted
    if command -v gparted &>/dev/null; then
        sudo gparted
    else
        echo "GParted não está instalado. Instalando temporariamente..."
        nix-shell -p gparted --run "sudo gparted"
    fi
    
    # Aguardar o GParted fechar
    echo "GParted fechado. Verificando se o disco ainda está ocupado..."
    sleep 2
    
    # Verificar novamente
    if check_disk_busy; then
        echo "O disco ainda está ocupado. Deseja tentar novamente?"
        if confirm "Abrir GParted novamente? / Open GParted again?"; then
            manual_partition_cleanup
        else
            echo "Não é possível continuar com o disco ocupado / Cannot continue with busy disk"
            exit 1
        fi
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
        
        sudo partprobe $disk 2>/dev/null || true
        sleep 2
        
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
        
        sudo partprobe $disk 2>/dev/null || true
        sleep 2
        
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
        
        sudo partprobe $disk 2>/dev/null || true
        sleep 2
        
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
        
        sudo partprobe $disk 2>/dev/null || true
        sleep 2
        
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
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Verificando se o disco está ocupado / Checking if disk is busy..."
    
    # Verificar se o disco está ocupado
    if check_disk_busy; then
        manual_partition_cleanup
    fi
    
    echo "Iniciando particionamento automático / Starting automatic partitioning..."
    
    local fs=$(cat "$STATE_DIR/filesystem")
    
    case $fs in
        ext4) partition_disk_ext4 ;;
        btrfs) partition_disk_btrfs ;;
        *) partition_disk_ext4 ;;
    esac
    
    sudo partprobe $(cat "$STATE_DIR/disk") 2>/dev/null || true
    sleep 2
    
    echo "Particionamento concluído / Partitioning complete"
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
    
    # Aguardar dispositivos aparecerem
    for i in {1..10}; do
        if [ -e "$root_dev" ] && [ -e "$boot_dev" ]; then
            break
        fi
        sleep 1
    done
    
    if [ ! -e "$root_dev" ]; then
        echo "ERRO: Dispositivo root não encontrado / ERROR: Root device not found"
        exit 1
    fi
    
    if [ ! -e "$boot_dev" ]; then
        echo "ERRO: Dispositivo boot não encontrado / ERROR: Boot device not found"
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
    
    # Gerar hardware-configuration.nix
    sudo nixos-generate-config --root /mnt
    
    # Configurar hardware-configuration.nix para usar labels e opções específicas
    if [ "$encrypt" = "yes" ]; then
        local uuid=$(sudo blkid -s UUID -o value ${disk}2 2>/dev/null)
        sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/mapper/cryptroot|g" /mnt/etc/nixos/hardware-configuration.nix
        sudo tee -a /mnt/etc/nixos/hardware-configuration.nix > /dev/null << EOF

boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/$uuid";
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
    powerManagement.finegrained = false;
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

    # Criar flake.nix apenas como arquivo, não executar
    if [ "$flakes" = "yes" ]; then
        sudo tee /mnt/etc/nixos/flake.nix > /dev/null << EOF
{
  description = "$hostname NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, nixpkgs-stable }@inputs: {
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
        echo "Para usar flakes após a instalação:"
        echo "1. Após reiniciar, edite o arquivo se necessário: sudo nano /etc/nixos/flake.nix"
        echo "2. Para rebuildar com flakes: sudo nixos-rebuild switch --flake /etc/nixos#$hostname"
        echo ""
    fi
    
    echo "Arquivos de configuração gerados com sucesso / Configuration files generated successfully"
}

install_system() {
    cd /mnt
    
    echo "Iniciando instalação do NixOS (usando nixpkgs mais recente)..."
    echo "Starting NixOS installation (using latest nixpkgs)..."
    
    # Instalar com configuração tradicional
    sudo nixos-install --no-root-passwd
}

main() {
    clear
    echo "=== INSTALADOR NIXOS (VERSÃO MAIS RECENTE) / NIXOS INSTALLER (LATEST VERSION) ==="
    echo
    
    while true; do
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
        
        if show_summary; then
            break
        fi
    done
    
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
        echo ""
        echo "O sistema usará Wayland por padrão (session type: wayland)"
        echo "The system will use Wayland by default (session type: wayland)"
    else
        echo "Instalação cancelada / Installation canceled."
        exit 1
    fi
}

main
