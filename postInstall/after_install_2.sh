#!/bin/bash
sudo systemctl enable sddm
echo -e "Now you can choose to install either \n\e[32m1.i3\e[0m\n\e[32m2.bspwm\e[0m. For any other WM or DE, check the arch wiki for details"
echo "Your choice(1 or 2): "
read choice
#touch ~/auxiliary_scripts/SecuArch/postInstall/choice.txt
#echo "$choice" > ~/auxiliary_scripts/SecuArch/postInstall/choice.txt
sed -i "s|^choice=choice$|choice=\"$choice\"|g" ~/auxiliary_scripts/SecuArch/postInstall/after_install_3.sh
if [ "$choice" == "1" ]; then
    yay -S i3 rofi thunar xclip clipmenu dunst feh picom xss-lock lxappearance arandr
    git clone https://github.com/pwnish3r/dotfiles-i3.git
    cd dotfiles-i3
    cp -r .config $HOME/
    echo -e "\e[32mInstall script 2/3 complete.The system will reboot now!\e[0m."
    sleep 2
elif [ "$choice" == "2" ]; then
    curl -L https://is.gd/gh0stzk_dotfiles -o $HOME/RiceInstaller
    chmod +x RiceInstaller
    echo -e "The Rice Installer will begin. Choose \e[31mNO\e[0m when asked to reboot"
    sleep 2
    ./RiceInstaller
    cd $HOME/.config
    git clone https://github.com/pwnish3r/dotfiles-bspwm.git
    cd dotfiles-bspwm
    cp -r bspwm ../
    cp -r nvim ../
    cp -r tmux ../
    cp -r zsh ../
    echo -e "\e[32mInstall script 2/3 complete.The system will reboot now!\e[0m."
    sleep 2
fi
