#!/usr/bin/env bash

# RUN ON CONTAINER

# renew certificates min period = 5 time per 7 days!!!

# Getting environments for using in current script
set -a
. ${ENV_PATH}
set +a

# see nginx snippets/letsencrypt-acme-challenge.conf
CERTIFICATE_WEB_ROOT="${PROJECT_DOCKER_FOLDER_CONTAINER}/nginx/web"

for i in ${!SSL_DOMAINS[*]}; do
    EMAIL="$(cut -d':' -f1 <<<"$SSL_DOMAINS[$i]")"
    LIST_DOMAINS="$(cut -d':' -f2 <<<"$SSL_DOMAINS[$i]")"

    COMMAND="certbot certonly --webroot --agree-tos --no-eff-email --email $EMAIL -w $CERTIFICATE_WEB_ROOT"

    for DOMAIN in $LIST_DOMAINS; do
        COMMAND="$COMMAND -d $DOMAIN"
    done

    eval $COMMAND
done