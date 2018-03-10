#!/bin/bash

# Code by Kurosudo 2018, Licensed under GNU GPL v3
if [ "$EUID" !=  0 ]; then
        echo "This script will not works without being root user"
        exit;
fi
echo "Updating repositories"
        apt-get update
if hash ssh 2>/dev/null; then
        echo "ssh installed";
        read -p "Please paste here your public ssh key, usually it's located in file id_rsa.pub: " sshkey
        mkdir -p /root/.ssh
        echo "$sshkey" >> /root/.ssh/authorized_keys
else 
        echo "ssh not installed";
        read -p "Do you want install ssh?(y/N): " sshinst
        if [ "$sshinst" == "y" ]; then
        echo "Installing SSH server"
                apt-get install -y openssh-server
        read -p "Please paste here your public ssh key, usually it's located in file id_rsa.pub: " sshkey
        mkdir -p /root/.ssh
        fi  
fi

if hash iptables 2>/dev/null; then
echo ""
else
read -p "Do you want install iptables? It's really great have firewall at machine(y/N): " iptins
if [ $iptins = "y" ]; then
        apt-get install -y iptables iptables-persistent
fi
fi
# Let's make some nice rules
read -p "What ports do you want open? use , between ports example 80,443,22 " ports
echo "Applying TCP rules"
echo "Enable all for loopback"
iptables -A INPUT -i lo -j ACCEPT
echo "Enable input for connection with state RELATED,ESTABLISHED"
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
echo "Allowing INPUT with $ports "
iptables -A INPUT -p tcp -m tcp --match multiport --dport $ports -j ACCEPT
echo "Drop non listed connection to machine"
iptables -A INPUT -j DROP
echo "Allow routing forward with state RELATED, ESTABLISHED"
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
echo "Saving rules to rules.v4"
iptables-save > /etc/iptables/rules.v4
echo "restarting iptables-persistent"
systemctl restart netfilter-persistent
systemctl enable netfilter-persistent
