# pg_vanila_backup
There is shell scripts for organize dedicated backup server for multiple PostgreSQL clusters by built-in PostgreSQL utilities: pg_basebackup & pg_dump

## Restrictions
* Ubuntu bash shell only support and tested now
* Only one major version support now, but you can make copy scripts for other major versions and correct path to PostgreSQL binary files into scripts copies.

## Catalog structure
Catalogs should be created for each db_hostname
db_hostname is name used for connection to PostgreSQL cluster should be backuped
### Create catalog
```bash
 mkdir -p /mnt/backups/db_hostname/{backups,wals,dumps,logs}
```
