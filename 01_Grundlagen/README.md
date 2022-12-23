# Linux HA Schulung

Copyright betadots GmbH 2022

Einführung in Linux Hochverfügbarkeit

## Grundlagen und Konzepte

### Was ist HA?

Hochverfügbarkeit bedeutet, dass man Dienste ausfallsicher betreiben möchte.
Dabei stehen unterschiedliche Verfahren zur Verfügung.

1. Ausfallsicherheit
1. Lastverteilung

#### Ausfallsicherheit/Cluster

Bei einem Cluster hat man einen Verbund von Systemen, die sich gegenseitig überwachen. Hier gibt es entweder das Active-Passive- oder das Active-Active-Modell.

Bei einem Active-Passive Cluster soll bei einem Ausfall das aktiven Systems der Cluster selbständig die Dienste auf dem Passiven Node starten.
Damit man die Systeme, die die Dienste nutzen, nicht umkonfigurieren muss, wird hier üblicherweise eine Virtuelle Service IP genutzt, die im Fehlerfall vom Aktiven auf den Passiven Node umgestellt wird.

Bei einem Active-Active Cluster laufen die Dienste dauerhaft auf beiden Systemen. Diese Cluster kombinieren Hochverfügbarkeit und Lastverteilung.
Üblicherweise steht vor dem Cluster ein Loadbalancer, der die Server auf Verfügbarkeit und auf korrektes Verhalten der Anwendung prüft.

#### Lastverteilung

Wenn man einen Dienst so zur Verfügung stellen möchte, dass der Dienst auch bie sehr vielen Zugriffen schnell antwortet, nutzt man einen Loadbalancer, der die Dienste auf Verfügbarkeit prüft (siehe Active-Active Cluster).

Je nach Anwendung kommen unterschiedliche Verteilmethoden zum Einsatz. Der Klassiger ist `round-robin`. Hier werden die eingehenden IP Verbindungen gleichmässig auf die Dienste verteilt.

Loadbalancer Verteilmethoden:

1. round-robin
1. gewichtetes round-robin
1. least connection
1. Last-basiertes Verteilen

## Tools

Anfang: Heartbeat: <http://www.linux-ha.org/wiki/Main_Page>

Anforderungen:

- Hardware
- Uhrzeit
- Storage
- Netzwerk
- Namensauflösung
- Firewalling
- Selinux

## Storage

### DRBD

### Ceph

### GFS2

### GlusterFS

## Applikationen

### Keepalived

### Pacemaker/Corosync

Corosync: Cluster Engine
Pacemaker: Cluster Resource Manager

Weiter geht es mit [LVS](../02_LVS)

License: CC BY-NC-SA 4.0
