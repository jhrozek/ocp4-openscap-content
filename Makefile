APP_NAME=ocp4-openscap-content

REPO?=quay.io/jhrozek
CNT_RUNTIME?=podman

CONTENT_REPO?=https://github.com/ComplianceAsCode/content
CONTENT_BRANCH?=master

.PHONY: build build-nocache tag-latest tag-branch push-latest push-branch

all: build

build:
	$(CNT_RUNTIME) build --build-arg=repo=${CONTENT_REPO} --build-arg=branch=${CONTENT_BRANCH} -f Dockerfile -t $(APP_NAME)

build-nocache:
	$(CNT_RUNTIME) build --build-arg=repo=${CONTENT_REPO} --build-arg=branch=${CONTENT_BRANCH} --no-cache -f Dockerfile -t $(APP_NAME)

tag-latest:
	$(CNT_RUNTIME) tag $(APP_NAME) $(REPO)/$(APP_NAME):latest

tag-branch:
	$(CNT_RUNTIME) tag $(APP_NAME) $(REPO)/$(APP_NAME):$(shell git rev-parse --abbrev-ref HEAD)

push-latest:
	$(CNT_RUNTIME) push $(REPO)/$(APP_NAME):latest

push-branch:
	$(CNT_RUNTIME) push $(APP_NAME) $(REPO)/$(APP_NAME):$(shell git rev-parse --abbrev-ref HEAD)
