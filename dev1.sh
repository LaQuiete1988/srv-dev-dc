#!/usr/bin/env bash

RED='\033[0;31m'
NC='\033[0m'

function adm_upd {
  docker exec php_dev_1 /bin/sh -c "cd adm && git pull origin develop && php artisan migrate --seed --force && cd .."
}

function core_upd {
  docker exec php_dev_1 /bin/sh -c "cd server && git pull origin develop && cd .."
  docker exec php_dev_1 sed -i \
    -e 's/localhost/mysql_dev_1/' \
    -e 's/127.0.0.1/php_dev_1/' \
    -e "s/\$dbname =.*/\$dbname = getenv(\'MYSQL_DATABASE\');/g" \
    -e "s/\$dbuser =.*/\$dbuser = getenv(\'MYSQL_USER\');/g" \
    -e "s/\$dbpass =.*/\$dbpass = getenv(\'MYSQL_PASSWORD\');/g" \
    server/include.php
  docker exec php_dev_1 sed -i 's/127.0.0.1/php_dev_1/' server/server.php
  docker exec php_dev_1 sed -i 's/php -f thread.php/cd \".ROOT_DIR.\" \&\& php -f thread.php/' \
    server/classes/SendSocket.php
}

export $(grep -v '^#' .env | xargs)

if [ "$1" = "core" ]; then
  core_upd
elif [ "$1" = "adm" ]; then
  adm_upd
elif [[ "${1:-unset}" == "unset" ]]; then
  echo -e "${RED}[ERROR]${NC} No parameter found."
else
  echo -e "${RED}[ERROR]${NC} Wrong parameter: $1."
fi