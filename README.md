# AUTcyberscient23B
This repo is aimed to allow you to set up a gophish based phishing instace. 
We have tested that it runs on UBUNTU LTS 22.04, but it should work on other compatible distrobutions as well.
More indepth information will be provided with our documentation.

## Setup locally
Prior to pulling this repo set up your server.

update your server
 sudo apt-get update
You may need to install git and/or make if it not already installed on your server
 sudo apt install git
 sudo apt install make

Clone into this repository.
 git clone https://github.com/Hgarnell/AUTcyberscient23B.git
Move into the Repository Directory
 cd AUTcyberscient23B

### Initialize containers
Once in your repository Directory, run the make init command.
    make init

You will need to update your `docker-compose.yml` file to adjust the variable names to your server public IP address and Domain name
    nano docker-compose.yml
The variables you are loking to change are named `SERVER_HOSTNAME=example.com` and `SERVER_IP`


### Build containers
After editing the variable names, you can go ahead and begin building your containers with the make build command, followed with the make start command.
    make build
    make start


### Check if containers are runnings
Check if your containers are working and that they arn't any errors.
    docker ps
    docker-compose logs

### View DNS information
To view DNS mail server information view the logs of the postfix docker container.
    docker logs autcyberscient23b_postfix_1 

### Login to GoPhish
To get the intial admin password for gophish view the logs for the gophish container
    docker logs autcyberscient23b_gophish_1 
Navigate to https://0.0.0.0:3333 to view the admin console for gophish.

    

This repo was help created by using the following resources
https://github.com/gophish/gophish
https://github.com/itsmostafa/gophish-prod/
https://github.com/cisagov/postfix-docker/