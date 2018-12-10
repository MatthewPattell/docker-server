#!/bin/sh

# RUN ON NGINX CONTAINER

# Export environment to OS
set -a
. ${ENV_PATH}
set +a

ENVIRONMENT=$(echo "$PROJECT_ENVIRONMENT" | tr '[:upper:]' '[:lower:]')

# find patterns on config files: <tag-name>search-string</tag-name>
# Example: findPattern "pattern-name" "string search"
function findPattern {
   export PERL_ARGUMENT1="$@"
   echo $(perl -e 'if ($ENV{'PERL_ARGUMENT1'} =~ /<$ARGV[0]>(.*)<\/$ARGV[0]>/) {print $1;};' -- "$1")
}

# get redis ip by host
if [ ! -z "$REDIS_HOST" ]; then
    export REDIS_IP=$(getent hosts "$REDIS_HOST" | cut -f 1 -d " ")
fi

# COPY nginx.conf
NGINX_TEMPLATE_CODE=$(cat "${PACKAGE_DOCKER_FOLDER_CONTAINER}"/nginx/nginx.conf)
NGINX_TEMPLATE_CODE="${NGINX_TEMPLATE_CODE//\$ENVIRONMENT/$PROJECT_ENVIRONMENT}"
echo "${NGINX_TEMPLATE_CODE}" > /etc/nginx/nginx.conf

# delete previous dynamic configs
find /etc/nginx/conf-dynamic.d -name "*.conf" -type f -delete

# create dynamic nginx configs
for COMMON_TEMPLATE in ${PACKAGE_DOCKER_FOLDER_CONTAINER}/nginx/conf-dynamic.d/*.conf; do
    COMMON_DYNAMIC=/etc/nginx/conf-dynamic.d/$(basename $COMMON_TEMPLATE)

    # get templace
    TEMPLATE_CODE=$(cat $COMMON_TEMPLATE)

    # copy template
    TEMPLATE_PATH=$(findPattern "template" $TEMPLATE_CODE)

    if [ ! -z $TEMPLATE_PATH ]; then
        if [ ! -f $TEMPLATE_PATH ]; then
            TEMPLATE_PATH="${PACKAGE_DOCKER_FOLDER_CONTAINER}/nginx/$TEMPLATE_PATH"
        fi

        # get template code without comments (if "copy template" directive exist)
        TEMPLATE_CODE=$(echo -e "$TEMPLATE_CODE \n\n$(grep -o '^[^#]*' $TEMPLATE_PATH)")
    fi

    # allow domain
    ONLY_DOMAINS=$(findPattern "domains-include" $TEMPLATE_CODE)
    ONLY_DOMAINS=$(echo $(perl -e 'print $ENV{$ARGV[0]}' -- $ONLY_DOMAINS))

    # root path
    REPLACE_ROOT=$(findPattern "root-path" $TEMPLATE_CODE)

    # Clean file
    echo "" > $COMMON_DYNAMIC

    # if empty domains, remove config
    if [ -z "$ONLY_DOMAINS" ]; then
        rm $COMMON_DYNAMIC
    fi

    for DOMAIN in $ONLY_DOMAINS; do
        # TODO: TOPDOMAIN and C_DOMAIN used only in certificates pattern. Replace them with $CERTIFICATE_DOMAIN variable.
        TOPDOMAIN=$(perl -e 'if ($ARGV[0] =~ /^((?<subdomain>[^\.]*)\.)?(?<domain>[^\.]*)\.(?<topdomain>((com\.ua)|.*))$/) {print $+{topdomain};};' -- "$DOMAIN")
        C_DOMAIN=$(perl -e 'if ($ARGV[0] =~ /^((?<subdomain>[^\.]*)\.)?(?<domain>[^\.]*)\.(?<topdomain>(com\.)?.*)$/) {print $+{domain};};' -- "$DOMAIN")
        TEMPLATE=$TEMPLATE_CODE
        TEMPLATE="${TEMPLATE//\$COMMON_DOMAIN/$DOMAIN}"
        TEMPLATE="${TEMPLATE//\$ENVIRONMENT/$ENVIRONMENT}"
        TEMPLATE="${TEMPLATE//\$TOPDOMAIN/$TOPDOMAIN}"
        TEMPLATE="${TEMPLATE//\$C_DOMAIN/$C_DOMAIN}"
        TEMPLATE="${TEMPLATE//\$PARSED_DOMAINS/$ONLY_DOMAINS}"
        TEMPLATE="${TEMPLATE//\$ROOT_PATH/$REPLACE_ROOT}"

        # TODO: rewrite get-certificates with sh and this part of script.
        for each in $(cat "${ENV_PATH}" | awk -F= '/^SSL_DOMAINS\[[0-9]\]/ {print $2}')
        do
            LIST_CERTIFICATE_DOMAINS=$(echo "$each" | cut -d ':' -f 2)
            MAIN_CERTIFICATE=$(echo "$LIST_CERTIFICATE_DOMAINS" | cut -d ' ' -f 1)
            for CERTIFICATE_DOMAIN in $LIST_CERTIFICATE_DOMAINS; do
                if [ "$CERTIFICATE_DOMAIN" = "$DOMAIN" ]; then
                    TEMPLATE="${TEMPLATE//\$CERTIFICATE_DOMAIN/$MAIN_CERTIFICATE}"
                fi
            done
        done

        SSL_DERICTIVE=""

        # find external certificate domain
        CERTIFICATE_DOMAIN=$(findPattern "certificate-domain" $TEMPLATE)

        # find server_name for check certificate
        if [ -z $CERTIFICATE_DOMAIN ]; then
            CERTIFICATE_DOMAIN=$(perl -e '$str = $ARGV[0];if ($str =~ /server_name([A-z.0-9]*);/) {print $1;};' -- $(echo $TEMPLATE | sed 's/ //g'))
        fi

        if [ $CERTIFICATE_DOMAIN != "" ]; then
            SSL_KEY=/etc/letsencrypt/live/${CERTIFICATE_DOMAIN}/privkey.pem;
            SSL_CERT=/etc/letsencrypt/live/${CERTIFICATE_DOMAIN}/fullchain.pem;

            if [ -f $SSL_KEY ] && [ -f $SSL_CERT ]; then
                SSL_DERICTIVE="
    ssl_certificate             ${SSL_CERT};
    ssl_certificate_key         ${SSL_KEY};
    ssl_trusted_certificate     ${SSL_CERT};
    include snippets/ssl.conf;
"
            fi
        fi

        TEMPLATE="${TEMPLATE//\$SSL_INCLUDE/$SSL_DERICTIVE}"

        echo "${TEMPLATE}" >> $COMMON_DYNAMIC
    done
done

# Run nginx with modules
nginx -g 'daemon off;'