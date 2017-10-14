PROJECT := kamailio-builder
DOCKER_ORG := telephoneorg
DOCKER_USER := joeblackwaslike
DOCKER_IMAGE := $(DOCKER_ORG)/$(PROJECT):latest

KAZOO_CONFIGS_BRANCH ?= 4.2

.PHONY: all build-builder build-kamailio clean

all: build-builder build-kamailio

build-builder:
	@docker build -t $(DOCKER_IMAGE) \
		--build-arg KAZOO_CONFIGS_BRANCH=$(KAZOO_CONFIGS_BRANCH) .

build-kamailio:
	@docker run -it --rm \
		-v "$(PWD)/dist:/dist" \
		$(DOCKER_IMAGE)

clean:
	@rm -rf dist/*
