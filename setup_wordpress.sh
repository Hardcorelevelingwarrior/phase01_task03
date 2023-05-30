#!/bin/bash
# Please do not remove this line. This command tells bash to stop executing on first error. 
set -e
# Your code goes below ...
echo 'This script should install and setup Wordpress'

#Update the repository
sudo apt update
sudo apt upgrade -y

#Install nginx web server
echo "nginx install"
sudo dpkg --configure -a
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

#Install PHP7.4
echo "======================="
echo "Install php7.4"
echo "======================="
sudo apt install php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl -y
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm


#Install MariaDB database server
sudo apt install mariadb-server mariadb-client -y
sudo systemctl enable mariadb
sudo systemctl start mysql

echo "============================================"
echo "Create database & user for wordpress"
echo "============================================"
#variable database
user="wpuser"
pass="admin"
dbname="wordpress"
echo "create db name"
#mysql -e "CREATE DATABASE $dbname;"
echo "Creating new user..."
#mysql -e "CREATE USER '$user'@'%' IDENTIFIED BY '$pass';"
echo "User successfully created!"
echo "Granting ALL privileges on $dbname to $user!"
mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$user'@'%';"
mysql -e "FLUSH PRIVILEGES;"
echo "Success :)"

#Install Wordpress
echo "============================================"
echo "Install WordPress via Bash Script   "
echo "============================================"
#download wordpress
wget https://wordpress.org/latest.zip
apt install unzip
#unzip wordpress
sudo mkdir -p /usr/share/nginx
sudo unzip -o latest.zip -d /usr/share/nginx/  

#change dir to wordpress
echo "CD TO WORDPRESS"
cd /usr/share/nginx/wordpress

#create wp config
echo "START CONFIG"
sudo cp wp-config-sample.php wp-config.php
perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
perl -pi -e "s/username_here/$user/g" wp-config.php
perl -pi -e "s/password_here/$pass/g" wp-config.php
sudo chown www-data:www-data /usr/share/nginx/wordpress -R
#sudo rm /etc/nginx/sites-enabled/default


#create uploads folder and set permissions
echo "folder html"
touch /etc/nginx/conf.d/wordpress.conf
cat > /etc/nginx/conf.d/wordpress.conf <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name www.example.com example.com;
  root /usr/share/nginx/wordpress;
  index index.php index.html index.htm index.nginx-debian.html;

  location / {
    try_files \$uri \$uri/ /index.php;
  }

   location ~ ^/wp-json/ {
     rewrite ^/wp-json/(.*?)$ /?rest_route=/\$1 last;
   }

  location ~* /wp-sitemap.*\.xml {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
  }

  error_page 404 /404.html;
  error_page 500 502 503 504 /50x.html;

  client_max_body_size 20M;

  location = /50x.html {
    root /usr/share/nginx/html;
  }

  location ~ \.php$ {
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
    include snippets/fastcgi-php.conf;

    # Add headers to serve security related headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header X-Frame-Options "SAMEORIGIN";
  }

  #enable gzip compression
  gzip on;
  gzip_vary on;
  gzip_min_length 1000;
  gzip_comp_level 5;
  gzip_types application/json text/css application/x-javascript application/javascript image/svg+xml;
  gzip_proxied any;

  # A long browser cache lifetime can speed up repeat visits to your page
  location ~* \.(jpg|jpeg|gif|png|webp|svg|woff|woff2|ttf|css|js|ico|xml)$ {
       access_log        off;
       log_not_found     off;
       expires           360d;
  }

  # disable access to hidden files
  location ~ /\.ht {
      access_log off;
      log_not_found off;
      deny all;
  }

}
EOF

systemctl reload nginx 