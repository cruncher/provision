#!/bin/bash

apt-get install -y sudo
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
rm nginx_signing.key

sudo su -c 'echo "deb http://nginx.org/packages/debian/ squeeze nginx" >> /etc/apt/sources.list'
sudo su -c 'echo "deb-src http://nginx.org/packages/debian/ squeeze nginx" >> /etc/apt/sources.list'
sudo su -c 'echo "Cmnd_Alias PROJECT_CMND = /usr/local/bin/supervisorctl status*, /usr/local/bin/supervisorctl restart*, /etc/init.d/nginx reload*" >> /etc/sudoers'
sudo su -c 'echo "# xxx ALL=(root) NOPASSWD: PROJECT_CMND" >> /etc/sudoers'

# Remove apache
sudo apt-get remove  -y --purge libapache2-mod-php5  apache2 libapache2-mod-php5filter php5
sudo apt-get autoremove  -y
sudo apt-get purge

sudo apt-get -y  install postgresql postgresql-client libpq-dev postgis postgresql-8.4-postgis gdal-contrib gdal-bin mcelog
sudo apt-get -y  install nginx
sudo apt-get -y  install memcached libjpeg62-dev libfreetype6-dev python-dev python-virtualenv python-pip git-core screen zsh vim gettext duplicity ncftp shorewall unzip

sudo apt-get -y update
sudo apt-get  -y upgrade

# postgis template
sudo su - postgres -c 'curl https://docs.djangoproject.com/en/dev/_downloads/create_template_postgis-debian1.sh|sh'

sudo pip install supervisor
sudo mkdir /etc/supervisord.d

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
sudo mv supervisord.conf /etc

wget https://raw.github.com/Supervisor/initscripts/master/debian-norrgard
sed -i 's/DAEMON=\/usr\/bin/DAEMON=\/usr\/local\/bin/g' debian-norrgard
sed -i 's/SUPERVISORCTL=\/usr\/bin/SUPERVISORCTL=\/usr\/local\/bin/g' debian-norrgard
sed -i 's/DAEMON_ARGS="--pidfile \${PIDFILE}"/DAEMON_ARGS="--pidfile \${PIDFILE} -c \/etc\/supervisord.conf"/g' debian-norrgard

sudo mv debian-norrgard /etc/init.d/supervisord
sudo chmod +x /etc/init.d/supervisord
sudo update-rc.d supervisord defaults
/etc/init.d/supervisord start
/etc/init.d/nginx stop

