#!/usr/bin/env bash

# up/down app

function getVendorPath() {
  package=$(readlink $1)
  package=$(dirname $(dirname "${package//.}"))
  cd $(dirname $1)
  vendor=$(dirname $(dirname "$PWD/$(basename $1)"))
  echo "$vendor$package"
}

# get package vendor dir
VENDOR_DIR=$(getVendorPath "${BASH_SOURCE[0]}")

# export environments
. "${VENDOR_DIR}/helpers/compile-env.sh"

ACTION=$1
DETACHED_MODE=${DEFAULT_DETACHED_MODE}

if [[ "$ACTION" = "compile" ]]; then
    echo "Env file created success"
    exit 0
fi

if [[ "${ACTION}" != "up" ]] && [[ "$DETACHED_MODE" = "-d" ]]; then
    DETACHED_MODE=""
fi

COMMAND=(docker-compose $SERVICES $ACTION $DETACHED_MODE $OTHER_PARAMS)

if [[ "$ACTION" = "restart" ]]; then
    # Stop
    "${COMMAND[@]/restart/down}"
    # Recompile/reexport env
    . "${VENDOR_DIR}/helpers/compile-env.sh" "up"
    # Run
    "${COMMAND[@]/restart/up}" $DEFAULT_DETACHED_MODE
elif [[ "$ACTION" = "init" ]]; then

    TARGET_DIR="$VENDOR_PARENT_DIR/docker"
    IS_NODE=0

	if [[ ! -z $(env | grep "npm_package*") ]]; then
		IS_NODE=1
	fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        cp -r "$VENDOR_DIR/sample" "$TARGET_DIR/"
        mv "$TARGET_DIR/gitignore" "$TARGET_DIR/.gitignore"
        mv "$TARGET_DIR/.env-sample" "$TARGET_DIR/.env.local"
        mv "$TARGET_DIR/.env-sample-prod" "$TARGET_DIR/.env.prod"
        mv "$TARGET_DIR/docker-compose.local-sample.yml" "$TARGET_DIR/docker-compose.local.yml"

        until RANDKEY=$(dd bs=21 count=1 if=/dev/urandom |
           LC_CTYPE=C LC_ALL=C tr -cd A-Za-z0-9)
            ((${#RANDKEY} >= 10)); do :; done

        for file in .env.local .env.prod; do
            sed -i "" "s/change_this_string/$RANDKEY/g" "$TARGET_DIR/$file"
        done

        # Configure NODE env
        if [[ "$IS_NODE" == 1 ]]; then
            # Fix nginx template for node
            sed -i "" "s/\/var\/www\/html\/frontend\/web/\/var\/www\/html/g" "$TARGET_DIR/nginx/conf-dynamic.d/domain.conf"
            sed -i "" "s/templates\/domain.conf/templates\/node.conf/g" "$TARGET_DIR/nginx/conf-dynamic.d/domain.conf"

            # Fix env services
            sed -i "" "s/\${SERVICES}/\${SERVICES_NODE}/g" "$TARGET_DIR/.env.local"

            # Remove prod env (must be created manualy)
            rm "$TARGET_DIR/.env.prod"
            rm "$TARGET_DIR/docker-compose.static-network.yml"
        fi

        if [[ -f "$VENDOR_DIR/docker/.env" ]]; then
            rm "$VENDOR_DIR/docker/.env"
        fi

        # Configure macos
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i "" "s/# HOST_NGINX_CONF_DIR/HOST_NGINX_CONF_DIR/g" "$TARGET_DIR/.env.local"
            sed -i "" "s/# HOST_NGINX_RESTART_COMMAND/HOST_NGINX_RESTART_COMMAND/g" "$TARGET_DIR/.env.local"
            sed -i "" "s/# HOST_ETC_HOST_IP/HOST_ETC_HOST_IP/g" "$TARGET_DIR/.env.local"
        else
            sed -i "" "s/# HOST_NGINX_CONF_DIR//g" "$TARGET_DIR/.env.local"
            sed -i "" "s/# HOST_NGINX_RESTART_COMMAND//g" "$TARGET_DIR/.env.local"
            sed -i "" "s/# HOST_ETC_HOST_IP//g" "$TARGET_DIR/.env.local"
        fi

        echo "Server init success."
        echo "Change root-path in: $TARGET_DIR/nginx/conf-dynamic.d/domain.conf"
    else
        echo "$TARGET_DIR folder already exists"
    fi

    exit 0;
else
    "${COMMAND[@]}"
fi

if [[ "$ACTION" = "up" ]] || [[ "$ACTION" = "down" ]] || [[ "$ACTION" = "restart" ]]; then
    # Auto update hosts file for host
    . "${VENDOR_DIR}/helpers/update-hosts.sh" "$ACTION"

    # Create/delete nginx proxies configs for host
    . "${VENDOR_DIR}/helpers/create-nginx-proxy.sh" "$ACTION"
fi
