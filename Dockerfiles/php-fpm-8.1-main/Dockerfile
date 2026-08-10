FROM node:21.4-alpine AS build-public

WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/root/.npm npm install && \
    npm run prod || \
    (echo "=== NPM Build Failed! Showing logs... ===" && \
     cat $(ls -t /root/.npm/_logs/*.log | head -n1) && \
     exit 1)


FROM tools:php-8.3-fpm-opcache

COPY --chown=www-data:www-data . /var/www/html
COPY --from=build-public --chown=www-data:www-data /app/public /var/www/html/public

RUN rm -f /usr/local/etc/php-fpm.d/* && \
    mv automation/conf/php-fpm/www.conf /usr/local/etc/php-fpm.d/ && \
    mkdir -p /var/run/php && chown -R www-data:www-data /var/run/php && \
    mv automation/conf/nginx/nginx.conf /etc/nginx/nginx.conf && \
    mv automation/conf/nginx/fastcgi_params /etc/nginx/fastcgi_params && \
    mv automation/conf/nginx/sites-enabled/default /etc/nginx/sites-available/default && \
    mv automation/php.ini /usr/local/etc/php/conf.d/php.ini && \
    mv automation/cron/sheduler /etc/cron.d && \
    rm -f /usr/local/etc/php-fpm.conf && \
    mv automation/conf/php-fpm/php-fpm.conf /usr/local/etc/php-fpm.conf && \
    chmod 0644 /etc/cron.d/sheduler && \
    crontab /etc/cron.d/sheduler && \
    mv automation/scripts/rotate-logs.sh /opt/rotate-logs.sh && \
    chmod +x /opt/rotate-logs.sh

WORKDIR /var/www/html

RUN --mount=type=cache,target=~/.composer \
    COMPOSER_HOME=~/.composer composer install --optimize-autoloader --prefer-dist && \
    chown -R www-data:www-data storage bootstrap/cache vendor && \
    chmod -R 775 storage && \
    chmod +x ./automation/php-artisan.sh && \
    mkdir /var/log/php-fpm && \
    chown www-data:www-data /var/log/php-fpm

RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

ENV TZ="Europe/London"
ENV LANGUAGE ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8
RUN locale-gen ru_RU.UTF-8

EXPOSE 80

CMD ["entrypoint.sh"]
