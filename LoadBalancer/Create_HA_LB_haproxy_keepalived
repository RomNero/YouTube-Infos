#######################
##  Install Web Server:
#######################
apt update
apt install apache2



#######################
##  Static Web Site:
#######################
vi /var/www/html/index.html

<!DOCTYPE html>
<html>
<head>
        <title>Webseite</title>
        <style>
                body {
                        background-color: #b85dff;
                }
                h1 {
                        text-align: center;
                        font-size: 3em;
                        color: white;
                        margin-top: 50px;
                }
                .text {
                        text-align: center;
                        font-size: 2em;
                        color: #03779F;
                        margin-top: 50px;
                }
        </style>
</head>
<body>
        <h1>Web01</h1>
        <div class="text">RomNero</div>
</body>
</html>


#################################
##  Install and config HAproxy
#################################
apt aptdate
apt install haproxy
systemctl enable haproxy

vi /etc/haproxy/haproxy.cfg

.......................
listen stats
        bind 0.0.0.0:8989
        mode http
        stats enable
        stats uri /haproxy_stats
        stats realm HAProxy\ Statistics
        stats auth admin:pass123
        stats admin if TRUE


frontend my-web
    bind 0.0.0.0:80
    default_backend my-web

backend my-web
    balance     roundrobin #static-rr  leastconn  first  source  uri  url_param  hdr  rdp-cookie
    server  web01 10.10.40.31:80 check
    server  web02 10.10.40.32:80 check


#################################
##  Install and config keepalived
#################################
apt install keepalived
systemctl enable keepalived

vi /etc/sysctl.conf
net.ipv4.ip_nonlocal_bind=1
#Save

sysctl -p

useradd -s /usr/bin/nologin keepalived_script

#Configuration:

vi /etc/keepalived/keepalived.conf

#### NODE01 #################
global_defs {
  router_id lb01
}

vrrp_script check_haproxy {
  script "/usr/bin/systemctl is-active --quiet haproxy"
  interval 2
  weight 2
}

vrrp_instance my-web {
    state MASTER
    interface ens18
    virtual_router_id 123
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass myPass12
    }
    virtual_ipaddress {
        10.10.40.35
    }
    track_script {
    check_haproxy
  }
}


#### NODE02 #################
global_defs {
  router_id lb01
}

vrrp_script check_haproxy {
#  script "/usr/bin/killall -0 haproxy"
  script "/usr/bin/systemctl is-active --quiet haproxy"
  interval 2
  weight 2
}

vrrp_instance my-web {
    state BACKUP
    interface ens18
    virtual_router_id 123
    priority 99
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass myPass12
    }
    virtual_ipaddress {
        10.10.40.35
    }
    track_script {
    check_haproxy
  }
}
