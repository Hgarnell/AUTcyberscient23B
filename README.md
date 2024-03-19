# AUTcyberscient23B
W## Setup locally
update your server
 sudo apt-get update
You may need to install git and/or make if it not already installed on your server
 sudo apt install git
 sudo apt install make

Clone into this repository.
 git clone https://github.com/Hgarnell/AUTcyberscient23B.git
Move to the Repository Directory
 cd AUTcyberscient23B


### Build containers
    make build
### Run containers
follow prompts on screen.
    make start
### Check if containers are runnings
    docker ps
    docker logs autcyberscient23b-gophish-1 | grep password
     to get the default username and password for this instance

### Run Postfix and setup. 
Before running set the terminal to priveleged mode.
    sudo -s
    make -B postfix

    

