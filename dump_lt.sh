#!/bin/bash

# This script used for prepare dump loaded to other enviroment without data obfuscation
# For example you should move data from stage to test enviroment
# This script requerie 
# - ini file with connection data for each dumped database
# - .pgpass with source database credentials
# - postgres:postgres file owner
# Dumps put into  subdirectory directory

[ "$1" ] || { echo "No arguments. Argument should be short name of projest (schema name)" >&2; exit 1; }

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
INI_FILE=${SCRIPT_DIR}/dump_lt.ini
INI_CHECK=$(grep $1 ${INI_FILE} | wc -l)
[ $INI_CHECK == "1" ] || { echo "Incorrect argument" >&2 ; exit 1 ; }

DB_NAME=$(grep $1 ${INI_FILE} | awk '{print $1}')
DMP_USER=$(grep $1 ${INI_FILE} | awk '{print $2}')
DMP_PORT=$(grep $1 ${INI_FILE} | awk '{print $3}')
DMP_HOST=$(grep $1 ${INI_FILE} | awk '{print $4}')

PRJ_NAME=$(echo $1 | sed 's/\_.*//')
DMP_PATH=${SCRIPT_DIR}/${DB_NAME}
DMP_FILE=${DMP_PATH}/${PRJ_NAME}_$(date +%Y%m%d).dump
GLOBAL_FILE=${DMP_PATH}/global_${PRJ_NAME}.sql

mkdir -p ${DMP_PATH}

PID_FILE=${DMP_PATH}/${DB_NAME}.pid
if [ ! -f ${PID_FILE} ]; then
        echo $$ > ${PID_FILE}
else
        echo "Error: other dump "${DB_NAME}" process running... PID: "$( cat ${PID_FILE} ) >&2
        exit 1
fi

pg_dumpall --roles-only -h $DMP_HOST -p ${DMP_PORT} -U postgres > ${GLOBAL_FILE}

sed -i '/ROLE postgres/d' ${GLOBAL_FILE}

sed -i "/CREATE ROLE/i DO \$\$\\
BEGIN\\
" ${GLOBAL_FILE}

sed -i "/CREATE ROLE/a\\
EXCEPTION\\
   WHEN DUPLICATE_OBJECT THEN\\
       RAISE NOTICE 'Role already exists, skipping creation.';\\
END\\
\$\$ LANGUAGE plpgsql;\\
"  ${GLOBAL_FILE}

DMP_LOG_FILE=${DMP_PATH}/${PRJ_NAME}_$(date +%Y%m%d).log
DMP_BIN=/usr/bin/pg_dump
DMP_PARAMETERS=" -v -b -Fc -h ${DMP_HOST} -U postgres -p ${DMP_PORT} -f ${DMP_FILE} ${DB_NAME}"

# run
${DMP_BIN} ${DMP_PARAMETERS} 2> ${DMP_LOG_FILE}

# remove PID
rm ${PID_FILE}

exit 0
