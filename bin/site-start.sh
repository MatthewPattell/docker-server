#!/usr/bin/env bash

# up/down app

DETACHED_MODE=""
ACTION=$2
MODE=${1}
ENV_MODE="docker-compose.${1}.yml"
DEV_SERVICES="-f docker-compose.redis.yml"
OTHER_PARAMS=${@:3}

if [ -f "docker/${ENV_MODE}" ]; then
    ENV_MODE="-f ${ENV_MODE}"
else
    ENV_MODE=""
    ACTION=$1
    OTHER_PARAMS=${@:2}
fi

if [ ${ACTION} = "up" ]; then
    DETACHED_MODE="-d"
fi

if [ "${MODE}" != "dev" ]; then
    DEV_SERVICES=""
fi

cd docker && \
    docker-compose -f docker-compose.yml ${ENV_MODE} ${DEV_SERVICES} ${ACTION} ${DETACHED_MODE} ${OTHER_PARAMS}