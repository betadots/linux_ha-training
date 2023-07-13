# HAproxy

```shell
vagrant up lb1.betadots.training app1.betadots.training app2.betadots.training
vagrant ssh lb1.betadots.training
sudo -i
```

Load-Balancer Anwendung

```shell
apt update; apt install -y haproxy
```

Konfiguration

```text
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
    balance roundrobin
    option httpchk HEAD /
    server srv1 172.16.120.13:80 check
    server srv2 172.16.120.14:80 check
```

TODO: API

Stoppen des load balancers: `vagrant destroy -f lb1.betadots.training`

Weiter geht es mit [Nginx](../05_Nginx)

License: CC BY-NC-SA 4.0
