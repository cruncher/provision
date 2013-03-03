#!/bin/bash
read -p "username? " username
mkdir -p /home/projects
if [ ! -d "/home/projects/$username" ]; then
        useradd -b /home/projects -m -s /bin/zsh $username
        sudo -u $username -H ssh-keygen -q -N '' -t rsa -f /home/projects/$username/.ssh/id_rsa
else
        echo "dir exists"
fi

