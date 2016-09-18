# Download OS image
FROM ubuntu:16.10

# Update packages
RUN apt-get update

# Install and configure Apache2 web server
RUN apt-get install -y apache2
RUN echo "\nServerName 127.0.0.1\n" >> /etc/apache2/apache2.conf

# Install and configure MySQL 5.7 database server
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "mysql-server-5.7 mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server-5.7 mysql-server/root_password_again password root" | debconf-set-selections
RUN apt-get install -y mysql-server-5.7
RUN usermod -d /usr/lib/mysql mysql

# Install PHP 7.0 and extensions
RUN apt-get install -y php7.0 libapache2-mod-php7.0 php7.0-mysql

# Install Drush 8
RUN apt-get install -y php7.0-zip php7.0-xml curl git
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN composer global require drush/drush:8.*

# Preparing web server for install Drupal
RUN apt-get install -y php7.0-gd php7.0-mbstring
COPY 000-default.conf /etc/apache2/sites-available
RUN a2enmod rewrite
RUN a2enmod headers
ENV PATH="/root/.composer/vendor/bin:${PATH}"
WORKDIR /var/www/html

# Download site files from repository
COPY id_rsa id_rsa.pub known_hosts /root/.ssh/
RUN rm -rf *
RUN git clone git@bitbucket.org:chmez070/portfolio-site.git .
RUN composer install

# Sync site root directory with local machine
VOLUME "/var/www/html"

CMD tail -f /dev/null