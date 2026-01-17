# Use WordPress 5.8.0 with PHP 7.4 (both have known vulnerabilities)
FROM wordpress:5.8.0-php7.4-apache

# Metadata
LABEL maintainer="pentester@lab.local"
LABEL description="Intentionally vulnerable WordPress for ethical hacking practice"
LABEL version="1.0"

# Install useful debugging and exploitation tools
RUN apt-get update && apt-get install -y \
    vim \
    nano \
    wget \
    curl \
    unzip \
    net-tools \
    iputils-ping \
    dnsutils \
    default-mysql-client \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP for maximum verbosity (reveals information useful for attackers)
RUN echo "display_errors = On" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "log_errors = On" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "error_log = /var/log/php_errors.log" >> /usr/local/etc/php/conf.d/custom.ini

# Disable PHP security functions (DANGEROUS - Lab only!)
RUN echo "disable_functions = " >> /usr/local/etc/php/conf.d/custom.ini

# Allow dangerous PHP settings
RUN echo "allow_url_fopen = On" >> /usr/local/etc/php/conf.d/custom.ini && \
    echo "allow_url_include = On" >> /usr/local/etc/php/conf.d/custom.ini

# Set permissive file permissions (vulnerable by design)
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Install WP-CLI for automation and easier plugin installation
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    chown www-data:www-data /usr/local/bin/wp

# Create uploads directory with permissive permissions
RUN mkdir -p /var/www/html/wp-content/uploads && \
    chmod -R 777 /var/www/html/wp-content/uploads

# Download and install vulnerable plugins
WORKDIR /tmp

# WP File Manager 6.0 (CVE-2020-25213 - RCE)
RUN wget -q https://downloads.wordpress.org/plugin/wp-file-manager.6.0.zip && \
    unzip -q wp-file-manager.6.0.zip -d /var/www/html/wp-content/plugins/ && \
    unzip -q /var/www/html/wp-content/plugins/wp-file-manager/wp-file-manager-6.O.zip -d /var/www/html/wp-content/plugins/ && \
    rm wp-file-manager.6.0.zip

# Mail Masta (LFI vulnerability)
RUN git clone --quiet https://github.com/p314dO/mail-masta.git /usr/src/wordpress/wp-content/plugins/mail-masta

# Social Warfare 3.5.2 (CVE-2019-9978 - RCE)
RUN wget -q https://downloads.wordpress.org/plugin/social-warfare.3.5.2.zip && \
    unzip -q social-warfare.3.5.2.zip -d /usr/src/wordpress/wp-content/plugins/ && \
    rm social-warfare.3.5.2.zip

# Appointment Booking Calendar 1.3.34 (SQL Injection)
RUN wget -q https://downloads.wordpress.org/plugin/appointment-booking-calendar.1.3.34.zip && \
    unzip -q appointment-booking-calendar.1.3.34.zip -d /usr/src/wordpress/wp-content/plugins/ && \
    rm appointment-booking-calendar.1.3.34.zip

# Work The Flow File Upload 2.5.2 (Arbitrary File Upload)
RUN git clone --quiet --branch 2.5.2 https://github.com/wp-plugins/work-the-flow-file-upload.git /usr/src/wordpress/wp-content/plugins/work-the-flow-file-upload

# Download and install vulnerable themes
# Twenty Fifteen 2.0 (XSS vulnerabilities)
RUN wget -q https://downloads.wordpress.org/theme/twentyfifteen.2.0.zip && \
    unzip -q twentyfifteen.2.0.zip -d /usr/src/wordpress/wp-content/themes/ && \
    rm twentyfifteen.2.0.zip

# Twenty Seventeen 1.0 (Multiple vulnerabilities)
RUN wget -q https://downloads.wordpress.org/theme/twentyseventeen.1.0.zip && \
    unzip -q twentyseventeen.1.0.zip -d /usr/src/wordpress/wp-content/themes/ && \
    rm twentyseventeen.1.0.zip

# Set proper permissions for all plugins and themes
RUN chown -R www-data:www-data /usr/src/wordpress/wp-content/plugins && \
    chown -R www-data:www-data /usr/src/wordpress/wp-content/themes && \
    chmod -R 755 /usr/src/wordpress/wp-content/plugins && \
    chmod -R 755 /usr/src/wordpress/wp-content/themes

WORKDIR /var/www/html

# Expose HTTP port
EXPOSE 80

# Default command (inherited from base image)
CMD ["apache2-foreground"]