FROM php:7.1.25-apache

LABEL maintainer="quanghuy.ico@gmail.com"

# Install Magento 2 dependencies
RUN apt-get update && apt-get install -y \
        cron \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libxslt1-dev \
        libicu-dev \
        mysql-client \
        xmlstarlet \
    && docker-php-ext-install -j$(nproc) bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) json \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-install -j$(nproc) mcrypt \
    && docker-php-ext-install -j$(nproc) mbstring \
    && docker-php-ext-install -j$(nproc) pcntl \
    && docker-php-ext-install -j$(nproc) soap \
    && docker-php-ext-install -j$(nproc) xsl \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) pdo \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && pecl install redis-4.2.0 \
    && docker-php-ext-enable redis \
    && a2enmod rewrite headers \
&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Install ioncube
RUN cd /tmp \
    && curl -o ioncube.tar.gz http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvvzf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_7.1.so /usr/local/lib/php/extensions/* \
    && rm -Rf ioncube.tar.gz ioncube \
    && echo "zend_extension=ioncube_loader_lin_7.1.so" > /usr/local/etc/php/conf.d/00_docker-php-ext-ioncube_loader_lin_7.1.ini

# Set up the application
COPY src /var/www/html/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY etc/php.ini /usr/local/etc/php/conf.d/00_magento.ini
COPY etc/apache.conf /etc/apache2/conf-enabled/00_magento.conf

# Copy hooks
COPY hooks /hooks/

# Set default parameters
ENV MYSQL_HOSTNAME="mysql" MYSQL_USERNAME="root" MYSQL_PASSWORD="secure" MYSQL_DATABASE="magento" CRYPT_KEY="" \
    URI="http://localhost" ADMIN_USERNAME="admin" ADMIN_PASSWORD="adm1nistrator" ADMIN_FIRSTNAME="admin" \
    ADMIN_LASTNAME="admin" ADMIN_EMAIL="admin@localhost.com" CURRENCY="EUR" LANGUAGE="en_US" \
    TIMEZONE="Europe/Amsterdam" BACKEND_FRONTNAME="admin" CONTENT_LANGUAGES="en_US"

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
