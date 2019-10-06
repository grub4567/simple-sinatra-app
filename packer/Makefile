#
# Packer Makefile
#

.PHONY: main
main: build

# Run the Packer template.
# The host's external IP is passed as an argument to the Packer template so that Packer can
# configure the appropriate AWS security group to only allow SSH access from the host's IP.
# The Packer output is also teed into a file so it can be reviewed later.
.PHONY: build
build:
	packer build \
		-var=host_ip=$(shell curl --silent api.ipify.org) \
		-force \
		packer.json \
		| tee output

# Clean up the output.
.PHONY: clean
clean:
	rm -rf output*

# Run shellcheck against any shell scripts.
.PHONY: check
check:
	find -type f -name *.sh | xargs shellcheck
