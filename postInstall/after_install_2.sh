#!/bin/bash
clear
sleep 0.1
figlet -f slant "WINDOW MANAGER"
sudo systemctl enable sddm
echo -e "Now you can choose to install either \n\e[32m1.i3\e[0m\n\e[32m2.bspwm\e[0m\n\e[32m3.Neither\e[0m."
echo -e "\nYour choice(1 or 2): "
read choice
if [ "$choice" == "1" ]; then
    yay -S --noconfirm i3 rofi xclip clipmenu dunst feh picom xss-lock lxappearance arandr alacritty
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

##############################################################################################
cp ~/auxiliary_scripts/SecuArch/media/wallpaper.png ~/Pictures/wallpapers/wallpaper.png
cp ~/auxiliary_scripts/SecuArch/media/SecuArchWallpaper.png ~/Pictures/wallpapers/SecuArchWallpaper.png
mkdir ~/.config/systemd && mkdir ~/.config/systemd/user/
cp ~/auxiliary_scripts/SecuArch/postInstall/service.service ~/.config/systemd/user/
cp -r ~/auxiliary_scripts/SecuArch/postInstall/dotfiles/. ~/
sudo mv ~/i3-auto-layout /usr/bin/
rm -r ~/.oh-my-zsh
systemctl --user enable service.service
##############################################################################################

clear
sleep 0.1

echo "Reboot Manually after oh-my-zsh install. Press Enter to proceed with the installation"
read enter
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
