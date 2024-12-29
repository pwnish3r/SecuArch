#!/bin/bash
pacman -Sy
pacman -S --noconfirm util-linux
pacman -S --noconfirm figlet
pacman-key --init || true
set -e
trap 'echo -e "\e[31mAn error occurred on line $LINENO. Exiting...\e[0m"; exit 1' ERR
trap 'echo -e "\e[31mAn error occurred. Cleaning up...\e[0m"; umount -R /mnt || true; exit 1' ERR
###################################################################
if [ -z "${PROGRESS}" ]; then
	export PROGRESS=0
else
	progress=$PROGRESS
fi
###################################################################
fetch_partitions(){
	lsblk
	while true; do
	    echo -e "\e[32mPlease enter the EFI partition (e.g., sda1):\e[0m"
	    read partition1
	    if lsblk | grep -q "${partition1}"; then
		break
	    else
		echo "Invalid partition. Please enter a valid partition (e.g., sda1)."
	    fi
	done
	while true; do
	    echo "Please enter the ROOT partition (e.g., sda2):"
	    read partition2
	    if lsblk | grep -q "${partition2}"; then
		break
	    else
		echo "Invalid partition. Please enter a valid partition (e.g., sda2)."
	    fi
	done
}
###################################################################


figlet -f slant "Welcome to SecuArch Install"
echo -e "\e[32mThis script will guide you through the SecuArch installation process."
echo -e "Follow the steps carefully and ensure you have an internet connection.\e[0m"

# 1. Set keymap and time settings
loadkeys en
timedatectl set-ntp true
chmod +x *.sh
chmod +x postInstall/*.sh
###################################################################
if (( progress == 0 )); then
	# 2. List available disks and prompt for selection
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
	echo -e "Choose method of disk wiping: " && echo -e "1.\e[33mblkdiscard (Perfect for SSD)\e[0m" && echo -e "2.\e[33msgdisk (All purpose)\e[0m" && echo -e "3.\e[33mdd (Completeley zeroes the disk. The most secure but very slow!)\e[33m"
	read method
	
	if [ "$method" == "1" ]; then
		wipefs --all $disk
		blkdiscard $disk
	fi
	
	if [ "$method" == "2" ]; then
		 wipefs --all $disk
		 sgdisk --zap-all $disk
	fi
	
	if [ "$method" == "3" ]; then
		dd if=/dev/urandom of=$disk bs=1M status=progress || true
	fi
	
	# 3. Partition the selected disk using fdisk (automated)
	echo -e "\n\nPartitioning $disk..."
	sgdisk -o $disk
	sgdisk -n 1:0:+1G -t 1:ef00 $disk  # EFI partition
	sgdisk -n 2:0:0 -t 2:8300 $disk   # Root partition


	# 4. Format the partitions
	echo -e "\e[32mFormatting the partitions...\e[0m"

	# Format the 1G EFI partition
	fetch_partitions
	mkfs.fat -F 32 /dev/${partition1}
	mkfs.btrfs /dev/${partition2}
	(( progress+=1 ))
	export PROGRESS=1
fi

###################################################################
# 5. Mount the partitions
if [ -z "${partition1}" ]; then
	fetch_partitions
fi

echo -e "\e[32mMounting the partitions...\e[0m"
mount /dev/${partition2} /mnt
btrfs subvolume create /mnt/@ || true
btrfs subvolume create /mnt/@home || true
umount /mnt || true
mount -o compress=zstd,subvol=@ /dev/${partition2} /mnt || true
mkdir -p /mnt/home || true
mount -o compress=zstd,subvol=@home /dev/${partition2} /mnt/home || true
mkdir -p /mnt/efi || true
mount /dev/${partition1} /mnt/efi || true
###################################################################

if (( progress == 1 )); then
	# 6. Install the base system and essential packages
	echo -e "\n\n\e[32mInstalling the base system...\e[0m"
	pacstrap -K /mnt base base-devel linux linux-headers linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift intel-ucode nano networkmanager networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh openssh man-db man-pages texinfo sudo vim

	# 7. Generate the fstab file
	genfstab -U /mnt >> /mnt/etc/fstab
	cat /mnt/etc/fstab
	(( progress+=1 ))
	export PROGRESS=2
fi
###################################################################

if (( progress == 2 )); then
	# 8. Chroot into the new system
	cp chroot_script.sh /mnt/root/
	arch-chroot /mnt /bin/bash /root/chroot_script.sh
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
