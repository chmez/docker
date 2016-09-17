# Download OS image
FROM ubuntu:16.10

# Set arguments
ARG email=chmez070@gmail.com
ARG db_user=alexgor_portfoli
ARG db_password=394zqcdq

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
RUN apt-get install -y php7.0-zip php7.0-xml curl
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN composer global require drush/drush:8.*

# Download Drupal 8 core and contrib modules
ENV PATH="/root/.composer/vendor/bin:${PATH}"
COPY make/*.make.yml .
RUN drush make profile.make.yml --prepare-install --overwrite -y
RUN rm *.make.yml

# Preparing web server for install Drupal
RUN apt-get install -y php7.0-gd
COPY 000-default.conf /etc/apache2/sites-available
RUN a2enmod rewrite
RUN a2enmod headers

# Preparing file system for install Drupal
WORKDIR /var/www/html
RUN rm LICENSE.txt README.txt
RUN mv example.gitignore .gitignore
RUN chown -R www-data:www-data sites/default
COPY portfolio profiles/portfolio

# Preparing DB server for install Drupal
RUN mysql -u root -proot -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password'"
RUN mysql -u root -proot -e "GRANT ALL PRIVILEGES ON $db_user.* TO '$db_user'@'localhost'"
RUN mysql -u root -proot -e "FLUSH PRIVILEGES"

# Install Drupal
RUN drush si portfolio --db-url=mysql://$db_user:$db_password@localhost:3306/$db_user --account-name=$db_user --account-pass=$db_password --account-mail=$email --locale=uk --site-name=Portfolio --site-mail=$email -y
RUN drush cr

# Sync site root directory with local machine
VOLUME "/var/www/html"

CMD tail -f /dev/null