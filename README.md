# pg_vanila_backup
There is shell scripts for organize dedicated backup server for multiple PostgreSQL clusters by built-in PostgreSQL utilities: pg_basebackup & pg_dump

## Restrictions
* Ubuntu bash shell only support and tested now
* Only one major version support now, but you can make copy scripts for other major versions and correct path to PostgreSQL binary files into scripts copies.
* pg_basebackup script (pg_backup.sh) support major version up to 13 and newest because backup manifest support started from PostgreSQL 13

## Catalog structure
Catalogs should be created for each db_hostname
db_hostname is name used for connection to PostgreSQL cluster should be backuped
### Create catalog
```bash
 mkdir -p /mnt/backups/db_hostname/{backups,wals,dumps,logs}
```
* */mnt/backups/* - root backup catalog
* */mnt/backups/scripts/* - proposed path of local catalog for this repo 
* *backup* - pg_basebackup subcatalog
* *wals* - backups wal's files subcatalog
* *dumps* - pg_dump dumps files subcatalog
* *logs* - runtime scripts log files subcatalog

## Using pg_backup.sh
```bash
/mnt/backups/scripts/pg_backup.sh [db_hostname] [backup_mode] [backup_depth_unit] [backup_depth_count]
```
### \[backup_mode\]
* n - none. Need backup WAL's file outside pg_backup.sh script
* f (default) - fetch. WAL's file needed for full backup restore has copied after db file backup finished
* s - stream. WAL's file needed for full backup restore has copied through parallel streaming replication process

### \[backup_depth_unit\]
* d (default) - depth as days number
* c - depth as backup counts

### \[backup_depth_count\] 
7 is default for days or counts both

### Command
crontab set for user postgres. For run scripts full path is needed. .pgpass need for replica user credentials
#### examples 
```bash
# default backup settings
00 01 * * * /mnt/backups/scripts/pg_backup.sh mydbhost1
# backup in stream mode
00 02 * * * /mnt/backups/scripts/pg_backup.sh mydbhost2 s d 7
# store 3 copy only
30 02 * * * /mnt/backups/scripts/pg_backup.sh mydbhost2 f c 3
```
