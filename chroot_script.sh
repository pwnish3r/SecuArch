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
clear
sleep 0.1
figlet -f slant "BASIC SYSTEM SETUP"
echo "Please select your timezone:"
timezone=$(tzselect)
GREEN "You selected: $timezone"
read -p "Do you want to apply this timezone? (y/n): " confirm
if [[ $confirm == "yes" || $confirm == "y" ]]; then
    ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    hwclock --systohc
    echo "Timezone set to $timezone and hardware clock updated."
else
    echo "Timezone selection canceled."
fi
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "KEYMAP=en" > /etc/vconsole.conf
clear
sleep 0.2
CYAN "\n\nPlease enter hostname:"
read hostn
echo "$hostn" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $hostn
EOF

#############################################
# 1. Set root password and create user
#############################################
clear
sleep 0.1
figlet -f slant "ROOT & USER"
echo -e "\n\nEnter a password for \e[32mroot\e[0m (type carefully!):"
passwd
echo ""
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
    PART_UUID=$(blkid -s UUID -o value "$ROOT_PARTITION")
    sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$PART_UUID:luksroot root=/dev/mapper/luksroot plymouth.enable=1 quiet splash\"|" /etc/default/grub
    sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block plymouth encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    CYAN "\nCreating initial ramdisk with new parameters..."
    if mkinitcpio -P > /dev/null 2>&1; then
    	GREEN "Success [!]"
    fi
fi

#############################################
# 3. Install & Configure GRUB
#############################################
clear
sleep 0.1
figlet -f slant "GRUB"
CYAN "\nInstalling GRUB"
if grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB > /dev/null 2>&1;then
	GREEN "Success [!]"
fi
CYAN "\nConfiguring GRUB"
if grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1;then
	GREEN "Success [!]"
fi
#############################################
# PLYMOUTH THEME
#############################################
setPlymouth(){
	clear
	sleep 0.1
	figlet -f slant "P L Y M O U T H"
	
	cd /home/$username/auxiliary_scripts/SecuArch/postInstall/plymouthTheme
	cp -r logo-mac-style /usr/share/plymouth/themes/
    cd ../
    cp -r angular /usr/share/plymouth/themes/
	CYAN "\nSetting the new plymouth theme..."
	if plymouth-set-default-theme -R angular > /dev/null 2>&1;then
		GREEN "Done [!]"
	fi
	CYAN "\nCreating initial ramdisk with new parameters..."
   	if mkinitcpio -P > /dev/null 2>&1; then
    		GREEN "Success [!]"
    	fi
}

#############################################
# GRUB THEME
#############################################
setGrubTheme(){
    clear
	CYAN "Installing Custom GRUB Theme...\n"
	CYAN "\n Select 1, 2 or 3 depending on your screen resolution: \n1. 1080p \n2. 2k \n3. 4k"
	read -p "Your choice: " choice
	if [ "$choice" == "1" ]; then
		screen="1080p"
	fi
	if [ "$choice" == "2" ]; then
		screen="2k"
	fi
	if [ "$choice" == "3" ]; then
		screen="4k"
	fi
    THEME_DIR="/usr/share/grub/themes"
    THEME_NAME=matrices
    cd /home/$username/auxiliary_scripts/SecuArch/postInstall/grubTheme/
    cp -a ${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}
    grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
    echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub
    CYAN "\nReconfiguring GRUB"
	if grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1;then
		GREEN "Success [!]"
	fi
}
#############################################
# 4. Enable networking and finalize
#############################################
systemctl enable NetworkManager
clear
sleep 0.1
figlet -f slant "Preparing Post Install"
su - "$username" <<EOF
cd ~
mkdir -p auxiliary_scripts
cd auxiliary_scripts
echo -e "\n\e[36mCloning the repository...\e[0m"
if git clone https://github.com/pwnish3r/SecuArch.git > /dev/null 2>&1;then
	echo -e "\e[36mDone [!]\e[36m"
fi
if git clone https://github.com/pwnish3r/assets.git > /dev/null 2>&1;then
	echo -e "\e[36mDone [!]\e[36m"
fi
cp -r assets/grubTheme SecuArch/postInstall/
cp -r assets/hyprlock SecuArch/postInstall/
cp -r assets/plymouthTheme SecuArch/postInstall/
cp -r assets/sddmTheme SecuArch/postInstall/
rm -rf assets
echo -e "\n\e[36mMaking post install scripts executable...\e[0m"
chmod +x SecuArch/postInstall/after_install_*.sh
chmod +x SecuArch/*.sh
echo -e "\n\e[36mActivating post install scripts autorun...\e[0m"
echo "\$HOME/auxiliary_scripts/SecuArch/scriptScheduler.sh" >> ~/.bashrc
cd ~/auxiliary_scripts
echo -e "\n\e[36mCloning the plymouth themes...\e[0m"
if git clone https://github.com/adi1090x/plymouth-themes.git > /dev/null 2>&1;then
	echo -e "\e[36mDone [!]\e[36m"
fi

EOF
setGrubTheme
setPlymouth
clear
sleep 1

#############################################
# 5. Reboot Prompt
#############################################
figlet -f slant "Base Setup Complete"
echo -e "\nBase System install complete. Do you want to reboot now? (\e[32myes\e[0m/\e[31mno\e[0m)"
read -p "Your answer: " reboot_now
if [ "$reboot_now" == "yes" ]; then
    touch /root/reboot.flag
    exit
else
    echo -e "\n\e[31mYou can reboot later with the 'reboot' command.\e[0m"
    exit
fi
