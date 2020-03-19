#!/usr/bin/env bash

# Execute command in service

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

SERVICE=$1
DEFAULT_SHELL=/bin/bash
COMMAND=$2

if [[ "$2" = "sh" ]] || [[ "$2" = "/bin/sh" ]]; then
    DEFAULT_SHELL=/bin/sh
    COMMAND=$3
fi

if [[ "$COMMAND" != "" ]]; then
    # @TODO_ tty composer not working :( https://github.com/symfony/symfony/issues/17010
    # https://github.com/composer/composer/issues/5856
    docker-compose ${SERVICES} exec ${SERVICE} ${DEFAULT_SHELL} -c "$COMMAND"
else
    docker-compose ${SERVICES} exec ${SERVICE} ${DEFAULT_SHELL}
fi
