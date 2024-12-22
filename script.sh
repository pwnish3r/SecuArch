#!/bin/bash

# 1. Set keymap and time settings
loadkeys en
timedatectl set-ntp true


set -e
trap 'echo "An error occurred on line $LINENO. Exiting..."; exit 1' ERR
trap 'echo "An error occurred. Cleaning up..."; umount -R /mnt || true; exit 1' ERR
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

dd if=/dev/urandom of=$disk bs=1M status=progress

# 3. Partition the selected disk using fdisk (automated)
echo "Partitioning $disk..."
sgdisk -o $disk
sgdisk -n 1:0:+1G -t 1:ef00 $disk  # EFI partition
sgdisk -n 2:0:0 -t 2:8300 $disk   # Root partition


# 4. Format the partitions
echo "Formatting the partitions..."

# Format the 1G EFI partition
lsblk
while true; do
    echo "Please enter the EFI partition (e.g., sda1):"
    read partition1
    if lsblk | grep -q "^${partition1}"; then
        break
    else
        echo "Invalid partition. Please enter a valid partition (e.g., sda1)."
    fi
done
mkfs.fat -F 32 /dev/${partition1}

# Format the main partition
while true; do
    echo "Please enter the ROOT partition (e.g., sda2):"
    read partition2
    if lsblk | grep -q "^${partition2}"; then
        break
    else
        echo "Invalid partition. Please enter a valid partition (e.g., sda2)."
    fi
done
mkfs.btrfs /dev/${partition2}

# 5. Mount the partitions
echo "Mounting the partitions..."
mount /dev/${partition2} /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
mount -o compress=zstd,subvol=@ /dev/${partition2} /mnt
mkdir -p /mnt/home
mount -o compress=zstd,subvol=@home /dev/${partition2} /mnt/home
mkdir -p /mnt/efi
mount /dev/${partition1} /mnt/efi

# 6. Install the base system and essential packages
echo "Installing the base system..."
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift intel-ucode nano networkmanager networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh openssh man-db man-pages texinfo sudo dosfstools ntfs-3g wget curl tmux vim zram metasploit nmap wireshark-cli wireshark-qt aircrack-ng john hydra burpsuite tcpdump openbsd-netcat responder open-vm-tools ufw autopsy sleuthkit apparmor audit logwatch ossec docker sliver exploitdb hashcat seclists aws-cli azure-cli google-cloud-sdk

# 7. Generate the fstab file
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# 8. Chroot into the new system
cp chroot_script.sh /mnt/root/
cp after_install_1.sh /mnt/root/
cp after_install_2.sh /mnt/root/
arch-chroot /mnt /bin/bash /root/chroot-setup.sh

