#!/bin/bash

DISTRIB=wheezy

read -p "update sources.list? (y/n)? " yn
if [ "$yn" = "y" ]; then
  apt-get -y update
  apt-get -y install netselect-apt
  /usr/bin/netselect-apt -n $DISTRIB -o sources.list
  sed -i 's/# deb http:\/\/security.debian.org/deb http:\/\/security.debian.org/g' sources.list
  sed -i "s/stable\/updates/$DISTRIB\/updates/g" sources.list
  mv /etc/apt/sources.list /etc/apt/sources.list.backup
  mv sources.list /etc/apt/
fi


apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get install -y sudo

echo "Cmnd_Alias PROJECT_CMND = /usr/local/bin/supervisorctl status*, /usr/local/bin/supervisorctl restart*, /etc/init.d/nginx reload*" >> /etc/sudoers
echo "# xxx ALL=(root) NOPASSWD: PROJECT_CMND" >> /etc/sudoers

# Remove apache
apt-get remove  -y --purge libapache2-mod-php5 apache2 libapache2-mod-php5filter php5 mysql-common
apt-get autoremove  -y
apt-get purge



## VIMRC ##
cat > vimrc <<EO_CONF
runtime! debian.vim
syntax on
set background=dark
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
if has("autocmd")
  filetype plugin indent on
endif
set incsearch           " Incremental search
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif
EO_CONF
mv /etc/vim/vimrc /etc/vim/vimrc.bckup
mv vimrc /etc/vim/vimrc

# skel content
cd /etc/skel/
curl -L https://dl.dropbox.com/u/63072/Data/skel.tar.gz | tar xvfz -
cd
# base stuff
curl -OL https://dl.dropbox.com/u/63072/Data/shorewall.zip

cd /etc/
unzip /root/shorewall.zip
sed -i 's/startup=0/startup=1/g' /etc/default/shorewall
/etc/init.d/shorewall start
rm /root/shorewall.zip

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

cd
curl -O https://raw.github.com/cruncher/provision/master/user_add.sh
curl -O https://raw.github.com/cruncher/provision/master/duplicity.sh

cd
mkdir -p .ssh
touch .ssh/authorized_keys
curl https://github.com/mbi.keys >> .ssh/authorized_keys

clear
echo "all done."
ls

