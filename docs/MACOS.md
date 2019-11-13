# Recommended config for Mac OS

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

# HOST NGINX SUPPORT (for create proxies nginx configs on host, because mac os does`n access to docker private network)
HOST_NGINX_PROXIES=yes
HOST_NGINX_KEEP_CONF=yes
HOST_NGINX_TEMPLATE_PATH=${VENDOR_DIR}/conf/nginx-proxy.conf
# Your nginx configs folder on mac
HOST_NGINX_CONF_DIR=/usr/local/etc/nginx/servers
# Restart nginx command on mac
HOST_NGINX_RESTART_COMMAND="sudo brew services restart nginx"

# Auto update hosts file
HOST_ETC_HOSTS_UPDATE=yes
HOST_ETC_KEEP_CONF=yes

# DO NOT REMOVE THIS LINE


```

And run ```composer server restart```