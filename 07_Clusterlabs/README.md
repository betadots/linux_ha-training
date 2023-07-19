# Clusterlabs

Multi Node FailOver

- Erkennen und Wiederherstellen von Ausfällen
- Starten und Stoppen von Anwendungen in der richtigen Reihenfolge (auch Multi-Node)

Komponenten

- libQB - core service
- corosync - Messaging und Quorum
- Resource agents - Scripte für Services
- Fencing agents - Scripts für Network Power Switche und SAN devices zur Isolation von Cluster Servern
- Pacemaker - Überwachung uns Steuerung von Anwendungen oder Diensten

Cluster Quorum

Cluster Resources

Installation

ACHTUNG im Training nutzen wir aktuell einen 2 Node Cluster.
Damit kann man kein Quorum abbilden. In der Produktion müssen das mindestens 3 und besser 5 Nodes sein!

Alle VMs hochfahren und vorbereiten

```shell
vagrant up app1.betadots.training app2.betadots.training
```

App1:

```shell
vagrant ssh app1.betadots.training
sudo -i
```

```shell
# hinzufügen zu /etc/network/interfaces
auto eth1
iface eth1 inet static
    address 10.100.10.13
    netmask 255.255.255.0
    network 10.100.10.0

auto eth2
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
```

```shell
# hinzufügen zu /etc/network/interfaces
auto eth1
iface eth1 inet static
    address 10.100.10.14
    netmask 255.255.255.0
    network 10.100.10.0

auto eth2
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
apt install -y pacemaker corosync crmsh pcs
```

Konfiguration

TCP ports 2224, 3121, and 21064, and UDP port 5405

<https://clusterlabs.org/pacemaker/doc/2.1/Clusters_from_Scratch/html/>

pcs service

```shell
systemctl enable --now pcsd
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

```
root@app1:~# pcs host auth app1.betadots.training app2.betadots.training
Username: hacluster
Password: 
app1.betadots.training: Authorized
app2.betadots.training: Authorized
root@app1:~# pcs cluster setup demo app1.betadots.training app2.betadots.training
No addresses specified for host 'app1.betadots.training', using 'app1.betadots.training'
No addresses specified for host 'app2.betadots.training', using 'app2.betadots.training'
Destroying cluster on hosts: 'app1.betadots.training', 'app2.betadots.training'...
app1.betadots.training: Successfully destroyed cluster
app2.betadots.training: Successfully destroyed cluster
Requesting remove 'pcsd settings' from 'app1.betadots.training', 'app2.betadots.training'
app1.betadots.training: successful removal of the file 'pcsd settings'
app2.betadots.training: successful removal of the file 'pcsd settings'
Sending 'corosync authkey', 'pacemaker authkey' to 'app1.betadots.training', 'app2.betadots.training'
app1.betadots.training: successful distribution of the file 'corosync authkey'
app1.betadots.training: successful distribution of the file 'pacemaker authkey'
app2.betadots.training: successful distribution of the file 'corosync authkey'
app2.betadots.training: successful distribution of the file 'pacemaker authkey'
Sending 'corosync.conf' to 'app1.betadots.training', 'app2.betadots.training'
app1.betadots.training: successful distribution of the file 'corosync.conf'
app2.betadots.training: successful distribution of the file 'corosync.conf'
Cluster has been successfully set up.
root@app1:~#
```

Corosync Konfiguration analysieren:

```shell
cat /etc/corosync/corosync.conf
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

(Achtung: Manchmal möchte man corosync/pacemaker nicht im autostart, kann zu flappenden Cluster führen)

```shell
pcs cluster start --all # oder
systemctl enable --now corosync pacemaker
```

Corosync verifizieren

1. Kommunikation

```shell
corosync-cfgtool -s # auf beiden Systemen und vergleichen
```

1. Mitglieder und Quorum

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

Das will man nur auf einem System machen, auf dem man kurz etwas testen möchte.
Produktive Cluster müssen unbedingt das Fencing eingerichtet bekommen, um Split-Brain Situationen zu verhindern.

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

Externe Agents unter `/usr/lib/stonith/plugins/external/` prüfen

Wir möchten fencing per ssh in unserer Lab Umgebung nutzen.

Für das external/ssh Script muss `at` auf allen Clusternodes nachinstalliert werden:

```shell
apt install -y at
```

Danach muss als root user auf einem Knoten ein ssh key erzeugt werden:


```shell
ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub
```

Der Public Key muss auf allen anderen Clusternodes in `/root/.ssh/authorized_keys` hinterlegt werden.

Außerdem muss der SSH Hostkey der anderen Nodes importiert werden:

```shell
ssh-keyscan app2.betadots.training >> /root/.ssh/known_hosts
```

```shell
pcs stonith list
pcs stonith describe <AGENT_NAME>
pcs cluster cib stonith_cfg
#pcs -f stonith_cfg stonith create <STONITH_ID> <STONITH_DEVICE_TYPE> [STONITH_DEVICE_OPTIONS]
# z.B.
pcs -f stonith_cfg stonith create resStonith ssh hostlist=app1.betadots.training,app2.betadots.training
pcs -f stonith_cfg property set stonith-enabled=true
pcs cluster cib-push stonith_cfg
```

Fencing testen:

```shell
pcs stonith fence  app1.betadots.training # hier nicht den lokalen Knoten angeben
```

app1 sollte nun rebootet werden. Wenn das Fencing nicht klappt, tauchen Fehler in `pcs status` auf. Diese kann man wie folgt löschen:


```shell
stonith_admin --cleanup --history=app1.betadots.training
```

Aktiv-Passiv Cluster

Wir brauchen eine Service IP, die schwenken kann.

Auf app1:

```shell
tail /var/log/pacemaker/pacemaker.log /var/log/corosync/corosync.log -fn0
```

Auf app2:

```shell
pcs resource create ClusterIP ocf:heartbeat:IPaddr2 \
    ip=10.100.10.21 cidr_netmask=24 op monitor interval=30s
```

auf app1 und app2:

```shell
ip -4 a s
```

oder:

```shell
ip -br a
```

Auf app1 oder app2:

```shell
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
systemctl disable --now apache2.service apache-htcacheclean.service
```

Cluster Resource hinzufügen

```shell
pcs resource create WebSite ocf:heartbeat:apache  \
      configfile=/etc/apache2/apache2.conf \
      statusurl="http://localhost/server-status" \
      op monitor interval=1min
```

Alternativ über systemd und nicht ocf Scripts (Die apache Status Site wird dann nicht benutzt):

```shell
# ggf die ocf resource löschen:
pcs resource delete WebSite
pcs resource create WebSite systemd:apache2
```

Resource ausgeben:

```shell
pcs resource config WebSite
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

Die Service IP und der Service müssen immer als eine zusammenhängende Einheit betrachtet werden.

```shell
pcs constraint colocation add WebSite with ClusterIP INFINITY
pcs constraint
pcs status
```

Resourcen Reihenfolgen

Frage: was muss zuerst gestartet werden? Die Service IP oder der Service?

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

Das move setzt einen colocation contraint von Infinity auf den neuen Node (`pcs constraint`). Dies kann zurückgesetzt werden:

```shell
pcs resource clear WebSite
```

Dies kann dazu führen, dass die Resource wieder verschoben wird.

Sollte es bei Ressourcen zu irgendwelchen Fehlern gekommen sein (einsehbar in `pcs status`):

```shell
Failed Resource Actions:
  * ClusterIP_monitor_30000 on app2.betadots.training 'error' (1): call=60, status='Timed Out', exitreason='', last-rc-change='2023-07-19 06:37:39Z', queued=0ms, exec=0ms
```

Dann kann man diese wie folgt löschen:

```shell
pcs resource cleanup ClusterIP
```

Weitere Resource mit -Infinity

Manchmal möchte man zwei Resources haben, welche auf unterschiedlichen Nodes laufen, dies kann man mit einem negativen colocation constraint setzen:

```shell
pcs resource create SecondIP ocf:heartbeat:IPaddr2 ip=10.100.10.22 cidr_netmask=24 op monitor interval=50s
pcs constraint colocation add SecondIP with ClusterIP -INFINITY
```

Weitere Informationen: https://clusterlabs.github.io/PAF/CentOS-7-admin-cookbook.html#adding-ips-on-standbys-nodes

Falls man ein Attribut einer Resource updaten möchte:

```shell
pcs resource update SecondIP ocf:heartbeat:IPaddr2 ip=10.100.10.22 cidr_netmask=24 op monitor interval=10s
```

Weiter geht es mit [DRBD](../08_DRBD)

License: CC BY-NC-SA 4.0
