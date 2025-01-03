#!/bin/bash
set -e
error_handler() {
    echo -e "\e[31mAn error occurred on line $1. Continuing execution...\e[0m"
}
trap 'error_handler $LINENO' ERR
clear


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
EDITOR=vim visudo

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager
clear

su - "$username" <<EOF
cd ~
mkdir -p auxiliary_scripts
cd auxiliary_scripts
git clone https://github.com/pwnish3r/SecuArch.git
echo -e "\e[32mMaking post install scripts executable...\e[0m"
chmod +x SecuArch/postInstall/after_install_*.sh
chmod +x SecuArch/*.sh
echo -e "\e[32Activating post install scripts autorun...\e[0m"
echo "\$HOME/auxiliary_scripts/SecuArch/scriptScheduler.sh" >> ~/.bashrc
EOF
sleep 1
echo -e "Base System install complete. Do you want to reboot now? (\e[32myes\e[0m/\e[31mno\e[0m)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    touch /root/reboot.flag
    exit
else
    echo -e "\n\e[31mYou can reboot later with the 'reboot' command.\e[0m"
    exit
fi
