#!/bin/bash

# Weekly cron job to backup to iRODS location
# Backed-up:
#    MySQL databases:
#       coge
#       wikidb
#       cogelinks
#    Data directories:
#       Wiki web directory
#       SVN code repo
#       CoGe data
# Created: 7/11/12 by mdb

echo `date` "Backup started"

ICMD=/usr/local/bin
DAYS_UNTIL_DELETE=21
VERSION=$(date '+%Y%m%d')
LOCAL=/storage/coge/backup
REMOTE=backup

#
# Dump databases and copy to remote iRODS location
#
LOCAL_MYSQL=$LOCAL/mysql_$VERSION
mkdir -p $LOCAL_MYSQL
echo `date` "Dumping MySQL databases"
mysqldump -u root -p321coge123 wikidb -c | gzip -9 > $LOCAL_MYSQL/wikidb.sql.gz
mysqlhotcopy -u root -p 321coge123 cogelinks $LOCAL_MYSQL
mysqlhotcopy --port=3307 -u root -p 321coge123 coge $LOCAL_MYSQL
echo `date` "Pushing MySQL databases to iRODS"
$ICMD/iput -bfr $LOCAL_MYSQL $REMOTE

#
# Remove old database backups
#
echo `date` "Deleting old backups (local & remote)"
LOCAL_DELETIONS=`find $LOCAL/mysql_* -maxdepth 1 -type d -mtime +$DAYS_UNTIL_DELETE`
if [ -n "$LOCAL_DELETIONS" ];
then
   echo delete local $LOCAL_DELETIONS
   rm -rf $LOCAL_DELETIONS
fi
for d in `$ICMD/ils backup | grep 'mysql_' | sed 's/.*\(mysql_.*\)/\1/'`
do
   if [ ! -d $LOCAL/$d ];
   then
      echo delete iRODS backup/$d
      $ICMD/irm -r backup/$d
   fi
done

#
# Sync data directories with remote iRODS location
#
echo `date` "Syncing data directories with iRODS"
$ICMD/icd
$ICMD/irsync -rs /opt/apache2/cogepedia i:$REMOTE/cogepedia
$ICMD/irsync -rs /storage/coge/data/genomic_sequence/ i:$REMOTE/genomic_sequence
$ICMD/irsync -rs /storage/coge/data/experiments/ i:$REMOTE/experiments

echo `date` "Backup completed"
