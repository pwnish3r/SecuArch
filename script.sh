#!/bin/bash

# 1. Set keymap and time settings
loadkeys en
timedatectl set-ntp true

# 2. List available disks and prompt for selection
echo "Listing available disks:"
fdisk -l
echo "Enter the disk you want to partition (e.g., /dev/sda):"
read disk

# 3. Partition the selected disk using fdisk (automated)
echo "Partitioning $disk..."
fdisk $disk <<EOF
g

n



+1G

t


1
n
2


p
w
EOF


# 4. Format the partitions
echo "Formatting the partitions..."

# Format the 512M EFI partition
lsblk
echo "Please enter the EFI partition: "
read partition1
mkfs.fat -F 32 /dev/${partition1}

# Format the main partition
echo "Please enter the main partition: "
read partition2
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
pacstrap -K /mnt base base-devel linux-lts linux-lts-headers linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift intel-ucode nano networkmanager networkmanager-iwd pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh openssh man-db man-pages texinfo sudo

# 7. Generate the fstab file
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# 8. Chroot into the new system
arch-chroot /mnt <<EOF
# Set time zone and hardware clock
ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime
hwclock --systohc

# Generate locale
vim /etc/locale.gen  # Pause so user can modify locale.gen

locale-gen

# Set up locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "KEYMAP=en" >> /etc/vconsole.conf
echo "ArchLinux" >> /etc/hostname
echo "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 Arch" >> /etc/hosts

# Set root password
passwd

# Ask for a username
echo "Enter a username for the new user:"
read username
useradd -mG wheel $username
passwd $username

# Enable sudo for the new user
echo "Uncommenting the wheel group in sudoers..."
sed -i '/# %wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB  
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager
EOF

# 9. Unmount the partitions and reboot
echo "Unmounting the system and rebooting..."
umount -R /mnt
reboot

