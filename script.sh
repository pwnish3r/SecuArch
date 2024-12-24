#!/bin/bash
if [ -z "${PROGRESS}" ]; then
	export PROGRESS=0
else
	progress=$PROGRESS
fi
pacman -Sy
pacman -S util-linux
fetch_partitions(){
	lsblk
	while true; do
	    echo "Please enter the EFI partition (e.g., sda1):"
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
# 1. Set keymap and time settings
loadkeys en
timedatectl set-ntp true

set -e
trap 'echo "An error occurred on line $LINENO. Exiting..."; exit 1' ERR
trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; exit 1' ERR
chmod +x *.sh
chmod +x postInstall/*.sh
if (( progress == 0 )); then
	# 2. List available disks and prompt for selection
	echo "Listing available disks:"
	fdisk -l

	while true; do
	    echo "Enter the disk you want to partition (e.g., /dev/sda):"
	    read disk
	    if lsblk | grep -q "^$(basename $disk)"; then
		break
	    else
		echo "Invalid disk. Please enter a valid disk (e.g., /dev/sda)."
	    fi
	done

	echo "You are about to overwrite $disk. All data will be lost."
	echo "Do you want to continue? Type YES to proceed:"
	read confirm
	if [ "$confirm" != "YES" ]; then
	    echo "Aborting the operation."
	    exit 1
	fi
	echo "Choose method of disk wiping: 1.blkdiscard (For SSD's)   2.sgdisk (For HDD's)   3.dd (Very slow but secure)"
	read method
	
	if [ "$method" == "1" ]; then
		blkdiscard $disk
	fi
	
	if [ "$method" == "2" ]; then
		 sgdisk --zap-all $disk
	fi
	
	if [ "$method" == "3" ]; then
		dd if=/dev/urandom of=$disk bs=1M status=progress || true
	fi
	
	# 3. Partition the selected disk using fdisk (automated)
	echo "Partitioning $disk..."
	sgdisk -o $disk
	sgdisk -n 1:0:+1G -t 1:ef00 $disk  # EFI partition
	sgdisk -n 2:0:0 -t 2:8300 $disk   # Root partition


	# 4. Format the partitions
	echo "Formatting the partitions..."

	# Format the 1G EFI partition
	fetch_partitions
	mkfs.fat -F 32 /dev/${partition1}
	mkfs.btrfs /dev/${partition2}
	(( progress+=1 ))
	export PROGRESS=1
fi

# 5. Mount the partitions
if [ -z "${partition1}" ]; then
	fetch_partitions
fi

echo "Mounting the partitions..."
mount /dev/${partition2} /mnt
btrfs subvolume create /mnt/@ || true
btrfs subvolume create /mnt/@home || true
umount /mnt || true
mount -o compress=zstd,subvol=@ /dev/${partition2} /mnt || true
mkdir -p /mnt/home || true
mount -o compress=zstd,subvol=@home /dev/${partition2} /mnt/home || true
mkdir -p /mnt/efi || true
mount /dev/${partition1} /mnt/efi || true

if (( progress == 1 )); then
	# 6. Install the base system and essential packages
	echo "Installing the base system..."
	pacstrap -K /mnt base base-devel linux linux-headers linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift intel-ucode nano networkmanager networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh openssh man-db man-pages texinfo sudo vim

	# 7. Generate the fstab file
	genfstab -U /mnt >> /mnt/etc/fstab
	cat /mnt/etc/fstab
	(( progress+=1 ))
	export PROGRESS=2
fi

if (( progress == 2 )); then
	# 8. Chroot into the new system
	cp chroot_script.sh /mnt/root/
	arch-chroot /mnt /bin/bash /root/chroot_script.sh
	(( progress+=1 ))
	export PROGRESS=3
fi
