#!/usr/bin/env bash

# run app service

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

SERVICE=$1
SERVICE_COMMAND=$2

cd ${DOCKER_FOLDER_NAME} && \
    docker-compose ${SERVICES} run --rm ${SERVICE} /bin/bash -c "${SERVICE_COMMAND}"