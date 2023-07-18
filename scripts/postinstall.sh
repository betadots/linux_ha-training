#!/bin/bash
hostn=$1

echo "### Setting hostname ${hostn}"
hostname $hostn

echo "### Updating ${hostn}"
apt -qq update
# ugrade is not required and only takes a lot of time
# DEBIAN_FRONTEND=noninteractive apt -qq --yes upgrade
apt -qq --yes autoclean

echo "### Installing additional packages ${hostn}"
apt -qq --yes install vim tcpdump htop locales-all curl iptraf-ng

echo "### Configuring locales on ${hostn}"
echo -e 'de_DE.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\nen_GB.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
echo -e '\nexport LANG=en_US.UTF-8\n' >> /root/.bashrc

echo "### Configuring some aliases in .bashrc on ${hostn}"
echo "alias ip='ip -c'" >> /root/.bashrc
