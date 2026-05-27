#!/bin/bash

# Check if script is being run as root
if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if root login is already enabled
if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
   echo "Root login is already enabled"
   exit 0
fi

# Enable root login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart ssh

echo "Root login has been enabled"
