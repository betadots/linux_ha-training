# Linux HA Schulung

Copyright betadots GmbH 2022

Einführung in Linux Hochverfügbarkeit

## Grundlagen und Konzepte

### Was ist HA?

Hochverfügbarkeit bedeutet, dass man Dienste ausfallsicher betreiben möchte.
Dabei stehen unterschiedliche Verfahren zur Verfügung.

1. Ausfallsicherheit
1. Lastverteilung

#### Ausfallsicherheit/Hardware

Sicherstellen, dass ein Hardwareausfall möglich ist

1. Netzwerk
1. Festplatten

Für den Ausfall einer Netzwerkkarte kommt Bonding zum Einsatz.
Für den Ausfall einer Festplatte wird RAID genutzt.

Bei RAID besteht die Möglichkeit das RAID in Hardware oder Software zu realisieren.
Für Hardware RAID wird ein RAID Controller benötigt, der üblicherweise im BIOS konfiguriert wird.
Unter Linux kann man RAID auch in Software abbilden (MD - Multiple Devices).

#### Ausfallsicherheit/Cluster

Bei einem Cluster hat man einen Verbund von Systemen, die sich gegenseitig überwachen. Hier gibt es entweder das Active-Passive- oder das Active-Active-Modell.

Bei einem Active-Passive Cluster soll bei einem Ausfall das aktiven Systems der Cluster selbständig die Dienste auf dem Passiven Node starten.
Damit man die Systeme, die die Dienste nutzen, nicht umkonfigurieren muss, wird hier üblicherweise eine Virtuelle Service IP genutzt, die im Fehlerfall vom Aktiven auf den Passiven Node umgestellt wird.

Bei einem Active-Active Cluster laufen die Dienste dauerhaft auf beiden Systemen. Diese Cluster kombinieren Hochverfügbarkeit und Lastverteilung.
Üblicherweise steht vor dem Cluster ein Loadbalancer, der die Server auf Verfügbarkeit und auf korrektes Verhalten der Anwendung prüft.

#### Lastverteilung

Wenn man einen Dienst so zur Verfügung stellen möchte, dass der Dienst auch bie sehr vielen Zugriffen schnell antwortet, nutzt man einen Loadbalancer, der die Dienste auf Verfügbarkeit prüft (siehe Active-Active Cluster).

Je nach Anwendung kommen unterschiedliche Verteilmethoden zum Einsatz. Der Klassiker ist `round-robin`. Hier werden die eingehenden IP Verbindungen gleichmässig auf die Dienste verteilt.

Loadbalancer Verteilmethoden:

1. round-robin (rr)
1. gewichtetes round-robin (wrr)
1. least connection (lc)
1. gewichtete least connection (wlc)
1. locality based least connection (lblc)
1. lblc with replication (lblcr)
1. destination hashing (dh)
1. source hashing (sh)
1. shortest expected delay (sed)
1. never queue (nq)
1. Last-basiertes Verteilen

## Hardware HA

- Strom: Redundante Netzteile
- Disk: RAID (HW oder SW)
- Netzwerk: Bonding (Active-Passive oder Active-Active)

## Tools

Veraltet: Heartbeat: <http://www.linux-ha.org/wiki/Main_Page>

Load Balancing:

- Linux Virtual Server
- LDirector
- HAproxy
- Nginx/Apache

Cluster:

- Keepalived
- Pacemaker/Corosync

Storage:

- DRBD
- OCFS2
- GlusterFS
- Ceph

Anforderungen:

- Hardware
- Uhrzeit
- Storage
- Netzwerk
- Namensauflösung
- Firewalling
- Selinux

Weiter geht es mit [Local HA](../02_Local_HA)

License: CC BY-NC-SA 4.0
