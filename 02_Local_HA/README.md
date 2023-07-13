# Local HA

1. Netzwerk Bonding
1. Disk RAID

```shell
vagrant up lb1.betadots.training
sudo -i
apt update
apt install -y ifenslave
```

## Netzwerk Bonding

Interfaces für Bonding down setzen:

```shell
ifdown eth1
ifdown eth2
```

Bonding Config erzeugen:

```shell
# /etc/network/interfaces
iface bond0 inet static
    address 10.100.10.11
    netmask 255.255.255.0
    network 10.100.10.0
    gateway 10.100.10.254
    bond-slaves eth1 eth2
    bond-mode active-backup
    bond-miimon 100
    bond-downdelay 200
    bond-updelay 200
```

Bonding starten:

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

Weiter geht es mit [LVS](../03_LVS)

License: CC BY-NC-SA 4.0
