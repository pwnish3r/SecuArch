#!/bin/bash

# Directory where scripts are stored
SCRIPT_DIR="$HOME/auxiliary_scripts/SecuArch/postInstall"

# File that tracks the current script to execute
CURRENT_SCRIPT_FILE="$SCRIPT_DIR/current_script"

# Initialize the tracking file if it doesn't exist
if [ ! -f "$CURRENT_SCRIPT_FILE" ]; then
    echo -e "\e[31mNo current script to run. Initializing with the first script...\e[0m"
    NEXT_SCRIPT=$(ls "$SCRIPT_DIR" | grep -E '^after_install_[0-9]+\.sh$' | sort | head -n 1)
    if [ -z "$NEXT_SCRIPT" ]; then
        echo -e "No scripts found to run. \e[31mExiting...\e[0m"
        exit 0
    fi
    echo "$NEXT_SCRIPT" > "$CURRENT_SCRIPT_FILE"
fi

# Read the current script name
CURRENT_SCRIPT=$(cat "$CURRENT_SCRIPT_FILE")

# Run the current script if it exists
if [ -f "$SCRIPT_DIR/$CURRENT_SCRIPT" ]; then
    echo "Executing $CURRENT_SCRIPT..."
    bash "$SCRIPT_DIR/$CURRENT_SCRIPT"
    echo -e "\e[32mFinished executing $CURRENT_SCRIPT.\e[0m"
    sleep 3
    rm -f "$SCRIPT_DIR/$CURRENT_SCRIPT"
    NEXT_SCRIPT=$(ls "$SCRIPT_DIR" | grep -E '^after_install_[0-9]+\.sh$' | sort | head -n 1)
    echo "$NEXT_SCRIPT" > "$CURRENT_SCRIPT_FILE"
    reboot
else
    echo "Script $CURRENT_SCRIPT not found. Exiting..."
    exit 1
fi

if [ -z "$NEXT_SCRIPT" ]; then
    echo "No more scripts to run. Cleaning up..."
    rm -f "$CURRENT_SCRIPT_FILE"
#    systemctl disable script-scheduler.service || true
    sed -i "s|^\"\$.*\"||g" ~/.bashrc
    exit 0
fi

# Update the current script file with the next script
echo "$NEXT_SCRIPT" > "$CURRENT_SCRIPT_FILE"

