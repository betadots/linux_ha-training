# Keepalived

Keppalived kombiniert Load-Balancing und HA.

Als Loadbalancing backend kommt LVS zum Einsatz. Man kann keepalived als einen director für LVS ansehen und funktioniert analog zu ldirectord.

Das HA Konzept wird mit VRRP (Virtual Router Redundancy Protocol) realisiert.
Das Konzept von VRRP besteht aus einer virtuellen IP/MAC, welche zwischen Systemen in einem VRRP Verbund wechseln kann.
Wenn das aktive System ausfällt, wir die IP/MAC auf einem anderen Host-Standby System hochgefahren.

VRRP verwendet Broadcast. Zusammengehörende Router werden über eine VRID (Virtual Router ID) konfiguriert.
Als virtuelle MAC wird eine Multicast-Adresse aus dem Bereich 00:00:5E:00:01:01 bis 00:00:5E:00:01:FF benutzt, die letzte 8 bit sind dabei die VRID.

VRRP ist ein eigener IP Protokolltyp mit der Nummer 112. Sofern Version 2 mit MD5 Authentication benutzt wird, wird abweichend allerdings Protokollnummer 51 (Authentication Header) verwendet.

VRRP2 hat authentifizierung.
VRRP3 hat IPv6 support, aber die authentifizierung wurde wieder entfernt.

Keepalived nutzt VRRP2.

Starten des 2ten Load-Balancer

    vagrant up lb2.betadots.training
    vagrant ssh lb2.betadots.training
    sudo -i

Nginx

    apt update
    apt install -y nginx

Gleiche Config wie gerade eben erzeugen.

Beide LB: Installation von keepalived

    apt install keepalived

Weiter geht es mit [Clusterlabs - Pacemaker/Corosync](../06_Clusterlabs)
