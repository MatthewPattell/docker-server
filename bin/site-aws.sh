#!/usr/bin/env bash

# Run aws command with env params

# get package vendor dir
VENDOR_DIR=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

ACTION="AWS_$(echo "$1" | tr '[:lower:]' '[:upper:]')"
COMMAND=${!ACTION}

if [ ! -z "$COMMAND" ]; then
    eval "${COMMAND[@]/-SERVICES-/$SERVICES}"
else
    echo "Command not found."
    exit 1
fi
