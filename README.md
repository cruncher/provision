Quick and dirty provisioning script, will install the following on a bare Debian squeeze:

* nginx
* supervisor (with rc.d init scripts)
* PostrgreSQL and PostGIS
* Imaging libraries for PIL
* virtualenv
* memcached


Usage:

    sh -c "`curl https://raw.github.com/cruncher/provision/master/provision.sh`"

    
