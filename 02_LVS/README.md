# Linux Virtual Server

## Begriffe

### Linux Virtual Server

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
Im Training werden wir NAT/Full-NAT nutzen, da dies die einfachste Methode ist und mit minimalen Änderungen an den Real-Servern auskommt.

|Modus       | Anpassungen Real Server? | Umfang der Anpassungen          |
|------------|--------------------------|---------------------------------|
|NAT/Full-Nat| nur bei NAT              | Setzen des Virtual Server als Default Gateway|
|TUN         | ja                       | Deaktivierung ARP Replies, Aktivierung IP-Tunneling|
|Direct Routing| ja                     | Deaktivierung von ARP-Replies, zusätzliches Interface nötig |
