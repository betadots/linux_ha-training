# Local HA

1. Netzwerk Bonding
1. Disk RAID

## Netzwerk Bonding

```shell
vagrant up lb1.betadots.training
vagrant ssh lb1.betadots.training
sudo -i
# welche interfaces existieren?
ip a
# installation ifenslave
apt install -y ifenslave
```

Interfaces für Bonding down setzen:

```shell
ifdown eth1
ifdown eth2
```

Bonding Config erzeugen (interfaces):

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

Bonding erzeugen (netplan):

```yaml
# /etc/netplan/99-bonding.yaml
network:
  version: 2
  ethernets:
    eth1:
      dhcp4: no
    eth2:
      dhcp4: no
  bonds:
    bond0:
      dhcp4: no
      interfaces: [eth1, eth2]
      addresses: [10.100.10.11/24]
      parameters:
        mode: active-backup
        primary: eth1
        mii-monitor-interval: 100
        up-delay: 200
        down-delay: 200
```

Ist das Interface Up?

```shell
ip a
```

Wenn nein: Bonding starten:

```shell
ifup bond0
```

Bei netplan:

```shell
netplan try
# Schauen, ob alles OK. Notfalls warten....
netplan apply
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

```shell
ping 10.100.10.11
```

Deaktivieren eth1 am Laptop:

```shell
VBoxManage controlvm lb1.betadots.training setlinkstate2 off
```

oder in der VM:

```shell
ip link set eth1 down
```

Anschauen in der VM:

```shell
ip a
```

Reaktiveren eth1

```shell
VBoxManage controlvm lb1.betadots.training setlinkstate2 on
```

oder in der VM:

```shell
ip link set eth1 up
```

Journal lesen in der VM:

```shell
journalctl --no-pager --lines 50
```

Bond Interface status:

```shell
cat /proc/net/bonding/bond0
```

---

## RAID (Software)

Prüfen Festplatten:

```shell
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
mdadm --create /dev/md/0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc --metadata=1.2
```

Prüfen MD Device

```shell
root@lb1:~# lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda      8:0    0  20G  0 disk  
└─sda1   8:1    0  20G  0 part  /
sdb      8:16   0  10G  0 disk  
└─md0    9:0    0  10G  0 raid1 /mnt
sdc      8:32   0  10G  0 disk  
└─md0    9:0    0  10G  0 raid1 /mnt
root@lb1:~# 
```

```shell
cat /proc/mdstat
mdadm --detail /dev/md0
```

```shell
root@lb1:~# mdadm --examine /dev/sdb
/dev/sdb:
          Magic : a92b4efc
        Version : 1.2
    Feature Map : 0x0
     Array UUID : ef044e82:c2466b52:bdf36688:9eab5e42
           Name : lb1.betadots.training:0  (local to host lb1.betadots.training)
  Creation Time : Mon Jul 17 10:14:40 2023
     Raid Level : raid1
   Raid Devices : 2

 Avail Dev Size : 20953088 (9.99 GiB 10.73 GB)
     Array Size : 10476544 (9.99 GiB 10.73 GB)
    Data Offset : 18432 sectors
   Super Offset : 8 sectors
   Unused Space : before=18280 sectors, after=0 sectors
          State : clean
    Device UUID : 22b2b196:5ac87516:f8e6f752:6b56779f

    Update Time : Mon Jul 17 10:15:33 2023
  Bad Block Log : 512 entries available at offset 136 sectors
       Checksum : 875a2899 - correct
         Events : 19


   Device Role : Active device 0
   Array State : AA ('A' == active, '.' == missing, 'R' == replacing)
root@lb1:~# 
```

Anlegen FS und mount

```shell
apt install -y xfsprogs
mkfs.xfs /dev/md0
mount /dev/md0 /mnt
```

Persistieren:

```shell
mdadm --detail --scan --verbose >> /etc/mdadm/mdadm.conf
```

Anpassen Sync Rate

```shell
dd if=/dev/urandom of=/mnt/testfile-1-1G bs=1G count=1 oflag=dsync
1+0 records in
1+0 records out
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 3.87684 s, 277 MB/s
```

2 Sysctl Parameter um Raid Resync einzuschränken/zu beschleunigen:

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
mdadm --zero-superblock /dev/sdb
mdadm --zero-superblock /dev/sdc
```

Umgebung aufräumen

```shell
exit # root
exit # vagrant
vagrant destroy -f
```

Weiter geht es mit [LVS](../03_LVS)

License: CC BY-NC-SA 4.0
