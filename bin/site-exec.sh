#!/usr/bin/env bash

# Execute command in service

COMMAND=/bin/bash

if [ "$2" != "" ]; then
    COMMAND="$COMMAND -c $2"
fi

cd docker && \
    docker-compose exec $1 $COMMAND