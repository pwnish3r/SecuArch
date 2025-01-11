#!/bin/bash
set -e
error_handler() {
    echo -e "\e[31mAn error occurred on line $1. Continuing execution...\e[0m"
}
trap 'error_handler $LINENO' ERR
clear


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
clear
sleep 0.1
figlet -f slant "ROOT & USER"
echo -e "\n\nEnter a password for \e[32mroot\e[0m (type carefully!):"
passwd
read -p "Enter a username for the new user: " username
if id "$username" &>/dev/null; then
    echo "User $username already exists. Skipping user creation."
else
    useradd -mG wheel "$username" || true
    echo "Enter a password for $username"
    while true; do
    	if passwd "$username"; then
        	GREEN "Password successfully set for \"$username\"."
        	break
   	 else
     		RED "Passwords did not match or an error occurred. Please try again."
    	fi
    done
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
    clear
    sleep 0.1
    figlet -f slant "LUKS2 Config"
    GREEN "\nConfiguring system for LUKS2 encryption..."
    # 2.1 Identify the underlying partition's UUID (not /dev/mapper/luksroot).
    PART_UUID=$(blkid -s UUID -o value "$ROOT_PARTITION")

    # 2.2 Edit /etc/default/grub to include cryptdevice param
    sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$PART_UUID:luksroot root=/dev/mapper/luksroot plymouth.enable=1\"|" /etc/default/grub
    # 2.3 Modify mkinitcpio.conf HOOKS
    # Typically: HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)
    sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block plymouth encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    # 2.4 Rebuild initramfs
    mkinitcpio -P
fi

#############################################
# 3. Install & Configure GRUB
#############################################
clear
sleep 0.1
figlet -f slant "GRUB"
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#############################################
# PLYMOUTH THEME
#############################################
setPlymouth(){
	cp -r /home/$username/auxiliary_scripts/plymouth-themes/pack_1/angular /usr/share/plymouth/themes/
	plymouth-set-default-theme -R angular
	mkinitcpio -P
}
#############################################
# 4. Enable networking and finalize
#############################################
systemctl enable NetworkManager
clear

# Su into the new user to clone your scripts
clear
sleep 0.1
figlet -f slant "Preparing Post Install"
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
cd ~/auxiliary_scripts
git clone https://github.com/adi1090x/plymouth-themes.git
EOF
setPlymouth
clear
sleep 1

#############################################
# 5. Reboot Prompt
#############################################
figlet -f slant "Base Setup Complete"
echo -e "\nBase System install complete. Do you want to reboot now? (\e[32myes\e[0m/\e[31mno\e[0m)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    touch /root/reboot.flag
    exit
else
    echo -e "\n\e[31mYou can reboot later with the 'reboot' command.\e[0m"
    exit
fi
