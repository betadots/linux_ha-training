# DRBD

Installation

    apt install -y drdb-utils

SELinux deaktivieren

    semanage permissive -a drbd_t

Firewall

DRBD nutzt Port 7789

Disks

2. Festplatte mit LVM

    pvcreate /dev/sdb
    vgcreate vg_training /dev/sdb
    lvcreate --name lv_training --size 512M vg_training

DRBD konfigurieren

    # /etc/drbd.d/drbd_training.res
    resource "drbd_lv_training" {
      device minor 1;
      meta-disk internal;
      net {
        protocol C;
        allow-two-primaries yes;
        fencing resource-and-stonith;
        verify-alg sha1;
      }
      handlers {
        fence-peer "/usr/lib/drbd/crm-fence-peer.9.sh";
        unfence-peer "/usr/lib/drbd/crm-unfence-peer.9.sh";
      }
      on "app1" {
        disk "/dev/vg_training/lv_training";
        node-id 0;
      }
      on "app2" {
        disk "/dev/vg_training/lv_training";
        node-id 1;
      }
      connection {
        host "app1" address 172.16.120.13:7789;
        host "app2" address 172.16.120.14:7789;
      }
    }

DRBD Device initialisieren

    drbdadm create-md drbd_lv_training
    modprobe drbd
    drbdadm up drbd_lv_training
    drbdadm status

Initiale Synchronisation erzwingen

    drbdadm primary --force drbd_lv_training
    drbdadm status

File System erzeugen

    mkfs.xfs /dev/drbd1
    mount /dev/drbd1 /mnt

Index.HTML erzeugen

    # /mnt/index.html
     <html>
      <body>My Test Site - DRBD</body>
     </html>

    chcon -R --reference=/var/www/html /mnt
    umount /dev/drbd1

DRBD in Pacemaker/Corosync integrieren

    pcs cluster cib drbd_cfg
    pcs -f drbd_cfg resource create WebData ocf:linbit:drbd \
     drbd_resource=wwwdata op monitor interval=29s role=Promoted \
     monitor interval=31s role=Unpromoted
    pcs -f drbd_cfg resource promotable WebData \
     promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 \
     notify=true
    pcs resource status
    pcs resource config
    pcs cluster cib-push drbd_cfg --config

Oder: 1 Kommando

    pcs resource create WebData ocf:linbit:drbd \
     drbd_resource=wwwdata op monitor interval=29s role=Promoted \
     monitor interval=31s role=Unpromoted \
     promotable promoted-max=1 promoted-node-max=1 clone-max=2  \
     clone-node-max=1 notify=true

Cluster prüfen

    pcs resource status
    pcs resource config

File System in Pacemaker ingtegrieren

    pcs cluster cib fs_cfg
    pcs -f fs_cfg resource create WebFS Filesystem \
      device="/dev/drbd1" directory="/var/www/html" fstype="xfs"
    pcs -f fs_cfg constraint colocation add \
      WebFS with Promoted WebData-clone
    pcs -f fs_cfg constraint order \
      promote WebData-clone then start WebFS

Reihenfolgen setzen

    pcs -f fs_cfg constraint colocation add WebSite with WebFS
    pcs -f fs_cfg constraint order WebFS then WebSite
    pcs -f fs_cfg constraint
    pcs cluster cib-push fs_cfg --config
    pcs resource status
    pcs resource config

Cluster switch

    pcs node standby <fqdn2>
    pcs status

    pcs node unstandby <fqdn2>
    pcs status

Weiter geht es mit [OCFS2](../08_OCFS2)
