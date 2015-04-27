Quick and dirty provisioning script, will install the following on a bare Debian Jessie:

* nginx
* supervisor (with rc.d init scripts)
* PostrgreSQL and PostGIS
* Imaging libraries for PIL
* virtualenv
* memcached


Usage:

    sh -c "`wget -O - https://raw.githubusercontent.com/cruncher/provision/jessie/provision.sh`"

