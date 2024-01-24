FROM php:8.3-apache
WORKDIR /var/www

# Installation de Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Installation des extensions PHP nécessaires pour Symfony
RUN apt-get update \
    && apt-get install -y --no-install-recommends locales apt-utils git libicu-dev g++ libpng-dev libxml2-dev libzip-dev libonig-dev libxslt-dev wget unzip libmagickwand-dev;

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN docker-php-ext-configure intl
RUN docker-php-ext-install pdo pdo_mysql gd opcache intl zip calendar dom mbstring xsl
RUN pecl install apcu imagick && docker-php-ext-enable apcu imagick

# Configuration du serveur Apache
COPY ./conf/apache.conf /etc/apache2/sites-available/apache.conf
RUN a2dissite 000-default.conf \
    && a2ensite apache.conf \
    && a2enmod rewrite

# Installation de ZSH et Starship prompt
# RUN apt-get install -y zsh;
# RUN chsh -s /bin/zsh;
# RUN curl -sS https://starship.rs/install.sh | sh -s -- -y
# RUN echo 'eval "$(starship init zsh)"' >> ~/.zshrc

RUN chown -R www-data:www-data /var/www
# Création d'un utilisateur Apache qui sera désigné comme utilisateur par défaut pour exécuter les commandes
RUN userdel www-data && useradd -ms /bin/sh www-data
# RUN cp ~/.zshrc /home/www-data/.zshrc
# RUN chown www-data /home/www-data/.zshrc
USER www-data

COPY ./composer.json ./composer.json
COPY ./composer.lock ./composer.lock

# Copie des fichiers de l'application Symfony
COPY . .

# Exposition du port 80 pour Apache
RUN composer install --ignore-platform-reqs --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
EXPOSE 80

# Démarrage d'Apache en arrière-plan
CMD ["apache2-foreground"]

# FROM composer AS vendor
# WORKDIR /var/www
