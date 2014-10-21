#!/bin/bash
#
# Simple script for creating backups with Duplicity.
# Full backups are made on the 1st day of each month or with the 'full' option.
# Incremental backups are made on any other days.
#
# USAGE: backup.sh [full]
#

# get day of the month
DATE=`date +%d`

# Set protocol (use scp for sftp and ftp for FTP, see manpage for more)
BPROTO=rsync

# set user and hostname of backup account
BUSER='backups'
BHOST='backup.cruncher.ch'
PASSPHRASE=''
export PASSPHRASE

# Setting the password for the Backup account that the
# backup files will be transferred to.
# for sftp a public key can be used, see:
# http://wiki.hetzner.de/index.php/Backup
#BPASSWORD='yourpass'

# directories to backup (but . for /)
BDIRS="home"
LOGDIR='/var/log/duplicity'

# Setting the pass phrase to encrypt the backup files. Will use symmetrical keys in this case.

# encryption algorithm for gpg, disable for default (CAST5)
# see available ones via 'gpg --version'
ALGO=AES

##############################

if [ $ALGO ]; then
 GPGOPT="--gpg-options '--cipher-algo $ALGO'"
fi

if [ $BPASSWORD ]; then
 BAC="$BPROTO://$BUSER:$BPASSWORD@$BHOST"
else
 BAC="$BPROTO://$BUSER@$BHOST"
fi

BAC="$BAC//home/projects/backups/10decembre"

# Check to see if we're at the first of the month.
# If we are on the 1st day of the month, then run
# a full backup. If not, then run an incremental
# backup.

if [ $DATE = 01 ] || [ "$1" = 'full' ]; then
 TYPE='full'
else
 TYPE='incremental'
fi

for DIR in $BDIRS
do
  if [ $DIR = '.' ]; then
    EXCLUDELIST='/usr/local/etc/duplicity-exclude.conf'
  else
    EXCLUDELIST="/usr/local/etc/duplicity-exclude-$DIR.conf"
  fi

  if [ -f $EXCLUDELIST ]; then
    EXCLUDE="--exclude-filelist $EXCLUDELIST"
  else
    EXCLUDE=''
  fi

  # first remove everything older than 2 months
  if [ $DIR = '.' ]; then
   CMD="duplicity remove-older-than 2M --force -v5 $BAC/system >> $LOGDIR/system.log"
  else
   CMD="duplicity remove-older-than 2M --force -v5 $BAC/$DIR >> $LOGDIR/$DIR.log"
  fi
  eval $CMD

  # do a backup
  if [ $DIR = '.' ]; then
    CMD="duplicity $TYPE -v5 $GPGOPT $EXCLUDE / $BAC/system >> $LOGDIR/system.log"
  else
    CMD="duplicity $TYPE -v5 $GPGOPT $EXCLUDE /$DIR $BAC/$DIR >> $LOGDIR/$DIR.log"
  fi
  eval  $CMD

done

# Check the manpage for all available options for Duplicity.
# Unsetting the confidential variables
unset PASSPHRASE
unset FTP_PASSWORD

exit 0


