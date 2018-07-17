#!/usr/bin/env bash

# Export environment to php/cron
. /var/www/html/docker/.env

# run cron command
eval $1