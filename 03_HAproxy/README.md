# HAproxy

Load-Balancer Anwendung

    apt update; apt install -y haproxy

Konfiguration

    # /etc/haproxy/haproxy.conf
    # am Ende einfügen:

    frontend stats
        bind *:8404
        stats enable
        stats uri /stats
        stats refresh 10s
        stats admin if TRUE
    
    frontend app
     bind *:80
     default_backend static

    backend static
     server srv1 172.16.120.11:80 check
     server srv2 172.16.120.12:80 check

Weiter geht es mit [Nginx](../04_Nginx)
