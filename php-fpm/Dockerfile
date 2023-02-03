FROM php:7.4-fpm-alpine3.16

ENV TZ=Europe/Moscow

WORKDIR /var/www

RUN apk update \
 && apk add --no-cache git tzdata \
 && docker-php-ext-install bcmath mysqli pdo_mysql pcntl \
 && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
 && sed -i 's/;date.timezone =/date.timezone = Europe\/Moscow/' /usr/local/etc/php/php.ini \
 && sed -i 's/listen = .*/listen = \${PHP_PORT}/g' /usr/local/etc/php-fpm.d/zz-docker.conf

#COPY ./apps /var/www/adm

CMD ["php-fpm"]
