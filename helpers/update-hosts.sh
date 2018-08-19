#!/usr/bin/env bash

[ "$HOST_ETC_HOSTS_UPDATE" != "yes" ] && return

# Do not need to do anything
[ "$1" = "init" ] && return

CURRENT_DIR="${BASH_SOURCE%/*}"
. "$CURRENT_DIR/functions/domains.sh"

HOSTS_FILE=$(cat $HOST_ETC_HOST_PATH)
HOSTS_ADDED_DOMAINS=$(dockerDomains)
HOST_NEWLINE=$'\n'

if [ -z "$HOST_ETC_HOSTS_IP" ]; then
    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${PROJECT_NAME}_nginx")
fi

# Generate unique section for hosts file
HOSTS_ADDED="$HOST_NEWLINE# ${PROJECT_NAME}-uds-begin$HOST_NEWLINE$CONTAINER_IP $HOSTS_ADDED_DOMAINS$HOST_NEWLINE# ${PROJECT_NAME}-uds-end"

# Check if hosts added change
if [[ $HOSTS_FILE != *$HOSTS_ADDED* ]]; then
    # Delete old section from hosts file
    HOSTS_FILE_RESULT=$(echo "$HOSTS_FILE" | tr '\n' @ | sed -E "s/\#[[:space:]]${PROJECT_NAME}-uds-begin.+\#[[:space:]]${PROJECT_NAME}-uds-end@?//g" | tr @ '\n')

    echo "Updated $HOST_ETC_HOST_PATH..."
    echo "$HOSTS_FILE_RESULT $HOSTS_ADDED" | sudo tee $HOST_ETC_HOST_PATH > /dev/null
fi