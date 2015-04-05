#!/bin/bash
read -p "username? " username
mkdir -p /home/projects
if [ ! -d "/home/projects/$username" ]; then
        useradd -b /home/projects -m -s /bin/zsh $username
        sudo -u $username -H ssh-keygen -q -N '' -t rsa -f /home/projects/$username/.ssh/id_rsa
        sudo -u $username git config --global user.name '$username deploy server'
        sudo -u $username git config --global user.email 'info@cruncher.ch'
        su -c 'createuser -drS $username' - postgres
        clear
        echo "Added $username"
        echo ""
        cat /home/projects/$username/.ssh/id_rsa.pub 
        echo ""
else
        echo "dir exists"
fi

