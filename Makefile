SERVICE_NAME := ceph-demo
UTILS_PATH := build-utils

.PHONY: $(SERVICE_NAME) submodules push clean
$(SERVICE_NAME): .state

-include $(UTILS_PATH)/make_lib/utils_repo.mk
PACKER := $(shell which packer 2>/dev/null)

BASE_TAG := latest

COMMIT := $(shell git rev-parse HEAD)
rev = $(shell git rev-parse --abbrev-ref HEAD)
BRANCH := $(shell \
if [[ "${rev}" != "HEAD" ]]; then \
	echo "${rev}" ; \
elif [ -n "${BRANCH_NAME}" ]; then \
	echo "${BRANCH_NAME}"; \
else \
	echo `git name-rev --name-only HEAD`; \
fi)

SUBMODULES := $(UTILS_PATH)
SUBTARGETS := $(patsubst %,%/.git,$(SUBMODULES))

$(SUBTARGETS):
	$(eval SSH_PRIVKEY := $(shell echo $(GITHUB_PRIVKEY) | sed -e 's|%|%%|g'))
	GIT_SSH_COMMAND="$(shell which ssh) -o StrictHostKeyChecking=no -o User=git `[ -n '$(SSH_PRIVKEY)' ] && echo -o IdentityFile='$(SSH_PRIVKEY)'`" \
	git submodule update --init $(basename $@)
	touch $@

submodules: $(SUBTARGETS)

.state: $(PACKER) packer.json files/packer.sh
	$(eval TAG := $(shell git rev-parse HEAD)-$(shell date '+%s'))
	$(PACKER) build -var 'base-tag=$(BASE_TAG)' -var 'image-tag=$(TAG)' packer.json
	printf "FROM $(SERVICE_IMAGE_NAME):$(TAG)\n \
	LABEL com.rbkmoney.$(SERVICE_NAME).parent=ceph/demo \
	com.rbkmoney.$(SERVICE_NAME).parent_tag=$(BASE_TAG) \
	com.rbkmoney.$(SERVICE_NAME).branch=$(BRANCH) \
	com.rbkmoney.$(SERVICE_NAME).commit_id=$(COMMIT) \
	com.rbkmoney.$(SERVICE_NAME).commit_number=`git rev-list --count HEAD`\n \
	ENTRYPOINT /usr/local/bin/ceph-set-env.sh /entrypoint.sh\n \
  EXPOSE 8080\n \
  ENV SERVICE_NAME=ceph-rgw" \
	| docker build -t "$(SERVICE_IMAGE_NAME):$(TAG)" -
	echo $(TAG) > $@

push:
	$(DOCKER) push "$(SERVICE_IMAGE_NAME):$(shell cat .state)"

clean:
	test -f .state \
	&& $(DOCKER) rmi -f "$(SERVICE_IMAGE_NAME):$(shell cat .state)" \
	&& rm .state
