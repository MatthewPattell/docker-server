#!/usr/bin/env bash

set -o errexit # exit when a command fails.
set -o pipefail # catch error in pipe operator
set -o nounset # exit when tries to use undeclared variables.
# set -o xtrace # debug tool

# Flags:
# --test - view commands that would be evaluated
# --yes - force confirm all domains
TEST=0
AUTOCONFIRM=0
while [[ ! $# -eq 0 ]]; do
    case "$1" in
        --test)
            TEST=1
            ;;
        --yes | -y)
            AUTOCONFIRM=1
            ;;
    esac
    shift
done

# RUN IN CONTAINER

# renew certificates min period = 5 time per 7 days!!!

# Getting environments for using in current script
set -a
. ${ENV_PATH}
set +a

# see nginx snippets/letsencrypt-acme-challenge.conf
CERTIFICATE_WEB_ROOT="${PACKAGE_DOCKER_FOLDER_CONTAINER}/nginx/web"

for i in ${!SSL_DOMAINS[*]}; do
    EMAIL=$(echo "${SSL_DOMAINS[$i]}" | cut -d':' -f1)
    LIST_DOMAINS=$(echo "${SSL_DOMAINS[$i]}" | cut -d':' -f2)

    COMMAND="certbot certonly --webroot --agree-tos --no-eff-email --email ${EMAIL} -w ${CERTIFICATE_WEB_ROOT}"

    for DOMAIN in ${LIST_DOMAINS}; do
        COMMAND="${COMMAND} -d ${DOMAIN}"
    done

    if [[ "${TEST}" = "1" ]]; then
        echo "command is: ${COMMAND}"
        continue
    fi

    CONFIRM_RESPONSE=
    if [[ "${AUTOCONFIRM}" = "1" ]]; then
        CONFIRM_RESPONSE="y"
    fi
    while true; do
        if [[ -z "${CONFIRM_RESPONSE}" ]]; then
            echo "Confirm new ssl certificated for ${LIST_DOMAINS}?"
            read -p "Type: [y]es/[s]kip/[b]reak: " CONFIRM_RESPONSE
        fi

        case "${CONFIRM_RESPONSE}" in
            y | yes )
                echo "eval ${COMMAND}"
                eval "${COMMAND}"
                break
                ;;
            s | skip | n | no )
                break
                ;;
            b | break)
                exit
                ;;
            * ) echo "Please answer [y]es, [s]kip or [b]reak.";;
        esac
    done
done