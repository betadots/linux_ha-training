# Keepalived

Keppalived kombiniert Load-Balancing und HA.

Als Loadbalancing backend kommt LVS zum Einsatz. Man kann keepalived als einen director für LVS ansehen und funktioniert analog zu ldirectord.

Das HA Konzept wird mit VRRP (Virtual Router Redundancy Protocol) realisiert.
Das Konzept von VRRP besteht aus einer virtuellen IP/MAC, welche zwischen Systemen in einem VRRP Verbund wechseln kann.
Wenn das aktive System ausfällt, wir die IP/MAC auf einem anderen Host-Standby System hochgefahren.

VRRP verwendet Broadcast. Zusammengehörende Router werden über eine VRID (Virtual Router ID) konfiguriert.
Als virtuelle MAC wird eine Multicast-Adresse aus dem Bereich 00:00:5E:00:01:01 bis 00:00:5E:00:01:FF benutzt, die letzte 8 bit sind dabei die VRID.

VRRP ist ein eigener IP Protokolltyp mit der Nummer 112. Sofern Version 2 mit MD5 Authentication benutzt wird, wird abweichend allerdings Protokollnummer 51 (Authentication Header) verwendet.

VRRP2 hat Authentifizierung.
VRRP3 hat IPv6 support, aber die Authentifizierung wurde wieder entfernt.

Keepalived nutzt VRRP2.

Kernel Komponenten:

- LVS Framework (getsockopts und setsockopts)
- Netfilter Framework (IPVS für NAT und Masquerading)
- Netlink Interface (VRRP)
- Multicast (VRRP Advertisements)

Elemente:

- Control Plane
- Scheduler
- Memory Management
- Core Components
- Checkers
- VRRP Stack
- System Call
- Netlink Reflector
- SMTP
- IPVS Wrapper
- IPVS
- Netlink
- Syslog

Healthcheck Framework

- TCP_CHECK
- HTTP_GET
- SSL_GET
- MISC_CHECK

Failover (VRRP) Framework

Bei ARP Problemen:

```shell
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 1
net.ipv4.conf.all.arp_filter = 0
net.ipv4.conf.eth0.arp_filter = 1 (eth0 ist das Interface der VRRP Instanz)
```

VMAC Interface

VRRP Konfiguration

```shell
# /etc/keepalived/keepalived.conf
vrrp_instance instance1 {
    state BACKUP
    interface eth0
    virtual_router_id 250
    use_vmac
        vmac_xmit_base         # Transmit VRRP adverts over physical interface
    priority 150
    advert_int 1
    virtual_ipaddress {
        10.100.10.254
    }
}
```

Durch die Anweisung `use_vmac` wird ein macvlan Interface mit dem Namen vrrp.<virtual_router_id> erzeugt. Hier also: vrrp.250
Alternativ kann man den Namen des Interfaces explizit setzen:

```shell
use_vmac vrrp.400
```

Dann muss das Interface konfiguriert werden:

```shell
net.ipv4.conf.vrrp.250.arp_filter = 0
net.ipv4.conf.vrrp.250.accept_local = 1 (this is needed for the address owner case)
net.ipv4.conf.vrrp.250.rp_filter = 0
```

Diese Konfiguration muss auch bei einem Wechsel des Interfaces vorgenommen werden.
Mit der Anweisung `notify_master` kann man dies automatisieren:

```shell
vrrp_instance instance1 {
    state BACKUP
    interface eth0
    virtual_router_id 250
    use_vmac
    priority 150
    advert_int 1
    virtual_ipaddress {
        10.100.10.254
    }
    notify_master "/usr/local/bin/vmac_tweak.sh vrrp.250"
}
```

Das Loadbalancing folgt den Möglichkeiten von LVS.

## Lab

Starten des 2ten Load-Balancer

```shell
vagrant up lb2.betadots.training
vagrant ssh lb2.betadots.training
sudo -i
apt install -y nginx
```

Netzwerk

```shell
# hinzufügen zu /etc/network/interfaces
auto eth1
iface eth1 inet static
    address 10.100.10.12
    netmask 255.255.255.0
    network 10.100.10.0

auto eth2
iface eth2 inet static
    address 172.16.120.12
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

Beide LB: Installation von keepalived

```shell
apt install -y keepalived
```

Keepalived kennt die folgenden Konfigurationen:

- global_defs
- virtual_server
- real_server
- vrrp_sync_group
- vrrp_instance

Siehe auch: <https://keepalived.readthedocs.io/en/latest/configuration_synopsis.html>

Beispiele liegen in `/usr/share/doc/keepalived/samples`

Kommando Optionen

```text
-f, --use-file=<config file>
-P, --vrrp # Nur VRRP, ohne LVS
-C, --check # Config check
-V, --dont-release-vrrp # VRRP config beim stoppen bestehen lassen
-I, --dont-release-ipvs # LVS config beim stoppen bestehen lassen
-d, --dump-conf # Config anzeigen
-x, --snmp # SNP aktivieren
```

Keepalived startet erst, wenn eine Config vorhanden ist

```text
! Configuration File for keepalived

global_defs {
   notification_email {
     root@localhost.localdomain
   }
   notification_email_from lb1@localhost.localdomain
   smtp_server localhost
   smtp_connect_timeout 30
}

vrrp_instance VI_1 {
    state MASTER
    interface eth1
    virtual_router_id 101
    priority 101
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.100.10.21
    }
}
```

```shell
systemctl start keepalived
```

Virtual IP: `ip a`

```text
# /etc/keepalived/keepalived.conf
virtual_server 172.16.120.21 80 {
    delay_loop 6
    lb_algo rr
    lb_kind NAT
    persistence_timeout 50
    protocol TCP

    real_server 172.16.120.13 80 {
        weight 1
        HTTP_GET {
            url {
              path /
            }
            connect_timeout 3
            retry 3
            delay_before_retry 3
        }
    }
    real_server 172.16.120.14 80 {
        weight 1
        HTTP_GET {
            url {
              path /
            }
            connect_timeout 3
            retry 3
            delay_before_retry 3
        }
    }
}
```

```shell
systemctl start keepalived
```

Alle VM Instanzen beenden: `vagrant destroy -f`

Weiter geht es mit [Clusterlabs - Pacemaker/Corosync](../07_Clusterlabs)

License: CC BY-NC-SA 4.0
