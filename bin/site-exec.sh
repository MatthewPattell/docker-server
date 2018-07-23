#!/usr/bin/env bash

# Execute command in service

# get package vendor dir
VENDOR_DIR=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

COMMAND=/bin/bash

if [ "$2" != "" ]; then
    COMMAND="$COMMAND -c $2"
fi

docker-compose exec $1 $COMMAND