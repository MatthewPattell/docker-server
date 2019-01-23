#!/usr/bin/env bash

# deploy code to server

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

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_NONE='\033[0m'

for i in "$@"
do
case ${i} in
    -s=*|--server-name=*)
    DEPLOY_SERVER_NAME="${i#*=}"
    shift
    ;;
    -c=*|--container-name=*)
    DEPLOY_CONTAINER_NAME="${i#*=}"
    shift
    ;;
    -p=*|--project-path=*)
    DEPLOY_PROJECT_PATH="${i#*=}"
    shift
    ;;
    -s=*|--strategy=*)
    DEPLOY_STRATEGY="${i#*=}"
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

DEPLOY_DEFAULT_SHELL=/bin/bash

if [ -z "$DEPLOY_SERVER_NAME" ]; then
    echo -e "${COLOR_RED}Server name not found (--server-name).${COLOR_NONE}"
    exit 1;
fi

if [ -z "$DEPLOY_CONTAINER_NAME" ]; then
    echo -e "${COLOR_RED}Container name not found (--container-name).${COLOR_NONE}"
    exit 1;
fi

if [ -z "$DEPLOY_PROJECT_PATH" ]; then
    echo -e "${COLOR_RED}Project path not found (--project-path).${COLOR_NONE}"
    exit 1;
fi

if [ -z "$DEPLOY_STRATEGY" ]; then
    echo -e "${COLOR_RED}Strategy not set (--strategy).${COLOR_NONE}"
    exit 1;
fi

DEPLOY_CONTAINER_ID=$(ssh -tt ${DEPLOY_SERVER_NAME} "docker ps -a --format 'table {{.ID}}' -f name=$DEPLOY_CONTAINER_NAME | sed -n 2p" | sed 's/[^0-9A-z]*//g')

if [ -z "$DEPLOY_CONTAINER_NAME" ]; then
    echo -e "${COLOR_RED}Container id not found.${COLOR_NONE}"
    exit 1;
fi

echo -e "\n${COLOR_GREEN} Container id found: $DEPLOY_CONTAINER_ID ${COLOR_NONE}"
echo -e "${COLOR_GREEN} Strategy: $DEPLOY_STRATEGY ${COLOR_NONE}"
echo -e "${COLOR_GREEN} Server: $DEPLOY_SERVER_NAME ${COLOR_NONE}\n"

# Strategy 1 git pull
if [ "$DEPLOY_STRATEGY" == 1 ]; then
    ssh -tt ${DEPLOY_SERVER_NAME} "cd $DEPLOY_PROJECT_PATH && git pull"
    exit 0
fi

# Strategy 2 git pull + docker container composer install
if [ "$DEPLOY_STRATEGY" == 2 ]; then
    ssh -tt ${DEPLOY_SERVER_NAME} "cd $DEPLOY_PROJECT_PATH && git pull && docker exec ${DEPLOY_CONTAINER_ID} ${DEPLOY_DEFAULT_SHELL} -c 'composer install'"
    exit 0
fi

# Strategy 3 in docker container git pull
if [ "$DEPLOY_STRATEGY" == 3 ]; then
    ssh -tt ${DEPLOY_SERVER_NAME} "docker exec ${DEPLOY_CONTAINER_ID} ${DEPLOY_DEFAULT_SHELL} -c 'git pull'"
    exit 0
fi

# Strategy 4 in docker container git pull + composer install
if [ "$DEPLOY_STRATEGY" == 4 ]; then
    ssh -tt ${DEPLOY_SERVER_NAME} "docker exec ${DEPLOY_CONTAINER_ID} ${DEPLOY_DEFAULT_SHELL} -c 'git pull && composer install'"
    exit 0
fi

echo -e "${COLOR_RED}Strategy case not foud. Use 1-4. ${COLOR_NONE}"