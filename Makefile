#Inspired by  https://github.com/itsmostafa/gophish-prod/blob/master/Makefile

.PHONY: all help build logs loc up stop down

# make all - Default Target. Does nothing.
all:
	@echo "Helper commands."
	@echo "For more information try 'make help'."

# target: help - Display callable targets.
help:
	@egrep "^# target:" [Mm]akefile

init:
	sudo chmod u+x init.sh
	./init.sh

# target: build = build all containers
build:
	docker-compose build

# start - Start Docker.
start:
	 docker-compose up -d

# stop - Stop all docker containers
stop:
	docker-compose stop

#down - Remove all docker containers
down:
	docker-compose down