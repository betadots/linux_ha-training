# Linux HA Schulung

Copyright betadots GmbH 2022

Einführung in Linux Hochverfügbarkeit

## Themen

- Grundlagen und Konzepte
- Lastverteilung - Loadbalancing
  - Ipvsadm + Ldirector <https://www.linux-magazin.de/ausgaben/2018/07/load-balancer/>
    - HAProxy <https://linuxhandbook.com/load-balancing-setup/>
    - Nginx
- Hochverfürbarkeit
  - Keepalived
  - Pacemaker/Corosync <https://clusterlabs.org/> <https://clusterlabs.org/pacemaker/doc/2.1/Clusters_from_Scratch/html/>
  - PCS Web UI <https://github.com/ClusterLabs/pcs-web-ui>
  - Scancore? <https://www.alteeve.com/w/ScanCore>
- Cluster Datei Systeme <https://en.wikipedia.org/wiki/Clustered_file_system>
  - OCFS2 <https://en.wikipedia.org/wiki/OCFS2> <https://www.admin-magazin.de/Das-Heft/2010/03/Cluster-Dateisystem-OCFS2-einfach-gemacht>
  - Ceph <https://ceph.io/en/> <https://en.wikipedia.org/wiki/Ceph_(software)#File_system>
  - Lustre <https://www.lustre.org/>
  - DRBD <http://www.drbd.org/>
  - GlusterFS <https://www.gluster.org/>
- HA in Diensten
  - BIND
  - MySQL
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
- Ivpsadm und Ldirector
- HAproxy
- Nginx
- Keepalived

Tag 2:

- Pacemaker/Corosync
- DRBD
- OCFS2

Tag 3:

- GlusterFS
- Ceph
- HA in Diensten - Diskussion, Vorstellung
- HA mit Containern - Diskussion, Vorstellung

License: CC BY-NC-SA 4.0
