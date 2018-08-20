Available environments (.env)
===========================

# Navigation
 - [Project envs](#project-envs)

## <a id="project-envs"></a>Project env (service: all)
Property | Values | Description
---------|--------|------------
`PROJECT_ENVIRONMENT` | `yes`/`no` | Project environment: Include different nginx ssl certificates (letsencrypt), toggle php xdebug, nginx cache control, rewrite to https 
`PROJECT_NAME` | `(string)` | Unique project name
`COMPOSE_PROJECT_NAME` | `(string)` `Default: $PROJECT_NAME` | Docker compose project name. Is is recommended to be equal `PROJECT_NAME`. [see more](https://docs.docker.com/compose/reference/envvars/#compose_project_name)
`PROJECT_ROOT_CONTAINER` | `(string)` `Default: /var/www/html` | Project root, inside server container. It is not recommended to change
`PROJECT_ROOT`| `(string)` `Default: ${VENDOR_PARENT_DIR}` | Project root in host machine. This can be changed for create task definition in aws and etc.
`PACKAGE_DOCKER_FOLDER`| `(string)` `Default: ${PROJECT_ROOT}${VENDOR_COMMON_DIR}/docker` | This is the path to the vendor package **docker** folder `vendor/matthew-p/docker-server/docker`
`PACKAGE_DOCKER_FOLDER_CONTAINER` | `string` `Default: /docker-server` | This is the path to the mounted **docker** folder on container
`PROJECT_DOCKER_FOLDER` | `(string)` `Default: ${PACKAGE_DOCKER_FOLDER}` | This is the path to the mounted **project docker** folder on container. Example: `volumes: - ${PROJECT_DOCKER_FOLDER}/nginx/logs:/var/log/nginx` it will be save nginx logs to your project docker folder.
`PROJECT_DOCKER_FOLDER_CONTAINER`| `(string)` `Default: ${PROJECT_ROOT_CONTAINER}/docker` | **project docker folder** in docker container.
`RUN_SERVER_COMPOSER` | `1`/`0` `Default: 0` | Require globaly composer asset plugin and run composer install in project root after server start (inside docker container)
`DEFAULT_DETACHED_MODE`| `(string)` `Default: -d` |  automatically added `-d` to `docker-compose up` (and `composer server up`)
`PROJECT_ENV_PATH_FORCE`| `(string)` `Default: not set` | Use only for generate .env without run server (e.g. create aws definition)
`SERVICES`| `(string)` | All path to docker compose files which need project

## Images env (service: all)
Property | Values | Description
---------|--------|------------
`NGINX_REPOSITORY`| `(string)` `Default: matthewpatell/universal-docker-nginx:2.1` | Nginx docker image
`SERVER_REPOSITORY`| `(string)` `Default: matthewpatell/universal-docker-server:2.2` | Server docker image (php, ssh and etc.)

## Server env (service: server)

`-f !!docker-compose.yml` add to `SERVICES` (default: added)

Property | Values | Description
---------|--------|------------
`SERVER_HTTP_PORT`| `(int)` `Default: 80` | Server http port. Used when `PROJECT_ENVIRONMENT=DEV`
`SERVER_SSL_PORT`| `(int)` `Default: 443` | Server https port. Used when `PROJECT_ENVIRONMENT=PROD`

## Mysql env (service: mysql)

`-f !!docker-compose.mysql.yml` add to `SERVICES` (default: added)

Property | Values | Description
---------|--------|------------
`MYSQL_HOST`| `(string)` `Default: mysql` | Mysql host (internal)
`MYSQL_PORT`| `(int)` `Default: 3306` | Mysql port (external)
`MYSQL_ROOT_PASSWORD` | `(string)` | Mysql root password
`MYSQL_DATABASE` | `(string)` | Mysql database (automatically created at first run)
`MYSQL_USER` | `(string)` | Mysql user
`MYSQL_PASSWORD` | `(string)` | Mysql password

## Redis env (service: redis)

`-f !!docker-compose.redis.yml` add to `SERVICES` (default: added)

Property | Values | Description
---------|--------|------------
`REDIS_HOST`| `(string)` `Default: redis` | Redis host (internal)
`REDIS_PORT`| `(int)` `Default: 6379` | Redis port (external)
`REDIS_PASSWORD` | `(string)` | Redis password
`REDIS_DATABASE` | `(string)` | Redis database

## SSH env (service: server)

`-f !!docker-compose.yml` add to `SERVICES` (default: added)

Property | Values | Description
---------|--------|------------
`SSH_PORT`| `(int)` `Default: 22` | SSH port (external)
`SSH_PASSWORD`| `(string)` | SSH password

## PHP-FPM env (service: server)

`-f !!docker-compose.yml` add to `SERVICES` (default: added)

Property | Values | Description
---------|--------|------------
`DEBUG_PORT`| `(int)` `Default: 9000` | PHP debug port
`PHP_IDE_CONFIG`| `(string)` `Default: "serverName=${PROJECT_NAME}`" | IDE Config
`XDEBUG_CONFIG`| `(string)` | Xdebug config