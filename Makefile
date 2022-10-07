.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
.DEFAULT_GOAL := help
SHELL:=/bin/bash
BUILD_NAME ?=web-scrapper

IMAGENAME=$(BUILD_NAME)
DOCKERCMD=docker exec -t $(IMAGENAME) $(MAKECMD)
DOCKERICMD=docker exec -i -t $(IMAGENAME) $(MAKECMD)
RUNCHECK=docker run --rm -v $$(pwd):/app -w /app golangci/golangci-lint:v1.45.2 golangci-lint run -E misspell -E dupl -E gocyclo -E revive -E gofmt -E bodyclose -E unparam -E gocritic --modules-download-mode=vendor --timeout 10m ./...

export RED='\033[0;31m'
export NC='\033[0m'
#IMAGENAME = web-scrapper
ListALlContainersCMD=docker container ls -aq --filter name=$(IMAGENAME)
ListRunningContainersCMD=docker container ls -q --filter name=$(IMAGENAME)
StopContainerCMD=docker container stop $$($(ListRunningContainersCMD))
RemoveContainerCMD=docker container rmi $$($(ListALlContainersCMD))
#DOCKERRUN=docker run -v $(PWD):/go/src/web-scrapper/ --workdir /go/src/web-scrapper/ --rm -e "ENV_VAR1=value1" -e "ENV_VAR2=$(CONSUL_HTTP_ADDR)" --name web-scrapper -i -t -p 8081:8082 web-scrapper /bin/ash;

MAKECMD= /usr/bin/make --no-print-directory
RUNCMD=run
GOCMD=go
GOBUILD=$(GOCMD) build -mod=vendor -o web-scrapper
GOCLEAN=$(GOCMD) clean -mod=vendor
GOTEST=$(GOCMD) test -mod=vendor -covermode=set -coverprofile=coverage.out ./...
GOCOV=$(GOCMD) tool cover -html=coverage.out -o coverage.html
GOGET=$(GOCMD) get

check: ## Runs different golang checks
	@if [ -f /.dockerenv ] ; then \
  		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.45.2; \
  		golangci-lint --version; \
  		golangci-lint run -E misspell -E dupl -E gocyclo -E revive -E gofmt -E bodyclose -E unparam -E gocritic --modules-download-mode=vendor --timeout 10m ./...; \
	else \
#		$(RUNCHECK); \
		$(DOCKERCMD) check; \
	fi;

shell: 
	@docker-compose exec web-scrapper bash

test: ## Runs go tests
	@if [ -f /.dockerenv ] ; then \
		$(GOTEST); \
	else \
		echo "running tests in docker env ..." ; \
		$(DOCKERCMD) test;\
	fi;
	@exit $(.SHELLSTATUS)

build: ## builds the docker image
	@if [ -f /.dockerenv ] ; then \
		$(GOBUILD); \
	else \
	  echo "building app in docker env ..." ; \
	  $(DOCKERCMD) build; \
  	fi;

run: 
	@if [ -f /.dockerenv ] ; then \
		pkill $(BUILD_NAME);\
		./$(BUILD_NAME) $(RUNCMD) $@ ;\
	else \
		echo "running app in docker env ..." ; \
		$(DOCKERICMD) run; \
	fi;

brun: ## builds and runs the new binary
	@$(MAKECMD) build
	@$(MAKECMD) run

up: ## Brings the docker images up
	@[ -f /.dockerenv ] || true
	@docker-compose pull
	@docker network create web-scrapper-network --subnet=192.169.100.0/24 || true
	@docker-compose up -d

reload: ## Brings the docker images up
	@[ -f /.dockerenv ] || true
	@docker-compose down --volumes
	@docker-compose up --force-recreate --build -d -V

reload_debug: ## Brings the docker images up
	@[ -f /.dockerenv ] || true
	@docker-compose down --volumes
	@docker-compose up --force-recreate --build -V

stop: ## Stops the docker images
	@[ -f /.dockerenv ] || true
	@docker-compose stop

pause:  ## Pauses the docker images
	@[ -f /.dockerenv ] || true
	@docker-compose pause

restart: ## Restarts the docker images
	@[ -f /.dockerenv ] || true
	@docker-compose restart

start: ## Starts the docker images
	@[ -f /.dockerenv ] || true
	@docker-compose start

down:  ## Destroys the docker images
	@[ -f /.dockerenv ] || true
	@docker-compose down --remove-orphans -v

docker_clean:  ## Destroys the docker images
	@[ -f /.dockerenv ] || true
	@docker-compose down --volumes --remove-orphans
	@docker-compose rm --force -v

ps:  ## Shows the docker image stats
	@[ -f /.dockerenv ] || true
	@docker ps -a

cov: ## Runs coverage tool
	@if [ -f /.dockerenv ] ; then \
		$(GOCOV); \
	else \
		echo -e ${RED}running coverage in docker env ...${NC} ; \
		$(DOCKERCMD) cov;\
	fi;
	@exit $(.SHELLSTATUS)