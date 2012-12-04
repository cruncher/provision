#!/bin/sh

# A duplicity script that backs up /etc and /home to a remote ftp server

DATE_TODAY=`date +%d`
PASSPHRASE='FIXME' # GPG
FTP_PASSWORD='FIXME'
FTP_USER='FIXME'
FTP_HOST='FIXME'
FTP_URL="$FTP_USER@$FTP_HOST"

export FTP_URL
export FTP_PASSWORD
export PASSPHRASE

###############################################

mkdir -p /var/log/duplicity

date >>/var/log/duplicity/etc.log
date >>/var/log/duplicity/home.log

duplicity remove-older-than 2M -v5 --allow-source-mismatch --force ftp://$FTP_URL/etc >>/var/log/duplicity/etc.log
duplicity remove-older-than 2M -v5 --allow-source-mismatch --force ftp://$FTP_URL/home >>/var/log/duplicity/home.log

if [ $DATE_TODAY = 01 ]
then
        duplicity full -v5 --allow-source-mismatch /etc  ftp://$FTP_URL/etc >>/var/log/duplicity/etc.log
        duplicity full -v5 --allow-source-mismatch /home ftp://$FTP_URL/home >>/var/log/duplicity/home.log
else
        duplicity incremental -v5 --allow-source-mismatch /etc ftp://$FTP_URL/etc >>/var/log/duplicity/etc.log
        duplicity incremental -v5 --allow-source-mismatch /home ftp://$FTP_URL/home >>/var/log/duplicity/home.log
fi

unset FTP_URL
unset PASSPHRASE
unset FTP_PASSWORD

exit 0

