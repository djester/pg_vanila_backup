#!/bin/bash

# Initialization

PG_BACKUP_HOST=$1
[ "${PG_BACKUP_HOST}" ] || { echo "ERROR: no host for backup" >&2; exit 1; }

PG_BACKUP_USER=replica
#PG_BACKUP_SLOT=bckp

PG_BACKUP_MODE=$2
PG_BACKUP_MODE_DEFAULT=f
[ "${PG_BACKUP_MODE}" ] || { PG_BACKUP_MODE=$PG_BACKUP_MODE_DEFAULT ; }

case $PG_BACKUP_MODE in
        "n"     )       PG_BACKUP_MODE_PARAMETER="--wal-method=none" ;;
        "f"     )       PG_BACKUP_MODE_PARAMETER="--wal-method=fetch" ;;
#       "s"     )       PG_BACKUP_MODE_PARAMETER="--wal-method=stream -S ${PG_BACKUP_SLOT}" ;;
        "s"     )       PG_BACKUP_MODE_PARAMETER="--wal-method=stream" ;;
        *       )       echo "ERROR: Unknown backup mode" ; exit 1 ;;
esac

PG_BACKUP_EXPIRATION_MODE=$3 # d - by days
                             # c - by count
                             # each other - no delete expired backup
PG_BACKUP_EXPIRATION_MODE_DEFAULT=c
[ "${PG_BACKUP_EXPIRATION_MODE}" ] || { PG_BACKUP_EXPIRATION_MODE=$PG_BACKUP_EXPIRATION_MODE_DEFAULT ; }

PG_BACKUP_EXPIRATION_DEFAULT=7
PG_BACKUP_EXPIRATION_DAYS=$4
[ "${PG_BACKUP_EXPIRATION_DAYS}" ] || { PG_BACKUP_EXPIRATION_DAYS=$PG_BACKUP_EXPIRATION_DEFAULT ; }
PG_BACKUP_EXPIRATION_COUNT=$4
[ "${PG_BACKUP_EXPIRATION_COUNT}" ] || { PG_BACKUP_EXPIRATION_COUNT=$PG_BACKUP_EXPIRATION_DEFAULT ; }

PG_BACKUP_BASE_DIR=/mnt/backups/${PG_BACKUP_HOST}
[ -d ${PG_BACKUP_BASE_DIR} ] || { echo "ERROR: backup base directory for host ${PG_BACKUP_HOST} is not exists" >&2; exit 1; }

PG_BACKUP_DIR=${PG_BACKUP_BASE_DIR}/backups
[ -d ${PG_BACKUP_DIR} ] || { echo "ERROR: backup directory for host ${PG_BACKUP_HOST} is not exists" >&2; exit 1; }

PG_BACKUP_LOGS=${PG_BACKUP_BASE_DIR}/logs
[ -d $PG_BACKUP_LOGS ] || { echo "ERROR: no log dirrectory for host ${PG_BACKUP_HOST} " >&2; exit 1; }

PG_BACKUP_DATE=$(date '+%Y%m%d%H%M')
PG_BACKUP_FILE=$PG_BACKUP_DIR/${PG_BACKUP_HOST}_base_${PG_BACKUP_DATE}.tar.gz
PG_BACKUP_WALS=$PG_BACKUP_DIR/${PG_BACKUP_HOST}_wals_${PG_BACKUP_DATE}.tar.gz
PG_BACKUP_LOG=$PG_BACKUP_LOGS/${PG_BACKUP_HOST}_base_${PG_BACKUP_DATE}.log

PG_BACKUP_TMP=$PG_BACKUP_DIR/_tmp_${PG_BACKUP_DATE}
[ -d $PG_BACKUP_TMP ] && { echo "ERROR: temporary directory ${PG_BACKUP_TMP} already exists " >&2; exit 1; }
#mkdir $PG_BACKUP_TMP
rm -rf $PG_BACKUP_TMP || { [ -d $PG_BACKUP_TMP ] && { echo "WARNING: cannot to remove temp backup directory" >&2; } || { echo "WARNING: no temp backup directory for remove " >&2; } }
rm ${PG_BACKUP_PID} || { echo "WARNING: no PID file for remove " >&2; }

#PG_BACKUP_CMD=/usr/lib/postgresql/16/bin/pg_basebackup
PG_BACKUP_CMD=/usr/bin/pg_basebackup
[ -f $PG_BACKUP_CMD ] || { echo "ERROR: pg_basebackup not found " >&2; exit 1; }

PG_BACKUP_PARAMETERS="-D ${PG_BACKUP_TMP} -Ft -z -Z 5 -v ${PG_BACKUP_MODE_PARAMETER} -h ${PG_BACKUP_HOST} -U ${PG_BACKUP_USER} --no-manifest"

PG_BACKUP_PID=$PG_BACKUP_BASE_DIR/pg_backup_${PG_BACKUP_HOST}.pid

echo "Backup PID file is ${PG_BACKUP_PID}"

[ -f $PG_BACKUP_PID ] && { echo "Backup script is already running with PID $(cat ${PG_BACKUP_PID})" >&2; exit 1; }

cat > ${PG_BACKUP_PID} <<EOF
$$
EOF

echo "Backup PID is $(cat ${PG_BACKUP_PID})"

# Do backup

#log file
exec >>$PG_BACKUP_LOG
exec 2>&1

echo Start backup at $(date)

$PG_BACKUP_CMD $PG_BACKUP_PARAMETERS

echo End backup at $(date)

# Move to main from temp directory
[ -f  ${PG_BACKUP_TMP}/base.tar.gz ] &&  mv ${PG_BACKUP_TMP}/base.tar.gz $PG_BACKUP_FILE || { echo "WARNING: temporary base.tar.gz not found" >&2; }
if [[ "${PG_BACKUP_MODE}" == "s" ]]
then
        [ -f  ${PG_BACKUP_TMP}/pg_wal.tar.gz ] && mv ${PG_BACKUP_TMP}/pg_wal.tar.gz $PG_BACKUP_WALS || { echo "WARNING: temporary pg_wal.tar.gz not found" >&2; }
fi

echo Start cleanup

# Clean temp files

echo temp files...
rmdir ${PG_BACKUP_TMP} || { [ -d ${PG_BACKUP_TMP} ] && { echo "WARNING: cannot to remove temp backup directory" >&2; } || { echo "WARNING: no temp backup directory for remove " >&2; } }

# Remove PID
echo remove PID file...
rm ${PG_BACKUP_PID} || { echo "WARNING: no PID file for remove " >&2; }

# Delete expired backup
echo backup files...
case ${PG_BACKUP_EXPIRATION_MODE} in
        d ) find ${PG_BACKUP_LOGS}/ -mtime +${PG_BACKUP_EXPIRATION_DAYS} -delete ;;
        c ) ls -1trd ${PG_BACKUP_LOGS}/* | head -n -${PG_BACKUP_EXPIRATION_COUNT} | xargs -d '\n' rm -f -- ;;
        * ) echo "No expired backup here" ;;
esac

# Delete expired backup logs
echo backup log files...
case ${PG_BACKUP_EXPIRATION_MODE} in
        d ) find ${PG_BACKUP_DIR}/ -mtime +${PG_BACKUP_EXPIRATION_DAYS} -delete ;;
        c ) ls -1trd ${PG_BACKUP_DIR}/* | head -n -${PG_BACKUP_EXPIRATION_COUNT} | xargs -d '\n' rm -f -- ;;
        * ) echo "No expired backup here" ;;
esac

# Success
echo All task complete successfully
exit 0
