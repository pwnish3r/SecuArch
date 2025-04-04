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


sed -i \"s|^$HOME/auxiliary_scripts.*$||g\" ~/.bashrc
rm -rf ~/Pictures/wallpapers
mkdir ~/Pictures/wallpapers
cp $SecuArchDir/media/SecuArchBlack.png ~/Pictures/wallpapers/
cp $SecuArchDir/media/SecuArchRed.png ~/Pictures/wallpapers/
hyprlock
rm -f ~/.config/systemd/user/service.service
rm -rf $SecuArchDir
rm -f ~/auxiliary_scripts/strap.sh
rm -rf ~/auxiliary_scripts/yay
systemctl --user daemon-reload
reboot
