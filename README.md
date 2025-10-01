# Linux HA Schulung

Copyright betadots GmbH 2023 - 2025

Feedback: tech@betadots.de

Einführung in Linux Hochverfügbarkeit

## Themen

- Grundlagen und Konzepte
  - Bonding
  - RAID
- Lastverteilung - Loadbalancing
  - Linux Virtual Server (LVS) - Ipvsadm + Ldirector <https://www.linux-magazin.de/ausgaben/2018/07/load-balancer/>
  - HAProxy <https://linuxhandbook.com/load-balancing-setup/>
  - Nginx
- Hochverfürbarkeit
  - Keepalived
  - Pacemaker/Corosync <https://clusterlabs.org/> <https://clusterlabs.org/pacemaker/doc/2.1/Clusters_from_Scratch/html/>
- Cluster Datei Systeme <https://en.wikipedia.org/wiki/Clustered_file_system>
  - DRBD <http://www.drbd.org/>
  - OCFS2 <https://en.wikipedia.org/wiki/OCFS2> <https://www.admin-magazin.de/Das-Heft/2010/03/Cluster-Dateisystem-OCFS2-einfach-gemacht>
  - Ceph <https://ceph.io/en/> <https://en.wikipedia.org/wiki/Ceph_(software)#File_system>
  - GlusterFS <https://www.gluster.org/>
- HA in Diensten
  - BIND
  - MySQL/MariaDB + MaxScale
  - PostgreSQL
  - LDAP
- HA mit Containern
  - Docker Swarm
  - Kubernetes

## Links

- <https://www.datacenter-insider.de/der-aufbau-eines-high-availability-cluster-mit-linux-a-958751/>

## Agenda

Tag 1:

- Grundlagen und Konzepte
- Bonding
- RAID
- LVS (Ivpsadm und Ldirectord)
- HAproxy

Tag 2:

- Nginx
- Keepalived
- Pacemaker/Corosync

Tag 3:

- DRBD
- GFS2
Optional - Nur zeigen
- OCFS2
- GlusterFS
- Ceph - Vorstellung
- HA in Diensten - Diskussion, Vorstellung
- HA mit Containern - Diskussion, Vorstellung

## Trainings Unterlagen holen

Zuerst brauchen wir einen GIT Client. Mit `which git` oder `git --version` prüfen, ob GIT installiert ist.

Wenn nicht: Je nach OS bitte installieren:

- Debian: `sudo apt-get install git`
- CentOS: `sudo yum install git`
- SuSE: `sudo zypper in git-core`
- Windows: `choco install git` # <- Erfordet [Chocolatey](https://chocolatey.org/)

Nun das GitHub Repository auf die Workstation/das Trainingslaptop herunterladen:

```shell
git clone https://github.com/betadots/linux_ha-training
cd linux_ha-training
```

Weiter geht es mit [Vorbereitung](00_Vorbereitung)

License: CC BY-NC-SA 4.0
