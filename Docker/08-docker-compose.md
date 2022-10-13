version: "3.6"
services:
  php-app:
    image: php:apache
    container_name: app
    ports:
      - '80:80'
    restart: unless-stopped
    depends_on:
      - app-db
      - app-redis
    networks:
      - internet
      - localnet

  app-db:
    image: postgres
    container_name: app-postres
    restart: unless-stopped
    environment:
      - 'POSTGRES_PASSWORD=mysecretpassword'
    networks:
      - localnet

  app-redis:
    image: redis
    container_name: app-redis
    restart: unless-stopped
    networks:
      - localnet

networks:
  internet:
    name: internet
    driver: bridge
  localnet:
    name: localnet
    driver: bridge

############ Flame + Heimdall ##########
version: "3.6"
services:
  flame:
    image: pawelmalak/flame
    container_name: flame
    ports:
      - '5005:5005'
    volumes:
      - '/opt/flame/data:/app/data'
    environment:
      - 'PASSWORD=flame_password'
    restart: unless-stopped

  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    container_name: heimdall
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - /opt/heimdall/config:/config
    ports:
      - 80:80
      - 443:443
    restart: unless-stopped



############ Nextcloud ##########
version: '3.5'
services:
  db:
    image: mariadb:10.5
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=mypasS123root
      - MYSQL_PASSWORD=mypasS123
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  app:
    image: nextcloud
    restart: always
    ports:
      - 8080:80
#    links:
#      - db
    volumes:
      - nextcloud:/var/www/html
    environment:
      - MYSQL_PASSWORD=mypasS123
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db
    depends_on:
      - db
volumes:
  nextcloud:
  db:

############ Wordpress ##########
version: '3.5'
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: rootPassDB
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db: