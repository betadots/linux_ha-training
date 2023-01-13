# Nginx

Starten des Load-Balancers

    vagrant up lb1.betadots.training
    vagrant ssh lb1.betadots.training
    sudo -i
    apt update; apt install -y nginx

Config

    # /etc/nginx/site-enabled/default
    upstream backend {
        server 172.16.120.13;
        server 172.16.120.14;
    }
    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }

Weiter geht es mit [Keepalived](../06_Keepalived)
