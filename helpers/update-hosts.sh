#!/usr/bin/env bash

[ "$HOST_ETC_HOSTS_UPDATE" != "yes" ] && return

ACTION=$1

# Do not need to do anything
[ "$ACTION" = "init" ] && return

CURRENT_DIR="${BASH_SOURCE%/*}"
. "$CURRENT_DIR/functions/domains.sh"
. "$CURRENT_DIR/functions/proxy-ip.sh"

HOSTS_FILE=$(cat "$HOST_ETC_HOST_PATH")
HOSTS_ADDED_DOMAINS=$(dockerDomains)
HOST_NEWLINE=$'\n'
HOST_BEGIN_SECTION="# ${PROJECT_NAME}-uds-begin"
HOST_END_SECTION="# ${PROJECT_NAME}-uds-end"
HOSTS_ADDED=""

if [[ "$ACTION" != "down" ]]; then
    export HOST_ETC_HOST_IP=$(nginxProxyIp)

    if [ "$HOST_ETC_HOST_IP" != "" ]; then
        # Generate unique section for hosts file
        HOSTS_ADDED="$HOST_NEWLINE$HOST_BEGIN_SECTION$HOST_NEWLINE$HOST_ETC_HOST_IP $HOSTS_ADDED_DOMAINS$HOST_NEWLINE$HOST_END_SECTION"
    fi
fi

# Check if hosts added change
if [[ $HOSTS_FILE != *$HOSTS_ADDED* ]] || [[ "$HOSTS_ADDED" == "" && "$HOST_ETC_KEEP_CONF" == "no" && $HOSTS_FILE == *$HOST_BEGIN_SECTION* ]]; then
    # Delete old section from hosts file
    HOSTS_FILE_RESULT=$(echo "$HOSTS_FILE" | tr '\n' @ | sed -E "s/\#[[:space:]]${PROJECT_NAME}-uds-begin.+\#[[:space:]]${PROJECT_NAME}-uds-end@?//g" | tr @ '\n')

    echo "Updated $HOST_ETC_HOST_PATH..."
    echo "$HOSTS_FILE_RESULT $HOSTS_ADDED" | sudo tee "$HOST_ETC_HOST_PATH" >/dev/null
fi
