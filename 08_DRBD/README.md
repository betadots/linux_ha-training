# DRBD

Installation

```shell
apt install -y drbd-utils lvm2
```

SELinux deaktivieren

```shell
semanage permissive -a drbd_t # nur auf RHEL Systemen
```

Firewall

DRBD nutzt Port 7789

Disks

Zweite Festplatte mit LVM

```shell
pvcreate /dev/sdb
vgcreate vg_training /dev/sdb
lvcreate --name lv_training --size 512M vg_training
```

DRBD konfigurieren

```shell
# /etc/drbd.d/drbd_training.res
resource drbd_disk {
  device minor 1;
  meta-disk internal;
  net {
    protocol C;
    allow-two-primaries yes;
    # fencing resource-and-stonith;
    verify-alg sha1;
  }
  handlers {
    fence-peer "/usr/lib/drbd/crm-fence-peer.9.sh";
    unfence-peer "/usr/lib/drbd/crm-unfence-peer.9.sh";
  }
  on app1.betadots.training {
    address 172.16.120.13:7789;
    volume 0 {
      device minor 0;
      disk "/dev/vg_training/lv_training";
      meta-disk internal;
    }
  }
  on app2.betadots.training {
    address 172.16.120.14:7789;
    volume 0 {
      device minor 0;
      disk "/dev/vg_training/lv_training";
      meta-disk internal;
    }
  }
}
```

DRBD Device initialisieren (auf beiden Nodes)

```shell
drbdadm create-md drbd_disk
# wenn es hier zu Fehlern kommt, muss der hostname geprüft werden (hostnamectl)
modprobe drbd
drbdadm up drbd_disk
drbdadm status
```

Initiale Synchronisation erzwingen (nur auf einem Node)

```shell
drbdadm primary --force drbd_disk
drbdadm status
cat /proc/drbd
```

File System erzeugen

```shell
apt install -y xfsprogs # auf app1 und app2
mkfs.xfs /dev/drbd0
mount /dev/drbd0 /mnt
```

Index.HTML erzeugen

```shell
# /mnt/index.html
 <html>
  <body>My Test Site - DRBD</body>
 </html>
```

Wieder unmounten:
```shell
chcon -R --reference=/var/www/html /mnt # nur auf RHEL Systemen
umount /mnt
```

DRBD in Pacemaker/Corosync integrieren

```shell
pcs cluster cib drbd_cfg
pcs -f drbd_cfg resource create WebData ocf:linbit:drbd \
     drbd_resource=drbd_disk op monitor interval=29s role=Started
pcs -f drbd_cfg resource promotable WebData \
     promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 \
     notify=true
pcs resource status
pcs resource config
pcs cluster cib-push drbd_cfg --config
```

Oder: 1 Kommando

```shell
pcs resource create WebData ocf:linbit:drbd \
     drbd_resource=drbd_disk op monitor interval=29s role=Started \
     promotable promoted-max=1 promoted-node-max=1 clone-max=2  \
     clone-node-max=1 notify=true
```

Cluster prüfen

```shell
pcs resource status
pcs resource config
```

File System in Pacemaker integrieren

```shell
pcs cluster cib fs_cfg
pcs -f fs_cfg resource create WebFS ocf:heartbeat:Filesystem \
      device="/dev/drbd0" directory="/var/www/html" fstype="xfs"
pcs -f fs_cfg constraint colocation add \
      WebFS with Promoted WebData-clone
pcs -f fs_cfg constraint order \
      promote WebData-clone then start WebFS
```

Reihenfolgen setzen

```shell
pcs -f fs_cfg constraint colocation add WebSite with WebFS
pcs -f fs_cfg constraint order WebFS then WebSite
pcs -f fs_cfg constraint
pcs cluster cib-push fs_cfg --config
pcs resource status
pcs resource config
```

Cluster switch

```shell
pcs node standby <fqdn2>
pcs status

pcs node unstandby <fqdn2>
pcs status
```

Pacemaker Web UI

pcsd stellt eine Web UI bereit. Erreichbar unter:

* https://10.100.10.13:2224
* https://10.100.10.14:2224

Einloggen mit dem hacluster User.

DRBD Connecting state

Sollte es vorkommen, dass beide DRBD Instanzen Ihre Verbindung verlieren und danach einen Splitbrain haben, kann man dies wieder korrigieren. Hierzu wird `/proc/drbd` geprüft.

Node 1:

```
... ro:Primary/Unknown ...
```

Node 2:

```
ro:Secondary/Unknow
```

Node 1 ist hier der Überlebende (in der Dokumentation oft "Survivor"). Auf Node 2:

```
drbdadm disconnect drbd_disk
drbdadm secondary drbd_disk
drbdadm connect --discard-my-data drbd_disk
```

Node 1:

```
drbdadm primary drbd_disk
drbdadm connect drbd_disk
```

Danach auf beiden Nodes mit `drbdadm status` prüfen ob alles wieder verbunden ist.

Weiter geht es mit [GFS2](../09_GFS2)

License: CC BY-NC-SA 4.0
