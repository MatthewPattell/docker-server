#!/bin/sh

# RUN ON NGINX CONTAINER

# Export environment to OS
set -a
. /var/www/html/docker/.env
set +a

ENVIRONMENT=$(echo "$PROJECT_ENVIRONMENT" | tr '[:upper:]' '[:lower:]')

# find patterns on config files
# Example: findPattern "pattern-name" "string search"
function findPattern {
   export PERL_ARGUMENT1="$@"
   echo $(perl -e 'if ($ENV{'PERL_ARGUMENT1'} =~ /<$ARGV[0]>(.*)<\/$ARGV[0]>/) {print $1;};' -- "$1")
}

# get redis ip by host
export REDIS_IP=$(getent hosts "$REDIS_HOST" | cut -f 1 -d " ")

echo $REDIS_IP

# COPY nginx.conf
NGINX_TEMPLATE_CODE=$(cat /var/www/html/docker/nginx/nginx.conf)
NGINX_TEMPLATE_CODE="${NGINX_TEMPLATE_CODE//\$ENVIRONMENT/$PROJECT_ENVIRONMENT}"
echo "${NGINX_TEMPLATE_CODE}" > /etc/nginx/nginx.conf

# delete previous dynamic configs
find /etc/nginx/conf-dynamic.d -name "*.conf" -type f -delete

# create dynamic nginx configs
for COMMON_TEMPLATE in /var/www/html/docker/nginx/templates/*.conf; do
    COMMON_DYNAMIC=/etc/nginx/conf-dynamic.d/$(basename $COMMON_TEMPLATE)

    # get templace
    TEMPLATE_CODE=$(cat $COMMON_TEMPLATE)

    # allow domain
    ONLY_DOMAINS=$(findPattern "domains-include" $TEMPLATE_CODE)
    ONLY_DOMAINS=$(echo $(perl -e 'print $ENV{$ARGV[0]}' -- $ONLY_DOMAINS))

    # Clean file
    echo "" > $COMMON_DYNAMIC

    # if empty domains, remove config
    if [[ -z $ONLY_DOMAINS ]]; then
        rm $COMMON_DYNAMIC
    fi

    for DOMAIN in $ONLY_DOMAINS; do
        TOPDOMAIN=$(perl -e 'if ($ARGV[0] =~ /((?<subdomain>.*)\.)?(?<domain>.*)\.(?<topdomain>.*)$/) {print $+{topdomain};};' -- "$DOMAIN")
        C_DOMAIN=$(perl -e 'if ($ARGV[0] =~ /((?<subdomain>.*)\.)?(?<domain>.*)\.(?<topdomain>.*)$/) {print $+{domain};};' -- "$DOMAIN")
        TEMPLATE=$TEMPLATE_CODE
        TEMPLATE="${TEMPLATE//\$COMMON_DOMAIN/$DOMAIN}"
        TEMPLATE="${TEMPLATE//\$ENVIRONMENT/$ENVIRONMENT}"
        TEMPLATE="${TEMPLATE//\$TOPDOMAIN/$TOPDOMAIN}"
        TEMPLATE="${TEMPLATE//\$C_DOMAIN/$C_DOMAIN}"
        TEMPLATE="${TEMPLATE//\$PARSED_DOMAINS/$ONLY_DOMAINS}"

        SSL_DERICTIVE=""

        # find external certificate domain
        CERTIFICATE_DOMAIN=$(findPattern "certificate-domain" $TEMPLATE)

        # find server_name for check certificate
        if [[ -z $CERTIFICATE_DOMAIN ]]; then
            CERTIFICATE_DOMAIN=$(perl -e '$str = $ARGV[0];if ($str =~ /server_name([A-z.0-9]*);/) {print $1;};' -- $(echo $TEMPLATE | sed 's/ //g'))
        fi

        if [[ $CERTIFICATE_DOMAIN != "" ]]; then
            SSL_KEY=/var/www/html/docker/letsencrypt/${PROJECT_ENVIRONMENT}/live/${CERTIFICATE_DOMAIN}/privkey.pem;
            SSL_CERT=/var/www/html/docker/letsencrypt/${PROJECT_ENVIRONMENT}/live/${CERTIFICATE_DOMAIN}/fullchain.pem;

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