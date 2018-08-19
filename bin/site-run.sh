#!/usr/bin/env bash

# run app service

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
SERVICE_COMMAND=$2

docker-compose ${SERVICES} run --rm ${SERVICE} /bin/bash -c "${SERVICE_COMMAND}"
docker-compose ${SERVICES} down