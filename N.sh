quero que vc crie um script de instalacoa minima do nixos, veja o manual: 

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
ele deve fazer todos esses processos de forma automatizada parecido com oque occorre com o archinstall do arch linux, ele deve oferecer opcoes de instalacao de ambientes desktop, por exemplo: de_cosmic_installer() {
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

de_hyprland_installer() {
    local state_file="$STATE_DIR/de_hyprland"
    local pkg_sddm="sddm"

    if [ -f "$state_file" ]; then
        if confirm "Dank Linux Hyprland detectado. Desinstalar?"; then
            cleanup_files "$state_file"
        fi
    else
        if confirm "Instalar Dank Linux Hyprland?"; then
            curl -fsSL https://install.danklinux.com | sh
            sudo pacman -S --noconfirm $pkg_sddm
            sudo systemctl enable sddm
            touch "$state_file"
        fi
    fi
}

de_installer() {
    while true; do
        clear
        echo "=== Ambientes Desktop ==="
        echo "1) Cosmic"
        echo "2) Gnome"
        echo "3) Hyprland"
        echo "4) Plasma"
        echo "5) Voltar"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) clear; de_cosmic_installer ;;
            2) clear; de_gnome_installer ;;
            3) clear; de_hyprland_installer ;;
            4) clear; de_plasma_installer ;;
            5) return ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
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
        echo "1) Ambientes desktop"
        echo "2) Sair"
        echo
        read -p "Selecione uma opção: " opcao

        case $opcao in
            1) 
            2) exit 0 ;;
            *) ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main_menu
