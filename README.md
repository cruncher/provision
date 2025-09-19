Quick and dirty provisioning script, will install the following on a bare Debian Trixie:

* nginx
* supervisor (with rc.d init scripts)
* PostrgreSQL and PostGIS
* Imaging libraries for PIL
* Redis, Memcached


Usage:

    sh -c "`wget -O - https://raw.githubusercontent.com/cruncher/provision/trixie/provision.sh`"

