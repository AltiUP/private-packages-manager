#!/bin/bash

# Private Packages Manager

#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
export PATH=$PATH:/sbin
PPM='/opt/ppm'
ppminstall="$PPM/install"

software="php7.3 php7.3-zip php7.3-xml php7.3-readline php7.3-opcache php7.3-mysql 
          php7.3-mbstring php7.3-json 
          php7.3-gd php7.3-fpm php7.3-curl php7.3-common php7.3-cli 
          php-cli php7.3-apc php-mbstring mariadb-server redis-server 
          apache2 git curl unzip sudo"


    # Defning return code check function
    check_result() {
        if [ $1 -ne 0 ]; then
            echo "Error: $2"
            exit $1
        fi
    }


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

    # Creating temporary file
    tmpfile=$(mktemp -p /tmp)

    # Checking root permissions
    if [ "x$(id -u)" != 'x0' ]; then
        check_error 1 "Script can be run executed only by root"
    fi

    # Checking admin user account
    if [ ! -z "$(grep ^ppm: /etc/passwd)" ] && [ -z "$force" ]; then
        echo 'Please remove ppm user account before proceeding.'
        check_result 1 "User ppm exists"
    fi

    # Checking wget
    if [ ! -e '/usr/bin/wget' ]; then
        apt-get -y install wget
        check_result $? "Can't install wget"
    fi


#----------------------------------------------------------#
#                       Brief Info                         #
#----------------------------------------------------------#

# Printing nice ascii aslogo
clear
echo
echo ' _|_|_|_|_|    _|_|_|_|_|    |_|||   |||_|'
echo ' _|      _|    _|      _|    |_| || || |_|'
echo ' _|_|_|_|_|    _|_|_|_|_|    |_|  |||  |_|'
echo ' _|            _|            |_|       |_|'
echo ' _|            _|            |_|       |_|'
echo
echo '                  Private Packages Manager'
echo -e "\n\n"

echo 'Following software will be installed on your system:'

# Web stack
    echo '   - Nginx Web Server'

# PHP-FPM
    echo '   - PHP-FPM 7.3'

# Printing start message and sleeping for 5 seconds
echo -e "\n\n\n\nInstallation will take about 10 minutes ...\n"
sleep 5


#----------------------------------------------------------#
#                   Upgrade repository                     #
#----------------------------------------------------------#

    # Updating system
    apt-get -y upgrade
    check_result $? 'apt-get upgrade failed'


#----------------------------------------------------------#
#                     Install packages                     #
#----------------------------------------------------------#

    # Update system packages
    apt-get update

    # Install apt packages
    apt-get -y install $software
    check_result $? "apt-get install failed"


#----------------------------------------------------------#
#                        Setup PPM                         #
#----------------------------------------------------------#

    # Clone repository
    git clone https://github.com/AltiUP/ppm.git /opt/ppm

    # Add user and group
    useradd ppm -d /opt/ppm -M -r
    usermod -a -G ppm www-data
    chown -R ppm:ppm /opt/ppm

    # Configuring Composer
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer


#----------------------------------------------------------#
#                    Configure Apache                      #
#----------------------------------------------------------#

    a2enmod rewrite headers proxy proxy_fcgi
    service apache2 start
    check_result $? "apache2 start failed"


#----------------------------------------------------------#
#                     Configure PHP                        #
#----------------------------------------------------------#

    ZONE=$(timedatectl 2>/dev/null|grep Timezone|awk '{print $2}')
    if [ -z "$ZONE" ]; then
        ZONE='UTC'
    fi
    for pconf in $(find /etc/php* -name php.ini); do
        sed -i "s/;date.timezone =/date.timezone = $ZONE/g" $pconf
        sed -i 's%_open_tag = Off%_open_tag = On%g' $pconf
    done


#----------------------------------------------------------#
#                     Configure PPM                        #
#----------------------------------------------------------#

    # Setup dependencies
    cd /opt/ppm
    sudo -u ppm composer install
    sudo -u ppm app/console doctrine:schema:create
    sudo -u ppm app/console cache:clear --env=prod
    cd ~


#----------------------------------------------------------#
#              Private Packages Manager Info               #
#----------------------------------------------------------#

# Show notification
echo '======================================================='
echo -e "Congratulations, you have just successfully installed \
Private Packages Manager

    --> 


We hope that you enjoy your installation of PPM. Please \
feel free to contact us anytime if you have any questions.
Thank you.

--
Sincerely yours
"

# Congrats
echo '======================================================='
echo
echo ' _|_|_|_|_|    _|_|_|_|_|    |_|||   |||_|'
echo ' _|      _|    _|      _|    |_| || || |_|'
echo ' _|_|_|_|_|    _|_|_|_|_|    |_|  |||  |_|'
echo ' _|            _|            |_|       |_|'
echo ' _|            _|            |_|       |_|'
echo
echo
cat $tmpfile
rm -f $tmpfile

# EOF
