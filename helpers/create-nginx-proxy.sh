#!/usr/bin/env bash

[ "$HOST_NGINX_PROXIES" != "yes" ] && return

ACTION=$1

# Do not need to create/recreate proxies
[ "$ACTION" = "init" ] && return

NGINX_CONF_PATH="${HOST_NGINX_CONF_DIR}/universal-${PROJECT_NAME}.conf"

if [[ "$ACTION" == "down" && "$HOST_NGINX_KEEP_CONF" == "no" ]]; then
    # Delete previous config if exist
    if [ -e "$NGINX_CONF_PATH" ]; then
        rm "$NGINX_CONF_PATH"
    fi

    return
fi

CURRENT_DIR="${BASH_SOURCE%/*}"
. "$CURRENT_DIR/functions/domains.sh"
. "$CURRENT_DIR/functions/proxy-ip.sh"

export HOST_ETC_HOST_IP=$(nginxProxyIp)

NGINX_TEMPLATE_CODE=$(cat "$HOST_NGINX_TEMPLATE_PATH")
NGINX_DOMAIN_PROXIES=$(dockerDomains)
NGINX_PROXY_PORT=$(docker port "${PROJECT_NAME}_nginx" "$SERVER_HTTP_PORT")
NGINX_PROXY_PORT="${NGINX_PROXY_PORT//0.0.0.0/}"

NGINX_TEMPLATE_CODE="${NGINX_TEMPLATE_CODE//\$PORT/$NGINX_PROXY_PORT}"
NGINX_TEMPLATE_CODE="${NGINX_TEMPLATE_CODE//\$DOMAINS/$NGINX_DOMAIN_PROXIES}"
NGINX_TEMPLATE_CODE="${NGINX_TEMPLATE_CODE//\$CONTAINER_IP/$HOST_ETC_HOST_IP}"

# check whether nginx config exists && is writable
if [[ ! -f "$NGINX_CONF_PATH" ]]; then
    if [[ -w "$NGINX_CONF_PATH" ]]; then
        touch "$NGINX_CONF_PATH"
    else
        sudo touch "$NGINX_CONF_PATH"
    fi
fi

if [[ ! -w "$NGINX_CONF_PATH" ]]; then
    sudo chown $(id -u):$(id -g) "$NGINX_CONF_PATH"
fi

if [[ $(<"$NGINX_CONF_PATH") != "$NGINX_TEMPLATE_CODE" ]]; then
    # Create proxy config
    echo "$NGINX_TEMPLATE_CODE" >"$NGINX_CONF_PATH"
    # Restart host nginx
    echo "Updated $NGINX_CONF_PATH..."
    echo "Restarting nginx server..."
    eval "${HOST_NGINX_RESTART_COMMAND[@]}"
fi
