#!/bin/bash

REMOTE_USER="BACKUPUSER@BACKUPHOST"

ssh $REMOTE_USER mkdir -p backups

REPO_URL="sftp:$REMOTE_USER:backups/"
LOGFILE="/var/log/restic/`date +"%Y%m%d-%H%M%S"`.log"

mkdir -p /var/log/restic
touch $LOGFILE
find /var/log/restic/ -type f -mtime 50 -delete

/usr/bin/restic \
        --quiet --repo $REPO_URL \
        --password-file=/root/.restic-password snapshots >> $LOGFILE 2>&1 \
        \
        || \
        /usr/bin/restic --repo $REPO_URL \
        --password-file=/root/.restic-password init | tee -a $LOGFILE


/usr/bin/restic \
        forget --keep-last 45  --prune \
        --password-file=/root/.restic-password \
        --repo $REPO_URL >> $LOGFILE 2>&1

/usr/bin/restic \
        --repo $REPO_URL \
        backup /home/projects \
        --password-file=/root/.restic-password \
        --exclude-file=/root/.restic-ignores \
        --exclude=.venv --exclude=.pyenv --exclude="*.sock" \
        --exclude-caches \
        --verbose=0 >> $LOGFILE 2>&1
