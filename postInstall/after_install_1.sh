#!/bin/bash

######################################################################################
installPackages(){
	package_file="$HOME/auxiliary_scripts/SecuArch/postInstall/packages.txt"
	mapfile -t packages < "$package_file"
	for pkg in "${packages[@]}"; do
		echo -e "Installing \e[32m$pkg\e[0m..."
		if ! yay -S --noconfirm --needed "$pkg" > /dev/null 2>&1; then
        		echo -e "Failed to install \e[31m$pkg\e[0m. Logging error..."
        		echo -e "$pkg" >> failed_packages.log
    		else
    			GREEN "Successfully installed \"$pkg\" [✔]"
    		fi
	done
	echo -e "\n\e[32mInstallation process complete.\e[0m"
}
######################################################################################

###################################################################
###################################################################
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    echo -n "$2"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\\b\\b\\b\\b\\b\\b"
    done
    printf " [Check]\n"
}
###################################################################
###################################################################

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

################ INTERNET CONNECTIVITY ###########################
clear
sleep 0.1
figlet -f slant "Internet"
echo -e "\n\nChecking for an internet connection..."
check_internet() {
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
if check_internet; then
    GREEN "Internet connection detected. Proceeding with the installation."
    sleep 1
else
    RED "No internet connection detected."
    while true; do
        read -p "Would you like to connect to a WiFi network? (yes/no): " wifi_choice
        case $wifi_choice in
            yes|YES|y|Y)
                # Use nmtui to connect to WiFi
                GREEN "Launching WiFi connection tool..."
                nmtui-connect
                if check_internet; then
                    GREEN "\n\nInternet connection established. Proceeding with the installation."
                    break
                else
                    RED "Still no internet connection detected. Please try again."
                fi
                ;;
            no|NO|n|N)
                RED "Internet is required to continue the installation. Please connect to the internet and restart the installation."
                exit 1
                ;;
            *)
                CYAN "Please answer yes or no."
                ;;
        esac
    done
fi
###################################################################
clear
sleep 0.1
timedatectl set-ntp true
CYAN "Installing Custom GRUB Theme\n"
if git clone https://github.com/vinceliuice/Elegant-grub2-themes.git $HOME/auxiliary_scripts/grub > /dev/null 2>&1;then
	GREEN "Done [✔]"
fi
sudo $HOME/auxiliary_scripts/grub/install.sh -t mojave -p blur -i right -b
#sudo cp -r $HOME/auxiliary_scripts/SecuArch/grubTheme/graphite /boot/grub/themes
#sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/graphite/theme.txt|' /etc/default/grub
#sudo sed -i 's|Arch|SecuArch|' /etc/default/grub
CYAN "\nReconfiguring GRUB"
if grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1;then
	GREEN "Success [✔]"
fi

cd $HOME/auxiliary_scripts
clear
sleep 0.1
figlet -f slant "BlackArch Strap"
echo -e "\n\n"
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
CYAN "Straping BlackArch into your system, this may take a while...\n"
sudo ./strap.sh > /dev/null 2>&1 < /dev/null &
pid=$!
spinner $pid
if wait $pid;then
	GREEN "Done [✔]"
fi
sleep 0.1

sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /usr/lib/systemd/system/grub-btrfsd.service
sudo systemctl enable grub-btrfsd
clear
sleep 0.1
figlet -f slant "Yay Install"


sudo pacman -S --needed --noconfirm git base-devel > /dev/null 2>&1
git clone https://aur.archlinux.org/yay.git > /dev/null 2>&1
cd yay
CYAN "Installing Yay, this may take a while...\n"
makepkg -si --noconfirm > /dev/null 2>&1 &
pid=$!
spinner $pid
if wait $pid;then
	GREEN "Done [✔]"
fi
yay
sleep 0.1
clear
YELLOW "\nAre you using a VM? (y/n)"
read -p "Your answer: " VM 
if [ "$VM" == "y" ];then
	YELLOW "\nAre you using a VirtualBox VM? (y/n)"
	read -p "Your answer: " vbox 
	if [ "$vbox" == "y" ];then 
		yay -S --noconfirm virtualbox-guest-utils
		systemctl enable vboxservice.service
	fi
fi
clear
sleep 0.1
if [ "$VM" == "n" ];then
	YELLOW "\n\n\nAre you using an AMD CPU? (y/n)"
	read CPU
	if [ "$CPU" == "n" ];then
		yay -S --noconfirm intel-ucode
	else
		yay -S --noconfirm amd-ucode
	fi
fi
sleep 1
clear
figlet -f slant "Install Packages"
installPackages
sleep 1
clear
figlet -f slant "Enable Services"
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo sed -i "s|^#unix_sock_group.*$|unix_sock_group= \"libvirt\"|g" /etc/libvirt/libvirtd.conf
sudo sed -i "s|^#unix_sock_rw_perms.*$|unix_sock_rw_perms= \"0770\"|g" /etc/libvirt/libvirtd.conf
sudo systemctl enable apparmor
sudo systemctl enable auditd
sudo systemctl enable docker
sudo systemctl start docker
sudo git clone -b master --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf
sudo cp /usr/share/sddm/themes/sddm-astronaut-theme/Themes/post-apocalyptic_hacker.conf /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo sed -i "s|astronaut.conf|custom.conf|g" /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop
sudo sed -i "s|^FullBlur.*$|FullBlur=\"true\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo sed -i "s|^BlurMax.*$|BlurMax=\"64\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo sed -i "s|^Blur.*$|Blur=\"1.0\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo sed -i "s|^AllowUppercaseLettersInUsernames.*$|AllowUppercaseLettersInUsernames=\"true\"|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo cp ~/auxiliary_scripts/SecuArch/postInstall/1.png /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/FSociety.png
sudo sed -i "s|post-apocalyptic_hacker.png|FSociety.png|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo sed -i "s|Fragile Bombers Attack|pixelon|g" /usr/share/sddm/themes/sddm-astronaut-theme/Themes/custom.conf
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw default allow incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo usermod -a -G libvirt $(whoami)
sudo systemctl restart libvirtd.service
sudo systemctl enable vmtoolsd.service
sudo systemctl start vmtoolsd.service
echo -e "\e[32mInstall script 1/3 complete.The system will reboot now!\e[0m."
sleep 2
