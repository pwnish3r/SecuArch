#!/bin/bash

SecuArchDir=~/auxiliary_scripts/SecuArch


hyprlock() {
	mkdir ~/.fonts
	cp $SecuArchDir/postInstall/hyprlock/Style_9/Fonts/. ~/.fonts/
	rm ~/.config/hypr/hyprlock-2k.conf
	rm ~/.config/hypr/hyprlock.conf
	cp $SecuArchDir/postInstall/hyprlock/Style_9/hyprlock.conf ~/.config/hypr/
	cp ~/.config/hypr/hyprlock.conf ~/.config/hypr/hyprlock-2k.conf
	cp $SecuArchDir/postInstall/hyprlock/Style_9/hyprlock.png ~/.config/hypr/
	cp $SecuArchDir/postInstall/hyprlock/Style_9/profile.png ~/.config/hypr/
}

install_zsh_plugins(){
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
}

sed -i "s|$HOME/auxiliary_scripts.*$||g" ~/.bashrc
rm -rf ~/Pictures/wallpapers
mkdir ~/Pictures/wallpapers
cp $SecuArchDir/media/SecuArchBlack.png ~/Pictures/wallpapers/
cp $SecuArchDir/media/SecuArchRed.png ~/Pictures/wallpapers/
#hyprlock
install_zsh_plugins
cp $SecuArchDir/postInstall/dotfiles/.zshrc ~/
rm -f ~/.config/systemd/user/service.service
rm -rf $SecuArchDir
rm -f ~/auxiliary_scripts/strap.sh
rm -rf ~/auxiliary_scripts/yay
systemctl --user daemon-reload
reboot
