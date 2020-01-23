APP_NAME=ocp4-openscap-content
NAMESPACE=openshift-compliance

REPO?=quay.io/jhrozek
CNT_RUNTIME?=podman

CONTENT_REPO?=https://github.com/ComplianceAsCode/content
CONTENT_BRANCH?=$(shell git rev-parse --abbrev-ref HEAD)
TAG?=latest

all: build

.PHONY: build
build:
	$(CNT_RUNTIME) build --build-arg=repo=${CONTENT_REPO} --build-arg=branch=${CONTENT_BRANCH} -f Dockerfile -t $(APP_NAME):$(TAG)

.PHONY: build-nocache
build-nocache:
	$(CNT_RUNTIME) build --build-arg=repo=${CONTENT_REPO} --build-arg=branch=${CONTENT_BRANCH} --no-cache -f Dockerfile -t $(APP_NAME):$(TAG)

.PHONY: build-dev
build-dev: check-content-path
	$(eval CONTENT_NAME = $(notdir ${CONTENT_PATH}))
	cp $(CONTENT_PATH) $(CONTENT_NAME)
	-$(CNT_RUNTIME) build --build-arg=content=${CONTENT_NAME} -f Dockerfile.dev -t $(APP_NAME):$(TAG)
	rm -f $(CONTENT_NAME)

.PHONY: check-content-path
check-content-path:
ifndef CONTENT_PATH
	$(error CONTENT_PATH is undefined)
endif

.PHONY: tag
tag:
	$(CNT_RUNTIME) tag $(APP_NAME) $(REPO)/$(APP_NAME):$(TAG)

.PHONY: tag-latest
tag-latest:
	$(CNT_RUNTIME) tag $(APP_NAME) $(REPO)/$(APP_NAME):latest

.PHONY: tag-branch
tag-branch:
	$(CNT_RUNTIME) tag $(APP_NAME) $(REPO)/$(APP_NAME):$(CONTENT_BRANCH)

.PHONY: push
push:
	$(CNT_RUNTIME) push $(APP_NAME) $(REPO)/$(APP_NAME):$(TAG)

.PHONY: push-latest
push-latest:
	$(CNT_RUNTIME) push $(REPO)/$(APP_NAME):latest

.PHONY: push-branch
push-branch:
	$(CNT_RUNTIME) push $(APP_NAME) $(REPO)/$(APP_NAME):$(CONTENT_BRANCH)

.PHONY: image-to-cluster
image-to-cluster: openshift-user check-from check-to
	@echo "Temporarily exposing the default route to the image registry"
	@oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
	@echo "Pushing image $(REPO)/$(APP_NAME):$(TAG) to the image registry"
	IMAGE_REGISTRY_HOST=$$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}'); \
		$(CNT_RUNTIME) login --tls-verify=false -u $(OPENSHIFT_USER) -p $(shell oc whoami -t) $${IMAGE_REGISTRY_HOST}; \
		$(CNT_RUNTIME) push --tls-verify=false $(FROM) $${IMAGE_REGISTRY_HOST}/$(NAMESPACE)/$(TO);
	@echo "Removing the route from the image registry"
	@oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":false}}' --type=merge
	$(eval IMAGE_PATH = image-registry.openshift-image-registry.svc:5000/$(NAMESPACE)/$(APP_NAME):$(TAG))

.PHONY: check-from
check-from:
ifndef FROM
	$(error FROM is undefined. See README.md for examples)
endif

.PHONY: check-to
check-to:
ifndef TO
	$(error TO is undefined. See README.md for examples)
endif


.PHONY: openshift-user
openshift-user:
ifeq ($(shell oc whoami 2> /dev/null),kube:admin)
	$(eval OPENSHIFT_USER = kubeadmin)
else
	$(eval OPENSHIFT_USER = $(oc whoami))
endif

