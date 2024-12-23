#!/bin/bash
set -e
trap 'echo "An error occurred on line $LINENO. Exiting..."; exit 1' ERR
cd $HOME
mkdir auxiliary_scripts
cd auxiliary_scripts
git clone https:/github.com/pwnish3r/SecuArch.git
chmod +x SecuArch/postInstall/after_install_*.sh
sudo systemctl enable SecuArch/script-scheduler.service
sudo cp -r grubTheme/CyberEXS /boot/grub/themes
sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/CyberEXS/theme.txt|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /usr/lib/systemd/system/grub-btrfsd.service
sudo systemctl enable grub-btrfsd
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
yay -S timeshift-autosnap dosfstools ntfs-3g wget curl tmux vim zram metasploit nmap wireshark-cli wireshark-qt aircrack-ng john hydra burpsuite tcpdump openbsd-netcat responder open-vm-tools ufw autopsy sleuthkit apparmor audit logwatch ossec docker sliver exploitdb hashcat seclists aws-cli azure-cli google-cloud-sdk
sudo pacman -S sddm
sudo systemctl enable sddm
systemctl enable vmtoolsd.service
systemctl start vmtoolsd.service
systemctl enable ufw
systemctl start ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable
systemctl enable apparmor
systemctl enable auditd
systemctl start docker
systemctl enable docker
yay -S qt6-svg
sudo git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
echo "Install script 1/2 complete. Do you want to reboot now? (yes/no)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    umount -R /mnt
    reboot
else
    echo "You can reboot later with the 'reboot' command."
fi
