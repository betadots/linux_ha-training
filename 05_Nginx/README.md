# Nginx

Starten des Load-Balancers

```shell
vagrant up lb1.betadots.training
vagrant ssh lb1.betadots.training
sudo -i
apt install -y nginx
```

Config

Netzwerk

```shell
# hinzufügen zu /etc/network/interfaces
auto eth1
iface eth1 inet static
    address 10.100.10.11
    netmask 255.255.255.0
    network 10.100.10.0

auto eth2
iface eth2 inet static
    address 172.16.120.11
    netmask 255.255.255.0
    network 172.16.120.0
```

```shell
ifup eth1
ifup eth2
```

Nginx

```shell
# /etc/nginx/sites-enabled/default
# alles andere rauslöschen
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
```

```shell
systemctl restart nginx
```

Ein Backend Stoppen. Was passiert?

In der nächsten Übung soll der Load Balancer Hochverfügbar gemacht werden.
Der existierende LB1 bleibt bestehen!

Weiter geht es mit [Keepalived](../06_Keepalived)

License: CC BY-NC-SA 4.0
