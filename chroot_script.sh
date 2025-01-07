#!/bin/bash
set -e
error_handler() {
    echo -e "\e[31mAn error occurred on line $1. Continuing execution...\e[0m"
}
trap 'error_handler $LINENO' ERR
clear

#############################################
# 0. Basic System Setup (locale, hostname, etc.)
#############################################
ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "KEYMAP=en" > /etc/vconsole.conf
echo "SecuArch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 SecuArch
EOF

#############################################
# 1. Set root password and create user
#############################################
echo -e "\n\nEnter a password for \e[32mroot\e[0m (type carefully!):"
passwd
read -p "Enter a username for the new user: " username
if id "$username" &>/dev/null; then
    echo "User $username already exists. Skipping user creation."
else
    useradd -mG wheel "$username" || true
    echo "Enter a password for $username:"
    passwd "$username" || true
fi

# Enable sudo for wheel group
if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers || true
fi
#EDITOR=vim visudo

#############################################
# 2. IF ENCRYPTED, Update mkinitcpio.conf & GRUB
#############################################
if [ "$ENCRYPTED" = "1" ]; then
    echo -e "\n\e[32mConfiguring system for LUKS2 encryption...\e[0m"

    # 2.1 Identify the underlying partition's UUID (not /dev/mapper/luksroot).
    # Adjust $ROOT_PARTITION if needed (e.g., /dev/sda2).
    # If your partition variable is something else, replace accordingly:
    PART_UUID=$(blkid -s UUID -o value "$ROOT_PARTITION")

    # 2.2 Edit /etc/default/grub to include cryptdevice param
    # If there's already a line, we replace it; if not, we insert a new line.
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=$PART_UUID:luksroot root=/dev/mapper/luksroot\"|" /etc/default/grub
    echo "cryptdevice=UUID=$PART_UUID:luksroot root=/dev/mapper/luksroot"
    echo "$ROOT_PARTITION"
    blkid
    read wait
    # 2.3 Modify mkinitcpio.conf HOOKS
    # Typically: HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)
    sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    # 2.4 Rebuild initramfs
    mkinitcpio -P
fi

#############################################
# 3. Install & Configure GRUB
#############################################
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#############################################
# 4. Enable networking and finalize
#############################################
systemctl enable NetworkManager
clear

# Su into the new user to clone your scripts
su - "$username" <<EOF
cd ~
mkdir -p auxiliary_scripts
cd auxiliary_scripts
git clone https://github.com/pwnish3r/SecuArch.git
echo -e "\e[32mMaking post install scripts executable...\e[0m"
chmod +x SecuArch/postInstall/after_install_*.sh
chmod +x SecuArch/*.sh
echo -e "\e[32mActivating post install scripts autorun...\e[0m"
echo "\$HOME/auxiliary_scripts/SecuArch/scriptScheduler.sh" >> ~/.bashrc
EOF

clear
sleep 1

#############################################
# 5. Reboot Prompt
#############################################
echo -e "Base System install complete. Do you want to reboot now? (\e[32myes\e[0m/\e[31mno\e[0m)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    touch /root/reboot.flag
    exit
else
    echo -e "\n\e[31mYou can reboot later with the 'reboot' command.\e[0m"
    exit
fi

