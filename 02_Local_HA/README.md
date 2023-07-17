# Local HA

1. Netzwerk Bonding
1. Disk RAID

## Netzwerk Bonding

```shell
vagrant up lb1.betadots.training
vagrant ssh lb1.betadots.training
sudo -i
apt update
apt install -y locales-all
unset LC_CTYPE
export LANG=en_US.UTF-8
apt install -y ifenslave
```

Interfaces für Bonding down setzen:

```shell
ifdown eth1
ifdown eth2
```

Bonding Config erzeugen:

```shell
# /etc/network/interfaces
auto bond0
iface bond0 inet static
    address 10.100.10.11
    netmask 255.255.255.0
    network 10.100.10.0
    # first interface will be the active one
    bond-slaves eth1 eth2
    # we could configure a primary that will always be used when available
    # bond-primary eth2
    bond-mode active-backup
    bond-miimon 100
    bond-downdelay 200
    bond-updelay 200
```

Ist das Interface Up?

```shell
ip a
```

Wenn nein: Bonding starten:

```shell
ifup bond0
```

Installation webserver:

```shell
apt install -y nginx
```

Laptop:

```shell
watch -n 0.5 'curl -I --silent 10.100.10.11'
```

alternativ:

```
ping 10.100.10.11
```

Deaktivieren eth1 am Laptop:

```shell
VBoxManage controlvm lb1.betadots.training setlinkstate2 off
```

Anschauen in der VM:

```shell
ip a
```

Reaktiveren eth1

```shell
VBoxManage controlvm lb1.betadots.training setlinkstate2 on
```

Journal lesen in der VM:

```shell
journalctl --no-pager --lines 50
```

Bond Interface status:

```shell
cat /proc/net/bonding/bond0
```

## RAID (Software)

Prüfen Festplatten:

```
root@lb1:~# lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  20G  0 disk 
└─sda1   8:1    0  20G  0 part /
sdb      8:16   0  10G  0 disk 
sdc      8:32   0  10G  0 disk 
root@lb1:~#
```

```shell
fdisk -l /dev/sdb
fdisk -l /dev/sdc
```

Anlegen des RAID:

```shell
apt install -y mdadm
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc

mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
Continue creating array? y
```

Prüfen MD Device

```shell
cat /proc/mdstat
mdadm -D /dev/md0
```

Anlegen FS und mount

```shell
apt install -y xfsprogs
mkfs.xfs /dev/md0
mount /dev/md0 /mnt
```

Anpassen Sync Rate

```shell
dd if=/dev/urandom of=/mnt/testfile-1-1G bs=1G count=1 oflag=dsync
1+0 records in
1+0 records out
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 3.87684 s, 277 MB/s
```

2 Sysctl Parameter:

```shell
cat /proc/sys/dev/raid/speed_limit_max
200000
cat /proc/sys/dev/raid/speed_limit_min
1000
echo 100000 > /proc/sys/dev/raid/speed_limit_min
```

Löschen eines RAID Devices:

```shell
umount /mnt
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sda
mdadm --zero-superblock /dev/sdb
```

Umgebung aufräumen

```shell
vagrant destroy -f
```

Weiter geht es mit [LVS](../03_LVS)

License: CC BY-NC-SA 4.0
