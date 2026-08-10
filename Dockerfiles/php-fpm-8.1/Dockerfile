# php-fpm 8.3 mysql redis rabbit cron
FROM php:8.3-fpm

RUN apt-get update \
  && apt-get install -y \
     apt-utils \
     cron \
     software-properties-common \
     libmemcached11 \
     libmemcachedutil2 \
     libmemcached-dev \
     libpq-dev \
     man \
     curl \
     cron \
     ffmpeg \
     unzip \
     p7zip-full \
     nginx \
     supervisor \
     nfs-common \
     locales \
     procps \
     pkg-config \
     icu-devtools \
     libicu-dev \
     libcurl4 \
     libcurl4-gnutls-dev \
     libfreetype6-dev \
     libjpeg62-turbo-dev \
     libpng-dev \
     libbz2-dev \
     libssl-dev \
     libgmp-dev \
     libtidy-dev \
     libxml2-dev \
     libxslt1-dev \
     libzip-dev \
     libonig-dev \
     librabbitmq-dev \
     xfonts-base \
     xfonts-75dpi \
 && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

RUN apt-get update && apt-get install -y gettext-base default-mysql-client
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g npm@10.2.4
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN apt-get update && apt-get install -y gettext-base default-mysql-client

RUN curl -L#o wkhtmltopdf.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb
RUN dpkg -i wkhtmltopdf.deb; apt-get install -y -f

RUN docker-php-ext-install mysqli \
    && docker-php-ext-install pdo_mysql \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && pecl install memcached \
    && docker-php-ext-enable memcached \
    && pecl install amqp \
    && docker-php-ext-enable amqp \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install pgsql \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip \
    && docker-php-ext-install bz2 \
    && docker-php-ext-install calendar \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install exif \
    && docker-php-ext-install gettext \
    && docker-php-ext-install gmp \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install shmop \
    && docker-php-ext-install sockets \
    && docker-php-ext-install sysvmsg \
    && docker-php-ext-install sysvsem \
    && docker-php-ext-install sysvshm \
    && docker-php-ext-install tidy \
    && docker-php-ext-install xsl \
    && docker-php-ext-install xml \
    && docker-php-ext-install opcache \
    && docker-php-source delete

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd \
  && docker-php-source delete
