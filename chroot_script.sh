#!/bin/bash
set -e
trap 'echo -e "\e[31mAn error occurred on line $LINENO. Exiting...\e[0m"; exit 1' ERR

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
echo -e "\n\nEnter a password for \e[32mroot\e[0m:"
passwd
echo -e "\nEnter a username for the \e[32mnew user\e[0m:"
read username
useradd -mG wheel $username || true
echo -e "\nEnter a password for\e[32m $username\e[0m:"
passwd $username
bash -c 'echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/99_wheel'
chmod 440 /etc/sudoers.d/99_wheel
visudo -cf /etc/sudoers.d/99_wheel
EDITOR=vim visudo

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager
su - "$username" <<EOF
cd ~
mkdir -p auxiliary_scripts
cd auxiliary_scripts
git clone https://github.com/pwnish3r/SecuArch.git
echo "Making post install scripts executable..."
chmod +x SecuArch/postInstall/after_install_*.sh
chmod +x SecuArch/*.sh
echo "Activating post install scripts autorun..."
echo "\$HOME/auxiliary_scripts/SecuArch/scriptScheduler.sh" >> ~/.bashrc
# sed -i "s|/home/user|/home/$username|g" SecuArch/script-scheduler.service
# sed -i "s|user|$username|g" SecuArch/script-scheduler.service 
# sed -i "s|^SCRIPT_DIR.*postInstall\"$|SCRIPT_DIR=\"/home/$username/auxiliary_scripts/SecuArch/postInstall\"|g" SecuArch/scriptScheduler.sh
# sudo mv SecuArch/script-scheduler.service /etc/systemd/system/
# sudo systemctl daemon-reload
# systemctl --user enable script-scheduler.service
# sudo systemctl start script-scheduler.service
EOF

echo -e "\e[32mBase System install complete. Do you want to reboot now?\e[0m (\e[32myes\e[0m/\e[31mno\e[0m)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    touch /root/reboot.flag
    exit
else
    echo -e "\n\e[31mYou can reboot later with the 'reboot' command.\e[0m"
    exit
fi
