# Keepalived

Starten des 2ten Load-Balancer

    vagrant up lb2.betadots.training
    vagrant ssh lb2.betadots.training
    sudo -i

Nginx

    apt update
    apt install -y nginx

Gleiche Config wie gerade eben erzeugen.

Beide webserver: Installation von keepalived

    apt install keepalived

Weiter geht es mit [Clusterlabs - Pacemaker/Corosync](../06_Clusterlabs)
