#!/bin/bash

mv ~/.zshrc-dot ~/.zshrc
sed -i \"s|^$HOME/auxiliary_scripts.*$||g\" ~/.bashrc
rm -f ~/.config/systemd/user/service.service
rm -f ~/auxiliary_scripts/SecuArch/postInstall/service.sh
rm -rf ~/auxiliary_scripts/SecuArch
rm -f ~/auxiliary_scripts/strap.sh
rm -rf ~/auxiliary_scripts/yay
systemctl --user daemon-reload
reboot
