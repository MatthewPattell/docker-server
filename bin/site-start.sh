#!/usr/bin/env bash

# up/down app

function getVendorPath() {
  (
  package=$(readlink $1)
  package=$(dirname $(dirname "${package//.}"))
  cd $(dirname $1)
  vendor=$(dirname $(dirname "$PWD/$(basename $1)"))
  echo "$vendor$package"
  )
}

# get package vendor dir
VENDOR_DIR=$(getVendorPath "${BASH_SOURCE[0]}")

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

ACTION=$1
DETACHED_MODE=$DEFAULT_DETACHED_MODE

if [[ "${ACTION}" = "down" || "${ACTION}" = "restart" ]] && [ "$DETACHED_MODE" = "-d" ]; then
    DETACHED_MODE=""
fi

COMMAND=(docker-compose $SERVICES $ACTION $DETACHED_MODE $OTHER_PARAMS)

if [ "$ACTION" = "restart" ]; then
    "${COMMAND[@]/restart/down}"
    "${COMMAND[@]/restart/up}" $DEFAULT_DETACHED_MODE
elif [ "$ACTION" = "init" ]; then

    TARGET_DIR="$VENDOR_PARENT_DIR/docker"

    if [ ! -d "$TARGET_DIR" ]; then
        cp -r "$VENDOR_DIR/sample" "$TARGET_DIR/"
        mv "$TARGET_DIR/.env-sample" "$TARGET_DIR/.env-local"
        mv "$TARGET_DIR/docker-compose.local-sample.yml" "$TARGET_DIR/docker-compose.local.yml"
        echo "Server init success."
        echo "Change root-path in: $TARGET_DIR/nginx/conf-dynamic.d/sample.conf"
    else
        echo "$TARGET_DIR folder already exists"
    fi

    exit 0;
else
    "${COMMAND[@]}"
fi
