#!/bin/bash
# Inspired by https://github.com/itsmostafa/gophish-prod/blob/master/init.sh
# prompt and set hostname
@read -p "Enter the hostname: " hostname; \
sudo hostnamectl set-hostname $$hostname


# install latest version of docker the lazy way
curl -sSL https://get.docker.com | sh

# upgrade packages
sudo apt update

# make it so you don't need to sudo to run docker commands
# note: make sure to log out and log in back in to reflect
sudo groupadd docker
sudo usermod -aG docker ubuntu


# install docker and docker-compose
sudo apt install docker-compose
sudo apt install docker-ce

# open firewall
sudo ufw enable
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 'OpenSSH'
sudo ufw allow 3333