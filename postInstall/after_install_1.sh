#!/bin/bash

######################################################################################
installPackages(){
	package_file="$HOME/auxiliary_scripts/SecuArch/postInstall/packages.txt"
	mapfile -t packages < "$package_file"
	for pkg in "${packages[@]}"; do
		echo -e "Installing \e[32m$pkg\e[0m..."
		if ! yay -S --noconfirm --needed "$pkg"; then
        		echo -e "Failed to install \e[31m$pkg\e[0m. Logging error..."
        		echo -e "$pkg" >> failed_packages.log
    		fi
	done
	echo -e "\n\e[32mInstallation process complete.\e[0m"
}
######################################################################################

################ INTERNET CONNECTIVITY ###########################
echo "Checking for an internet connection..."
check_internet() {
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
if check_internet; then
    echo "Internet connection detected. Proceeding with the installation."
    sleep 2
else
    echo "No internet connection detected."
    while true; do
        read -p "Would you like to connect to a WiFi network? (yes/no): " wifi_choice
        case $wifi_choice in
            yes|YES|y|Y)
                # Use nmtui to connect to WiFi
                echo "Launching WiFi connection tool..."
                nmtui-connect
                if check_internet; then
                    echo "Internet connection established. Proceeding with the installation."
                    break
                else
                    echo "Still no internet connection detected. Please try again."
                fi
                ;;
            no|NO|n|N)
                echo "Internet is required to continue the installation. Please connect to the internet and restart the installation."
                exit 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
fi
###################################################################
timedatectl set-ntp true
sudo cp -r $HOME/auxiliary_scripts/SecuArch/grubTheme/darkmatter /boot/grub/themes
sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/darkmatter/theme.txt|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
cd $HOME/auxiliary_scripts
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
sleep 1
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /usr/lib/systemd/system/grub-btrfsd.service
sudo systemctl enable grub-btrfsd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
yay
sleep 1
echo "Are you using a virtualbox VM? (y/n)"
read VM
if [ "$VM" == "y" ];then
	yay -S --noconfirm virtualbox-guest-utils
	systemctl enable vboxservice.service
fi
sleep 1
installPackages
sleep 1
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo sed -i "s|^#unix_sock_group.*$|unix_sock_group= \"libvirt\"|g" /etc/libvirt/libvirtd.conf
sudo sed -i "s|^#unix_sock_rw_perms.*$|unix_sock_rw_perms= \"0770\"|g" /etc/libvirt/libvirtd.conf
sudo systemctl enable apparmor
sudo systemctl enable auditd
sudo systemctl enable docker
sudo systemctl start docker
sudo git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
sudo sed -i "s|^FullBlur.*$|FullBlur=\"true\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo sed -i "s|^BlurMax.*$|BlurMax=\"64\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo sed -i "s|^Blur.*$|Blur=\"1.0\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo sed -i "s|^AllowUppercaseLettersInUsernames.*$|AllowUppercaseLettersInUsernames=\"true\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/theme1.conf
sudo cp ~/auxiliary_scripts/SecuArch/postInstall/1.png /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/1.png
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo usermod -a -G libvirt $(whoami)
sudo systemctl restart libvirtd.service
sudo systemctl enable vmtoolsd.service
sudo systemctl start vmtoolsd.service
echo -e "\e[32mInstall script 1/3 complete.The system will reboot now!\e[0m."
sleep 2
