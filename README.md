Universal docker server
===========================
Nginx, PHP-FPM, MySql, Redis

Installation
------------

The preferred way to install this extension is through [composer](http://getcomposer.org/download/).

Either run

```
php composer.phar require --prefer-dist matthew-p/docker-server "@dev"
```

or add

```
"matthew-p/docker-server": "@dev"
```

to the require section of your `composer.json` file.

## After install package:

1. Add or update section **scripts** in **composer.json**:
    ```json
    ...
    "scripts": {
        "server": "vendor/bin/site-start.sh --env-file=docker/.env-local",
        "server-run": "vendor/bin/site-run.sh --env-file=docker/.env-local",
        "server-exec": "vendor/bin/site-exec.sh --env-file=docker/.env-local",
     
        // (optional)
        "server-prod": "vendor/bin/site-aws.sh --env-file=docker/.env-prod",
        // (optional)
        "server-deploy-dev": "vendor/bin/site-deploy.sh --env-file=docker/.env-dev"
    }
    ...
    ```
    where **"docker/.env-local"** relative path to your local env config _(will be created in next step)_.
2. Run: ```composer server init```. This will create a **docker** folder in your project root directory.
3. Change **root-path** in _docker/nginx/conf-dynamic.d/sample.conf_
4. See [supported os](#supported-os) and config **docker/.env-local** according to your operating system
5. Run server: ```composer server up ```

## Supported OS
 - [Linux](docs/LINUX.md)
 - [Mac OS](docs/MACOS.md)
 
## Environments && Commands
 - [See all available environments](docs/ENVIRONMENTS.md)
 - [See console commands](docs/COMMANDS.md)
 
## PhpStorm samples
 - [Deploy config](phpstorm/SAMPLE_DEPLOY_CONFIG.xml)

**FEATURES**
---
- Multiple config: ```vendor/bin/site-start.sh --env-file=docker/.env-dev,docker/.env-local```
- Use environment, extends, overriding between configs
    ```
    // Simple usage
    SERVICES="$SERVICES -f my.yml"
    
    // Will be recompiled (bad example)
    SERVICES="${SERVICES} -f my.yml"
    
    // Will be recompiled (good example)
    SERVICES="${SERVICES_EXTERNAL} -f my.yml"
    ```
- Use all environments in docker-compose files
- Overriding, extends docker-compose files
- Run container and execute command: ```composer server-run server "ls && top"```
- Run command in working container: ```composer server-exec server "composer install"```
- AWS create/update "Task Definitions"
- Auto update _/etc/hosts_ file on host machine
- Auto create nginx proxies on host machine
- Deploy
- And etc.  

## LIFEHACKS
- Configure hosts file:
    1. Check nginx container _IP_ and add to hosts file:
        ```bash
        docker inspect sample_nginx
        ```
        view **"IPAddress"** and add to:
        ```bash
        sudo nano /etc/hosts
        ```
        _172.18.0.4 sample.io_ (for example)  
        save and check it.
    2. Open browser and check **sample.io**

    OR see below **static network layer**
  
- **Add static network layer** _(only for Linux)_
    1. Change **SERVICES** variable in your local env (docker/.env-local) to:
        ```
        SERVICES="$SERVICES -f docker/docker-compose.common.yml -f docker/docker-compose.static-network.yml"
        ```
    2. Run: ```composer server restart``` and check it.
- **Update package without composer install and depencies**

    - with composer image:
    
        ```docker run --rm --interactive --volume $PWD:/app composer update --ignore-platform-reqs --no-scripts```
    
    - with server images:

        ```docker run --rm --interactive --volume $PWD:/app matthewpatell/universal-docker-server:3.8 bash -c 'cd /app && composer install --no-scripts'```
        
    - with server image and additional global packages:
        ```docker run --rm --interactive --volume $PWD:/app matthewpatell/universal-docker-server:3.8 bash -c 'cd /app && composer global require "fxp/composer-asset-plugin:^1.4.2" && composer global require "hirak/prestissimo:~0.3.7" && composer install --no-scripts'```

That's all. Check it. :)
