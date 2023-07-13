# Vorbereitung

## Vagrant Installation

Bitte eine aktuelle Version von Vagrant installieren: [https://developer.hashicorp.com/vagrant/downloads](https://developer.hashicorp.com/vagrant/downloads)
Achtung: wenn Vagrant schon installiert ist, dann unbedingt pruefen, ob die Version aktuell ist!

```shell
which vagrant
vagrant --version
```

Debian:

```shell
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

CentOS:

```shell
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install vagrant
```

Windows:

```shell
choco install vagrant
```

Falls Vargant vorher schon installiert war, muss man die Plugins reaktivieren: `vagrant plugin expunge --reinstall`

## Vagrant Erweiterungen

Es werden zwei Vagrant Plugins eingesetzt:

- vagrant-hostmanager
- vagrant-vbguest

Das Hostmanager Plugin erzeugt auf dem Trainings Laptop Einträge in /etc/hosts, so dass man mit dem Browser direkt auf die VM zugreiffen kann.

Das VBGuest Plugin installiert automatisch die VirtualBox Guest Extensions in einer VM, damit wir dieses GIT Repository als ein Volume in die VM mounten können.

```shell
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-vbguest
```

Falls die Plugins schon installiert waren, kann man prüfen, ob Aktualisierungen vorliegen:

```shell
vagrant plugin update
```

## Vagrant Box

Vagrant arbeitet mit vorbereiteten VM Images. Wir muessen das Debian Bullseye64 Image lokal ablegen:

```shell
vagrant box add debian/bullseye64 --provider virtualbox
    ==> box: Loading metadata for box 'debian/bullseye64'
        box: URL: https://vagrantcloud.com/debian/bullseye64
    ==> box: Adding box 'debian/bullseye64' (vxxx.y) for provider: virtualbox
        box: Downloading: https://vagrantcloud.com/centos/boxes/bullseye64/versions/xxxx.y/providers/virtualbox.box
        box: Download redirected to host: cloud.centos.org
    ==> box: Successfully added box 'debian/bullseye64' (vxxxx.y) for 'virtualbox'!
```

## VirtualBox Vorbereitung

Unbedingt pruefen, ob die Host-only Netzwerke einen DHCP Server aktiviert haben !!

VirtualBox -> Datei -> Host-Only Netzwerk -> DHCP Server

Wenn der Host-Only DHCP Server aktiv ist: deaktivieren.
Wenn im DHCP Server Daten hinterlegt sind, diese bitte durch '0.0.0.0' ersetzen (auch wenn man DHCP danach ausschaltet.

Wenn man den DHCP Server deaktivieren musste, muss das Linux System neu gestartet werden! Unbedingt neu starten!

## Virtualbox

Als Virtualisierungsbackend wird [Virtualbox](https://virtualbox.org) genutzt.
Bitte prüfen, ob Virtualbox installiert ist, notfalls nachinstallieren.
Ausserdem werden die VirtualBox Guest Extensions benötigt.

## VM starten

Jetzt können die VMs instantiiert werden:

```shell
vagrant up <server>.betadots.training <server>.betadots.training ...
```

Danach Login:

```shell
vagrant ssh <server>.betadots.training
sudo -i
```

## VM sichern

Wenn man am Abend das Laptop auschalten will, muss man die VMs vorher sichern (nicht runterfahren!):

```shell
vagrant suspend
```

Am naechsten Tag können die VMs wieder geladen werden:

```shell
vagrant resume
```

## VM pruefen

Pruefen, ob eth1 Interface eine IP hat, `ip a`. Wenn nein: `ifup eth1`

Achtung: Namensauflösung innerhalb der VM.

In `/etc/hosts` sicherstellen, dass folgender Eintrag entfernt wird:

```shell
127.0.1.1 server<n>.betadots.training server<n>
```

Weiter geht es mit [Grundlagen](../01_Grundlagen)
