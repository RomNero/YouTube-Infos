сперва регистрируем домен у регистратора и прописываем dnc A записи указывающий на ip нашего vps
на нём устанавливаем lunux (debian/ubuntu/devuan)


### Install Packages:



* Docker: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
* Apache: apt install apache2
* a2enmod proxy rewrite ssl headers proxy_http

### Let'sEncrypt:

генерируем сертификаты для своего домена

apt install certbot

### Generate Matrix Config:

это нужно сделать чтобы создался каталог с файлом настроек /opt/matrix/synapse/homeserver.yaml
указываем свой домен

```
docker run -it --rm \
    -v "/opt/matrix/synapse:/data" \
    -e SYNAPSE_SERVER_NAME=matrix.DOMAIN.COM \
    -e SYNAPSE_REPORT_STATS=no \
    matrixdotorg/synapse:latest generate
```    
    
#### Change Matrix configuration (homeserver.yaml). postgres database:

меняем базу данных с sqlite на postgresql следующим образом

```
database:
  name: psycopg2
  args:
    user: synapse
    password: STRONGPASSWORD_123654
    database: synapse
    host: postgres
    cp_min: 5
    cp_max: 10
...
#Registration:
enable_registration: false
```

если регистрация пользователей из клиента не требуются то пропускайте эту настройку
не обязательно но можно включить регистрацию так, только с google captcha v2
#### Change Matrix configuration. registration, turnserver, recaptcha V2!!!:
```
#Registration:
recaptcha_public_key: "SECRETxxxxxxxxxxxxxxxxxxxxxxxxpubKEY"
recaptcha_private_key: "SECRETxxxxxxxxxxxxxxxxxxxxxxxxprivKEY"
  
enable_registration_captcha: true 

enable_registration: true
enable_registration_without_verification: false

enable_registration_email: true
email_from: 'noreply@example.com'

max_avatar_size: 3M
max_upload_size: 20M
encryption_enabled_by_default_for_room_type: all
allow_guest_access: false
encryption_enabled_by_default_for_room_type: all
allowed_avatar_mimetypes: ["image/png", "image/jpeg", "image/gif"]


#turn_uris: [ "turn:turn.matrix.org?transport=udp", "turn:turn.matrix.org?transport=tcp" ]
#turn_shared_secret: "fghfghXXXXXXXXXXXXXSECRETXXXXKEYXXXXXXXXXXXXXXXXXXXXXASDFSDd"
#turn_user_lifetime: 86400000
#turn_allow_guests: true


```


### Docker Compose (файл /opt/matrix/docker-compose.yml)
```
version: '3.8'

services:
  synapse-admin:
    container_name: synapse-admin
    hostname: synapse-admin
    image: awesometechnologies/synapse-admin:latest
    # context: https://github.com/Awesome-Technologies/synapse-admin.git
    ports:
      - "8080:80"
    restart: unless-stopped

  element:
    image: vectorim/element-web:latest
    container_name: matrix_element
    restart: unless-stopped
    volumes:
     - ./element-config.json:/app/config.json
    ports:
     - '127.0.0.1:8088:80'

  synapse:
    image: matrixdotorg/synapse:latest
    container_name: matrix_synapse
    restart: unless-stopped
    volumes:
     - ./synapse:/data
    ports:
     - '127.0.0.1:8008:8008'
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    container_name: matrix_postgres
    restart: unless-stopped
    volumes:
     - ./postgresdata:/var/lib/postgresql/data
    environment:
     - POSTGRES_DB=synapse
     - POSTGRES_USER=synapse
     - POSTGRES_PASSWORD=STRONGPASSWORD_123654
     - POSTGRES_INITDB_ARGS=--lc-collate C --lc-ctype C --encoding UTF8
 ```


### SSL Let'sEncrypt

certbot certonly

### Apache Configuration:

#### Add Ports:

добавляем порт 8448 федерации в настройки apache2  на хосте

```
vi /etc/apache2/ports.conf
<IfModule ssl_module>
        Listen 8448
</IfModule>
```

#### VirtualHost:

добавляем файл настроек /etc/apache2/sites-available/matrix.conf

```
<VirtualHost *:80>
    ServerName  matrix.youDOMAIN.COM
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>
<VirtualHost *:443>
    SSLEngine on
    ServerName matrix.youDOMAIN.COM

    SSLCertificateFile  /etc/letsencrypt/live/matrix.youDOMAIN.COM/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/matrix.youDOMAIN.COM/privkey.pem

    RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
    AllowEncodedSlashes NoDecode
    ProxyPreserveHost on
    ProxyPass /_matrix http://127.0.0.1:8008/_matrix nocanon
    ProxyPassReverse /_matrix http://127.0.0.1:8008/_matrix
    ProxyPass /_synapse/client http://127.0.0.1:8008/_synapse/client nocanon
    ProxyPassReverse /_synapse/client http://127.0.0.1:8008/_synapse/client

    #чтобы включить админ панель нужно добавить эти две строчки endpoint. чтобы выключить доступ к админке нужно их комментировать и перезапускать сервер.
    ProxyPass /_synapse/admin http://127.0.0.1:8008/_synapse/admin nocanon
    ProxyPassReverse /_synapse/admin http://127.0.0.1:8008/_synapse/admin
</VirtualHost>

<VirtualHost *:8448>
    SSLEngine on
    ServerName matrix.youDOMAIN.COM

    SSLCertificateFile  /etc/letsencrypt/live/matrix.youDOMAIN.COM/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/matrix.youDOMAIN.COM/privkey.pem


    RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
    AllowEncodedSlashes NoDecode
    ProxyPass /_matrix http://127.0.0.1:8008/_matrix nocanon
    ProxyPassReverse /_matrix http://127.0.0.1:8008/_matrix
</VirtualHost>
```


## ELEMENT WEB

### Element Configuration:

vi /opt/matrix/element-config.json

```
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://element.youDOMAIN.COM",
            "server_name": "element.youDOMAIN.COM"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "disable_custom_urls": false,
    "disable_guests": false,
    "disable_login_language_selector": false,
    "disable_3pid_login": false,
    "brand": "Element",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "bug_report_endpoint_url": "https://element.io/bugreports/submit",
    "uisi_autorageshake_app": "element-auto-uisi",
    "default_country_code": "GB",
    "show_labs_settings": false,
    "features": { },
    "default_federate": true,
    "default_theme": "light",
    "room_directory": {
        "servers": [
            "matrix.org"
        ]
    },
    "enable_presence_by_hs_url": {
        "https://matrix.org": false,
        "https://matrix-client.matrix.org": false
    },
    "setting_defaults": {
        "breadcrumbs": true
    },
    "jitsi": {
        "preferred_domain": "meet.element.io"
    },
    "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx"
}
```

### Apache Conf for Element:

/etc/apache2/sites-available/element.conf

```
<VirtualHost *:80>
    ServerName  element.youDOMAIN.COM
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>
<VirtualHost *:443>
    SSLEngine on
    ServerName element.youDOMAIN.COM

    Header set X-Frame-Options SAMEORIGIN
    Header set X-Content-Type-Options nosniff
    Header set X-XSS-Protection "1; mode=block"
    Header set Content-Security-Policy "frame-ancestors 'self'"

    SSLCertificateFile  /etc/letsencrypt/live/matrix.youDOMAIN.COM/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/matrix.youDOMAIN.COM/privkey.pem

    ProxyPreserveHost on
    ProxyPass / http://127.0.0.1:8088/
    ProxyPassReverse / http://127.0.0.1:8088/
</VirtualHost>
```



#### Apache2 применяем настройки вебсервера на хосте:

проверяем конфиг

```apache2ctl -t```

если Syntax OK применяем настройки

```a2ensite *```

перезагружаем сервер
```service apache2 restart```



### Create Admin-User:

Создание пользователя из консоли(создадим админа)

```docker exec -it matrix_synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml```

#### Test Sites:

проверку своего сервера можно сделать здесь, на этом сервисе
[https://federationtester.matrix.org]


#### рабочие Url

##### сервер
[https://matrix.youDOMAIN.COM/_matrix/static/]


##### админка 
работает на 8080 доступ только по http без s. 
рекомендуется выключать и включать по мере необходимости. 
в конфиге apache2 с последующим его перезапуском

доступ к админке(авторизуемся админом)
[HTTP://matrix.youDOMAIN.COM:8080/]


###### web клиент:
[https://element.youDOMAIN.COM/]

