#!/bin/bash
read -p "username? " username
mkdir -p /home/projects
if [ ! -d "/home/projects/$username" ]; then
        useradd -b /home/projects -m -s /bin/zsh $username
        usermod -p '*' $username
        usermod -aG docker $username
        su -c "ssh-keygen -q -N '' -t rsa -f /home/projects/$username/.ssh/id_rsa" - $username
        su -c "git config --global user.name '$username deploy server'" - $username
        su -c "git config --global user.email 'info@cruncher.ch'" - $username
        su -c "createuser -drS $username" - postgres
        clear
        echo "Added $username"
        echo ""
        cat /home/projects/$username/.ssh/id_rsa.pub
        echo ""
else
        echo "dir exists"
fi
