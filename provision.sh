#!/bin/bash


echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen 
/usr/sbin/locale-gen

export DEBIAN_FRONTEND=noninteractive
DISTRIB=bookworm
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"


echo 'export LC_ALL="en_US.UTF-8"' >> /etc/profile
echo 'export LANG="en_US.UTF-8"' >> /etc/profile
echo 'export LC_MESSAGES="en_US.UTF-8"' >> /etc/profile

read -p "update sources.list? (y/n)? " yn_sources
read -p "create swap? (y/n)? " yn_swap

if [ "yn_sources" = "y" ]; then
  apt-get -y update
  apt-get -y install netselect-apt
  /usr/bin/netselect-apt -n $DISTRIB -o sources.list
  sed -i 's/# deb http:\/\/security.debian.org/deb http:\/\/security.debian.org/g' sources.list
  sed -i "s/stable\/updates/$DISTRIB\/updates/g" sources.list
  mv /etc/apt/sources.list /etc/apt/sources.list.backup
  mv sources.list /etc/apt/
fi

# swap
if [ "yn_swap" = "y" ]; then
  dd if=/dev/zero of=/swapfile bs=1024 count=1M
  chmod 0600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo " /swapfile       none    swap    sw      0       0" >> /etc/fstab
  echo 10 | sudo tee /proc/sys/vm/swappiness
  echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf
fi

apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get install -y sudo ca-certificates curl gnupg

## SYSCTL ##

page_size=`getconf PAGE_SIZE`
phys_pages=`getconf _PHYS_PAGES`
shmall=`expr $phys_pages / 2`
shmmax=`expr $shmall \* $page_size`
echo "kernel.shmmax = $shmmax" >> /etc/sysctl.conf
echo "kernel.shmall = $shmall" >> /etc/sysctl.conf
sysctl -p

echo "Cmnd_Alias PROJECT_CMND = /usr/bin/supervisorctl status*, /usr/bin/supervisorctl restart*, /etc/init.d/nginx reload*" >> /etc/sudoers
echo "# xxx ALL=(root) NOPASSWD: PROJECT_CMND" >> /etc/sudoers
echo "# mbi ALL=NOPASSWD: /usr/bin/apt-get, /usr/bin/aptitude" >> /etc/sudoers

# Remove apache
apt-get remove  -y --purge libapache2-mod-php apache2  php mysql-common
apt-get autoremove  -y
apt-get purge

apt-get -y  install build-essential
apt-get -y  install nginx postgresql postgresql-client postgresql-contrib  apt-dater-host debian-goodies libffi-dev libssl-dev ntp supervisor redis-server
# apt-get -y  install mcelog 
pg_ctlcluster 15 main start
    
# Pyenv:
apt-get -y  install make fail2ban libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev  git
apt-get -y  install librsync-dev lftp rsync net-tools
apt-get -y  install memcached libjpeg-dev libfreetype6-dev python3-dev python3-venv python3-pip git-core screen zsh vim gettext ncftp unzip ncurses-dev  ncurses-term
# apt-get -y  install nodejs
apt-get -y  install certbot python3-certbot-nginx
apt-get -y  install restic
apt-get -y  install bpytop

# /usr/bin/npm install -g clean-css-cli
mkdir /var/log/restic

apt-get -y install apt-transport-https ca-certificates curl gnupg2  software-properties-common
# curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
# apt-get -y update
# sudo apt-get -y install docker-ce docker-ce-cli containerd.io
# apt-get -y install docker docker-compose

/etc/init.d/nginx stop
rm -f /etc/nginx/sites-enabled/default
systemctl enable nginx


# Setup certbot nginx autoreload after update
mkdir -p /etc/letsencrypt/renewal-hooks/post
curl -s -o /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh \
  https://gist.githubusercontent.com/justinhartman/79c527076ce7cc740423eb92b5600d52/raw/5709ad0ff74d713b3ab26c6b7c8999f98838ff0a/01_nginx-reload-post-hook.sh 
chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

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
set mouse-=a

EO_CONF
mv /etc/vim/vimrc /etc/vim/vimrc.bckup
mv vimrc /etc/vim/vimrc
update-alternatives --set editor /usr/bin/vim.basic

# skel content
cd /etc/skel/
curl -L https://raw.githubusercontent.com/cruncher/provision/bookworm/dl/skel.tar.gz | tar xvfz -

# SSHD conf from https://wiki.mozilla.org/Security/Guidelines/OpenSSH
cd
cat > sshdconf <<EO_CONF
# Supported HostKey algorithms by order of preference.
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Password based logins are disabled - only public key based logins are allowed.
AuthenticationMethods publickey
 
# LogLevel VERBOSE logs user's key fingerprint on login. Needed to have a clear audit track of which key was using to log in.
LogLevel VERBOSE
 
# Log sftp level file access (read/write/etc.) that would not be easily logged otherwise.
Subsystem sftp  /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO
 
# Root login is not allowed for auditing reasons. This is because it's difficult to track which process belongs to which root user:
#
# On Linux, user sessions are tracking using a kernel-side session id, however, this session id is not recorded by OpenSSH.
# Additionally, only tools such as systemd and auditd record the process session id.
# On other OSes, the user session id is not necessarily recorded at all kernel-side.
# Using regular users in combination with /bin/su or /usr/bin/sudo ensure a clear audit track.
PermitRootLogin No


# Hardened:
# https://www.ssh-audit.com/hardening_guides.html#debian_12
#
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
# RequiredRSASize 3072
CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-
HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256
PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256

EO_CONF
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
mv sshdconf /etc/ssh/sshd_config

# sshd hardening from 
# https://www.ssh-audit.com/hardening_guides.html#debian_12
rm /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" 
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
mv /etc/ssh/moduli.safe /etc/ssh/moduli

/etc/init.d/ssh try-restart



# node exporter
cd
mkdir -p tmp_ne
cd tmp_ne
groupadd --system prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus
curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest| grep browser_download_url|grep linux-amd64|cut -d '"' -f 4|wget -qi -
tar -xvf node_exporter*.tar.gz
cd  node_exporter*/
cp node_exporter /usr/local/bin
cd
rm -rf tmp_ne

cat >  /etc/systemd/system/node_exporter.service <<EO_CONF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EO_CONF

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Fix debian 12 fail2ban
cat > /etc/fail2ban/jail.local <<EO_CONF
[DEFAULT]
# Debian 12 has no log files, just journalctl
backend = systemd

# "bantime" is the number of seconds that a host is banned.
bantime  = 1h
# "maxretry" is the number of failures before a host get banned.
maxretry = 5
# A host is banned if it has generated "maxretry" during the last "findtime"
findtime  = 1h

[sshd]
enabled = true
EO_CONF

systemctl restart fail2ban.service


cd
curl -OL https://raw.github.com/cruncher/provision/bookworm/user_add.sh
chmod +x user_add.sh 

cd
mkdir -p .ssh
touch .ssh/authorized_keys
curl -L https://github.com/mbi.keys >> .ssh/authorized_keys

cd
strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 64 | tr -d '\n' > .restic-password
chmod 400 .restic-password
touch .restic-ignores

curl -OL https://raw.githubusercontent.com/cruncher/provision/bookworm/backup.sh
chmod +x backup.sh

# clear
echo "all done."
hash -r
ls
