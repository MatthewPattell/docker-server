#!/usr/bin/env bash

# RUN ON CONTAINER

cp ${1} /var/spool/cron/crontabs/root
chmod 0600 /var/spool/cron/crontabs/root

exit 0