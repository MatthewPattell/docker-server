#!/usr/bin/env bash

# RUN ON SERVER SERVICE

# Getting environments for using in current script
set -a
. ${ENV_PATH}
set +a

bash /scripts/set-permissions.sh

# add environments to os (for php CLI)
echo "export XDEBUG_CONFIG=\"${XDEBUG_CONFIG}\"" >> ~/.bashrc
echo "export PHP_IDE_CONFIG=\"${PHP_IDE_CONFIG}"\" >> ~/.bashrc

# Set ssh access
echo 'root:'$SSH_PASSWORD | chpasswd
while IFS= read -r key; do
    echo $key >> /root/.ssh/authorized_keys
done < ${PROJECT_DOCKER_FOLDER_CONTAINER}/ssh/authorized_keys

# Install deploy key and ssh config if exits
DEPLOY_KEY=${PROJECT_DOCKER_FOLDER_CONTAINER}/ssh/site_deploy_key
SSH_CONFIG=${PROJECT_DOCKER_FOLDER_CONTAINER}/ssh/config

if [ -f $DEPLOY_KEY ] && [ -f $SSH_CONFIG ]; then
    cp $DEPLOY_KEY /root/.ssh/site_deploy_key
    cp $SSH_CONFIG /root/.ssh/config

    chmod 0600 /root/.ssh/site_deploy_key
    chmod 0644 /root/.ssh/config
fi

# Config composer
composer config -g github-oauth.github.com $GIT_AUTHTOKEN
composer global require "fxp/composer-asset-plugin": "^1.4.2"
composer global require "hirak/prestissimo:~0.3.7"

cd ${PROJECT_ROOT_CONTAINER} && composer install

# php debug
if [[ $PROJECT_ENVIRONMENT == "DEV" ]]; then
    phpenmod xdebug
fi

exit 0