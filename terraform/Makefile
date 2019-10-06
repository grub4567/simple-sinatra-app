#
# Terraform Makefile
#

workspace ?= development

.PHONY: main
main: apply

.PHONY: init
init:
	terraform init

.PHONY: workspace.new
workspace.new:
	terraform workspace new $(workspace)

.PHONY: workspace.select
workspace.select:
	terraform workspace select $(workspace)

.PHONY: plan
plan: workspace.select
	terraform plan -var-file=$(workspace).tfvars

.PHONY: apply
apply: workspace.select
	terraform apply -var-file=$(workspace).tfvars

.PHONY: destory
destory: workspace.select
	terraform destroy -var-file=$(workspace).tfvars
