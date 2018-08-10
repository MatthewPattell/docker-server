#!/usr/bin/env bash

# Export environment to php/cron
set -a
    . ${ENV_PATH}
set +a

# run cron command
eval $1