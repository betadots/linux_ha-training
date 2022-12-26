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
Kann auch als Daemon laufen, um mehrere LVS Instanzen in einem CLusterverbund zu betreiben.

## Betriebsarten

LVS kann in 3 unterschiedlichen Betriebsarten genutzt werden.

1. Virtual Server mit NAT (VS/NAT)
1. Virtual Serve rmit Tunneling (VS/TUN)
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

## Einrichtung

Login lb1

    vagrant ssh lb1.betadots.training
    sudo -i

### NAT

#### Einrichten des NAT

    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    echo 'net.ipv4.vs.conntrack = 1' | tee -a /etc/sysctl.conf
    sysctl -p

Überprüfen

    sysctl net.ipv4.ip_forward
    sysctl net.ipv4.vs.conntrack

#### Einrichten des Masquerading

    iptables -t nat -A POSTROUTING -m ipvs --vaddr 10.100.10.11 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 172.16.120.0/24 -j MASQUERADE

#### Installation

Debian `apt install -y ipvsadm`
Almalinux `dnf install -y ipvsdam`

#### Config file anlegen (nur Almalinux)

    touch /etc/sysconfig/ipvsadm
    systemctl enable --now ipvsadm
    systemctl status ipvsadm

#### ipvsadm

`ipvsadm` ist ein Kommando:

    ipvsadm --help
    ipvsadm v1.31 2019/12/24 (compiled with popt and IPVS v1.2.1)
    Usage:
      ipvsadm -A|E virtual-service [-s scheduler] [-p [timeout]] [-M netmask] [--pe persistence_engine] [-b sched-flags]
      ipvsadm -D virtual-service
      ipvsadm -C
      ipvsadm -R
      ipvsadm -S [-n]
      ....

Einrichten des Load-Balancers:

    ipvsadm -A -t 10.100.10.11:80 -s rr
    ipvsadm -a -t 10.100.10.11:80 -r 172.16.120.15:80 -m
    ipvsadm -a -t 10.100.10.11:80 -r 172.16.120.16:80 -m

Einsehen der Konfiguration:

    ipvsadm -L
    IP Virtual Server version 1.2.1 (size=4096)
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
    TCP  lb1.betadots.training:ht rr
      -> web1.betadots.training:ht Masq    1      0          0
      -> web2.betadots.training:ht Masq    1      0          0

Auf web1: `apt update; apt install -y apache2; systemctl start apache2`
Auf web2: `apt update; apt install -y nginx; systemctl start nginx`

Jetzt kann auf den Webservice zugegriffen werden:

    curl http://10.100.10.11

Für den nächsten Punkt muss die LB VM neu instantiiert werden:

    vagrant destroy -f lb1.betadots.training
    vagrant up lb1.betadots.training
    vagrant ssh lb1.betadots.training
    sudo -i

### Direct Routing

#### Loadbalancer

Installation: `apt update; apt install -y ipvsadm`

Einrichten des Load-Balancers:

    ipvsadm -A -t 10.100.10.11:80 -s rr
    ipvsadm -a -t 10.100.10.11:80 -r 10.100.10.15:80 -g
    ipvsadm -a -t 10.100.10.11:80 -r 10.100.10.16:80 -g

Einsehen der Konfiguration:

    ipvsadm -L

#### Webserver

Auf web1

Lösung 1: iptables um Anfragen gegen VIP anzunehmen:

    iptables -t nat -A PREROUTING -p tcp -d 10.100.10.11 --dport 80 -j REDIRECT

Lösung 2: arptables und VIP (WIP)

    apt update
    apt install -y arptables
    arptables -A IN -d 10.100.10.11 -j DROP
    arptables -A OUT -s 10.100.10.11 -j mangle --mangle-ip-s 10.100.10.15

    ip addr add 10.100.10.11 dev lo label lo:0

Auf web2

Installation Webserver `apt update; apt install -y nginx; systemctl start nginx`

Lösung 1: iptables um Anfragen gegen VIP anzunehmen:

    iptables -t nat -A PREROUTING -p tcp -d 10.100.10.11 --dport 80 -j REDIRECT

Lösung 2: arptables und VIP (WIP)

    apt update
    apt install -y arptables
    arptables -A INPUT -d 10.100.10.11 -j DROP
    arptables -A OUTPUT -s 10.100.10.11 -j mangle --mangle-ip-s 10.100.10.16

    ip addr add 10.100.10.11/32 dev lo label lo:0

Fehleranalyse

    tcpdump  -ni eth2 port 80

Jetzt kann auf den Webservice zugegriffen werden:

    curl http://10.100.10.11

Für den nächsten Punkt müssen alle VMs neu instantiiert werden:

    vagrant destroy -f

Weiter geht es mit [HAproxy](../03_HAproxy)
