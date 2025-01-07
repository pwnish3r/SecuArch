#!/bin/bash
pacman -Syy
pacman -S --noconfirm util-linux
pacman -S --noconfirm figlet
pacman-key --init || true
set -e
trap 'echo -e "\e[31mAn error occurred on line $LINENO. Exiting...\e[0m"; exit 1' ERR
trap 'echo -e "\e[31mAn error occurred. Cleaning up...\e[0m"; umount -R /mnt || true; umount /dev/mapper/luksroot || true; cryptsetup close luksroot; exit 1' ERR

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
	    echo -e "\e[32mPlease enter the EFI partition (e.g., sda1):\e[0m"
	    read partition1
	    if lsblk | grep -q "${partition1}"; then
		break
	    else
		echo -e "\e[31mInvalid partition. Please enter a valid partition (e.g., sda1).\e[0m"
	    fi
	done
	while true; do
	    echo -e "\e[32mPlease enter the ROOT partition (e.g., sda2):\e[0m"
	    read partition2
	    if lsblk | grep -q "${partition2}"; then
		break
	    else
		echo -e "\e[31mInvalid partition. Please enter a valid partition (e.g., sda2).\e[0m"
	    fi
	done
}
###################################################################

clear
figlet -f slant "SecuArch Install"
echo -e "\e[32mThis script will guide you through the SecuArch installation process."
echo -e "Follow the steps carefully and ensure you have an internet connection.\e[0m"
sleep 3
loadkeys en
timedatectl set-ntp true
chmod +x *.sh
chmod +x postInstall/*.sh

###################################################################
# 1. Disk formatting
###################################################################
if (( progress == 0 )); then
	cryptsetup close luksroot || true
	umount /mnt || true
	umount /dev/mapper/luksroot || true
	# 2. List available disks and prompt for selection
	clear
	echo -e "\e[32mListing available disks:\e[0m\n\n"
	sleep 1
	fdisk -l
	while true; do
	    echo -e "\n\n\e[32mEnter the disk you want to partition (e.g., /dev/sda):\e[0m"
	    read disk
	    if lsblk | grep -q "^$(basename $disk)"; then
		break
	    else
		echo -e "\e[31mInvalid disk. Please enter a valid disk (e.g., /dev/sda).\e[0m"
	    fi
	done

	echo -e "You are about to \e[31moverwrite\e[0m $disk. All data will be \e[31mlost\e[0m."
	echo -e "Do you want to continue? Type \e[32mYES\e[0m to proceed:"
	read confirm
	if [ "$confirm" != "YES" ]; then
	    echo -e "\e[31mAborting the operation.\e[0m"
	    exit 1
	fi
	echo -e "Choose method of disk wiping: " && echo -e "1.\e[33mblkdiscard (Preferred. Works with TRIM compatible hardware. If in a VM, use this for QEMU/KVM)\e[0m" && echo -e "2.\e[33msgdisk (All purpose. Use this if using Virtual Box without TRIM.)\e[0m" && echo -e "3.\e[33mdd (Completeley zeroes the disk. The most secure but very slow!)\e[0m"
	read method
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
	echo -e "\n\e[33mWould you like to enable LUKS2 encryption for your root partition? (y/n)\e[0m"
	read encryption_choice
	if [ "$encryption_choice" = "y" ] || [ "$encryption_choice" = "Y" ]; then
	    echo -e "\n\e[32mSetting up LUKS2 on /dev/${partition2}...\e[0m"
	    cryptsetup luksFormat --type luks1 /dev/${partition2}
	    cryptsetup open /dev/${partition2} luksroot
	    mkfs.btrfs -f /dev/mapper/luksroot
	    rootdev="/dev/mapper/luksroot"
	    export ENCRYPTED=1
	else
	    echo -e "\n\e[32mFormatting /dev/${partition2} with BTRFS...\e[0m"
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
echo -e "\e[32mMounting the partitions...\e[0m"
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
if (( progress == 1 )); then	
	clear
	echo -e "\n\n\e[32mInstalling the base system...\e[0m"
	pacstrap -K /mnt base base-devel linux linux-headers linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift nano networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh openssh man-db man-pages texinfo sudo vim
	genfstab -U -p /mnt >> /mnt/etc/fstab
	nano /mnt/etc/fstab
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
