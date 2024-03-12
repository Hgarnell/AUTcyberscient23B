# AUTcyberscient23B
Dockercontainer
## Setup locally
Clone into this repository.
 git clone https://github.com/Hgarnell/AUTcyberscient23B.git
 update 
 sudo apt-get update
### Build containers
    run : make build
### Run containers
    follow prompts on screen.
    then run: make start
### Check if containers are runnings
    docker ps
    docker logs autcyberscient23b-gophish-1 | grep password
     to get the default username and password for this instance

### Run Postfix and setup. 
    Before running set the terminal to priveleged mode. (sudo -s)
    then run: make -B postfix

    

