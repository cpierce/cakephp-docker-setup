# Set master image
FROM php:8.3-fpm-alpine

# Set user to root
USER root

# Set working directory
WORKDIR /var/www/html

# Install Additional dependencies
RUN apk update && apk add --no-cache \
    build-base shadow vim curl autoconf make gnupg g++ zlib libzip-dev \
    libpng-dev libjpeg-turbo-dev libwebp-dev libxpm-dev zlib-dev \
    openssl-dev oniguruma-dev linux-headers \
    icu-dev bzip2-dev freetype freetype-dev \
    freetds freetds-dev \
    git unzip

RUN set -xe && \
    cd /tmp/ && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS

# Add and Enable PHP Extenstions
RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN docker-php-ext-install mbstring
RUN docker-php-ext-configure gd \
      --with-freetype=/usr/include/ \
      --with-jpeg=/usr/include/
RUN docker-php-ext-install gd
RUN docker-php-ext-install intl
RUN docker-php-ext-install zip
RUN docker-php-ext-install bz2
RUN pecl update-channels
RUN pecl install igbinary
RUN pecl install xdebug
RUN docker-php-ext-enable pdo_mysql igbinary xdebug mbstring gd zip intl bz2

# Install PHP Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Remove Cache
RUN rm -rf /var/cache/apk/*

# Add UID '1000' to www-data
RUN usermod -u 1000 www-data

# Change current user to www
USER www-data

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
