#!/bin/sh
echo "Updating and upgrading..."
apt-get update
apt-get upgrade -y
echo "Installing required apps..."
apt-get install strongswan xl2tpd libstrongswan-standard-plugins libstrongswan-extra-plugins -y
echo "Creating VPN folder in /home to store config files..."
mkdir /home/vpn
echo "Copying files to where they need to be..."
cp ipsec.conf /etc/
cp ipsec.secrets /etc/
cp conn.conf /home/vpn/
cp conn.secret /home/vpn/
cp xl2tpd.conf /etc/xl2tpd/
cp l2tpd.conf /home/vpn/
