#!/bin/bash
clear
sleep 0.1
figlet -f slant "WINDOW MANAGER"
sudo systemctl enable sddm
echo -e "Now you can choose to install either \n\e[32m1.i3\e[0m\n\e[32m2.bspwm\e[0m\n\e[32m3.Neither\e[0m."
echo -e "\nYour choice(1, 2 or 3): "
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
sudo sed -i "s|^Session=.*$|Session=i3.desktop|g" /etc/sddm.conf
mkdir ~/Pictures/wallpapers
cp ~/auxiliary_scripts/SecuArch/media/wallpaper.png ~/Pictures/wallpapers/wallpaper.png
cp ~/auxiliary_scripts/SecuArch/media/SecuArchWallpaper.png ~/Pictures/wallpapers/SecuArchWallpaper.png
mkdir ~/.config/systemd && mkdir ~/.config/systemd/user/
cp ~/auxiliary_scripts/SecuArch/postInstall/service.service ~/.config/systemd/user/
cp -r ~/auxiliary_scripts/SecuArch/postInstall/dotfiles/. ~/
chmod +x ~/autotiling
sudo mv ~/autotiling /usr/bin/
sudo mv ~/plugins /usr/share/zsh/
rm -r ~/.oh-my-zsh
sed -i "s|^ExecStart=.*|ExecStart=$HOME/auxiliary_scripts/SecuArch/postInstall/service.sh|g" ~/.config/systemd/user/service.service
chmod +x ~/auxiliary_scripts/SecuArch/postInstall/service.sh
systemctl --user enable service.service
##############################################################################################

clear
sleep 0.1

echo "Reboot Manually after oh-my-zsh install.The system will also restart on the next boot to complete the setup. Press Enter to proceed with the installation"
read enter
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
