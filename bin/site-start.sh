#!/usr/bin/env bash

# up/down app

# get package vendor dir
VENDOR_DIR=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

ACTION=$1

if [ "${ACTION}" = "down"  ] && [ "$DEFAULT_DETACHED_MODE" = "-d" ]; then
    DEFAULT_DETACHED_MODE=""
fi

docker-compose ${SERVICES} ${ACTION} ${DEFAULT_DETACHED_MODE} ${OTHER_PARAMS}