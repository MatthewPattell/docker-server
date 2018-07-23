#!/usr/bin/env bash

# up/down app

# get package vendor dir
VENDOR_DIR=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

ACTION=$1
DETACHED_MODE=$DEFAULT_DETACHED_MODE

if [[ "${ACTION}" = "down" || "${ACTION}" = "restart" ]] && [ "$DETACHED_MODE" = "-d" ]; then
    DETACHED_MODE=""
fi

COMMAND=(docker-compose $SERVICES $ACTION $DETACHED_MODE $OTHER_PARAMS)

if [ "$ACTION" = "restart" ]; then
    "${COMMAND[@]/restart/down}"
    "${COMMAND[@]/restart/up}" $DEFAULT_DETACHED_MODE
else
    "${COMMAND[@]}"
fi
