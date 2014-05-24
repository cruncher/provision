Quick and dirty provisioning script, will install the following on a bare Debian wheezy:

* nginx
* supervisor (with rc.d init scripts)
* PostrgreSQL and PostGIS
* Imaging libraries for PIL
* virtualenv
* memcached


Usage:

    sh -c "`curl https://raw.githubusercontent.com/cruncher/provision/wheezy-no-postgis/provision.sh`"

    
