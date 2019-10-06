#
# Terraform Makefile
#

# The name of the default Terraform workspace.
workspace ?= development

.PHONY: main
main: apply

# This target will set everything up for using Terraform.
# Initialize Terraform.
# Create a new Terraform workspace if one with the provided doesn't already exist.
# Select the Terraform workspace.
.PHONY: init
init:
	terraform init
	if ! terraform workspace list | grep $(workspace); then \
		terraform workspace new $(workspace); \
	fi
	terraform workspace select $(workspace)

# Run Terraform plan with the variables for the workspace.
.PHONY: plan
plan: init 
	terraform plan -var-file=$(workspace).tfvars

# Run Terraform apply with the variables for the workspace.
.PHONY: init
apply: init
	terraform apply -var-file=$(workspace).tfvars

# Run Terraform destroy with the variables for the workspace.
.PHONY: init
destroy: init
	terraform destroy -var-file=$(workspace).tfvars
