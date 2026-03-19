#!/bin/bash

PG_WAL_HOST=$1
[ "${PG_WAL_HOST}" ] || { echo "ERROR: no host for backup" >&2; exit 1; }

PG_WAL_USER=replica
PG_WAL_SLOT=$2
PG_WAL_SLOT=${PG_WAL_SLOT:-bckp}
PG_WAL_BASE_DIR=/mnt/backups/${PG_WAL_HOST}
[ -d ${PG_WAL_BASE_DIR} ] || { echo "ERROR: base directory for host ${PG_WAL_HOST} is not exists" >&2; exit 1; }

PG_WAL_DIR=${PG_WAL_BASE_DIR}/wals
[ -d ${PG_WAL_DIR} ] || { echo "ERROR: wals directory for host ${PG_WAL_HOST} is not exists" >&2; exit 1; }

PG_WAL_LOGS=${PG_WAL_BASE_DIR}/logs
[ -d ${PG_WAL_LOGS} ] || { echo "ERROR: logs directory for host ${PG_WAL_HOST} is not exists" >&2; exit 1; }

PG_WAL_LOG=$PG_WAL_LOGS/wal_receive.log

PG_WAL_RECEIVE_CMD="/usr/bin/pg_receivewal"
#PG_WAL_RECEIVE_CMD="/usr/lib/postgresql/16/bin/pg_receivewal"
PG_WAL_RECEIVE_PARAMETERS="--no-loop -D ${PG_WAL_DIR} --if-not-exists -S ${PG_WAL_SLOT} -h ${PG_WAL_HOST} -U ${PG_WAL_USER}"

#log file
exec >>$PG_WAL_LOG
exec 2>&1

echo Start at $(date)

${PG_WAL_RECEIVE_CMD} ${PG_WAL_RECEIVE_PARAMETERS}

exit 0
