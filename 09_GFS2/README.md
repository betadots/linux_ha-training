# GFS2

Installation (auf beiden Nodes)

```shell
apt install -y gfs2-utils dlm-controld
```

Im Pacemaker das DLM konfigurieren

```shell
pcs cluster cib dlm_cfg
pcs -f dlm_cfg resource create dlm \
    ocf:pacemaker:controld op monitor interval=60s
pcs -f dlm_cfg resource clone dlm clone-max=2 clone-node-max=1
pcs resource status
```

Cluster config

```shell
pcs cluster cib-push dlm_cfg --config
pcs resource status
pcs resource config
```

File System erzeugen

```shell
pcs resource disable WebFS
pcs resource
```

Prüfen, wer ist DRBD Primary?

```shell
mkfs.gfs2 -p lock_dlm -j 2 -t mycluster:web /dev/drbd0
mount /dev/drbd0 /mnt/
cat <<-END >/mnt/index.html
<html>
<body>My Test Site - GFS2</body>
</html>
END
umount /mnt
```

Prüfen WebFS Resource

```shell
pcs resource config WebFS
pcs resource update WebFS fstype=gfs2
pcs resource config WebFS
```

DLM aufnehmen

```shell
pcs constraint colocation add WebFS with dlm-clone
```

Quorum deaktivieren (wir habe nur 2 Nodes)

```shell
pcs property set no-quorum-policy=freeze
```

Active-Active Konfigurieren

```shell
pcs cluster cib active_cfg
pcs -f active_cfg resource clone WebFS
pcs -f active_cfg constraint
```

```shell
pcs -f active_cfg resource update WebData-clone promoted-max=2
pcs cluster cib-push active_cfg --config
pcs resource enable WebFS
```

```shell
pcs resource
```

Corosync config (erzeugt durch PCS): `cat /etc/corosync/corosync.conf`

Weiter geht es mit [GlusterFS](../10_GlusterFS)

License: CC BY-NC-SA 4.0