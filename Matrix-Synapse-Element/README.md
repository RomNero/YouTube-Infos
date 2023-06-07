### Install Packages:

* Docker: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
* Apache: apt install apache2
* a2enmod proxy rewrite ssl headers proxy_http

### Let'sEncrypt:

apt install certbot

### Generate Matrix Config:

```
docker run -it --rm \
    -v "/opt/matrix/synapse:/data" \
    -e SYNAPSE_SERVER_NAME=matrix.DOMAIN.COM \
    -e SYNAPSE_REPORT_STATS=no \
    matrixdotorg/synapse:latest generate
```    
    
#### Change Matrix configuration. postgres database:

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

### Docker Compose
```
version: '3.8'

services:
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

```
vi /etc/apache2/ports.conf
<IfModule ssl_module>
        Listen 8448
</IfModule>
```

#### VirtualHost:

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

##### Test Sites:

[https://matrix.youDOMAIN.COM/_matrix/static/] [1]

[https://federationtester.matrix.org] [2]


### Create Admin-User:

docker exec -it matrix_synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml



## ELEMENT WEB

### Element Configuration:

vi element-config.json

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
