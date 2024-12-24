#!/bin/bash
echo "Now you can choose to install either i3 or bspwm. For any other WM or DE, check the arch wiki for details"
echo "Your choice: "
read choice
if [ "$choice" == "i3" ]; then
    yay -S i3 rofi thunar xclip clipmenu dunst feh picom xss-lock lxappearance arandr
    git clone https://github.com/pwnish3r/dotfiles-i3.git
    cd dotfiles-i3
    cp -r .config $HOME/
    echo "Install script 2/2 complete. Do you want to reboot now? (yes/no)"
    read reboot_now
    if [ "$reboot_now" == "yes" ]; then
        umount -R /mnt
        reboot
    else
        echo "You can reboot later with the 'reboot' command."
    fi
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
    echo "Install script 2/2 complete. Do you want to reboot now? (yes/no)"
    read reboot_now
    if [ "$reboot_now" == "yes" ]; then
        reboot
    else
        echo "You can reboot later with the 'reboot' command."
    fi
fi

