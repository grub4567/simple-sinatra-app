#

environment ?= development

.PHONY: main
main: build

.PHONY: build
build:
	packer build \
		-on-error=cleanup \
		-var-file=$(environment).json \
		-force \
		packer.json \
		| tee output

.PHONY: clean
clean:
	rm -rf output*

.PHONY: check
check:
	find -type f -name *.sh | xargs shellcheck
