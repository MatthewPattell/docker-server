#!/usr/bin/env bash

# run app service

# get package vendor dir
VENDOR_DIR=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

SERVICE=$1
SERVICE_COMMAND=$2

docker-compose ${SERVICES} run --rm ${SERVICE} /bin/bash -c "${SERVICE_COMMAND}"
docker-compose ${SERVICES} down