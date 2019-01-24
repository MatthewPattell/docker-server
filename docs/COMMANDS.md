# Available console commands

List simple commands run in project root.

 - `composer server init` create project docker folder, prepare docker env
 - `composer server up` run server [see more](https://docs.docker.com/compose/reference/up/)
 - `composer server down` stop server [see more](https://docs.docker.com/compose/reference/down/)
 - `composer server restart` sequential execution of commands `down` and `up`
 - `composer server "logs server"` shown logs service `server`
 - `composer server-run server "ls -l"` create service `server`, run command `ls -l` inside container and remove service
 - `composer server-exec server "ls -l"` run command inside exist running service `server`
 - `composer server-deploy-dev` deploy you code to remote server (add to your composer file `"server-deploy-prod": "vendor/bin/site-deploy.sh --env-file=docker/.env-dev"`)
 
[See AWS commands](ENVIRONMENTS.md#auto-update-hosts-envs)

# Nginx container
 - `nginx -s reload` reload all configs (use after run `/scripts/init-nginx.sh`)
 
# PHP-FPM container
 - `service php7.1 start|stop|status|restart|reload|force-reload` php-fpm commands
 
# Server container
 - `service php7.1 start|stop|status|restart|reload|force-reload` php-fpm commands
 - `supervisorctl status` status all supervisor services
 - `supervisorctl stop all` stop all supervisor services
 - `supervisorctl start all` start all supervisor services
 - `supervisorctl restart all` restart all supervisor services
 - `supervisorctl restart service-name` restart service-name service
 
## Get SSL certificates script

### Test certbot commands

Run command: 

    ENV_PATH=/path-to-project/docker/scripts/test/.env bash ./docker/scripts/get-certificates.sh --test
    Output example:
    
Output example:

    eval certbot certonly --webroot --agree-tos --no-eff-email --email admin@test.com  -w /home/konstantin/Project/lib/docker-server/nginx/web -d foo.com -d t.foo.com
    eval certbot certonly --webroot --agree-tos --no-eff-email --email admin@test.com  -w /home/konstantin/Project/lib/docker-server/nginx/web -d baz.com -d admin.baz.com -d bar.com

