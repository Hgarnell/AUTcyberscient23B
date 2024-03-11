#!/bin/bash

#prompt user for hostname
read -p "Enter a hostname name(Name of your webserver): " user_hostname

#Set cloud to false
sudo bash -c 'awk "/^preserve_hostname: false\$/ {\$2=\"true\"} 1" /etc/cloud/cloud.cfg > /etc/cloud/cloud.cfg.tmp && mv /etc/cloud/cloud.cfg.tmp /etc/cloud/cloud.cfg'
#Set hostname
sudo hostnamectl set-hostname $user_hostname

#Install recquired packages
apt install opendkim opendkim-tools postfix-policyd-spf-python postfix-pcre

# Add user "postfix" to "opendkim" group
sudo usermod -G opendkim postfix

#Generate keys
sudo mkdir -p /etc/opendkim/keys

sudo chown -R opendkim:opendkim /etc/opendkim

sudo chmod  744 /etc/opendkim/keys

#Create Selector Key
mkdir /etc/opendkim/keys/$user_hostname

opendkim-genkey -b 2048 -d $user_hostname -D /etc/opendkim/keys/$user_hostname -s default -v

# Change Permission for the keys
chown opendkim:opendkim /etc/opendkim/keys/$user_hostname/default.private

#Remove all the spaces and output the private key