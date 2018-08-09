#!/usr/bin/env bash

# Execute command in service

# get package vendor dir
VENDOR_DIR=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

SERVICE=$1
DEFAULT_SHELL=/bin/bash
COMMAND=$2

if [ "$2" = "sh" ] || [ "$2" = "/bin/sh" ]; then
    DEFAULT_SHELL=/bin/sh
    COMMAND=$3
fi

if [ "$COMMAND" != "" ]; then
    COMMAND="-c $COMMAND"
fi

# @TODO_ tty composer not working :( https://github.com/symfony/symfony/issues/17010
# https://github.com/composer/composer/issues/5856
docker-compose ${SERVICES} exec $SERVICE $DEFAULT_SHELL $COMMAND
