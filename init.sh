#!/bin/bash
# Inspired by https://github.com/itsmostafa/gophish-prod/blob/master/init.sh

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

