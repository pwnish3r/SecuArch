#!/bin/bash
clear
sleep 0.1
figlet -f slant "Script 2"
sudo systemctl enable sddm
echo -e "Now you can choose to install either \n\e[32m1.i3\e[0m\n\e[32m2.bspwm\e[0m. For any other WM or DE, check the arch wiki for details"
echo "Your choice(1 or 2): "
read choice
if [ "$choice" == "1" ]; then
    yay -S --noconfirm i3 rofi thunar xclip clipmenu dunst feh picom xss-lock lxappearance arandr alacritty
    git clone https://github.com/pwnish3r/dotfiles-i3.git
    cd dotfiles-i3
    cp -r .config $HOME/
    sleep 1
elif [ "$choice" == "2" ]; then
    curl -L https://is.gd/gh0stzk_dotfiles -o $HOME/RiceInstaller
    chmod +x RiceInstaller
    echo -e "The Rice Installer will begin. Choose \e[31mNO\e[0m when asked to reboot"
    sleep 1
    ./RiceInstaller
    cd $HOME/.config
    git clone https://github.com/pwnish3r/dotfiles-bspwm.git
    cd dotfiles-bspwm
    cp -r bspwm ../
    cp -r nvim ../
    cp -r tmux ../
    cp -r zsh ../
    sleep 1
fi
cp -r ~/auxiliary_scripts/SecuArch/postInstall/dotfiles/. ~/
mkdir ~/Picture/wallpapers
cp ~/auxiliary_scripts/SecuArch/media/wallpaper.png ~/Pictures/wallpapers/wallpaper.png
clear
sleep 0.1
echo -e "Cleaning up..."
rm -r -f ~/auxiliary_scripts/SecuArch
rm -f ~/auxiliary_scripts/strap.sh
rm -r -f /auxiliary_scripts/yay
echo -e "\e[32mInstall script 2/3 complete.The system will reboot now!\e[0m."
