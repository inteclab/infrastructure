#!/usr/bin/env bash

# OS Installation & Updates
sudo apt update && sudo apt full-upgrade -y
sudo apt install unattended-upgrades

# Disable root login and password-based SSH
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Do the stuff below as teleport admin
echo 'goto t.acap.cc and add a new ubuntu ssh node'
export USERNAME="mrpeterlee"
export GID="1026"
echo "sudo groupadd -g $GID $USERNAME"
echo "sudo useradd -m -u $GID -g $GID $USERNAME"
echo "sudo usermod -aG sudo $USERNAME"
