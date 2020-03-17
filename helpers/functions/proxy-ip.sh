#!/usr/bin/env bash

function nginxProxyIp() {
    if [[ -z "$HOST_ETC_HOST_IP" ]]; then
        HOST_ETC_HOST_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}' "${PROJECT_NAME}_nginx" | head -n1)

        if [[ $(<"$PROJECT_ENV_PATH") != "$HOST_ETC_HOST_IP" ]]; then
            echo "HOST_ETC_HOST_IP=$HOST_ETC_HOST_IP" >>"$PROJECT_ENV_PATH"
        fi
    fi

    echo "$HOST_ETC_HOST_IP"
}
