#Inspired by  https://github.com/itsmostafa/gophish-prod/blob/master/Makefile

.PHONY: all help build logs loc up stop down

#target: Make =  make all - Default Target. Does nothing.
all:
	@echo "Helper commands."
	@echo "For more information try 'make help'."

# target: help = Display callable targets.
help:
	@egrep "^# target:" [Mm]akefile

# target: init = Run initial starting script
init:
	sudo chmod u+x init.sh
	./init.sh

# target: build = build all containers
build:
	docker-compose build

# target: start =  Start Docker.
start:
	 docker-compose up -d
	 
#target: postfix =  Start postfix script.
postfix:
	 sudo chmod u+x postfix-init.sh
	./postfix-init.sh


#target: stop = Stop all docker containers
stop:
	docker-compose stop

# target: down = Remove all docker containers
down:
	docker-compose down

# target: generateOpenSSL = Generates openssl key to /root/AUTcyberscient23B/dhparam/dhparam-2048.pem
generateOpenSSL:
	openssl dhparam -out /root/AUTcyberscient23B/dhparam/dhparam-2048.pem 2048

# target: runEncryptPart1 = Runs the first script out of 2.
runEncryptPart1:
	sudo chmod u+x http.sh
	./http.sh $(DOMAIN)
	
# target:runEncryptPart2 = Runs the second script out of 2.
runEncryptPart2:
	sudo chmod u+x https.sh
	./https.sh $(DOMAIN)
