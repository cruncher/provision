#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
DISTRIB=stretch
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"

echo 'export LC_ALL="en_US.UTF-8"' >> /etc/profile
echo 'export LANG="en_US.UTF-8"' >> /etc/profile
echo 'export LC_MESSAGES="en_US.UTF-8"' >> /etc/profile

read -p "update sources.list? (y/n)? " yn_sources
read -p "create swap? (y/n)? " yn_swap
read -p "launch firewall? (y/n)? " yn_fw

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
apt-get install -y sudo curl gnupg-agent
# curl -sL https://deb.nodesource.com/setup_0.12 | bash -
# curl -sL https://deb.nodesource.com/setup_5.x | bash -
# curl -sL https://deb.nodesource.com/setup_7.x | bash -
curl -sL https://deb.nodesource.com/setup_12.x | bash -

## SYSCTL ##

page_size=`getconf PAGE_SIZE`
phys_pages=`getconf _PHYS_PAGES`
shmall=`expr $phys_pages / 2`
shmmax=`expr $shmall \* $page_size`
echo "kernel.shmmax = $shmmax" >> /etc/sysctl.conf
echo "kernel.shmall = $shmall" >> /etc/sysctl.conf
sysctl -p

echo "Cmnd_Alias PROJECT_CMND = /usr/local/bin/supervisorctl status*, /usr/local/bin/supervisorctl restart*, /etc/init.d/nginx reload*" >> /etc/sudoers
echo "# xxx ALL=(root) NOPASSWD: PROJECT_CMND" >> /etc/sudoers
echo "# mbi ALL=NOPASSWD: /usr/bin/apt-get, /usr/bin/aptitude" >> /etc/sudoers

# Remove apache
apt-get remove  -y --purge libapache2-mod-php apache2  php mysql-common libmysqlclient18
apt-get autoremove  -y
apt-get purge

apt-get -y  install build-essential
apt-get -y  install nginx postgresql postgresql-client postgresql-contrib  apt-dater-host debian-goodies libffi-dev libssl-dev ntpd
apt-get -y  install mcelog 
# Pyenv:
apt-get -y  install sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
apt-get -y  install librsync-dev lftp
apt-get -y  install memcached libjpeg-dev libfreetype6-dev python-dev python3-dev python-virtualenv python-pip git-core screen zsh vim gettext ncftp shorewall unzip ncurses-dev
apt-get -y  install nodejs
/usr/bin/npm install -g clean-css-cli
mkdir /var/log/duplicity
pip install lockfile

# had to manually do these in one occasion
#pg_createcluster 9.4 main
#pg_ctlcluster 9.4 main start

# ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
# ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib
# ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib


## SUPERVISORD ##
pip install supervisor
mkdir /etc/supervisord.d

cat > supervisord.conf <<EO_CONF
[unix_http_server]
file=/var/tmp/supervisor.sock   ; (the path to the socket file)
[supervisord]
logfile=/var/log/supervisord.log ; (main log file;default $CWD/supervisord.log)
logfile_maxbytes=50MB        ; (max main logfile bytes b4 rotation;default 50MB)
logfile_backups=10           ; (num of main logfile rotation backups;default 10)
loglevel=info                ; (log level;default info; others: debug,warn,trace)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
nodaemon=false               ; (start in foreground if true;default false)
minfds=1024                  ; (min. avail startup file descriptors;default 1024)
minprocs=200                 ; (min. avail process descriptors;default 200)
environment=LANG=en_US.UTF-8, LC_ALL=en_US.UTF-8, LC_LANG=en_US.UTF-8
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
[supervisorctl]
serverurl=unix:///var/tmp/supervisor.sock ; use a unix:// URL  for a unix socket
[include]
files = /etc/supervisord.d/*.conf
EO_CONF
mv supervisord.conf /etc

wget --no-check-certificate https://raw.github.com/Supervisor/initscripts/master/debian-norrgard
sed -i 's/DAEMON=\/usr\/bin/DAEMON=\/usr\/local\/bin/g' debian-norrgard
sed -i 's/SUPERVISORCTL=\/usr\/bin/SUPERVISORCTL=\/usr\/local\/bin/g' debian-norrgard
sed -i 's/DAEMON_ARGS="--pidfile \${PIDFILE}"/DAEMON_ARGS="--pidfile \${PIDFILE} -c \/etc\/supervisord.conf"/g' debian-norrgard
sed -i 's/# server_names_hash_bucket_size 64/server_names_hash_bucket_size 64/g' /etc/nginx/nginx.conf
rm /etc/nginx/sites-enabled/default
mv debian-norrgard /etc/init.d/supervisord
chmod +x /etc/init.d/supervisord
update-rc.d supervisord defaults
/etc/init.d/supervisord start
/etc/init.d/nginx stop


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
update-alternatives --set editor /usr/bin/vim.basic

# skel content
cd /etc/skel/
curl -L https://raw.githubusercontent.com/cruncher/provision/stretch/dl/skel.tar.gz | tar xvfz -

# base stuff
if [ "$yn_fw" = "y" ]; then
  cd
  curl -OL https://raw.githubusercontent.com/cruncher/provision/stretch/dl/shorewall.zip
  cd /etc/
  unzip /root/shorewall.zip
  sed -i 's/startup=0/startup=1/g' /etc/default/shorewall
  /etc/init.d/shorewall start
  rm /root/shorewall.zip
fi

# SSHD conf from https://wiki.mozilla.org/Security/Guidelines/OpenSSH
cat > sshdconf <<EO_CONF
# Supported HostKey algorithms by order of preference.
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
 
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
 
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
 
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
 
# Password based logins are disabled - only public key based logins are allowed.
AuthenticationMethods publickey
 
# LogLevel VERBOSE logs user's key fingerprint on login. Needed to have a clear audit track of which key was using to log in.
LogLevel VERBOSE
 
# Log sftp level file access (read/write/etc.) that would not be easily logged otherwise.
Subsystem sftp  /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO
 
# Root login is not allowed for auditing reasons. This is because it's difficult to track which process belongs to which root user:
#
# On Linux, user sessions are tracking using a kernel-side session id, however, this session id is not recorded by OpenSSH.
# Additionally, only tools such as systemd and auditd record the process session id.
# On other OSes, the user session id is not necessarily recorded at all kernel-side.
# Using regular users in combination with /bin/su or /usr/bin/sudo ensure a clear audit track.
PermitRootLogin No
 
# Use kernel sandbox mechanisms where possible in unprivileged processes
# Systrace on OpenBSD, Seccomp on Linux, seatbelt on MacOSX/Darwin, rlimit elsewhere.
UsePrivilegeSeparation sandbox
EO_CONF
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
mv sshdconf /etc/ssh/sshd_config
/etc/init.d/ssh try-restart

cd
curl -OL https://raw.github.com/cruncher/provision/stretch/user_add.sh
curl -OL https://raw.githubusercontent.com/cruncher/provision/stretch/duplicity.sh
chmod +x user_add.sh duplicity.sh

cd
mkdir -p .ssh
touch .ssh/authorized_keys
curl -L https://github.com/mbi.keys >> .ssh/authorized_keys

cd
mkdir tmp
cd tmp
wget https://code.launchpad.net/duplicity/0.7-series/0.7.10/+download/duplicity-0.7.10.tar.gz
tar xvfz duplicity-0.7.10.tar.gz
cd duplicity-0.7.10
python setup.py build
python setup.py install
cd

clear
echo "all done."
hash -r
ls
