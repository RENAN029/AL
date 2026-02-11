Esse script abaixo esta funcionando perfeitamente:
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
    echo "Selecione o idioma do sistema:"
    echo "1) Português do Brasil (pt_BR.UTF-8)"
    echo "2) English (en_US.UTF-8)"
    echo "3) Español (es_ES.UTF-8)"
    echo "4) Français (fr_FR.UTF-8)"
    echo "5) Deutsch (de_DE.UTF-8)"
    read -p "Opção: " lang_opcao
    
    case $lang_opcao in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/lang" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
        3) echo "es_ES.UTF-8" > "$STATE_DIR/lang" ;;
        4) echo "fr_FR.UTF-8" > "$STATE_DIR/lang" ;;
        5) echo "de_DE.UTF-8" > "$STATE_DIR/lang" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/lang" ;;
    esac
}

select_keyboard() {
    echo "Selecione o layout do teclado:"
    echo "1) br (ABNT2)"
    echo "2) us"
    echo "3) es"
    echo "4) fr"
    echo "5) de"
    read -p "Opção: " kb_opcao
    
    case $kb_opcao in
        1) echo "br" > "$STATE_DIR/keyboard" ;;
        2) echo "us" > "$STATE_DIR/keyboard" ;;
        3) echo "es" > "$STATE_DIR/keyboard" ;;
        4) echo "fr" > "$STATE_DIR/keyboard" ;;
        5) echo "de" > "$STATE_DIR/keyboard" ;;
        *) echo "us" > "$STATE_DIR/keyboard" ;;
    esac
}

select_swap_size() {
    echo "Selecione o tamanho do swap:"
    echo "1) 2GB"
    echo "2) 4GB"
    echo "3) 8GB"
    echo "4) 16GB"
    echo "5) 32GB"
    read -p "Opção: " swap_opcao
    
    case $swap_opcao in
        1) echo "2G" > "$STATE_DIR/swap" ;;
        2) echo "4G" > "$STATE_DIR/swap" ;;
        3) echo "8G" > "$STATE_DIR/swap" ;;
        4) echo "16G" > "$STATE_DIR/swap" ;;
        5) echo "32G" > "$STATE_DIR/swap" ;;
        *) echo "4G" > "$STATE_DIR/swap" ;;
    esac
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) Cosmic"
    echo "2) GNOME"
    echo "3) KDE Plasma"
    echo "4) Nenhum (apenas terminal)"
    read -p "Opção: " de_opcao
    
    case $de_opcao in
        1) echo "cosmic" > "$STATE_DIR/desktop" ;;
        2) echo "gnome" > "$STATE_DIR/desktop" ;;
        3) echo "plasma" > "$STATE_DIR/desktop" ;;
        4) echo "none" > "$STATE_DIR/desktop" ;;
        *) echo "none" > "$STATE_DIR/desktop" ;;
    esac
}

select_bluetooth() {
    if confirm "Habilitar Bluetooth?"; then
        echo "yes" > "$STATE_DIR/bluetooth"
    else
        echo "no" > "$STATE_DIR/bluetooth"
    fi
}

select_cups() {
    if confirm "Habilitar suporte a impressão (CUPS)?"; then
        echo "yes" > "$STATE_DIR/cups"
    else
        echo "no" > "$STATE_DIR/cups"
    fi
}

detect_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda): " disk_name
    echo "/dev/$disk_name" > "$STATE_DIR/disk"
}

partition_disk() {
    local disk=$(cat "$STATE_DIR/disk")
    
    echo "Particionando $disk automaticamente..."
    
    if [ -d /sys/firmware/efi ]; then
        echo "UEFI detectado"
        echo "uefi" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel gpt
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 esp on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.fat -F 32 ${disk}1
        sudo fatlabel ${disk}1 NIXBOOT
        sudo mkfs.ext4 ${disk}2 -L NIXROOT
    else
        echo "BIOS/Legacy detectado"
        echo "bios" > "$STATE_DIR/boot_mode"
        
        sudo parted $disk -- mklabel msdos
        sudo parted $disk -- mkpart primary 1MB 512MB
        sudo parted $disk -- set 1 boot on
        sudo parted $disk -- mkpart primary 512MB 100%
        
        sudo mkfs.ext4 ${disk}1 -L NIXBOOT
        sudo mkfs.ext4 ${disk}2 -L NIXROOT
    fi
}

mount_partitions() {
    sudo mount /dev/disk/by-label/NIXROOT /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

create_swap() {
    local swap_size=$(cat "$STATE_DIR/swap")
    
    echo "Criando arquivo swap de $swap_size..."
    sudo dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$(echo $swap_size | sed 's/G//') status=progress
    sudo chmod 600 /mnt/.swapfile
    sudo mkswap /mnt/.swapfile
    sudo swapon /mnt/.swapfile
}

generate_config() {
    sudo nixos-generate-config --root /mnt
    
    local lang=$(cat "$STATE_DIR/lang")
    local keyboard=$(cat "$STATE_DIR/keyboard")
    local boot_mode=$(cat "$STATE_DIR/boot_mode")
    local desktop=$(cat "$STATE_DIR/desktop")
    local bluetooth=$(cat "$STATE_DIR/bluetooth")
    local cups=$(cat "$STATE_DIR/cups")
    
    read -p "Nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    
    read -s -p "Senha do usuário: " userpass
    echo
    read -s -p "Confirme a senha: " userpass2
    echo
    
    if [ "$userpass" != "$userpass2" ]; then
        echo "Senhas não conferem!"
        exit 1
    fi
    
    local pass_hash=$(mkpasswd -m sha-512 "$userpass")
    
    sudo tee /mnt/etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  $([ "$boot_mode" = "uefi" ] && echo 'boot.loader.systemd-boot.enable = true;' || echo 'boot.loader.grub.enable = true; boot.loader.grub.device = "'$(cat "$STATE_DIR/disk")'";')
  
  # Locale
  i18n.defaultLocale = "$lang";
  console.keyMap = "$keyboard";
  
  # Time
  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;
  
  # Network
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.hostName = "nixos";
  
  # Swap
  swapDevices = [ {
    device = "/.swapfile";
    size = $(echo $(cat "$STATE_DIR/swap") | sed 's/G//' | awk '{print $1 * 1024}');
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
  ')
  
  $([ "$desktop" = "gnome" ] && echo '
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  ')
  
  $([ "$desktop" = "plasma" ] && echo '
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.sddm.enable = true;
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
  
  system.stateVersion = "25.11";
}
EOF
}

install_system() {
    cd /mnt
    sudo nixos-install --no-root-passwd
}

main() {
    clear
    echo "=== Instalador Automático NixOS 25.11 ==="
    echo
    
    select_language
    select_keyboard
    select_swap_size
    select_desktop
    select_bluetooth
    select_cups
    detect_disk
    
    if confirm "Iniciar particionamento automático em $(cat "$STATE_DIR/disk")?"; then
        partition_disk
    else
        echo "Particionamento cancelado."
        exit 1
    fi
    
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

Enquanto esse nao esta:
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

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

select_language() {
    echo "Selecione o idioma do sistema / Select system language:"
    echo "1) Português Brasileiro (pt_BR.UTF-8)"
    echo "2) English US (en_US.UTF-8)"
    read -p "Opção: " lang_opt
    case $lang_opt in
        1) echo "pt_BR.UTF-8" > "$STATE_DIR/language" ;;
        2) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
        *) echo "en_US.UTF-8" > "$STATE_DIR/language" ;;
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

select_disk() {
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo
    read -p "Digite o disco para instalação (ex: sda, nvme0n1): " disk
    echo "/dev/$disk" > "$STATE_DIR/disk"
}

select_desktop() {
    echo "Selecione o ambiente desktop:"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Cosmic"
    echo "4) Nenhum (somente terminal)"
    read -p "Opção: " de_opt
    echo "$de_opt" > "$STATE_DIR/desktop"
}

select_swap() {
    echo "Tamanho do arquivo swap em GB:"
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
        *) echo "2" > "$STATE_DIR/swap_size" ;;
    esac
}

select_username() {
    read -p "Digite o nome do usuário: " username
    echo "$username" > "$STATE_DIR/username"
    read -s -p "Digite a senha: " password
    echo
    read -s -p "Confirme a senha: " password2
    echo
    if [ "$password" != "$password2" ]; then
        echo "Senhas não coincidem!"
        exit 1
    fi
    echo "$password" > "$STATE_DIR/password"
}

show_summary() {
    clear
    echo "=== RESUMO DA INSTALAÇÃO ==="
    echo "Idioma: $(cat $STATE_DIR/language 2>/dev/null || echo 'Não selecionado')"
    echo "Teclado: $(cat $STATE_DIR/keyboard 2>/dev/null || echo 'Não selecionado')"
    echo "Disco: $(cat $STATE_DIR/disk 2>/dev/null || echo 'Não selecionado')"
    echo "Desktop: $(case $(cat $STATE_DIR/desktop 2>/dev/null) in 1) echo 'GNOME';; 2) echo 'KDE Plasma';; 3) echo 'Cosmic';; 4) echo 'Nenhum';; *) echo 'Não selecionado';; esac)"
    echo "Swap: $(cat $STATE_DIR/swap_size 2>/dev/null | sed 's/0/Sem swap/g')GB"
    echo "Usuário: $(cat $STATE_DIR/username 2>/dev/null || echo 'Não definido')"
    echo "============================"
    echo
    if ! confirm "Continuar com a instalação?"; then
        echo "Instalação cancelada."
        exit 0
    fi
}

partition_disk() {
    local disk=$(cat $STATE_DIR/disk)
    
    echo "Particionando $disk..."
    
    if [ -d /sys/firmware/efi ]; then
        parted $disk -- mklabel gpt
        parted $disk -- mkpart primary 2048s 512MB
        parted $disk -- set 1 esp on
        parted $disk -- mkpart primary 512MB 100%
        mkfs.fat -F 32 ${disk}1
        fatlabel ${disk}1 NIXBOOT
        mkfs.ext4 -L NIXROOT ${disk}2
    else
        parted $disk -- mklabel msdos
        parted $disk -- mkpart primary 2048s 512MB
        parted $disk -- set 1 boot on
        parted $disk -- mkpart primary 512MB 100%
        mkfs.ext4 -L NIXBOOT ${disk}1
        mkfs.ext4 -L NIXROOT ${disk}2
    fi
}

setup_mounts() {
    mount /dev/disk/by-label/NIXROOT /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/NIXBOOT /mnt/boot
}

setup_swap() {
    local swap_size=$(cat $STATE_DIR/swap_size)
    if [ "$swap_size" != "0" ]; then
        dd if=/dev/zero of=/mnt/.swapfile bs=1G count=$swap_size status=progress
        chmod 600 /mnt/.swapfile
        mkswap /mnt/.swapfile
        swapon /mnt/.swapfile
    fi
}

generate_config() {
    nixos-generate-config --root /mnt
    
    local lang=$(cat $STATE_DIR/language)
    local kb=$(cat $STATE_DIR/keyboard)
    local username=$(cat $STATE_DIR/username)
    local password=$(cat $STATE_DIR/password)
    local desktop=$(cat $STATE_DIR/desktop)
    local swap_size=$(cat $STATE_DIR/swap_size)
    
    local hashed_password=$(mkpasswd -m sha-512 "$password")
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    grub = {
      enable = true;
      device = "$(cat $STATE_DIR/disk)";
      efiSupport = ${if [ -d /sys/firmware/efi ]; then echo "true"; else echo "false"; fi};
      enableCryptodisk = true;
    };
    efi = {
      canTouchEfiVariables = ${if [ -d /sys/firmware/efi ]; then echo "true"; else echo "false"; fi};
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    wireless.iwd.enable = true;
  };

  time.timeZone = "America/Sao_Paulo";
  services.ntp.enable = true;

  i18n = {
    defaultLocale = "$lang";
    extraLocaleSettings = {
      LC_TIME = "$lang";
      LC_MONETARY = "$lang";
      LC_PAPER = "$lang";
      LC_MEASUREMENT = "$lang";
    };
  };

  console.keyMap = "$kb";

  services.xserver = {
    enable = true;
    xkb.layout = "$kb";
    xkb.variant = "";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.cups-filters ];
  };

  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "lp" ];
    shell = pkgs.bash;
    hashedPassword = "$hashed_password";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    vim
    nano
    htop
    file
    unzip
    zip
    ntfs3g
    openssl
    pciutils
    usbutils
    killall
  ];
EOF

    if [ "$swap_size" != "0" ]; then
        cat >> /mnt/etc/nixos/configuration.nix << EOF

  swapDevices = [{
    device = "/.swapfile";
    size = $((swap_size * 1024));
  }];
EOF
    fi

    case $desktop in
        1)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    evince
    totem
  ];
  environment.systemPackages = with pkgs; [
    gnome-initial-setup
    gnome-console
    gnome-software
    gnome-tweaks
    gnome-disk-utility
    gnome-backgrounds
  ];
EOF
            ;;
        2)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  environment.systemPackages = with pkgs; [
    konsole
    dolphin
    kdeconnect
    partition-manager
    ark
  ];
EOF
            ;;
        3)
            cat >> /mnt/etc/nixos/configuration.nix << EOF

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.systemPackages = with pkgs; [
    cosmic-term
    cosmic-files
    cosmic-store
    cosmic-wallpapers
  ];
EOF
            ;;
    esac

    cat >> /mnt/etc/nixos/configuration.nix << EOF

  system.stateVersion = "25.11";
}
EOF

    sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXROOT|g" /mnt/etc/nixos/hardware-configuration.nix
    sed -i "s|/dev/disk/by-uuid/[0-9a-f-]*|/dev/disk/by-label/NIXBOOT|g" /mnt/etc/nixos/hardware-configuration.nix
}

main() {
    clear
    echo "=== INSTALADOR NIXOS 25.11 ==="
    
    select_language
    select_keyboard
    select_disk
    select_desktop
    select_swap
    select_username
    
    show_summary
    
    echo "Iniciando instalação..."
    
    partition_disk
    setup_mounts
    setup_swap
    
    nixos-generate-config --root /mnt
    generate_config
    
    nixos-install --no-root-passwd
    
    echo "Instalação concluída! Reinicie o sistema."
}

main
Quero que vc deixe o primeiro que esta funcionando perfeitamente com uma estrutura parecida com o 2, eles foram baseados nesse prompt: 
"Desejo que vc crie um "arch install" para o nixos em uma instalacao minima, existem algumas instrucoes sobre o que vc deve fazer, foque no minimalismo e simplicidade. Ele deve oferecer opcao de selecionar linguagem do sistema e do teclado(as opcoes devem ser so portugues brasileiro e ingles americano), swap, particionar o disco automaticamente em ext4, criar um arquivo swap, configurar o booloader grub, nome do usuario e a senha(esse usuario deve ter permissoes de root mais nao ser um root em si), configurar o pipewire, iwd ou outra forma de network e cups, configurar o relogio(ntp) e a regiao e o bluetooth.  Utilize so os ambientes desktop dados. Atualmente a versao do nix e 25.11. Todas as opcoes devem ser selecionaveis para evitar erro do usuario. Nao e para instalar os meta pacotes dos ambientes desktop e sim so os pacotes mais importantes como esses dados no script. Primeiro as opcoes devem ser selecionados e so depois o script deve fazer toda a configuracao. O particionamento pode mostrar os discos disponiveis e pedir pro usuario digitar o que ele quer. Deve ter uma mensagem mostrando as opcoes selecionadas e perguntar se o usuario quer continuar a instalacao ou cancelar. Ele nao deve possuir cores. Mande ele completo.
Aqui esta slgumas instrucoes do site do nix:
NixOS Installation Guide

This guide is a companion guide for the official manual. In addition to describing the steps from the official manual, it provides known good instructions for common use cases. When there is a discrepancy between the manual and this guide, the supported case is the one described in the manual.

Use this guide as a step-by-step guide, choices will be presented, use only the selected section, and continue at the section it tells you to at the end.
Installation target

NixOS can be installed on an increasing variety of hardware:

    regular (Intel or AMD) desktop computers, laptops or physically accessible servers, covered on this page
    SBCs (like the Raspberry Pis) and other ARM boards, see NixOS on ARM
    cloud and remote servers, see NixOS friendly hosters

Installation method

NixOS, as with most Linux-based operating systems, can be installed in different ways.

    The classic way, booting from the installation media. (Described below.)
    Booting the media from an existing Linux installation

Making the installation media

Since NixOS 14.11 the installer ISO is hybrid. This means it is bootable on both CD and USB drives. It also boots on EFI systems, like most modern motherboards and apple systems. The following instructions will assume the standard way of copying the image to a USB drive. When using a CD or DVD, the usual methods to burn to disk should work with the iso.
"Burning" to USB drive

First, download a NixOS ISO image or create a custom ISO. Then plug in a USB stick large enough to accommodate the image. Then follow the platform instructions:
From Linux

    Find the right device with lsblk or fdisk -l. Replace /dev/sdX with the proper device in the following steps.
    Copy to device: cp nixos-xxx.iso /dev/sdX

Note: do not use /dev/sdX1 or partitions of the disk, use the whole disk /dev/sdX.

Writing the disk image with dd if=nixos.iso of=/dev/sdX bs=4M status=progress conv=fdatasync also works.
From macOS

    Find the right device with diskutil list, let's say diskX.
    Unmount with diskutil unmountDisk diskX.
    Burn with: sudo dd if=path_to_nixos.iso of=/dev/diskX

Breeze-dialog-information.png 	
Tip
Using rdiskX instead of diskX can makes a large speed difference. You can check the write speed with iostat 2 in another terminal.
From Windows

    Download USBwriter.
    Start USBwriter.
    Choose the downloaded ISO as 'Source'
    Choose the USB drive as 'Target'
    Click 'Write'
    When USBwriter has finished writing, safely unplug the USB drive.

Alternative installation media instructions

The previous methods are the supported methods of making the USB installation media.

Those methods are also documented, they can allow using the USB drive to boot multiple distributions. This is not supported, your mileage may vary.

    Using Unetbootin
    Manual USB Creation
    multibootusb

Booting the installation media
Breeze-preferences-other.png 	
This article or section needs expansion.
Reason: Troubleshooting steps, and details are lacking. (Discuss in Talk:NixOS Installation Guide#)
Please consult the pedia article metapage for guidelines on contributing.

Since the installation media is hybrid, it will boot both in legacy bios mode and UEFI mode.

Whatever mode is used to boot the installation media, your motherboard or computer's configuration may need to be changed to allow booting from a Optical Disk Drive (for CD/DVD) or an external USB drive.
Legacy bios boot

This is the only boot possible on machines lacking EFI/UEFI.
UEFI boot

The EFI bootloader of the installation media is not signed and is not using a signed shim to boot. This means that Secure Boot will need to be disabled to boot.
Connecting to the internet

The installation will definitely need a working internet connection. It is possible to install without one, but the available set of packages is limited.
Wired

For network interfaces supported by the kernel, DHCP resolution should already have happened once the shell is available.
Tethered (Internet Sharing)

If you can not connect to the internet via cable or wifi, you may use smartphone's tethering capability to share internet. Depending on your smartphones capabilities, only stock kernel drivers may be required which can help providing a working network connection.
Wireless

Network Manager is installed on the graphical ISO, meaning that it is possible to use nmtui on the command line to connect to a network.

Using the "Applications" tab at top left or the launcher bar at bottom, choose a terminal application and from there launch nmtui. This will allow you to 'activate' a (wireless) connection - your local SSIDs should be visible in the list, else you can add a new connection. When the wireless connection is active and you have tested it, it is likely the install app which launched on startup has not detected the new connection. Close down the install app, and reopen it from the launcher bar at the bottom of the screen. This should then find the new connection and proceed.

On the minimal ISO, or if you are more familiar with wpa_supplicant then you can also run wpa_passphrase ESSID | sudo tee /etc/wpa_supplicant.conf, then enter your password and systemctl restart wpa_supplicant.
Partitioning

To partition the persistent storage run sudo fdisk /dev/diskX, where `diskX` is the disk you want to partition. Typically, this might be something like /dev/sda.


Depending on your hardware, you should follow either the DOS or (U)EFI partitioning instructions.

A very simple example setup is given here.
DOS Instructions

In the DOS interactive prompt, enter the following commands:

    o (dos disk label)
    n new
    p primary (4 primary in total)
    1 (partition number [1/4])
    2048 first sector (alignment for performance)
    +500M last sector (boot sector size)
    rm signature (Y), if ex. => warning of overwriting existing system, could use wipefs
    n
    p
    2
    default (fill up partition)
    default (fill up partition)
    w (write)

UEFI Instructions

In the UEFI interactive prompt, enter the following commands:

    g (gpt disk label)
    n
    1 (partition number [1/128])
    2048 first sector
    +500M last sector (boot sector size)
    t
    1 (EFI System)
    n
    2
    default (fill up partition)
    default (fill up partition)
    w (write)

Label partitions

Labelling partitions is useful since you can have common partition labels across multiple setups, and it makes partitions easier to handle.

First, find the partitions you just created using lsblk. For example, if the drive was called /dev/sda, the partitions will typically be named /dev/sda1 and /dev/sda2.

sudo mkfs.fat -F 32 /dev/sda1
sudo fatlabel /dev/sda1 NIXBOOT
sudo mkfs.ext4 /dev/sda2 -L NIXROOT

Mount partitions

Mount your boot and root drives so we can access them and install NixOS:

sudo mount /dev/disk/by-label/NIXROOT /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot

Create swap file

sudo dd if=/dev/zero of=/mnt/.swapfile bs=1024 count=2097152 # 2GB size
sudo chmod 600 /mnt/.swapfile
sudo mkswap /mnt/.swapfile
sudo swapon /mnt/.swapfile

Create NixOS config

Generate the config using sudo nixos-generate-config --root /mnt

Then, edit the config using sudo -e /mnt/etc/nixos/configuration.nix.

Here are some of the most essential changes to make:

  # ... keep the existing config

  # Keyboard layout
  services.xserver.xkb.layout = "us";

  # Add a user!
  users.users.alice = {
    isNormalUser = true;
    description = "Alice";
    extraGroups = [ "wheel" ]; # Sudo access
    shell = pkgs.bash;
    home = "/home/alice";
  };

  # Networking config (ie: wifi)
  # <your networking config here>

  # Configure bootloader device
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for EFI only

  # Install an editor to edit the configuration
  environment.systemPackages = with pkgs; [ nano ]; # or vim!

  # ...

To edit the hardware config, use sudo -e /mnt/etc/nixos/hardware-configuration.nix.

You can then update the file systems to use labels.

  # ...

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXROOT";
      # ...
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/NIXBOOT";
      # ...
    };

  # ...

Install NixOS

cd /mnt
sudo nixos-install

after installation: Run passwd to change user password.

If internet broke/breaks, set wpa_supplicant config flags to connect to wifi.

Then, try one of the following to rebuild without downloads

    nixos-rebuild switch --option substitute false
    nixos-rebuild switch --option binary-caches ""

Additional notes for specific hardware

These are collected notes or links for specific hardware issues.


    Blog post how to install NixOS on a Dell 9560
    Brand servers may require extra kernel modules be included into initrd (boot.initrd.extraKernelModules in configuration.nix) For example HP Proliant needs "hpsa" module to see the disk drive.

For generic wifi or hardware issues, you may need to build your ISO with more up-to-date kernel packages:

  # Add this to your ISO config
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # You might need to disable ZFS if it isn't supported on the latest kernel packages
  # boot.supportedFilesystems.zfs = lib.mkForce false;
Esse script abaixo e um exemplo de como seria, por enquanto so forneca esses desktops como opcao de instalar. Garanta todo um bom funcionamento.

#!/bin/bash
set -e

STATE_DIR="$HOME/.config/arch_scripts"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

de_cosmic_installer() {
    local state_file="$STATE_DIR/de_cosmic"
    local pkg_cosmic="cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers"

    if [ -f "$state_file" ] || pacman -Q cosmic-session &>/dev/null; then
        if confirm "Cosmic detectado. Desinstalar?"; then
            echo "Desinstalando Cosmic..."
            sudo systemctl disable cosmic-greeter 2>/dev/null || true
            pacman -Qq cosmic-session &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_cosmic || true
            cleanup_files "$state_file"
            echo "Cosmic desinstalado."
        fi
    else
        if confirm "Instalar Cosmic?"; then
            echo "Instalando Cosmic..."
            sudo pacman -S --noconfirm $pkg_cosmic
            sudo systemctl enable cosmic-greeter
            touch "$state_file"
            echo "Cosmic instalado. Reinicie para aplicar."
        fi
    fi
}

de_gnome_installer() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_gnome="gnome-initial-setup gnome-console gnome-software gnome-tweaks gnome-disk-utility gnome-backgrounds"

    if [ -f "$state_file" ] || pacman -Q gnome-shell &>/dev/null; then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            sudo systemctl disable gdm 2>/dev/null || true
            pacman -Qq gnome-shell &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_gnome || true
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            sudo pacman -S --noconfirm $pkg_gnome
            sudo systemctl enable gdm
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma_installer() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_plasma="plasma-meta konsole dolphin kdeconnect partitionmanager ark"

    if [ -f "$state_file" ] || pacman -Q plasma-meta &>/dev/null; then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            sudo systemctl disable sddm 2>/dev/null || true
            pacman -Qq plasma-meta &>/dev/null && sudo pacman -Rsnu --noconfirm $pkg_plasma || true
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            sudo pacman -S --noconfirm $pkg_plasma
            sudo systemctl enable sddm
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

main_menu() {
    while true; do
        clear
        echo "=== Arch Scripts ==="
        echo "1) "
        echo "2) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1)  ;;
            2) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu. Ele nao deve ter comentarios(as #)"
