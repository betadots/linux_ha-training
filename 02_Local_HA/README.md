# Local HA

1. Netzwerk Bonding
1. Disk RAID

```
vagrant up lb1.betadots.training
sudo -i
apt update
apt install -y ifenslave
```

## Netzwerk Bonding

Prüfen, ob Interfaces Down sind:

    ifdown eth1
    ifdown eth2

Bonding Config erzeugen:

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

Installation webserver

    apt install -y nginx

Laptop:

    watch -n 0.5 'curl 10.100.10.11'

Deaktivieren eth1

    VBoxManage controlvm lb1.betadots.training setlinkstate2 off

Anschauen in der VM

    ip a

Reaktiveren eth1

    VBoxManage controlvm lb1.betadots.training setlinkstate2 on

## RAID (Software)

Weiter geht es mit [LVS](../03_LVS)

License: CC BY-NC-SA 4.0
