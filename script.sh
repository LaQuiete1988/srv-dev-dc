function app_installation(){
  docker exec php_dev_1 git clone https://$GIT_USERNAME:$GIT_TOKEN@github.com/VladimirDronik/adm.git -b $ADM_VERSION
  docker cp ./php-fpm/apps/. php_dev_1:/var/www/adm/
#   docker exec php_dev_1 sed -i \
# -e 's/DB_DATABASE=.*/DB_DATABASE=\${MYSQL_DATABASE}/g' \
# -e 's/DB_USERNAME=.*/DB_USERNAME=\${MYSQL_USER}/g' \
# -e 's/DB_PASSWORD=.*/DB_PASSWORD=\${MYSQL_PASSWORD}/g' \
# adm/.env
  docker exec php_dev_1 php adm/artisan key:generate
  docker exec php_dev_1 chown -R www-data:www-data adm
  docker exec php_dev_1 find /var/www/adm -type f -exec chmod 644 {} \+
  docker exec php_dev_1 find /var/www/adm -type d -exec chmod 755 {} \+
  docker exec php_dev_1 chmod -R ug+rwx /var/www/adm/storage /var/www/adm/bootstrap/cache
  # docker exec php_dev_1 ln -s /var/www/server/userscripts /var/www/adm/storage/app/scripts
  # docker exec php_dev_1 chown -R www-data:www-data /var/www/server/userscripts
  # docker exec php_dev_1 chmod -R 770 /var/www/server/userscripts
  docker exec -it php_dev_1 php adm/artisan migrate --seed --force
  
  # docker exec -it php_dev_1 php adm/artisan create:user
  
}

export $(grep -v '^#' .env | xargs)
app_installation