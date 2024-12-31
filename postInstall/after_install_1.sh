#!/bin/bash
######################################################################################
installPackages(){
	package_file="$HOME/auxiliary_scripts/SecuArch/postInstall/testing.txt"
	mapfile -t packages < "$package_file"
	for pkg in "${packages[@]}"; do
		echo -e "Installing \e[32m$pkg\e[0m..."
		if ! yay -S --noconfirm "$pkg"; then
        		echo -e "Failed to install \e[31m$pkg\e[0m. Logging error..."
        		echo -e "$pkg" >> failed_packages.log
    		fi
	done
	echo -e "\n\e[32mInstallation process complete.\e[0m"
}
######################################################################################

sudo cp -r $HOME/auxiliary_scripts/SecuArch/grubTheme/catppuccin-mocha-grub-theme /boot/grub/themes
sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/catppuccin-mocha-grub-theme/theme.txt|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
cd $HOME/auxiliary_scripts
'''
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
'''
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /usr/lib/systemd/system/grub-btrfsd.service
sudo systemctl enable grub-btrfsd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
yay
installPackages
'''
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo sed -i "s|^#unix_sock_group.*$|unix_sock_group= \"libvirt\"|g" /etc/libvirt/libvirtd.conf
sudo sed -i "s|^#unix_sock_rw_perms.*$|unix_sock_rw_perms= \"0770\"|g" /etc/libvirt/libvirtd.conf
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt
sudo systemctl restart libvirtd.service
sudo systemctl enable vmtoolsd.service
sudo systemctl start vmtoolsd.service
sudo systemctl enable ufw
sudo systemctl start ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable
sudo systemctl enable apparmor
sudo systemctl enable auditd
sudo systemctl enable docker
sudo systemctl start docker
'''
sudo git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
sudo sed -i "s|^FullBlur.*$|FullBlur=\"true\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo sed -i "s|^BlurMax.*$|BlurMax=\"64\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo sed -i "s|^Blur.*$|Blur=\"1.0\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo sed -i "s|^AllowUppercaseLettersInUsernames.*$|AllowUppercaseLettersInUsernames=\"true\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo cp ~/auxiliary_scripts/SecuArch/postInstall/1.png /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/1.png
echo -e "\e[32mInstall script 1/2 complete.The system will reboot now!\e[0m."
sleep 4
