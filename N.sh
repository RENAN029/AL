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
        echo "Selecione o idioma do sistema:"
        echo "1) Português do Brasil (pt_BR.UTF-8)"
        echo "2) English (en_US.UTF-8)"
        read -p "Opção: " lang_opcao
        
        case $lang_opcao in
            1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang"; break ;;
            2) echo "en_US.UTF-8" > "$STATE_DIR/lang"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

select_keyboard() {
    while true; do
        clear
        echo "Selecione o layout do teclado:"
        echo "1) br (ABNT2)"
        echo "2) us"
        read -p "Opção: " kb_opcao
        
        case $kb_opcao in
            1) echo "br" > "$STATE_DIR/keyboard"; break ;;
            2) echo "us" > "$STATE_DIR/keyboard"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

select_timezone() {
    while true; do
        clear
        echo "Selecione o fuso horário:"
        echo "1) America/Sao_Paulo"
        echo "2) America/New_York"
        read -p "Opção: " tz_opcao
        
        case $tz_opcao in
            1) echo "America/Sao_Paulo" > "$STATE_DIR/timezone"; break ;;
            2) echo "America/New_York" > "$STATE_DIR/timezone"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

select_filesystem() {
    while true; do
        clear
        echo "Selecione o sistema de arquivos:"
        echo "1) ext4 (recomendado)"
        echo "2) btrfs (com suporte a snapshots)"
        read -p "Opção: " fs_opcao
        
        case $fs_opcao in
            1) echo "ext4" > "$STATE_DIR/filesystem"; break ;;
            2) echo "btrfs" > "$STATE_DIR/filesystem"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

select_bootloader() {
    while true; do
        clear
        echo "Selecione o bootloader:"
        echo "1) systemd-boot (recomendado para UEFI)"
        echo "2) GRUB"
        read -p "Opção: " bl_opcao
        
        case $bl_opcao in
            1) echo "systemd-boot" > "$STATE_DIR/bootloader"; break ;;
            2) echo "grub" > "$STATE_DIR/bootloader"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

select_encryption() {
    clear
    if confirm "Deseja criptografar o disco (LUKS)?"; then
        echo "yes" > "$STATE_DIR/encryption"
    else
        echo "no" > "$STATE_DIR/encryption"
    fi
}

select_swap_size() {
    while true; do
        clear
        echo "Selecione o tamanho do swap:"
        echo "1) 2GB"
        echo "2) 4GB"
        echo "3) 8GB"
        echo "4) Sem swap"
        read -p "Opção: " swap_opcao
        
        case $swap_opcao in
            1) echo "2G" > "$STATE_DIR/swap"; break ;;
            2) echo "4G" > "$STATE_DIR/swap"; break ;;
            3) echo "8G" > "$STATE_DIR/swap"; break ;;
            4) echo "none" > "$STATE_DIR/swap"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

select_desktop() {
    while true; do
        clear
        echo "Selecione o ambiente desktop:"
        echo "1) COSMIC"
        echo "2) GNOME"
        echo "3) KDE Plasma"
        echo "4) Nenhum (apenas terminal)"
        read -p "Opção: " de_opcao
        
        case $de_opcao in
            1) echo "cosmic" > "$STATE_DIR/desktop"; break ;;
            2) echo "gnome" > "$STATE_DIR/desktop"; break ;;
            3) echo "plasma" > "$STATE_DIR/desktop"; break ;;
            4) echo "none" > "$STATE_DIR/desktop"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
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

select_nvidia() {
    clear
    if confirm "Instalar drivers proprietários da NVIDIA?"; then
        echo "nvidia" > "$STATE_DIR/gpu"
    else
        echo "open" > "$STATE_DIR/gpu"  # Intel/AMD drivers (open-source)
    fi
}

select_flakes() {
    clear
    if confirm "Habilitar flakes (experimental)?"; then
        echo "yes" > "$STATE_DIR/flakes"
    else
        echo "no" > "$STATE_DIR/flakes"
    fi
}

select_hardware_type() {
    while true; do
        clear
        echo "Tipo de hardware:"
        echo "1) Desktop (foco em desempenho máximo)"
        echo "2) Laptop (foco em economia de energia)"
        read -p "Opção: " hw_opcao
        
        case $hw_opcao in
            1) echo "desktop" > "$STATE_DIR/hardware_type"; break ;;
            2) echo "laptop" > "$STATE_DIR/hardware_type"; break ;;
            *) echo "Opção inválida. Tente novamente."; sleep 2 ;;
        esac
    done
}

detect_disk() {
    while true; do
        clear
        echo "Discos disponíveis:"
        lsblk -d -o NAME,SIZE,MODEL | grep -v loop
        echo
        read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk_name
        
        if [ -e "/dev/$disk_name" ]; then
            echo "/dev/$disk_name" > "$STATE_DIR/disk"
            break
        else
            echo "Disco /dev/$disk_name não encontrado. Tente novamente."
            sleep 3
        fi
    done
}

partition_disk_auto() {
    local disk=$(cat "$STATE_DIR/disk")
    
    clear
    echo "AVISO: O particionamento automático IRÁ APAGAR TODOS OS DADOS em $disk"
    if ! confirm "Tem certeza que deseja continuar?"; then
        echo "Particionamento cancelado. Saindo..."
        exit 1
    fi
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel gpt
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 esp on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel msdos
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 boot on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.ext4 ${disk}1 -L NIXBOOT
    fi
    
    local fs=$(cat "$STATE_DIR/filesystem")
    if [ "$fs" = "btrfs" ]; then
        if confirm "Deseja criar subvolumes btrfs (recomendado)?"; then
            sudo mkfs.btrfs -L NIXROOT ${disk}2
            sudo mount /dev/disk/by-label/NIXROOT /mnt
            sudo btrfs subvolume create /mnt/root
            sudo btrfs subvolume create /mnt/home
            sudo btrfs subvolume create /mnt/nix
            sudo umount /mnt
            sudo mount -o compress=zstd,subvol=root /dev/disk/by-label/NIXROOT /mnt
            sudo mkdir -p /mnt/{home,nix,boot}
            sudo mount -o compress=zstd,subvol=home /dev/disk/by-label/NIXROOT /mnt/home
            sudo mount -o compress=zstd,noatime,subvol=nix /dev/disk/by-label/NIXROOT /mnt/nix
        else
            sudo mkfs.btrfs -L NIXROOT ${disk}2
            sudo mount /dev/disk/by-label/NIXROOT /mnt
        fi
    else
        sudo mkfs.ext4 -L NIXROOT ${disk}2
        sudo mount /dev/disk/by-label/NIXROOT /mnt
    fi
    
    if [ -d /sys/firmware/efi ]; then
        sudo mkdir -p /mnt/boot
        sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    else
        sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
    fi
    
    local encrypt=$(cat "$STATE_DIR/encryption")
    if [ "$encrypt" = "yes" ]; then
        echo "Configurando criptografia LUKS..."
        # Implementation would go here
    fi
}

partition_disk_manual() {
    clear
    echo "Iniciando particionamento manual com cfdisk"
    echo "Por favor, exclua as partições existentes e crie as seguintes partições:"
    if [ -d /sys/firmware/efi ]; then
        echo "- Partição 1: 512MB, tipo EFI System"
        echo "- Partição 2: restante do disco, tipo Linux filesystem"
    else
        echo "- Partição 1: 512MB, tipo Linux filesystem (boot)"
        echo "- Partição 2: restante do disco, tipo Linux filesystem (root)"
    fi
    echo
    read -p "Pressione Enter para abrir o cfdisk no disco $(cat "$STATE_DIR/disk")..."
    
    sudo cfdisk $(cat "$STATE_DIR/disk")
    
    echo "Após particionar, informe os nomes das partições:"
    read -p "Partição de boot (ex: ${disk}1): " boot_part
    read -p "Partição root (ex: ${disk}2): " root_part
    
    if [ -d /sys/firmware/efi ]; then
        sudo mkfs.fat -F 32 $boot_part
        sudo fatlabel $boot_part NIXBOOT
        echo "uefi" > "$STATE_DIR/boot_mode"
    else
        sudo mkfs.ext4 $boot_part -L NIXBOOT
        echo "bios" > "$STATE_DIR/boot_mode"
    fi
    
    local fs=$(cat "$STATE_DIR/filesystem")
    if [ "$fs" = "btrfs" ]; then
        sudo mkfs.btrfs -L NIXROOT $root_part
    else
        sudo mkfs.ext4 -L NIXROOT $root_part
    fi
    
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

partition_disk() {
    clear
    if confirm "Deseja particionamento automático? (Recomendado)"; then
        partition_disk_auto
    else
        partition_disk_manual
    fi
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    
    if [ "$swap_size" != "none" ]; then
        echo "Criando arquivo swap de $swap_size..."
        sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$(echo $swap_size | sed 's/G//') status=progress
        sudo chmod 600 /mnt/.swapfile
        sudo mkswap /mnt/.swapfile
        sudo swapon /mnt/.swapfile
    fi
}

generate_config() {
    sudo nixos-generate-config --root /mnt
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local timezone=$(cat "$STATE_DIR/timezone")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local bootloader=$(cat "$STATE_DIR/bootloader")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    local gpu=$(cat "$STATE_DIR/gpu")
    local flakes=$(cat "$STATE_DIR/flakes")
    local hw_type=$(cat "$STATE_DIR/hardware_type")
    local swap_size=$(cat "$STATE_DIR/swap")
    local fs=$(cat "$STATE_DIR/filesystem")
    
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    while true; do
        read -s -p "Senha do usuário: " userpass
        echo
        read -s -p "Confirme a senha: " userpass2
        echo
        if [ "$userpass" = "$userpass2" ] && [ -n "$userpass" ]; then
            break
        else
            echo "Senhas não conferem ou estão vazias. Tente novamente."
        fi
    done
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    # Configurações de economia de energia para laptop
    local power_settings=""
    if [ "$hw_type" = "laptop" ]; then
        power_settings='
  # Power management for laptop
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };
'
    else
        power_settings='
  # Maximum performance for desktop
  powerManagement.enable = false;
  services.thermald.enable = true;
'
    fi
    
    # Configuração de GPU
    local gpu_settings=""
    if [ "$gpu" = "nvidia" ]; then
        gpu_settings='
  # NVIDIA proprietary drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = '"$([ "$hw_type" = "laptop" ] && echo "true" || echo "false")"';
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
'
    else
        gpu_settings='
  # Open-source drivers (Intel/AMD)
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
'
    fi
    
    # Configuração do bootloader
    local bootloader_settings=""
    if [ "$bootloader" = "systemd-boot" ]; then
        bootloader_settings='
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
'
    else
        if [ "$boot_mode" = "uefi" ]; then
            bootloader_settings='
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
'
        else
            bootloader_settings='
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "'$(cat "$STATE_DIR/disk")'";
'
        fi
    fi
    
    # Opções do sistema de arquivos
    local fs_options=""
    if [ "$fs" = "btrfs" ]; then
        fs_options='
  # Btrfs optimizations
  boot.kernelParams = [ "noatime" ];
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";
'
    fi
    
    # Swap
    local swap_config=""
    if [ "$swap_size" != "none" ]; then
        swap_config="
  swapDevices = [ {
    device = \"/.swapfile\";
    size = $(echo $swap_size | sed 's/G//' | awk '{print $1 * 1024}');
  } ];"
    fi
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  $bootloader_settings
  
  # Locale
  i18n.defaultLocale = "$lang";
  i18n.extraLocaleSettings = {
    LC_TIME = "$lang";
    LC_MONETARY = "$lang";
    LC_PAPER = "$lang";
    LC_MEASUREMENT = "$lang";
  };
  
  console.keyMap = "$keyboard";
  
  # X11/Wayland
  services.xserver.enable = true;
  services.xserver.xkb.layout = "$keyboard";
  
  # Wayland is default
  services.xserver.displayManager.gdm.wayland = true;
  
  # Time
  time.timeZone = "$timezone";
  services.ntp.enable = true;
  
  # Power management
  $power_settings
  
  # GPU drivers
  $gpu_settings
  
  # Network
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.hostName = "nixos";
  
  $swap_config
  
  # PipeWire (modern audio)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Bluetooth
  $([ "$bluetooth" = "yes" ] && echo 'hardware.bluetooth.enable = true; services.blueman.enable = true;')
  
  # CUPS (printing)
  $([ "$cups" = "yes" ] && echo 'services.printing.enable = true;')
  
  $fs_options
  
  # User
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "$pass_hash";
    shell = pkgs.bash;
  };
  
  # Sudo without password for wheel
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
  services.displayManager.gdm.enable = true;
  environment.gnome.excludePackages = (with pkgs; [
    atomix cheese epiphany evince geary gedit gnome-characters
    gnome-music gnome-photos gnome-terminal gnome-tour hitori iagno tali totem
  ]);
  ')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    plasma-browser-integration konsole elisa
  ];
  ')
  
  # Flakes support
  $([ "$flakes" = "yes" ] && echo '
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
  ];
  
  $([ "$desktop" = "gnome" ] && echo '  environment.systemPackages = with pkgs; [ firefox gnome-tweaks ];')
  $([ "$desktop" = "plasma" ] && echo '  environment.systemPackages = with pkgs; [ firefox ];')
  $([ "$desktop" = "cosmic" ] && echo '  environment.systemPackages = with pkgs; [ firefox ];')
  
  system.stateVersion = "25.11"; # NixOS version identifier
}
EOF
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/lang 2>/dev/null)"
    echo "Teclado: $(cat $STATE_DIR/keyboard 2>/dev/null)"
    echo "Fuso horário: $(cat $STATE_DIR/timezone 2>/dev/null)"
    echo "Hardware: $(cat $STATE_DIR/hardware_type 2>/dev/null | sed 's/desktop/Desktop/; s/laptop/Laptop/')"
    echo "Sistema de arquivos: $(cat $STATE_DIR/filesystem 2>/dev/null)"
    echo "Bootloader: $(cat $STATE_DIR/bootloader 2>/dev/null)"
    echo "Criptografia: $(cat $STATE_DIR/encryption 2>/dev/null | sed 's/yes/Sim/; s/no/Não/')"
    echo "Swap: $(cat $STATE_DIR/swap 2>/dev/null | sed 's/none/Sem swap/')"
    echo "Desktop: $(case $(cat $STATE_DIR/desktop 2>/dev/null) in cosmic) echo "COSMIC";; gnome) echo "GNOME";; plasma) echo "KDE Plasma";; none) echo "Nenhum";; esac)"
    echo "Bluetooth: $(cat $STATE_DIR/bluetooth 2>/dev/null | sed 's/yes/Habilitado/; s/no/Desabilitado/')"
    echo "CUPS: $(cat $STATE_DIR/cups 2>/dev/null | sed 's/yes/Habilitado/; s/no/Desabilitado/')"
    echo "GPU: $(cat $STATE_DIR/gpu 2>/dev/null | sed 's/nvidia/NVIDIA (proprietário)/; s/open/Intel/AMD (open-source)/')"
    echo "Flakes: $(cat $STATE_DIR/flakes 2>/dev/null | sed 's/yes/Habilitado/; s/no/Desabilitado/')"
    echo "Disco: $(cat $STATE_DIR/disk 2>/dev/null)"
    echo "Usuário: $(cat $STATE_DIR/username 2>/dev/null)"
    echo "============================"
    echo
}

install_system() {
    cd /mnt
    sudo nixos-install --no-root-passwd
    
    echo
    echo "Instalação concluída com sucesso!"
    echo "Após reiniciar, faça login com o usuário $(cat $STATE_DIR/username)"
    echo
    if confirm "Deseja reiniciar agora?"; then
        sudo reboot
    else
        echo "Você pode reiniciar manualmente com o comando: reboot"
    fi
}

main() {
    clear
    echo "=== Instalador Automático NixOS ==="
    echo
    
    select_hardware_type
    select_language
    select_keyboard
    select_timezone
    select_filesystem
    select_bootloader
    select_encryption
    select_swap_size
    select_desktop
    select_bluetooth
    select_cups
    select_nvidia
    select_flakes
    detect_disk
    
    # Criar usuário
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    show_summary
    
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
    
    partition_disk
    create_swap
    generate_config
    
    install_system
}

main
