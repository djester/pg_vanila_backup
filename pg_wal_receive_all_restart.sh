#!/bin/bash

systemctl list-units --no-pager -all | grep pg_wal | grep -v slice | awk '{ print $1 }' | xargs -i sh -c 'systemctl start {}'
