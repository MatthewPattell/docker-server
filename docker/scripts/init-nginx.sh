#!/usr/bin/env bash

set -o errexit # exit when a command fails.
set -o pipefail # catch error in pipe operator
set -o nounset # exit when tries to use undeclared variables.
# set -o xtrace # debug tool

# RUN ON NGINX CONTAINER

# Export environment to OS
set -a
. ${ENV_PATH}
set +a

bash /scripts/set-permissions.sh

ENVIRONMENT=$(echo "$PROJECT_ENVIRONMENT" | tr '[:upper:]' '[:lower:]')

# find patterns on config files: <tag-name>search-string</tag-name>
# Example: findPattern "pattern-name" "<pattern-name>string search</pattern-name>"
function findPattern {
    local PATTERN=$1
    local TEXT=$2

    echo $(echo ${TEXT} | sed -n "s:.*<${PATTERN}>\(.*\)</${PATTERN}>.*:\1:p")
}

# COPY nginx.conf
NGINX_TEMPLATE_CODE=$(cat "${PACKAGE_DOCKER_FOLDER_CONTAINER}"/nginx/nginx.conf)
NGINX_TEMPLATE_CODE="${NGINX_TEMPLATE_CODE//\$ENVIRONMENT/$PROJECT_ENVIRONMENT}"
echo "${NGINX_TEMPLATE_CODE}" > /etc/nginx/nginx.conf

# delete previous dynamic configs
find /etc/nginx/conf-dynamic.d/ -name "*.conf" -type f -delete

# add default host
if [ "$NGINX_DEFAULT_HOST" = "yes" ]; then
    cp ${PACKAGE_DOCKER_FOLDER_CONTAINER}/nginx/templates/default.conf /etc/nginx/conf-dynamic.d/default.conf
fi

# create dynamic nginx configs
for TEMPLATE_NAME in ${PACKAGE_DOCKER_FOLDER_CONTAINER}/nginx/conf-dynamic.d/*.conf; do
    TARGET_CONFIG_PATH=/etc/nginx/conf-dynamic.d/$(basename ${TEMPLATE_NAME})
    # Remove old file
    [[ -f file ]] && rm "${TARGET_CONFIG_PATH}"

    # get template content
    BASE_TEMPLATE_CODE=$(cat ${TEMPLATE_NAME})

    # copy template
    TEMPLATE_PATH=$(findPattern "template" "${BASE_TEMPLATE_CODE}")

    if [[ ! -z "${TEMPLATE_PATH}" ]]; then
        if [[ ! -f "${TEMPLATE_PATH}" ]]; then
            TEMPLATE_PATH="${PACKAGE_DOCKER_FOLDER_CONTAINER}/nginx/${TEMPLATE_PATH}"
        fi

        # get template code without comments (if "copy template" directive exist)
        BASE_TEMPLATE_CODE=$(echo -e "$BASE_TEMPLATE_CODE \n\n$(grep -o '^[^#]*' ${TEMPLATE_PATH})")
    fi

    # allow domain
    ONLY_DOMAINS=$(findPattern "domains-include" "${BASE_TEMPLATE_CODE}")

    # if domain variable not exist
    if [[ -z "${!ONLY_DOMAINS:-}" ]]; then
        continue
    fi

    ONLY_DOMAINS=${!ONLY_DOMAINS}

    # if empty domain, skip creating config
    if [[ -z "$ONLY_DOMAINS" ]]; then
        continue
    fi

    # create new config
    echo "" >> "${TARGET_CONFIG_PATH}"

    # root path
    REPLACE_ROOT=$(findPattern "root-path" "${BASE_TEMPLATE_CODE}")

    # custom snippets
    REPLACE_CUSTOM_SNIPPETS=$(findPattern "custom-snippets" "${BASE_TEMPLATE_CODE}")

    for DOMAIN in ${ONLY_DOMAINS}; do
        DOMAIN_1LVL=$(echo "${DOMAIN}" | sed -n "s/\([^\.]*\)\.\([^\.]*\)/\2/p")
        DOMAIN_2LVL=$(echo "${DOMAIN}" | sed -n "s/\([^\.]*\)\.\([^\.]*\)/\1/p")

        if [ "$DOMAIN_DEFAULT" = "$DOMAIN" ] && [ "$NGINX_DEFAULT_HOST" != "yes" ]; then
          DEFAULT_HOST=" default_server"
        else
          DEFAULT_HOST=""
        fi

        TEMPLATE_CODE="${BASE_TEMPLATE_CODE}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$COMMON_DOMAIN/$DOMAIN}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$ENVIRONMENT/$ENVIRONMENT}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$DOMAIN_1LVL/$DOMAIN_1LVL}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$DOMAIN_2LVL/$DOMAIN_2LVL}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$PARSED_DOMAINS/$ONLY_DOMAINS}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$ROOT_PATH/$REPLACE_ROOT}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$CUSTOM_SNIPPETS/$REPLACE_CUSTOM_SNIPPETS}"
        TEMPLATE_CODE="${TEMPLATE_CODE//\$DEFAULT/$DEFAULT_HOST}"

        for i in ${!SSL_DOMAINS[*]}; do
            LIST_CERTIFICATE_DOMAINS=$(echo "${SSL_DOMAINS[$i]}" | cut -d ':' -f 2)
            MAIN_CERTIFICATE=$(echo ${LIST_CERTIFICATE_DOMAINS} | cut -d ' ' -f 1)
            for CERTIFICATE_DOMAIN in ${LIST_CERTIFICATE_DOMAINS}; do
                if [[ "${CERTIFICATE_DOMAIN}" = "${DOMAIN}" ]]; then
                    TEMPLATE_CODE="${TEMPLATE_CODE//\$CERTIFICATE_DOMAIN/$MAIN_CERTIFICATE}"
                    break 2
                fi
            done
        done

        # find external certificate domain
        CERTIFICATE_DOMAIN=$(findPattern "certificate-domain" "${TEMPLATE_CODE}")
        # or use current server_name (DOMAIN)
        if [[ -z ${CERTIFICATE_DOMAIN} ]]; then
            # TODO: replace with bash.
            CERTIFICATE_DOMAIN=DOMAIN
        fi

        SSL_DIRECTIVE=""
        if [[ "${CERTIFICATE_DOMAIN}" != "" ]]; then
            SSL_KEY=/etc/letsencrypt/live/${CERTIFICATE_DOMAIN}/privkey.pem;
            SSL_CERT=/etc/letsencrypt/live/${CERTIFICATE_DOMAIN}/fullchain.pem;

            if [[ -f ${SSL_KEY} ]] && [[ -f ${SSL_CERT} ]]; then
                SSL_DIRECTIVE="
    ssl_certificate             ${SSL_CERT};
    ssl_certificate_key         ${SSL_KEY};
    ssl_trusted_certificate     ${SSL_CERT};
    include snippets/ssl.conf;
"
            fi
        fi

        TEMPLATE_CODE="${TEMPLATE_CODE//\$SSL_INCLUDE/$SSL_DIRECTIVE}"

        echo "${TEMPLATE_CODE}" >> "${TARGET_CONFIG_PATH}"
    done
done
