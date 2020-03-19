#!/usr/bin/env bash

# Run aws command with env params

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

ACTION="AWS_$(echo "$1" | tr '[:lower:]' '[:upper:]')"
ACTION="${ACTION[@]/-/_}"
COMMAND=${!ACTION}

if [[ ! -z "$COMMAND" ]]; then
    eval "${COMMAND[@]/-SERVICES-/$SERVICES}"
else
    echo "Command not found."
    exit 1
fi
