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

### ldirector

Analyse der Real Server auf Verfügbarkeit.

## Betriebsarten

LVS kann in 3 unterschiedlichen Betriebsarten genutzt werden.

1. Virtual Server mit NAT (VS/NAT)
1. Virtual Serve rmit Tunneling (VS/TUN)
1. Virtual Server mit Direct Routing (VS/DR)

Im Training werden wir NAT nutzen, da dies die einfachste Methode ist und mit minimalen Änderungen an den Real-Servern auskommt.

|Modus          | VS/NAT        | VS/TUN     | VS/DR         |
|---------------|---------------|------------|---------------|
|server         | any           | tunneling  | no ARP device |
|server network | private       | LAN/WAN    | LAN           |
|server number  | low (10-20)   | high       | high          |
|server gateway | load balancer | own router | own router    |

### NAT

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

Hinweis: wir machen NAT.

Weiter geht es mit [HAproxy](../03_HAproxy)
