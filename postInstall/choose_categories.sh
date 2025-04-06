#!/bin/bash

if ! command -v dialog &>/dev/null; then
  echo "dialog not found. Installing..."
  sudo pacman -S --noconfirm dialog
fi

if [ ! -f categories.txt ]; then
  echo "categories.txt not found!"
  exit 1
fi

OPTIONS=()
while IFS= read -r category; do
  OPTIONS+=("$category" "$category tools" off)
done < categories.txt

CHOICES=$(dialog --clear --stdout \
  --title "Hacking Category Installer" \
  --checklist "Select categories to install:" 20 60 12 \
  "${OPTIONS[@]}")

clear

if [[ -z "$CHOICES" ]]; then
  echo "No categories selected. Exiting."
  exit 0
fi

echo "Installing selected BlackArch categories..."
for category in $CHOICES; do
  category=${category//\"}  
  echo " Installing: $category"
  sudo pacman -S --needed "blackarch-$category"
done

echo "[!] Done installing selected categories."