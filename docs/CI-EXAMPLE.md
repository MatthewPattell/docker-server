# CI Example

Contains your **.gitlab-ci.yml** file:
```dotenv
image: docker:latest

services:
  - docker:dind

variables:
  DOCKER_APP_PATH: /var/www/html
  SERVER_RUN_COMMAND: "vendor/bin/site-run.sh --env-file=docker/.env-ci"

# Cache modules in between jobs
cache:
  key: $CI_COMMIT_REF_SLUG
  paths:
    - vendor/

before_script:
  - apk add --no-cache python py2-pip git bash curl
  - pip install --no-cache-dir docker-compose==1.22.0
  # wait mysql and run composer
  - docker run --rm --interactive --volume $PWD:/app composer install --ignore-platform-reqs --no-scripts
  - ${SERVER_RUN_COMMAND} server_test
    "while ! curl mysql:3306; do ((c++)) && ((c==30)) && break; sleep 2; done && composer install"

stages:
  - tests
  - code style
  - notify
  - deploy

tests:
  stage: tests
  script:
    # wait nginx and run tests
    - ${SERVER_RUN_COMMAND} server_test
      "while ! curl http://nginx:81; do ((c++)) && ((c==30)) && break; sleep 2; done && vendor/bin/codecept run"

code style:
  stage: code style
  script:
    - ${SERVER_RUN_COMMAND} "--no-deps server_test" "vendor/bin/phpcs --extensions=php,js,css ."
  when: on_success

.notify success:
  stage: notify
  script:
    - ${SERVER_RUN_COMMAND} "--no-deps
      -e CI_COMMIT_REF_SLUG=$CI_COMMIT_REF_SLUG
      -e CI_PROJECT_NAME=$CI_PROJECT_NAME
      -e CI_PIPELINE_ID=$CI_PIPELINE_ID
      -e CI_PROJECT_URL=$CI_PROJECT_URL
      server_test"
      "/scripts/telegram/gitlab-ci-notify.sh ✅"
  when: on_success

notify error:
  stage: notify
  script:
    - ${SERVER_RUN_COMMAND} "--no-deps
      -e CI_COMMIT_REF_SLUG=$CI_COMMIT_REF_SLUG
      -e CI_PROJECT_NAME=$CI_PROJECT_NAME
      -e CI_PIPELINE_ID=$CI_PIPELINE_ID
      -e CI_PROJECT_URL=$CI_PROJECT_URL
      server_test"
      "/scripts/telegram/gitlab-ci-notify.sh ❌"
  when: on_failure

# Coverage
.pages:
  stage: deploy
  script:
    - touch index1.html
  artifacts:
    paths:
      - console/runtime/logs/coverage
    expire_in: 1 week
  only:
    - master
  when: on_success
```

Contains your env file **docker/.env-ci**:

```dotenv
# ENVIRONMENT (PROD/DEV)
PROJECT_ENVIRONMENT=DEV

# PROJECT
PROJECT_NAME=sample-ci
PROJECT_DOCKER_FOLDER=${PROJECT_ROOT}/docker

# DOMAINS
DOMAIN_COMMON_TEST=nginx

GIT_AUTHTOKEN=token

# TELEGRAM NOTIFICATIONS
TELEGRAM_BOT_TOKEN=bot-token
TELEGRAM_CHAT_ID=chat-id

SERVICES="$SERVICES -f docker/docker-compose.common.yml -f !!docker-compose.tests.yml"
```

Contains your `common-test.conf` file in `docker/nginx/conf-dynamic.d`:
```
# Variable automaticaly replaced:
# SSL_INCLUDE, COMMON_DOMAIN, PARSED_DOMAINS, DOMAIN_1LVL, DOMAIN_2LVL

# allow domains:
#
# <domains-include>DOMAIN_COMMON_TEST</domains-include>
#
# parsed domains: $PARSED_DOMAINS

# change certificate domain:
#
# <certificate-domain>$CERTIFICATE_DOMAIN</certificate-domain>

server {
    charset              utf-8;
    client_max_body_size 50M;

    listen               81;

    server_name          $COMMON_DOMAIN;

    root                 /var/www/html/frontend/web;
    index                index-test.php;

    # if ssl certificate exist for domain, here will be included ssl directives
    $SSL_INCLUDE

    include snippets/letsencrypt-acme-challenge.conf;
    include snippets/rewrite.conf;
    include snippets/static.conf;
    include snippets/external-rules.conf;

    location / {
        # Redirect everything that isn't a real file to index-test.php
        try_files $uri $uri/ /index-test.php$is_args$args;
        # tell nginx to pass php scripts to php-fpm
        include php-fpm.conf;
    }
}
```

That's all. Check it. :)