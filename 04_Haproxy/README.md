# HAproxy

```shell
vagrant up lb1.betadots.training app1.betadots.training app2.betadots.training
vagrant ssh lb1.betadots.training
sudo -i
```

Netzwerk Konfigurieren

lb1:

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

App1:

```shell
vagrant ssh app1.betadots.training
sudo -i
```

```shell
# hinzufügen zu /etc/network/interfaces
auto eth2
iface eth2 inet static
    address 172.16.120.13
    netmask 255.255.255.0
    network 172.16.120.0
```

```shell
ifup eth2
```

Webserver installieren

```shell
apt install -y apache2
```

App2:

```shell
vagrant ssh app2.betadots.training
sudo -i
```

```shell
# hinzufügen zu /etc/network/interfaces
auto eth2
iface eth2 inet static
    address 172.16.120.14
    netmask 255.255.255.0
    network 172.16.120.0
```

```shell
ifup eth2
```

Webserver installieren

```shell
apt install -y nginx
```

Load-Balancer Anwendung

lb1:

```shell
apt install -y haproxy
```

Konfiguration

```text
# /etc/haproxy/haproxy.cfg
# am Ende einfügen:

frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
    # option http-use-htx
    http-request use-service prometheus-exporter if { path /metrics }

frontend app
    bind *:80
    default_backend static

backend static
    balance roundrobin
    option httpchk HEAD /
    server srv1 172.16.120.13:80 check
    server srv2 172.16.120.14:80 check
```

Neustart HAproxy

```shell
systemctl restart haproxy
```

Vom Laptop:

```shell
watch --interval 1 'curl http://10.100.10.11'
```

Web Interface:

`http://10.100.10.11:8404/stats`

Stoppen eines Webservers. Was sehen wir?

TODO: API, Peers

Für die nächste Übung muss der Load Balancer neu eingerichtet werden:

```shell
vagrant destroy -f lb1.betadots.training
```

Weiter geht es mit [Nginx](../05_Nginx)

License: CC BY-NC-SA 4.0
