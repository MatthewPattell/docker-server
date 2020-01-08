#!/usr/bin/env bash

# Export environment to OS
set -a
. "$ENV_PATH"
set +a

# get redis ip by host
if [[ ! -z "$REDIS_HOST" ]]; then
    export REDIS_IP=$(getent hosts "$REDIS_HOST" | cut -d" " -f1)
fi

nginx -g 'daemon on;'