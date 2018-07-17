#!/usr/bin/env bash

# run app service

COMPOSE_FILES="-f docker-compose.yml"
ENV_MODE="docker-compose.${1}.yml"
SERVICE=$1
SERVICE_COMMAND=$2

if [ -f "docker/${ENV_MODE}" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ENV_MODE}"
    SERVICE=$2
    SERVICE_COMMAND=$3
fi

cd docker && \
    docker-compose ${COMPOSE_FILES} run --rm ${SERVICE} /bin/bash -c "${SERVICE_COMMAND}"