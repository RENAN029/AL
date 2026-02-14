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
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado / Select keyboard layout:"
    echo "1) Português Brasileiro (br)"
    echo "2) English US (us)"
    read -p "Opção: " kb_opt
    case $kb_opt in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
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
        1) echo "2G" > "$STATE_DIR/swap" ;;
        2) echo "4G" > "$STATE_DIR/swap" ;;
        3) echo "8G" > "$STATE_DIR/swap" ;;
        4) echo "0" > "$STATE_DIR/swap" ;;
        *) echo "2G" > "$STATE_DIR/swap" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop / Select desktop environment:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) KDE Plasma"
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

detect_disk() {
    echo "Discos disponíveis / Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
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

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO / INSTALLATION SUMMARY ==="
    echo "Idioma / Language: $(cat $STATE_DIR/lang 2>/dev/null)"
    echo "Teclado / Keyboard: $(cat $STATE_DIR/keyboard 2>/dev/null)"
    echo "Disco / Disk: $(cat $STATE_DIR/disk 2>/dev/null)"
    echo "Desktop: $(case $(cat $STATE_DIR/desktop 2>/dev/null) in cosmic) echo "Cosmic";; gnome) echo "GNOME";; plasma) echo "KDE Plasma";; none) echo "Nenhum / None";; esac)"
    echo "Swap: $(cat $STATE_DIR/swap 2>/dev/null | sed 's/0/Sem swap\/No swap/g')"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth 2>/dev/null)"
    echo "CUPS: $(cat $STATE_DIR/cups 2>/dev/null)"
    echo "Usuário / Username: $(cat $STATE_DIR/username 2>/dev/null)"
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
    
    # Desmontar todas as partições do disco
    for partition in $(lsblk -l -o NAME,MOUNTPOINT | grep "^$disk_base" | awk '{print $1}' | grep -v "^$disk_base$"); do
        if mount | grep -q "/dev/$partition"; then
            echo "Desmontando /dev/$partition..."
            sudo umount -l "/dev/$partition" 2>/dev/null || true
        fi
    done
    
    # Desativar swap
    for partition in $(swapon --show | grep "$disk" | awk '{print $1}'); do
        echo "Desativando swap em $partition..."
        sudo swapoff "$partition" 2>/dev/null || true
    done
    
    # Desativar LVM se existir
    if command -v vgchange &>/dev/null; then
        sudo vgchange -an 2>/dev/null || true
    fi
    
    sleep 3
}

refresh_partitions() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Atualizando tabela de partições / Refreshing partition table..."
    
    # Tentar partprobe
    sudo partprobe "$disk" 2>/dev/null || true
    
    # Forçar kernel a reler a tabela de partições
    sudo blockdev --rereadpt "$disk" 2>/dev/null || true
    
    # Alternativa: usar udevadm
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
        
        # Tentar wipefs com força
        sudo wipefs -a -f "$disk" 2>/dev/null || true
        
        # Zerar os primeiros 100MB do disco
        echo "Zerando início do disco / Zeroing beginning of disk..."
        sudo dd if=/dev/zero of="$disk" bs=1M count=100 status=progress 2>/dev/null || true
        
        # Remover tabela de partições
        sudo parted -s "$disk" mklabel gpt 2>/dev/null || true
        sudo parted -s "$disk" mklabel msdos 2>/dev/null || true
        
        refresh_partitions
        
        echo "Disco limpo com sucesso / Disk successfully wiped"
    else
        echo "Operação cancelada / Operation canceled"
        exit 1
    fi
}

check_and_prepare_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Verificando se o disco $disk está em uso / Checking if disk $disk is in use..."
    
    force_unmount_all
    
    # Verificar processos usando o disco
    if command -v lsof &>/dev/null; then
        local using_processes=$(lsof "$disk" 2>/dev/null | grep "$disk" || true)
        if [ -n "$using_processes" ]; then
            echo "Processos usando o disco / Processes using the disk:"
            echo "$using_processes"
            echo "Por favor, feche esses processos e tente novamente / Please close these processes and try again"
            exit 1
        fi
    fi
    
    wipe_disk
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    
    check_and_prepare_disk
    
    echo "Particionando $disk..."
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        # Criar partições
        sudo parted -s $disk mklabel gpt
        sudo parted -s $disk mkpart primary fat32 1MB 512MB
        sudo parted -s $disk set 1 esp on
        sudo parted -s $disk mkpart primary ext4 512MB 100%
        
        refresh_partitions
        
        # Formatar partições
        echo "Formatando partição EFI..."
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
        
        echo "Formatando partição root..."
        sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        # Criar partições
        sudo parted -s $disk mklabel msdos
        sudo parted -s $disk mkpart primary ext4 1MB 512MB
        sudo parted -s $disk set 1 boot on
        sudo parted -s $disk mkpart primary ext4 512MB 100%
        
        refresh_partitions
        
        # Formatar partições
        echo "Formatando partição boot..."
        sudo mkfs.ext4 -F ${disk}1 -L NIXBOOT
        
        echo "Formatando partição root..."
        sudo mkfs.ext4 -F ${disk}2 -L NIXROOT
    fi
    
    refresh_partitions
    
    echo "Particionamento concluído / Partitioning complete"
    sleep 3
}

mount_partitions() {
    echo "Montando partições / Mounting partitions..."
    
    # Garantir que /mnt não esteja montado
    if mount | grep -q "/mnt"; then
        sudo umount -l /mnt 2>/dev/null || true
        sudo umount -l /mnt/boot 2>/dev/null || true
    fi
    
    # Aguardar labels aparecerem
    echo "Aguardando partições ficarem disponíveis / Waiting for partitions to become available..."
    for i in {1..10}; do
        if [ -e /dev/disk/by-label/NIXROOT ] && [ -e /dev/disk/by-label/NIXBOOT ]; then
            break
        fi
        sleep 2
        refresh_partitions
    done
    
    # Verificar se as partições existem
    if [ ! -e /dev/disk/by-label/NIXROOT ]; then
        echo "ERRO: Partição NIXROOT não encontrada / ERROR: NIXROOT partition not found"
        ls -la /dev/disk/by-label/
        exit 1
    fi
    
    if [ ! -e /dev/disk/by-label/NIXBOOT ]; then
        echo "ERRO: Partição NIXBOOT não encontrada / ERROR: NIXBOOT partition not found"
        ls -la /dev/disk/by-label/
        exit 1
    fi
    
    # Montar partições
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    
    echo "Partições montadas com sucesso / Partitions mounted successfully"
    df -h /mnt /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    
    if [ "$swap_size" != "0" ]; then
        echo "Criando arquivo swap de $swap_size..."
        
        if [ -f /mnt/.swapfile ]; then
            sudo rm -f /mnt/.swapfile
        fi
        
        sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$(echo $swap_size | sed 's/G//') status=progress
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
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local username=$(cat "$STATE_DIR/username")
    local userpass=$(cat "$STATE_DIR/userpass")
    local swap_size=$(cat "$STATE_DIR/swap" | sed 's/G//')
    local disk=$(cat "$STATE_DIR/disk")
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    # Gerar hardware-configuration.nix primeiro
    sudo nixos-generate-config --root /mnt
    
    # Criar configuration.nix
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader = {
    $([ "$boot_mode" = "uefi" ] && echo 'systemd-boot.enable = true;' || echo 'grub.enable = true; grub.device = "'$disk'";')
  };

  i18n.defaultLocale = "$lang";
  console.keyMap = "$keyboard";
  
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.hostName = "renan-desktop";
  
  $([ "$swap_size" != "0" ] && echo 'swapDevices = [{ device = "/.swapfile"; }];')
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
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
  
  environment.systemPackages = with pkgs; [
    firefox
    fastfetch
    neovim
    git
    curl
    wget
  ];
  
  system.stateVersion = "25.11";
}
EOF

    # Corrigir hardware-configuration.nix para usar labels
    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g" /mnt/etc/nixos/hardware-configuration.nix
    sudo sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g" /mnt/etc/nixos/hardware-configuration.nix
    
    echo "Arquivos de configuração gerados com sucesso / Configuration files generated successfully"
}

install_system() {
    cd /mnt
    
    # Instalar sem usar flakes (método tradicional)
    echo "Iniciando instalação pelo método tradicional / Starting installation using traditional method..."
    sudo nixos-install --no-root-passwd
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 / NIXOS 25.11 INSTALLER ==="
    echo
    
    select_language
    select_keyboard
    detect_disk
    select_desktop
    select_swap_size
    select_bluetooth
    select_cups
    select_username
    
    show_summary
    
    partition_disk
    mount_partitions
    create_swap
    generate_configs
    
    if confirm "Iniciar instalação do NixOS? / Start NixOS installation?"; then
        install_system
        echo "Instalação concluída! Reinicie o sistema. / Installation complete! Reboot the system."
        echo "Digite 'reboot' para reiniciar. / Type 'reboot' to restart."
    else
        echo "Instalação cancelada / Installation canceled."
        exit 1
    fi
}

main
