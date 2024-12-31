#!/bin/bash

choice=choice

if [ "$choice" == "2" ];then 
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

