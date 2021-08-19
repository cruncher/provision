#!/bin/bash

REMOTE_USER="BACKUPUSER@BACKUPHOST"

ssh $REMOTE_USER mkdir -p backups
REPO_URL="sftp:$REMOTE_USER:backups/"
LOGFILE="/var/log/restic/`date +"%Y%m%d-%H%M%S"`.log"

mkdir -p /var/log/restic
touch $LOGFILE

# Make sure the repo exists, create it otherwise
/usr/bin/restic \
        --quiet --repo $REPO_URL \
        --password-file=/root/.restic-password snapshots >> $LOGFILE 2>&1 \
        \
        || \
        /usr/bin/restic --repo $REPO_URL \
        --password-file=/root/.restic-password init | tee -a $LOGFILE


# Prune backups older than 45 days
/usr/bin/restic \
        forget --keep-last 45  --prune \
        --password-file=/root/.restic-password \
        --repo $REPO_URL >> $LOGFILE 2>&1

# Take a new snapshot
/usr/bin/restic \
        --repo $REPO_URL \
        backup /home/projects \
        --password-file=/root/.restic-password \
        --exclude-file=/root/.restic-ignores \
        --exclude-caches \
        --verbose=0 >> $LOGFILE 2>&1

