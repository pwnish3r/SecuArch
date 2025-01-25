#!/bin/bash
pacman -Syy
pacman -S --noconfirm util-linux
pacman -S --noconfirm figlet
pacman -Sy --noconfirm cryptsetup grub
pacman-key --init || true
set -e
trap 'echo -e "\e[31mAn error occurred on line $LINENO. Exiting...\e[0m"; exit 1' ERR
trap 'echo -e "\e[31mAn error occurred. Cleaning up...\e[0m"; umount -R /mnt || true; umount /dev/mapper/luksroot || true; cryptsetup close luksroot; exit 1' ERR

###################################################################
###################################################################
RED() {
    local RED="\e[31m"
    local RESET="\e[0m"
    echo -e "${RED}$1${RESET}"
}
GREEN() {
    local GREEN="\e[32m"
    local RESET="\e[0m"
    echo -e "${GREEN}$1${RESET}"
}
YELLOW() {
    local YELLOW="\e[33m"
    local RESET="\e[0m"
    echo -e "${YELLOW}$1${RESET}"
}
BLUE() {
    local BLUE="\e[34m"
    local RESET="\e[0m"
    echo -e "${BLUE}$1${RESET}"
}
CYAN() {
    local CYAN="\e[36m"
    local RESET="\e[0m"
    echo -e "${CYAN}$1${RESET}"
}
###################################################################
###################################################################



###################################################################
if [ -z "${PROGRESS}" ]; then
	export PROGRESS=0
else
	progress=$PROGRESS
fi
###################################################################
###################################################################
fetch_partitions(){
	lsblk
	while true; do
	    GREEN "Please enter the EFI partition (e.g., sda1):"
	    read -p "Partition 1: " partition1
	    if lsblk | grep -q "${partition1}"; then
		break
	    else
		RED "ERROR: Invalid partition. Please enter a valid partition (e.g., sda1)"
	    fi
	done
	while true; do
	    GREEN "Please enter the ROOT partition (e.g., sda2):"
	    read -p "Partition 2: " partition2
	    if lsblk | grep -q "${partition2}"; then
		break
	    else
		RED "ERROR: Invalid partition. Please enter a valid partition (e.g., sda2)"
	    fi
	done
}

###################################################################
###################################################################
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    echo -n "$2"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\\b\\b\\b\\b\\b\\b"
    done
    printf " [Check]\n"
}
###################################################################
###################################################################
pacstrap_package() {
    local package=$1
    echo "Installing package: $package"
    if pacstrap /mnt "$package" --needed --noconfirm > /dev/null 2>&1; then
        GREEN "[✔] Successfully installed: $package\n"
    else
        RED "[✘] Failed to install: $package\n" >&2
    fi
}
###################################################################
###################################################################

clear
figlet -f slant "SecuArch Install"
GREEN "This script will guide you through the SecuArch installation process.\nFollow the steps carefully and ensure you have an internet connection."
sleep 3
clear
loadkeys en
timedatectl set-ntp true
chmod +x *.sh
###################################################################
# 1. Disk formatting
###################################################################
figlet -f slant "Disk Formatting"
if (( progress == 0 )); then
	cryptsetup close luksroot > /dev/null 2>&1 || true 
	umount /mnt > /dev/null 2>&1 || true
	umount /dev/mapper/luksroot > /dev/null 2>&1 || true 
	# 2. List available disks and prompt for selection
	GREEN "\nListing available disks:\n"
	sleep 1
	fdisk -l
	while true; do
	    GREEN "\nEnter the disk you want to partition (e.g., /dev/sda):"
	    read -p "Disk: " disk
	    if lsblk | grep -q "^$(basename $disk)"; then
		break
	    else
		RED "ERROR: Invalid partition. Please enter a valid partition (e.g., /dev/sda)"
	    fi
	done

	echo -e "\nYou are about to \e[31moverwrite\e[0m $disk. All data will be \e[31mlost\e[0m."
	echo -e "Do you want to continue? Type \e[32mYES\e[0m to proceed:\n"
	read -p "Choice: " confirm
	if [ "$confirm" != "YES" ]; then
	    RED "Aborting the operation"
	    exit 1
	fi
	echo -e "\nChoose method of disk wiping: " && echo -e "1.\e[33mblkdiscard (Preferred. Works with TRIM compatible hardware. If in a VM, use this for QEMU/KVM)\e[0m" && echo -e "2.\e[33msgdisk (All purpose. Use this if using Virtual Box without TRIM.)\e[0m" && echo -e "3.\e[33mdd (Completeley zeroes the disk. The most secure but very slow!)\e[0m\n\n"
	read -p "Choice: " method
	if [ "$method" == "1" ]; then
		wipefs --all $disk
		blkdiscard $disk
	fi
	if [ "$method" == "2" ]; then
		 wipefs --all $disk
		 sgdisk --zap-all $disk
		 dd if=/d1ev/urandom of=$disk bs=1M count=10 status=progress || true
	fi
	
	if [ "$method" == "3" ]; then
		dd if=/d1ev/urandom of=$disk bs=1M status=progress || true
	fi
	clear
	echo -e "\n\nPartitioning $disk..."
	sgdisk -o $disk
	sgdisk -n 1:0:+1G -t 1:ef00 $disk  # EFI partition
	sgdisk -n 2:0:0 -t 2:8300 $disk   # Root partition
	fetch_partitions
	mkfs.fat -F 32 /dev/${partition1}
	clear
	sleep 0.1
	figlet -f slant "Encryption"
	echo -e "\n\n"
	YELLOW "Would you like to enable LUKS2 encryption for your root partition? (y/n)"
	read -p "Choice: " encryption_choice
	if [ "$encryption_choice" = "y" ] || [ "$encryption_choice" = "Y" ]; then
	    GREEN "\nSetting up LUKS2 on /dev/${partition2}..."
	    cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --pbkdf-force-iterations=1000000 /dev/${partition2}
	    cryptsetup open /dev/${partition2} luksroot
	    mkfs.btrfs -f /dev/mapper/luksroot
	    rootdev="/dev/mapper/luksroot"
	    export ENCRYPTED=1
	else
	    GREEN "\nFormatting /dev/${partition2} with BTRFS..."
	    mkfs.btrfs -f /dev/${partition2}
	    rootdev="/dev/${partition2}"
	    export ENCRYPTED=0
	fi
	(( progress+=1 ))
	export PROGRESS=1
	fi
###################################################################
# 2. Mount the partitions
###################################################################
if [ -z "${partition1}" ]; then
	fetch_partitions
fi
clear
figlet -f slant "Partition Mounting"
GREEN "\nMounting the partitions..."
mount "$rootdev" /mnt
btrfs subvolume create /mnt/@ || true
btrfs subvolume create /mnt/@home || true
umount /mnt || true
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ "$rootdev" /mnt || true

mkdir -p /mnt/home || true
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home "$rootdev" /mnt/home || true

mkdir -p /mnt/efi || true
mount /dev/${partition1} /mnt/efi || true

###################################################################
# 3. Install the base system and essential packages
###################################################################
clear
sleep 0.1
figlet -f slant "Pacstrap"
if (( progress == 1 )); then
	GREEN "\n\nInstalling the base system...\n"
	packages=(base base-devel linux linux-headers linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift nano networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh openssh man-db man-pages texinfo sudo vim plymouth figlet pv)
	for pkg in "${packages[@]}"; do
		pacstrap_package "$pkg"
	done
	genfstab -U -p /mnt >> /mnt/etc/fstab
	(( progress+=1 ))
	export PROGRESS=2
fi

###################################################################
# 4. Chroot into the new system
###################################################################
if (( progress == 2 )); then
	if [ "$encryption_choice" = "y" ] || [ "$encryption_choice" = "Y" ]; then
		export ENCRYPTED=1
		export ROOT_PARTITION="/dev/${partition2}"
	else
		export ENCRYPTED=0
	fi

	cp chroot_script.sh /mnt/root/
	arch-chroot /mnt /bin/bash -c "ENCRYPTED=$ENCRYPTED ROOT_PARTITION=$ROOT_PARTITION /root/chroot_script.sh"
	(( progress+=1 ))
	export PROGRESS=3
	if [ -f /mnt/root/reboot.flag ]; then
    		echo -e "\e[32mInside-chroot script requested a reboot. Rebooting now...\e[0m"
	    	rm /mnt/root/reboot.flag
    		reboot
	else
    		echo -e "\e[31mNo reboot flag found. Doing nothing.\e[0m"
	fi
fi
