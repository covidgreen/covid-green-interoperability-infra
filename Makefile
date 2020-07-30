.ONESHELL:
.SHELL := /bin/bash


# #########################################
# Shell swag
# #########################################
GREEN = \033[1;32m
RESET = \033[0m
WHITE = \033[1;38;5;231m


# #########################################
# Environment variables defaults
# #########################################
ENVIRONMENT ?=
PROJECT_KEY ?=


# #########################################
# Make target aliases
# #########################################
MAKE_TF_INIT = $(MAKE) --no-print-directory internal-init
MAKE_TF_PLAN = $(MAKE) --no-print-directory internal-plan
MAKE_TF_APPLY = $(MAKE) --no-print-directory internal-apply


# #########################################
# Commands args
# #########################################
PROJECT_ENVIRONMENT_KEY = interop-$(ENVIRONMENT)
PROJECT_ENVIRONMENT_TFVAR_FILE = env-vars/$(ENVIRONMENT).tfvars
TERRAFORM_PLAN_FILE = terraform-$(ENVIRONMENT).tfplan

# Lets use profiles that use this convention
AWS_PROFILE = $(PROJECT_ENVIRONMENT_KEY)

# Determine from tf vars file - will use the first match
AWS_REGION = $(shell grep '^aws_region' $(PROJECT_ENVIRONMENT_TFVAR_FILE) | head -n 1 | cut -d '"' -f 2)

# Derive these using a convention
TERRAFORM_BACKEND_BUCKET ?= $(PROJECT_ENVIRONMENT_KEY)-terraform-store
TERRAFORM_BACKEND_KEY ?= $(PROJECT_KEY)
TERRAFORM_BACKEND_TABLE ?= $(PROJECT_ENVIRONMENT_KEY)-terraform-lock


# #########################################
# interop targets
# #########################################
# QA
.PHONY: qa-init qa-plan qa-apply
qa-init:
	@$(MAKE_TF_INIT) ENVIRONMENT=qa PROJECT_KEY=interop
qa-plan:
	@$(MAKE_TF_PLAN) ENVIRONMENT=qa PROJECT_KEY=interop
qa-apply:
	@$(MAKE_TF_APPLY) ENVIRONMENT=qa PROJECT_KEY=interop

# PROD
.PHONY: prod-init prod-plan prod-apply
prod-init:
	@$(MAKE_TF_INIT) ENVIRONMENT=prod PROJECT_KEY=interop
prod-plan:
	@$(MAKE_TF_PLAN) ENVIRONMENT=prod PROJECT_KEY=interop
prod-apply:
	@$(MAKE_TF_APPLY) ENVIRONMENT=prod PROJECT_KEY=interop


# #########################################
# Generic targets - not dependant on a project
# #########################################
.PHONY: update validate format
update:
	@echo "$(WHITE)==> Updating modules - $(GREEN)terraform get$(RESET)"
	terraform get -update

validate:
	@echo "$(WHITE)==> Validate terraform code - $(GREEN)terraform validate$(RESET)"
	terraform validate

format:
	@echo "$(WHITE)==> Format terraform code - $(GREEN)terraform fmt$(RESET)"
	terraform fmt -recursive


# #########################################
# internal targets - don't expect these to be invoked directly
# #########################################
.PHONY: internal-init internal-plan internal-apply
internal-init:
	@echo "$(WHITE)==> Setting up environment - $(GREEN)$(PROJECT_ENVIRONMENT_KEY)$(WHITE) in $(GREEN)$(AWS_REGION)$(RESET) using AWS profile $(GREEN)$(AWS_PROFILE)$(RESET), S3 bucket $(GREEN)$(TERRAFORM_BACKEND_BUCKET)$(RESET) and DynamoDB table $(GREEN)$(TERRAFORM_BACKEND_TABLE)$(RESET)"
	terraform init -get=true \
		-upgrade=true \
		-input=false \
		-lock=true \
		-reconfigure \
		-backend=true \
		-backend-config="region=$(AWS_REGION)" \
		-backend-config="dynamodb_table=$(TERRAFORM_BACKEND_TABLE)" \
		-backend-config="bucket=$(TERRAFORM_BACKEND_BUCKET)" \
		-backend-config="key=$(PROJECT_KEY)" \
		-backend-config="profile=$(AWS_PROFILE)"

internal-plan:
	@echo "$(WHITE)==> Planning changes - $(GREEN)$(PROJECT_ENVIRONMENT_KEY) - terraform plan$(RESET)"
	terraform plan -out $(TERRAFORM_PLAN_FILE) -var-file $(PROJECT_ENVIRONMENT_TFVAR_FILE)

internal-apply:
	@echo "$(WHITE)==> Applying changes - $(GREEN)$(PROJECT_ENVIRONMENT_KEY) - terraform apply$(RESET)"
	terraform apply -parallelism=10 $(TERRAFORM_PLAN_FILE)
