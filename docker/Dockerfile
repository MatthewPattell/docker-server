FROM ubuntu:16.04
MAINTAINER Mathew Patell <likomi@mail.ru>

# Setup environment
ENV DEBIAN_FRONTEND noninteractive

# Update sources
RUN apt-get update -y --fix-missing

# Install utils
RUN apt-get install -y apt-utils mc htop nano wget zip unzip bash-completion vim

# Install rsyslog and cron
RUN apt-get install -y rsyslog cron

# CURL
RUN apt-get install -y curl

# php repository
ADD ondrej-ubuntu-php-xenial.list /etc/apt/sources.list.d/
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
RUN apt-get update -y --fix-missing

# install php
RUN apt-get install -y --allow-unauthenticated php7.1 php7.1-bcmath php7.1-bz2 php7.1-cgi php7.1-cli php7.1-common php7.1-curl php7.1-dba php7.1-dev php7.1-enchant php7.1-fpm php7.1-gd php7.1-gmp php7.1-imap php7.1-interbase php7.1-intl php7.1-json php7.1-ldap php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-odbc php7.1-opcache php7.1-pgsql php7.1-phpdbg php7.1-pspell php7.1-readline php7.1-recode php7.1-snmp php7.1-soap php7.1-sqlite3 php7.1-sybase php7.1-tidy php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip php7.1-xdebug
RUN apt-get install -y php-imagick

# php pecl extensions
RUN apt-get install libyaml-dev -y && \
    printf "\n" | pecl install yaml-2.0.0

RUN echo "extension=yaml.so" >> /etc/php/7.1/mods-available/yaml.ini
RUN phpenmod yaml

RUN apt-get install -y mysql-client-5.7

# install git
RUN apt-get --yes --force-yes install git

# install sshd
RUN apt-get install -y openssh-server openssh-client passwd
RUN mkdir -p /var/run/sshd

#RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Put your own public key at id_rsa.pub for key-based login.
RUN mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys && chmod 700 /root/.ssh

# Install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Fix terminal
RUN echo "export TERM=xterm mc" >> ~/.bashrc

# Install ssl cerbot
RUN apt-get install -y software-properties-common && \
    add-apt-repository ppa:certbot/certbot && \
    apt-get update && \
    apt-get install -y python-certbot-apache

# Install images utils
RUN apt-get install -y libjpeg-progs jpegoptim pngquant

# Install supervisord
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisord

# Install java and minify tools
RUN apt-get install -y default-jre
RUN wget https://dl.google.com/closure-compiler/compiler-latest.zip -P /tmp && \
    unzip /tmp/compiler-latest.zip -d /tmp/compiler && \
    mv /tmp/compiler/closure-compiler* /home/closure-compiler.jar && \
    rm -R /tmp/compiler && \
    wget https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar -O /home/yuicompressor.jar && \
    chown www-data /home/closure-compiler.jar && \
    chown www-data /home/yuicompressor.jar

RUN mkdir /var/log/cron

EXPOSE 9000

CMD ["supervisord", "-n"]
