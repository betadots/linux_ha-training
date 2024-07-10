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
172.16.120.13 app1.betadots.training
172.16.120.14 app2.betadots.training

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
pcs cluster status
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
pcs cluster start --all
systemctl enable corosync pacemaker
# oder
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

Danach als root user auf allen Knoten einen ssh key erzeugen:


```shell
ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub
```

Der Public Key muss auf den anderen Clusternodes in `/root/.ssh/authorized_keys` hinterlegt werden.

Außerdem muss der SSH Hostkey der anderen Nodes importiert werden:

```shell
# app1:
ssh-keyscan app2.betadots.training >> /root/.ssh/known_hosts
# app2:
ssh-keyscan app1.betadots.training >> /root/.ssh/known_hosts
```

```shell
pcs stonith list
pcs stonith describe <AGENT_NAME>
pcs cluster cib stonith_cfg
#pcs -f stonith_cfg stonith create <STONITH_ID> <STONITH_DEVICE_TYPE> [STONITH_DEVICE_OPTIONS]
# z.B.
pcs -f stonith_cfg stonith create resStonith ssh hostlist=app1.betadots.training,app2.betadots.training
pcs -f stonith_cfg property set stonith-enabled=true
pcs cluster verify --full -f stonith_cfg
pcs cluster cib-push stonith_cfg
```

Fencing testen:

```shell
# app2:
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

SBD Fencing

Stonith Block Device: https://projects.clusterlabs.org/w/fencing/using_sbd_with_pacemaker/

Für SBD Kann man einen Watchdog nutzen oder shared storage nutzen. Für den Watchdog müssen wir das softdog Kernelmodul laden (auf allen Nodes):

```shell
echo softdog >> /etc/modules-load.d/modules.conf
systemctl restart systemd-modules-load
```

Möchte man eine Shared Disk nutzen, müssen wir dies in DRBD konfigurieren (Es ist vermutlich nicht sinnvoll das DRBD hier zu nutzen weil es sehr wahrscheinlich zu einem splitbrain kommt):

```shell
lvcreate --name lv_sbd --size 50M vg_training
```

Ebenfalls muss auf allen Clusternodes das sbd Paket installiert werden:

```shell
apt install -y sbd
```

Für SDB muss der Timeout von 5s auf 30s hochgesetzt werden:

```shell
sed -i 's/SBD_WATCHDOG_TIMEOUT=.*/SBD_WATCHDOG_TIMEOUT=30/' /etc/default/sbd
sed -i 's/SBD_OPTS=.*/SBD_OPTS="-v"/' /etc/default/sbd
```

Bevor sdb konfiguriert wird, muss das Cluster gestoppt werden (??):

```shell
pcs cluster stop # will stonith the nodes
```

Quorum Device

Pacemaker hat die Möglichkeit ein 'Quorum Device' in das Cluster aufzunehmen. Dies sind Cluster Nodes auf denen keine Resources laufen. Sie werden nur genutzt damit andere Clusternodes die Verfügbarkeit um Quorum Device prüfen. Ein übliches Setup: Zwei Rechenzentren und Dienste werden zwischen den Standorten geswitcht. Um Splitbrain zu vermeiden kann man an einem dritten Standort ebenfalls einen Clusternode starten. Da dieser nur zum erreichen des Quorums genutzt wird, kann hier wesentlich kleinere Hardware genutzt werden

Auf allen vorhandenen Clusternodes:

```shell
apt install -y corosync-qdevice
```

Auf dem Quorum Node:

```shell
apt install -y pcs corosync-qnetd
systemctl enable --now pcsd
pcs cluster destroy
passwd hacluster
pcs qdevice setup model net --enable --start
pcs qdevice status net --full
```

Auf einem der vorhandenen Clusternodes muss der Quorum Node dem Cluster hinzugefügt/authentifiziert werden:

```shell
pcs host auth app3.betadots.training
```

Die vorhandene Konfiguration kann man sich noch anschauen:

```shell
pcs quorum config && pcs quorum status
```

Und dann den Quorum Node aktivieren:

```shell
pcs quorum device add model net host=app3.betadots.training algorithm=ffsplit
```

Ausgabe sollte ca so aussehen:

```terminal
root@app1:~# pcs quorum device add model net host=app3.betadots.training algorithm=ffsplit
Setting up qdevice certificates on nodes...
app1.betadots.training: Succeeded
app2.betadots.training: Succeeded
app3.betadots.training: Succeeded
Enabling corosync-qdevice...
app2.betadots.training: corosync-qdevice enabled
app3.betadots.training: corosync-qdevice enabled
app1.betadots.training: corosync-qdevice enabled
Sending updated corosync.conf to nodes...
app1.betadots.training: Succeeded
app3.betadots.training: Succeeded
app2.betadots.training: Succeeded
app1.betadots.training: Corosync configuration reloaded
Starting corosync-qdevice...
app1.betadots.training: corosync-qdevice started
app3.betadots.training: not starting corosync-qdevice: corosync is not running
app2.betadots.training: corosync-qdevice started
root@app1:~# 
```

Nochmal den Status prüfen, der app3 sollte hier nun auftauchen:

```shell
pcs quorum config && pcs quorum status
```

Auf dem Quorum Node kann der Status auch geprüft werden:

```shell
pcs qdevice status net --full
```


Ausgabe:

```terminal
root@app3:~# pcs qdevice status net --full
QNetd address:			*:5403
TLS:				Supported (client certificate required)
Connected clients:		0
Connected clusters:		0
Maximum send/receive size:	32768/32768 bytes

root@app3:~# pcs qdevice status net --full
QNetd address:			*:5403
TLS:				Supported (client certificate required)
Connected clients:		2
Connected clusters:		1
Maximum send/receive size:	32768/32768 bytes
Cluster "demo":
    Algorithm:		Fifty-Fifty split (KAP Tie-breaker)
    Tie-breaker:	Node with lowest node ID
    Node ID 1:
        Client address:		::ffff:172.16.120.13:51794
        HB interval:		8000ms
        Configured node list:	1, 2, 3
        Ring ID:		1.66
        Membership node list:	1, 2
        Heuristics:		Undefined (membership: Undefined, regular: Undefined)
        TLS active:		Yes (client certificate verified)
        Vote:			ACK (ACK)
    Node ID 2:
        Client address:		::ffff:172.16.120.14:60690
        HB interval:		8000ms
        Configured node list:	1, 2, 3
        Ring ID:		1.66
        Membership node list:	1, 2
        Heuristics:		Undefined (membership: Undefined, regular: Undefined)
        TLS active:		Yes (client certificate verified)
        Vote:			No change (ACK)

root@app3:~# 
```

Alternativ zum Quorum Device kann man einen Node zum Cluster hinzufügen und mit:

```
pcs cluster ban $resource $node
```

Hiermit wird per opt-out bestimmt, dass auf einem Node die Resource nicht angelegt werden darf. Alternativ kann man das Cluster auch opt-in aufbauen.

Weiter geht es mit [DRBD](../08_DRBD)

License: CC BY-NC-SA 4.0
