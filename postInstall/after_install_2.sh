#!/bin/bash
clear
sleep 0.1
figlet -f slant "WINDOW MANAGER"
sudo systemctl enable sddm
clear
##########################################################################################
CYAN() {
    local CYAN="\e[36m"
    local RESET="\e[0m"
    echo -e "${CYAN}$1${RESET}"
}
##########################################################################################
CYAN "\ni3WM will now install on your machine with preconfigured dotfiles.For usage, check my github repository under SecuArch/help"
CYAN "Press any key to contiue..."
read key
clear
sleep 0.1
############################# i3 #################################################################
yay -S --noconfirm i3 rofi xclip clipmenu dunst feh picom xss-lock lxappearance arandr alacritty
cd ~/auxiliary_scripts/SecuArch/postInstall/dotfiles/i3dots
cp -r .config $HOME/
cd ../
chmod +x autotiling
sudo mv autotiling /usr/bin/
cd ~/auxiliary_scripts/SecuArch/postInstall/rofi
chmod +x setup.sh
./setup.sh
sed -i "s|^theme.*$|theme='style-10'|g" ~/.config/rofi/launchers/type-6/launcher.sh
sleep 1
################################## Hyprland | zsh #######################################################
sudo sed -i "s|^Session=.*$|Session=i3.desktop|g" /etc/sddm.conf
mkdir ~/Pictures/wallpapers
cp ~/auxiliary_scripts/SecuArch/media/wallpaper.png ~/Pictures/wallpapers/wallpaper.png
cp ~/auxiliary_scripts/SecuArch/media/SecuArchWallpaper.png ~/Pictures/wallpapers/SecuArchWallpaper.png
mkdir ~/.config/systemd && mkdir ~/.config/systemd/user/
cp ~/auxiliary_scripts/SecuArch/postInstall/service.service ~/.config/systemd/user/
git clone -b v2.0 https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
sed -i "s|^ExecStart=.*|ExecStart=$HOME/auxiliary_scripts/SecuArch/postInstall/service.sh|g" ~/.config/systemd/user/service.service
chmod +x ~/auxiliary_scripts/SecuArch/postInstall/service.sh
sudo mv ~/auxiliary_scripts/SecuArch/postInstall/fonts/* /usr/share/fonts
fc-cache -fv
systemctl --user enable service.service
clear
sleep 0.1
echo "Reboot Manually after oh-my-zsh install with the 'reboot' command.The system will also restart on the next boot to complete the setup. Press Enter to proceed with the installation"
read enter
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#sh <(curl -L https://raw.githubusercontent.com/JaKooLit/Arch-Hyprland/main/auto-install.sh)