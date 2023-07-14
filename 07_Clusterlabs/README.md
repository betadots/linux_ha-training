# Clusterlabs

Multi Node FailOver

- Erkennen und Wiederherstellen von Ausfällen
- Starten und Stoppen von Anwendungen in der richtigen Reihenfolge (auch Multi-Node)

Komponenten

- libQB - core service
- corosync - Messaging und Quorum
- Resource agents - Scripte für Services
- Fencing agents - Scripts für Network Power Switche und SAN devices zur Isolation von Cluster Servern
- Pacemaker - Überwachung uns Steierung von Anwendungen oder Diensten

Cluster Quorum

Cluster Resources

Installation

Alle VMs hochfahren und vorbereiten

```shell
vagrant up app1.betadots.training app2.betadots.training
```

App1:

```shell
vagrant ssh app1.betadots.training
sudo -i
apt update
apt install -y locales-all
unset LC_CTYPE
export LANG=en_US.UTF-8
```

```shell
# hinzufügen zu /etc/network/interfaces
allow-hotplug eth1
iface eth1 inet static
    address 10.100.10.13
    netmask 255.255.255.0
    network 10.100.10.0
    gateway 10.100.10.254
allow-hotplug eth2
iface eth2 inet static
    address 172.16.120.13
    netmask 255.255.255.0
    network 172.16.120.0
```

```shell
ifup eth1
ifup eth2
```

App2:

```shell
vagrant ssh app2.betadots.training
sudo -i
apt update
apt install -y locales-all
unset LC_CTYPE
export LANG=en_US.UTF-8
```

```shell
# hinzufügen zu /etc/network/interfaces
allow-hotplug eth1
iface eth1 inet static
    address 10.100.10.14
    netmask 255.255.255.0
    network 10.100.10.0
    gateway 10.100.10.254
allow-hotplug eth2
iface eth2 inet static
    address 172.16.120.14
    netmask 255.255.255.0
    network 172.16.120.0
```

```shell
ifup eth1
ifup eth2
```

Auf beiden Systemen:

```shell
# hinzufügen zu /etc/hosts
172.16.120.13 app1 app1.betadots.training
172.16.120.14 app2 app2.betadots.training

# WICHTIG: 127.0.0.1 app<n> entfernen!!!
```

```shell
apt update; apt install -y pacemaker corosync crmsh pcs
```

Konfiguration

TCP ports 2224, 3121, and 21064, and UDP port 5405

<https://clusterlabs.org/pacemaker/doc/2.1/Clusters_from_Scratch/html/>

pcs service

```shell
systemctl start pcsd
systemctl enable pcsd
```

hacluster user

```shell
passwd hacluster
```

Debian erzeugt automatisch einen Cluster. Den wollen wir löschen

```shell
pcs cluster destroy
```

Cluster Nodes authentifizieren (nur auf einem Node)

```shell
pcs host auth <fqdn1> <fqdn2>
pcs cluster setup <name> <fqdn1> <fqdn2>
```

pcs Kommandos

```shell
cluster     Configure cluster options and nodes.
resource    Manage cluster resources.
stonith     Manage fence devices.
constraint  Manage resource constraints.
property    Manage pacemaker properties.
acl         Manage pacemaker access control lists.
qdevice     Manage quorum device provider on the local host.
quorum      Manage cluster quorum settings.
booth       Manage booth (cluster ticket manager).
status      View cluster status.
config      View and manage cluster configuration.
pcsd        Manage pcs daemon.
host        Manage hosts known to pcs/pcsd.
node        Manage cluster nodes.
alert       Manage pacemaker alerts.
client      Manage pcsd client configuration.
dr          Manage disaster recovery configuration.
tag         Manage pacemaker tags.
```

Auslesen pacemaker Features

```shell
pacemakerd --features
```

Cluster Starten

```shell
pcs cluster start --all # oder
systemctl start corosync
systemctl start pacemaker
```

Corosync verifizieren

1. Kommunikation

```shell
corosync-cfgtool -s
```

2. Mitglieder und Quorum

```shell
corosync-cmapctl | grep members
```

Pacemaker verifizieren

```shell
pcs status
```

Aktuelle Config auslesen

```shell
pcs cluster cib
```

Config validieren

```shell
pcs cluster verify --full
```

Fencing

Abschalten

```shell
pcs property set stonith-enabled=false
```

Aktivieren

Power Fencing

- Power Switch
- IPMI
- Hardware Watchdog

Fabric Fencing

- Shared Storage
- Intelligente Netzwerk Switche

Fencing einrichten

Suchen nach Paketen mit dem Namen `*fence*`

```shell
apt search ^fence-
apt install -y fence-agents fence-virt fence-virtd
```

```shell
pcs stonith list
pcs stonith describe <AGENT_NAME>
pcs cluster cib stonith_cfg
pcs -f stonith_cfg stonith create <STONITH_ID> <STONITH_DEVICE_TYPE> [STONITH_DEVICE_OPTIONS]
# z.B.
# pcs -f stonith_cfg stonith create resStonith ssh hostlist=app1,app2
pcs -f stonith_cfg property set stonith-enabled=true
```

Aktiv-Passiv Cluster

```shell
pcs resource create ClusterIP ocf:heartbeat:IPaddr2 \
    ip=10.100.10.21 cidr_netmask=24 op monitor interval=30s

pcs resource standards
pcs resource providers
pcs resource agents ocf:heartbeat
```

Resourcen anzeigen

```shell
pcs status
```

Resources schwenken (Achtung: wo ist die ClusterIP aktiv?)

```shell
pcs cluster stop <fqdn1>
```

Verhindern von Resource Relocation nach Wiederverfügbarkeit

```shell
pcs resource defaults
pcs resource defaults update resource-stickiness=100
```

Installation Apache

```shell
apt install -y apache2
```

Einrichtung server-status (wird vom apache Resource Agent benötigt)

```shell
# /etc/apache2/conf-enabled/status.conf
<Location /server-status>
  SetHandler server-status
  Require local
</Location>
```

```shell
systemctl restart apache2
```

Cluster Resource hinzufügen

```shell
pcs resource create WebSite ocf:heartbeat:apache  \
      configfile=/etc/apache2/apache2.conf \
      statusurl="http://localhost/server-status" \
      op monitor interval=1min
```

Timeout setzen

```shell
pcs resource op defaults
pcs resource op defaults update timeout=240s
```

Cluster Status prüfen

```shell
pcs status
```

Webserver prüfen

```shell
wget -O - http://localhost/server-status
```

Resourcen Abhängigkeiten

```shell
pcs constraint colocation add WebSite with ClusterIP INFINITY
pcs constraint
pcs status
```

Resourcen Reihenfolgen

```shell
pcs constraint order ClusterIP then WebSite
pcs constraint
```

Cluster Node Präferenz

```shell
pcs constraint location WebSite prefers <fqdn>=50
pcs constraint
pcs status
```

Placement Scores

```shell
crm_simulate -sL
```

Resourcen Switchen

```shell
pcs resource move WebSite <fqdn>
pcs constraint
pcs status
```

Weiter geht es mit [DRBD](../08_DRBD)

License: CC BY-NC-SA 4.0