SHELL := /bin/bash

# Do things in edx-platform
.PHONY: clean help pull pull-odoo install-docker install-docker-buildx 

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))

ifndef ODOO_COMMIT_ID 
ODOO_COMMIT_ID:=15.0
endif

ifndef TAG
TAG:=odoo15
endif

ifndef PLATFORM 
PLATFORM:=linux/amd64,linux/arm64
endif


BUILD_DIR:=./${TAG}/build
ODOO_TGZ:=${BUILD_DIR}/odoo.tgz
SHA1SUM_FILE:=${ODOO_TGZ}.sha1sum

ifndef DOCKER_REGISTRY
DOCKER_REGISTRY:=192.168.10.100:5000
endif

ifndef ODOO_SHA
OLD_ODOO_SHA:=$(firstword $(shell sha1sum "${ODOO_TGZ}"))
endif

COMMA:=,

# Careful with mktemp syntax: it has to work on Mac and Ubuntu, which have differences.
PRIVATE_FILES := $(shell mktemp -u /tmp/private_files.XXXXXX)

log_success = (echo -e "\x1B[32m>> $1\x1B[39m")
log_error = (>&2 echo -e "\x1B[31m>> $1\x1B[39m" && exit 1)

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

.env-export: .env
	sed -ne '/^export / {p;d}; /.*=/ s/^/export / p' .env > .env-export

install-docker: ## Install docker
	sudo apt-get update; sudo apt-get upgrade -y
	sudo apt-get instal docker docker-compose
	sudo groupadd docker
	sudo usermod -aG docker ${USER}
	@read -t 10 -p "Hit ENTER or wait ten seconds to reboot(CTL+C to cancle)"
	sudo reboot

install-docker-buildx: ## Install docker buildx for muti-platform build.
	mkdir -p ~/.docker/cli-plugins
	curl -o ~/.docker/cli-plugins/docker-buildx -L "https://github.com/docker/buildx/releases/download/v0.6.3/buildx-v0.6.3.linux-$(dpkg --print-architecture)"
	chmod a+x ~/.docker/cli-plugins/docker-buildx
	sudo mkdir -p /etc/docker/
	sudo systemctl stop docker.socket
	sudo systemctl stop docker
	echo '{"registry-mirrors":["https://registry.cn-hangzhou.aliyuncs.com"]}' > daemon.json
	sudo mv daemon.json /etc/docker/
	sudo systemctl daemon-reload
	sudo systemctl restart docker
	docker run --privileged --rm tonistiigi/binfmt --install all
	docker buildx create --name odoobuilder --driver docker-container --platform linux/amd64,linux/arm64 --use
	docker buildx ls
	docker buildx inspect --bootstrap

pull-odoo:
	mkdir -p ${BUILD_DIR}
	curl -o "${ODOO_TGZ}" -L https://github.com/odoo/odoo/tarball/${ODOO_COMMIT_ID}
	sha1sum "${ODOO_TGZ}" > ${SHA1SUM_FILE}
	if [[ z"${ODOO_SHA}" != z"" ]] ; then  echo "${ODOO_SHA} ${ODOO_TGZ}" | sha1sum -c --quiet - || $(call log_error, "odoo source sha1sum check failed"); fi

docker-build: ## These make targets currently only build LMS images.
	if [ z"${ODOO_SHA}" != z"" ] && [ "${OLD_ODOO_SHA}" != "${ODOO_SHA}" ] ; then make pull-odoo; else if ! cat "${SHA1SUM_FILE}" | sha1sum -c --quiet -; then make pull-odoo ;fi ; fi
	echo "TAG:${TAG} ODOO_COMMIT_ID=${ODOO_COMMIT_ID} ODOO_SHA=$(firstword ${ODOO_SHA} $(shell cat "${SHA1SUM_FILE}")) PLATFORM:${PLATFORM}"
	docker buildx build ./${TAG} -t ${DOCKER_REGISTRY}/odoo:${TAG} --build-arg TAG=${TAG} --platform=${PLATFORM} --push # > ./build/job.log 2>&1 &

docker-pull: ## update the Docker image used by "make shell"
	docker pull ${DOCKER_REGISTRY}/odoo:${TAG}

docker-auth: ## login docker
	echo "$$DOCKERHUB_PASSWORD" | docker login -u "$$DOCKERHUB_USERNAME" --password-stdin

docker-push: ## push to docker hub
	docker push ${DOCKER_REGISTRY}/odoo:${TAG}	

shell: ## launch a bash shell in a Docker container with all edx-platform dependencies installed
	docker run -it -e "NO_PYTHON_UNINSTALL=1" -e "PIP_INDEX_URL=https://pypi.python.org/simple" -e TERM \
	-v `pwd`:/edx/app/edxapp/edx-platform:cached \
	-v edxapp_lms_assets:/edx/var/edxapp/staticfiles/ \
	-v edxapp_node_modules:/edx/app/edxapp/edx-platform/node_modules \
	edxops/edxapp:latest /edx/app/edxapp/devstack.sh open
