Quick and dirty provisioning script, will install the following on a bare Debian Stretch:

* nginx
* supervisor (with rc.d init scripts)
* PostrgreSQL and PostGIS
* Imaging libraries for PIL
* virtualenv
* memcached


Usage:

    sh -c "`wget -O - https://raw.githubusercontent.com/cruncher/provision/bookworm/provision.sh`"

