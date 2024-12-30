#!/bin/bash
echo -e "Now you can choose to install either \e[32mi3\e[0m or \e[32mbspwm\e[0m. For any other WM or DE, check the arch wiki for details"
echo "Your choice: "
read choice
if [ "$choice" == "i3" ]; then
    yay -S i3 rofi thunar xclip clipmenu dunst feh picom xss-lock lxappearance arandr
    git clone https://github.com/pwnish3r/dotfiles-i3.git
    cd dotfiles-i3
    cp -r .config $HOME/
    echo -e "\e[32mInstall script 2/2 complete.The system will reboot now!\e[0m."
    sleep 2
elif [ "$choice" == "bspwm" ]; then
    curl -L https://is.gd/gh0stzk_dotfiles -o $HOME/RiceInstaller
    chmod +x RiceInstaller
    ./RiceInstaller
    cd $HOME/.config
    git clone https://github.com/pwnish3r/dotfiles-bspwm.git
    cd dotfiles-bspwm
    cp -r bspwm ../
    cp -r nvim ../
    cp -r tmux ../
    cp -r zsh ../
    echo -e "\e[32mInstall script 2/2 complete.The system will reboot now!\e[0m."
    sleep 2
fi
sudo systemctl enable sddm
