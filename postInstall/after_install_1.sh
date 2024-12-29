#!/bin/bash
######################################################################################
installPackages(){
	package_file="$HOME/auxiliary_scripts/SecuArch/postInstall/packages.txt"
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

sudo cp -r $HOME/auxiliary_scripts/SecuArch/grubTheme/dedsec /boot/grub/themes
sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/dedsec/theme.txt|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
cd $HOME/auxiliary_scripts
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /usr/lib/systemd/system/grub-btrfsd.service
sudo systemctl enable grub-btrfsd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
installPackages
systemctl enable vmtoolsd.service
systemctl start vmtoolsd.service
systemctl enable ufw
systemctl start ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable
systemctl enable apparmor
systemctl enable auditd
systemctl enable docker
systemctl start docker
sudo git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
echo -e "\e[32mInstall script 1/2 complete\e[0m. Do you want to reboot now? (yes/no)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    reboot
else
    echo "You can reboot later with the 'reboot' command."
fi
