#!/bin/bash

set -e

# SFTP:
#REMOTE_USER="BACKUPUSER@BACKUPHOST"
#REPO_URL="sftp:$REMOTE_USER:backups/"

# S3:
# export AWS_ACCESS_KEY_ID="bucket-access-key"
# export AWS_SECRET_ACCESS_KEY="bucket-secret"
# REPO_URL="s3:sos-ch-gva-2.exo.io/bucket-name"

CANARY_HASH='abcdef-02134-abcdef-02134'
LOGFILE="/var/log/restic/`date +"%Y%m%d-%H%M%S"`.log"

mkdir -p /var/log/restic
touch $LOGFILE

echo "Start: $(date)" >> $LOGFILE


/usr/bin/restic \
        --quiet --repo $REPO_URL \
        --password-file=/root/.restic-password snapshots >> $LOGFILE 2>&1 \
        \
        || \
        /usr/bin/restic --repo $REPO_URL \
        --password-file=/root/.restic-password init | tee -a $LOGFILE


/usr/bin/restic \
        forget --keep-last 75  --prune \
        --password-file=/root/.restic-password \
        --repo $REPO_URL >> $LOGFILE 2>&1

/usr/bin/restic \
        --repo $REPO_URL \
        backup / \
        --password-file=/root/.restic-password \
        --exclude-file=/root/.restic-ignores \
        --exclude=.venv --exclude=.pyenv --exclude="*.sock" \
        --exclude-caches \
        --verbose=0 >> $LOGFILE 2>&1


curl -s -o /dev/null  https://canary.cruncher.ch/report/$CANARY_HASH/?result=$LOGFILE   >> $LOGFILE 2>&1


echo "Finished: $(date)" >> $LOGFILE
