#!/usr/bin/env bash

RED='\033[0;31m'
NC='\033[0m'

function adm_upd {
  current_branch=$(docker exec php_dev_$1 /bin/sh -c "cd adm && git symbolic-ref HEAD | \
    sed 's/refs\/heads\///' && cd ..")
  if [ $current_branch = $2 ]; then
    docker exec php_dev_$1 /bin/sh -c "cd adm && git pull origin $2 && php artisan migrate --seed --force && cd .."
  else
    docker exec php_dev_$1 /bin/sh -c "rm -r adm \
      && git clone https://$GIT_USERNAME:$GIT_TOKEN@github.com/VladimirDronik/adm.git -b $2"
    docker cp ./php-fpm/apps/. php_dev_$1:/var/www/adm/
    docker exec php_dev_$1 /bin/sh -c "php adm/artisan key:generate \
      && chown -R www-data:www-data /var/www/adm/storage /var/www/adm/bootstrap/cache \
      && find /var/www/adm -type f -exec chmod 644 {} \+ \
      && find /var/www/adm -type d -exec chmod 755 {} \+ \
      && chmod -R ug+rwx /var/www/adm/storage /var/www/adm/bootstrap/cache \
      && rm /var/www/adm/storage/app/alice_init.php \
      && rm -r /var/www/adm/storage/app/server \
      && rm -r /var/www/adm/storage/app/scripts \
      && ln -s /var/www/server/userscripts /var/www/adm/storage/app/scripts"
    docker exec mysql_dev_$1 mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "DROP DATABASE $MYSQL_DATABASE"
    docker exec mysql_dev_$1 mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "CREATE DATABASE $MYSQL_DATABASE \
      CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    docker exec -it php_dev_$1 php adm/artisan migrate --seed --force
    docker exec mysql_dev_$1 mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "INSERT INTO smarthome.users (login, password) \
      VALUES ('superadmin', '\$2y\$10\$91Yik94WZGKPycXmr0QaHOj03mdU/wBGxGeArN09F.OoHIRHGfz7O'), \
      ('admin', '\$2y\$10\$91Yik94WZGKPycXmr0QaHOj03mdU/wBGxGeArN09F.OoHIRHGfz7O'), \
      ('user', '\$2y\$10\$91Yik94WZGKPycXmr0QaHOj03mdU/wBGxGeArN09F.OoHIRHGfz7O')"
  fi
}

function core_files_change {
    docker exec php_dev_$1 sed -i \
            -e 's/localhost/mysql_dev_$1/' \
            -e 's/127.0.0.1/php_dev_$1/' \
            -e "s/\$dbname =.*/\$dbname = getenv(\'MYSQL_DATABASE\');/g" \
            -e "s/\$dbuser =.*/\$dbuser = getenv(\'MYSQL_USER\');/g" \
            -e "s/\$dbpass =.*/\$dbpass = getenv(\'MYSQL_PASSWORD\');/g" \
            server/include.php
        docker exec php_dev_$1 sed -i 's/127.0.0.1/php_dev_1/' server/server.php
        docker exec php_dev_$1 sed -i 's/php -f thread.php/cd \".ROOT_DIR.\" \&\& php -f thread.php/' \
            server/classes/SendSocket.php
}

function core_upd {

    if [[ $(docker exec php_dev_$1 ls | grep -x server) ]]; then
      
      current_branch=$(docker exec php_dev_$1 /bin/sh -c "cd server && git symbolic-ref HEAD | \
        sed 's/refs\/heads\///' && cd ..")
      
      if [ $current_branch = $2 ]; then
        docker exec php_dev_$1 /bin/sh -c "cd server && git pull origin $2 && cd .."
        core_files_change $1
      else
        docker exec php_dev_$1 /bin/sh -c "rm -r server \
            && git clone https://$GIT_USERNAME:$GIT_TOKEN@github.com/VladimirDronik/server.git -b $2"
        core_files_change $1
      fi

    else 
      docker exec php_dev_$1 git clone https://$GIT_USERNAME:$GIT_TOKEN@github.com/VladimirDronik/server.git -b $2
      core_files_change $1
    fi

    
}

export $(grep -v '^#' .env | xargs)

# $1 - server number (2 or 3 for dev2 or dev3)
# $2 - adm or core
# $3 - branch name

if [[ $1 != 2 && $1 != 3 ]]; then
  echo -e "${RED}[ERROR]${NC} First parameter can be just 2 or 3 (for dev2 or dev3)."
else 
  if [ "$2" = "core" ]; then
    core_upd $1 $3
    # echo $1
    # echo $2
    # echo $3
  elif [ "$2" = "adm" ]; then
    adm_upd $1 $3
    # echo $1
    # echo $2
    # echo $3
  elif [[ "${2:-unset}" == "unset" ]]; then
    echo -e "${RED}[ERROR]${NC} Second parameter not found."
  else
    echo -e "${RED}[ERROR]${NC} Wrong parameter: $2."
  fi
fi