#!/usr/bin/env bash

# Execute command in service

for i in "$@"
do
case $i in
    -e=*|--env-file=*)
    ENV_FILE=$(realpath "${i#*=}")
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

if [ ! -f "$ENV_FILE" ]; then
    echo "Env file does not exist: $ENV_FILE"
    exit 1;
fi

# Getting environments for using in current script
set -a
. $ENV_FILE
set +a

COMMAND=/bin/bash

if [ "$2" != "" ]; then
    COMMAND="$COMMAND -c $2"
fi

cd ${DOCKER_FOLDER_NAME} && \
    docker-compose exec $1 $COMMAND