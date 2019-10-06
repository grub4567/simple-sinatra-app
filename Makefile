#
# Makefile
#

.PHONY: packer
packer:
	$(MAKE) -C packer build

.PHONY: terraform
terraform:
	$(MAKE) -C terraform apply

.PHONY: terraform.destroy
terraform.destroy:
	$(MAKE) -C terraform destroy
