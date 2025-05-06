#!/bin/bash

file_path="/etc/NetworkManager/dispatch.d/ifup-local"
content='if [ "$1" == "eno6" ]; then
  /sbin/ethtool -G eno6 rx 4096 tx 2048
fi'

# Check if the file exists
if [ ! -e "$file_path" ]; then
  # Create the file if it doesn't exist
  echo "$content" | sudo tee "$file_path" > /dev/null
  # Set ownership to root
  sudo chown root:root "$file_path"
  # Set permissions to 755
  sudo chmod 755 "$file_path"
  echo "File '$file_path' created and configured."
else
  echo "File '$file_path' already exists. No changes made."
fi
