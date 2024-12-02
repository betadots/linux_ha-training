# Linux Virtual Server

## Begriffe

### Virtual Server

Die Summe aller Server, die in einem Verbund arbeiten.
Hier geht es um Lastverteilung.

Ein Virtual Server hat einen oder mehrere Sockets oder `Virtual IPs` (IP + Port), die auf Anfragen anderer Systeme reagieren.

Die Anfragen werden durch einen `Real Server` beantwortet.

### Real Server

Ein System, welches einen oder mehrere Dienste hat, welche Anfragen beantworten.

### Virtual IP

Die virtuelle IP auf dem Virtual Server, über die die Real Server erreichbar sind.

### ipvsadm

Linux Tool zum Management von LVS (Aktivierung, Verwaltung und Überwachung).
Kann auch als Daemon laufen, um mehrere LVS Instanzen in einem Clusterverbund zu betreiben.

## Betriebsarten

LVS kann in 3 unterschiedlichen Betriebsarten genutzt werden.

1. Virtual Server mit NAT (VS/NAT)
1. Virtual Server mit Tunneling (VS/TUN)
1. Virtual Server mit Direct Routing (VS/DR)

Im Training werden wir NAT und DR nutzen, da dies die einfachste Methode ist und mit minimalen Änderungen an den Real-Servern auskommt.

|Modus          | VS/NAT        | VS/TUN     | VS/DR         |
|---------------|---------------|------------|---------------|
|server         | any           | tunneling  | no ARP device |
|server network | private       | LAN/WAN    | LAN           |
|server number  | low (10-20)   | high       | high          |
|server gateway | load balancer | own router | own router    |

### Network Address Translation

NAT hat Limitierungen in Hinsicht aus die Skalierung, da der gesamte Traffik über den Load-Balancer geht.

Lösung: DNS hybrid.

Dazu werden mehrere Load-Balancer mit jeweils einem dedizierten Pool von Real Servern aufgebaut. Die Verteilung der Anfragen an die Load-Balancer geht dann über DNS Round-Robin.

### Tunneling

Beim Tunneling nimmt der Load-Balancer die Anfrage entgegen, die Antwort wird direkt vom Real-Server an den Client gesendet.

Bedingung: **alle** Server (Linux Virtual Server und Real Servers) müssen IP Tunneling oder IP Encapsulation aktiviert haben.

### Direct Routing

Der Load-Balancer nimmt die Anfragen entgegen und sendet diese an die Real-Server. Die Antworten können von den Real-Servern gesendet werden.

Hier hat man keinen Tunneling Overhead, aber alle Systeme müssen im gleichen physikalischem Segment stehen.

---

## Einrichtung

Hochfahren der VMs:

```shell
vagrant up lb1.betadots.training app1.betadots.training app2.betadots.training
```

Login lb1

```shell
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
ifup eth1 eth2
```

Login app1

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

Login app2

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

### NAT

#### Einrichten des NAT

lb1:

```shell
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv4.vs.conntrack = 1' | tee -a /etc/sysctl.conf
sysctl -p
```

Fehlermeldung wegen conntrack:

Überprüfen

```shell
sysctl net.ipv4.ip_forward
sysctl net.ipv4.vs.conntrack
```

#### Einrichten des Masquerading

lb1:

```shell
iptables -t nat -A POSTROUTING -m ipvs --vaddr 10.100.10.11 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.16.120.0/24 -j MASQUERADE
```

Jetzt ist das conntrack module geladen: `sysctl -p`

#### Installation

lb1:

- Debian: `apt update; apt install -y ipvsadm`
- AlmaLinux: `dnf install -y ipvsdam`

#### Config file anlegen (nur Almalinux)

```shell
# Nur RedHat Systeme: touch /etc/sysconfig/ipvsadm
systemctl enable --now ipvsadm
systemctl status ipvsadm
```

#### Nutzung von ipvsadm

`ipvsadm` ist ein Kommando:

```shell
ipvsadm --help
ipvsadm v1.31 2019/12/24 (compiled with popt and IPVS v1.2.1)
Usage:
  ipvsadm -A|E virtual-service [-s scheduler] [-p [timeout]] [-M netmask] [--pe persistence_engine] [-b sched-flags]
  ipvsadm -D virtual-service
  ipvsadm -C
  ipvsadm -R
  ipvsadm -S [-n]
  ....
```

---

Einrichten des Load-Balancers:

```shell
ipvsadm -A -t 10.100.10.11:80 -s rr
ipvsadm -a -t 10.100.10.11:80 -r 172.16.120.13:80 -m
ipvsadm -a -t 10.100.10.11:80 -r 172.16.120.14:80 -m
```

Einsehen der Konfiguration:

```shell
ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  lb1.betadots.training:ht rr
  -> app1.betadots.training:ht Masq    1      0          0
  -> app2.betadots.training:ht Masq    1      0          0
```

Installation Webserver

App1:

```shell
vagrant ssh app1.betadots.training
sudo -i
apt install -y apache2
systemctl start apache2
```

App2:

```shell
vagrant ssh app2.betadots.training
sudo -i
apt install -y nginx
systemctl start nginx
```

Jetzt kann auf den Webservice zugegriffen werden:

```shell
watch --interval 1 'curl http://10.100.10.11'
```

Für den nächsten Punkt muss die LB VM neu instantiiert werden:

```shell
vagrant destroy -f lb1.betadots.training
vagrant up lb1.betadots.training
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
ifup eth1 eth2
```

### Direct Routing

#### Loadbalancer

Installation: `apt install -y ipvsadm`

Einrichten des Load-Balancers:

```shell
ipvsadm -A -t 10.100.10.11:80 -s rr
ipvsadm -a -t 10.100.10.11:80 -r 10.100.10.13:80 -g
ipvsadm -a -t 10.100.10.11:80 -r 10.100.10.14:80 -g
```

Einsehen der Konfiguration:

```shell
ipvsadm -L
```

#### Webserver

Auf app1:

Netzwerk konfigurieren

```shell
# zu /etc/network/interfaces hinzufügen
auto eth1
iface eth1 inet static
    address 10.100.10.13
    netmask 255.255.255.0
    network 10.100.10.0
```

```shell
ifup eth1
```

iptables um Anfragen gegen VIP anzunehmen:

```shell
iptables -t nat -A PREROUTING -p tcp -d 10.100.10.11 --dport 80 -j REDIRECT
```

Auf app2:

Netzwerk konfigurieren

```shell
# zu /etc/network/interfaces hinzufügen
auto eth1
iface eth1 inet static
    address 10.100.10.14
    netmask 255.255.255.0
    network 10.100.10.0
```

```shell
ifup eth1
```

iptables um Anfragen gegen VIP anzunehmen:

```shell
iptables -t nat -A PREROUTING -p tcp -d 10.100.10.11 --dport 80 -j REDIRECT
```

Fehleranalyse

```shell
# apt install -y tcpdump schon installiert
tcpdump  -ni eth2 port 80
```

Jetzt kann auf den Webservice zugegriffen werden:

Workstation!!!

```shell
curl http://10.100.10.11
```

Deaktivieren eines Webservers. Was sehen wir?

ipvsadm flushen: `ipvsadm --clear`

Lösung: ldirectord

lb1:

```shell
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv4.vs.conntrack = 1' | tee -a /etc/sysctl.conf
sysctl -p
```

Fehlermeldung wegen conntrack:

Überprüfen

```shell
sysctl net.ipv4.ip_forward
sysctl net.ipv4.vs.conntrack
```

#### Einrichten des Masquerading

```shell
iptables -t nat -A POSTROUTING -m ipvs --vaddr 10.100.10.11 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.16.120.0/24 -j MASQUERADE
```

```shell
apt install -y ldirectord
```

Die Konfiguratoin muss in `/etc/ha.d` hinterlegt werden.

```shell
mkdir -p /etc/ha.d
cp /usr/share/doc/ldirectord/examples/ldirectord.cf /etc/ha.d/ldirectord.cf
```

Konfiguration anpassen

```text
# Sample for an http virtual service
virtual=10.100.10.11:80
    servicename=Web Site
    comment=Test load balanced web site
    real=172.16.120.13:80 masq
    real=172.16.120.14:80 masq
    #fallback=127.0.0.1:80 gate
    service=http
    scheduler=rr
    #persistent=600
    #netmask=255.255.255.255
    protocol=tcp
    checktype=negotiate
    checkport=80
    request="/"
    #receive="install"
    #virtualhost=www.x.y.z
```

Service starten: `systemctl start ldirectord`

Web Server stoppen, `ipvsadm -L`

Aktivieren maintenance:

```text
# /etc/ha.d/conf/ldirectord.cf
# main section !!!
maintenancedir=/etc/ha.d/web/
```

Node deaktivieren:

```shell
mkdir /etc/ha.d/web
touch /etc/ha.d/web/172.16.120.13:80
ipvsadm -L
```

Für den nächsten Punkt müssen alle VMs neu instantiiert werden:

```shell
vagrant destroy -f
```

Weiter geht es mit [HAproxy](../04_Haproxy)

License: CC BY-NC-SA 4.0
