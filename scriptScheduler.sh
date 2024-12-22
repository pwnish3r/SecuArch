#!/bin/bash

# Directory where scripts are stored
SCRIPT_DIR="$HOME/auxiliary_scripts/postInstall"

# File that tracks the current script to execute
CURRENT_SCRIPT_FILE="$SCRIPT_DIR/after_install_1.sh"

# Check if the tracking file exists
if [ ! -f "$CURRENT_SCRIPT_FILE" ]; then
    echo "No current script to run. Exiting..."
    exit 0
fi

# Read the current script name
CURRENT_SCRIPT=$(cat "$CURRENT_SCRIPT_FILE")

# Run the current script if it exists
if [ -f "$SCRIPT_DIR/$CURRENT_SCRIPT" ]; then
    echo "Executing $CURRENT_SCRIPT..."
    bash "$SCRIPT_DIR/$CURRENT_SCRIPT"
    echo "Finished executing $CURRENT_SCRIPT."
    rm -f "$SCRIPT_DIR/$CURRENT_SCRIPT"
else
    echo "Script $CURRENT_SCRIPT not found. Exiting..."
    exit 1
fi

# Determine the next script to run
NEXT_SCRIPT=$(ls "$SCRIPT_DIR" | grep -E '^after_install_[0-9]+\\.sh$' | sort | head -n 1)

if [ -z "$NEXT_SCRIPT" ]; then
    echo "No more scripts to run. Cleaning up..."
    rm -f "$CURRENT_SCRIPT_FILE"
    systemctl disable script-scheduler.service
    exit 0
fi

# Update the current script file with the next script
echo "$NEXT_SCRIPT" > "$CURRENT_SCRIPT_FILE"

