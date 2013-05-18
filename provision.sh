#!/bin/bash


read -p "update sources.list? (y/n)? " yn
if [ "$yn" = "y" ]; then
  apt-get -y update
  apt-get -y install netselect-apt
  /usr/bin/netselect-apt -n squeeze -o sources.list
  sed -i 's/# deb http:\/\/security.debian.org/deb http:\/\/security.debian.org/g' sources.list
  sed -i 's/stable\/updates/squeeze\/updates/g' sources.list
  mv /etc/apt/sources.list /etc/apt/sources.list.backup
  mv sources.list /etc/apt/
fi


apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get install -y sudo

wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
rm nginx_signing.key

echo "deb http://nginx.org/packages/debian/ squeeze nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/debian/ squeeze nginx" >> /etc/apt/sources.list
echo "Cmnd_Alias PROJECT_CMND = /usr/local/bin/supervisorctl status*, /usr/local/bin/supervisorctl restart*, /etc/init.d/nginx reload*" >> /etc/sudoers
echo "# xxx ALL=(root) NOPASSWD: PROJECT_CMND" >> /etc/sudoers

# Remove apache
apt-get remove  -y --purge libapache2-mod-php5  apache2 libapache2-mod-php5filter php5
apt-get autoremove  -y
apt-get purge

apt-get -y  install postgresql postgresql-client libpq-dev postgis postgresql-8.4-postgis gdal-contrib gdal-bin mcelog apt-dater-host
apt-get -y  install nginx
apt-get -y  install memcached libjpeg62-dev libfreetype6-dev python-dev python-virtualenv python-pip git-core screen zsh vim gettext duplicity ncftp shorewall unzip

apt-get -y update
apt-get  -y upgrade

# postgis template
su - postgres -c 'curl https://docs.djangoproject.com/en/1.5/_downloads/create_template_postgis-debian.sh|sh'

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
mv debian-norrgard /etc/init.d/supervisord
chmod +x /etc/init.d/supervisord
update-rc.d supervisord defaults
/etc/init.d/supervisord start
/etc/init.d/nginx stop
sed -i 's/include \/etc\/nginx\/conf.d\/\*\.conf;/include \/etc\/nginx\/sites-enabled\/\*\.conf;/g' /etc/nginx/nginx.conf


## SYSCTL ##
#kernel.shmmax=8589934592
cat > 98-mem-tuning.conf <<EO_CONF
kernel.shmall=2097152
EO_CONF

cat > 99-network-tuning.conf <<EO_CONF
net.ipv4.ip_local_port_range=1024 65000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.core.netdev_max_backlog=4096
net.core.rmem_max=16777216
net.core.somaxconn=4096
net.core.wmem_max=16777216
net.ipv4.tcp_max_syn_backlog=20480
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_wmem=4096 65536 16777216
vm.min_free_kbytes=65536
EO_CONF

mv 98-mem-tuning.conf 99-network-tuning.conf /etc/sysctl.d/
/sbin/sysctl -p /etc/sysctl.d/98-mem-tuning.conf
/sbin/sysctl -p /etc/sysctl.d/99-network-tuning.conf

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
curl -O https://raw.github.com/cruncher/provision/master/user_add.sh
curl -O https://raw.github.com/cruncher/provision/master/duplicity.sh

cd /etc/
unzip /root/shorewall.zip
sed -i 's/startup=0/startup=1/g' /etc/default/shorewall
/etc/init.d/shorewall start
rm /root/shorewall.zip
cd

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

clear
echo "all done..."
ls

