#!/bin/bash

# Command-line parameters
PG_DMP_DB=$1
PG_DMP_USER=$2
PG_DMP_HOST=$3
PG_DMP_PORT=$4
PG_DMP_PORT_DEFAULT=5432
[ "${PG_DMP_PORT}" ] || { PG_DMP_PORT=${PG_DMP_PORT_DEFAULT} ; }
PG_DMP_ENCODE=$5
PG_DMP_ENCODE_DEFAULT=UTF8
[ "${PG_DMP_ENCODE}" ] || { PG_DMP_ENCODE=${PG_DMP_ENCODE_DEFAULT} ; }

# Build dump command
PG_DMP_PATH=/mnt/backups/${PG_DMP_HOST}/dumps
PG_DMP_LOG_PATH=/mnt/backups/${PG_DMP_HOST}/logs
mkdir -p ${PG_DMP_PATH}
mkdir -p ${PG_DMP_LOG_PATH}
PG_DMP_FILE=${PG_DMP_PATH}/${PG_DMP_DB}_$(date +%Y%m%d).dump
PG_DMP_LOG_FILE=${PG_DMP_LOG_PATH}/dump_${PG_DMP_DB}_$(date +%Y%m%d).log
PG_DMP_BIN=/usr/bin/pg_dump
PG_DMP_PARAMETERS=" -v -b -Fc -E ${PG_DMP_ENCODE} -h ${PG_DMP_HOST} -U ${PG_DMP_USER} -p ${PG_DMP_PORT} -f ${PG_DMP_FILE} ${PG_DMP_DB}"

# Run dump
#echo "debug"
#echo ${PG_DMP_BIN} ${PG_DMP_PARAMETERS} " 2> " ${PG_DMP_LOG_FILE}
# run
${PG_DMP_BIN} ${PG_DMP_PARAMETERS} 2> ${PG_DMP_LOG_FILE}
exit 0
