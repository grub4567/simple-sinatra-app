#

.PHONY: main
main: build

.PHONY: build
build:
	packer build \
		-var=host_ip=$(shell curl --silent api.ipify.org) \
		-force \
		packer.json \
		| tee output

.PHONY: clean
clean:
	rm -rf output*

.PHONY: check
check:
	find -type f -name *.sh | xargs shellcheck
