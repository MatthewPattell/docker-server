# Recommended config for Linux

Contains your env file **docker/.env.local**:
```dotenv
# ENVIRONMENT (PROD/DEV)
PROJECT_ENVIRONMENT=DEV

# PROJECT
# Required and UNIQUE project name
PROJECT_NAME=sample
PROJECT_DOCKER_FOLDER=${PROJECT_ROOT}/docker

# Add composer asset plugin and run composer install in project root after server service start
RUN_SERVER_COMPOSER=0

# DOMAINS
DOMAIN_COMMON=sample.io

SERVICES="$SERVICES -f docker/docker-compose.local.yml"

# Enable xdebug
XDEBUG_CONFIG="default_enable=1 remote_host=172.30.0.1 remote_enable=1 profiler_enable_trigger=0 remote_port=${DEBUG_PORT}"

# Auto update hosts file
HOST_ETC_HOSTS_UPDATE=yes
HOST_ETC_KEEP_CONF=yes

# DO NOT REMOVE THIS LINE


```

And run ```composer server restart```