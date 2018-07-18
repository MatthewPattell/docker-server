#!/usr/bin/env bash

# up/down app

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

ACTION=$1

if [ "${ACTION}" = "down"  ] && [ "$DEFAULT_DETACHED_MODE" = "-d" ]; then
    DEFAULT_DETACHED_MODE=""
fi

cd ${DOCKER_FOLDER_NAME} && \
    docker-compose ${SERVICES} ${ACTION} ${DEFAULT_DETACHED_MODE} ${OTHER_PARAMS}