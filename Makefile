SHELL := /bin/bash

# Do things in edx-platform
.PHONY: clean extract_translations help pull pull_translations push_translations requirements shell upgrade
.PHONY: api-docs docs guides swagger install-requirements

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))

# Careful with mktemp syntax: it has to work on Mac and Ubuntu, which have differences.
PRIVATE_FILES := $(shell mktemp -u /tmp/private_files.XXXXXX)

help: ## display this help message
	@echo "Please use \`make <target>' where <target> is one of"
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | sort | awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

clean: ## archive and delete most git-ignored files
	# Remove all the git-ignored stuff, but save and restore things marked
	# by start-noclean/end-noclean. Include Makefile in the tarball so that
	# there's always at least one file even if there are no private files.
	sed -n -e '/start-noclean/,/end-noclean/p' < .gitignore > /tmp/private-files
	-tar cf $(PRIVATE_FILES) Makefile `git ls-files --exclude-from=/tmp/private-files --ignored --others`
	-git clean -fdX
	tar xf $(PRIVATE_FILES)
	rm $(PRIVATE_FILES)

install-docker: ## Install docker
	sudo apt-get update; sudo apt-get upgrade -y
	sudo apt-get instal docker docker-compose
	sudo groupadd docker
	sudo usermod -aG docker ${USER}
	@read -t 10 -p "Hit ENTER or wait ten seconds to reboot(CTL+C to cancle)"
	sudo reboot

install-docker-buildx:
	mkdir -p ~/.docker/cli-plugins
	curl -o ~/.docker/cli-plugins/docker-buildx -L "https://github.com/docker/buildx/releases/download/v0.6.3/buildx-v0.6.3.linux-$(dpkg --print-architecture)"
	chmod a+x ~/.docker/cli-plugins/docker-buildx
	sudo systemctl restart docker
	docker run --privileged --rm tonistiigi/binfmt --install all
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name odoobuilder --driver docker-container --platform linux/amd64,linux/arm64 --use
	docker buildx ls
	docker buildx inspect --bootstrap


ifndef ODOO_COMMIT_ID 
ODOO_COMMIT_ID:=15.0
endif

ifndef ${TAG}
TAG:=odoo15
endif

ifndef PLATFORM 
PLATFORM:=linux/amd64,linux/arm64
endif

docker-build: ## These make targets currently only build LMS images.
	@echo ${TAG} ${ODOO_COMMIT_ID} ${ODOO_SHA} ${PLATFORM}
	docker buildx build ./${TAG} -t telesoho/odoo:${TAG} --build-arg ODOO_COMMIT_ID=${ODOO_COMMIT_ID} --build-arg ODOO_SHA=${ODOO_SHA} --platform=${PLATFORM} --pull --push

docker-load:
	# docker buildx build ./${TAG} -t telesoho/odoo:${TAG} --build-arg ODOO_COMMIT_ID=${ODOO_COMMIT_ID} --build-arg ODOO_SHA=${ODOO_SHA} --platform=${PLATFORM} --pull --load


docker-pull: ## update the Docker image used by "make shell"
	docker pull telesoho/odoo:${TAG}

docker-auth: ## login docker
	echo "$$DOCKERHUB_PASSWORD" | docker login -u "$$DOCKERHUB_USERNAME" --password-stdin

# docker-tag: docker-build
# 	docker tag telesoho/odoo telesoho/odoo:${GITHUB_SHA}
# 	docker tag telesoho/odoo:latest telesoho/odoo:${GITHUB_SHA}-newrelic


docker-push: docker-tag docker-auth ## push to docker hub
	docker push 'telesoho/odoo:latest'
	docker push "openedx/odoo:${GITHUB_SHA}"
	docker push 'openedx/odoo:latest-newrelic'
	docker push "openedx/odoo:${GITHUB_SHA}-newrelic"

shell: ## launch a bash shell in a Docker container with all edx-platform dependencies installed
	docker run -it -e "NO_PYTHON_UNINSTALL=1" -e "PIP_INDEX_URL=https://pypi.python.org/simple" -e TERM \
	-v `pwd`:/edx/app/edxapp/edx-platform:cached \
	-v edxapp_lms_assets:/edx/var/edxapp/staticfiles/ \
	-v edxapp_node_modules:/edx/app/edxapp/edx-platform/node_modules \
	edxops/edxapp:latest /edx/app/edxapp/devstack.sh open
