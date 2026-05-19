# LAB-08-B — Cross-Region Disaster Recovery (Terraform)
# See README.md for full walkthrough.

.PHONY: setup validate teardown

TFVARS ?= terraform.tfvars

setup:
	@echo "=== Terraform Init ==="
	terraform init
	@echo "=== Terraform Apply (interactive) ==="
	terraform apply -var-file="$(TFVARS)"

validate:
	@echo "=== Terraform Validate ==="
	terraform validate
	@echo "=== Terraform Plan ==="
	terraform plan -var-file="$(TFVARS)"

teardown:
	@echo "=== Terraform Destroy ==="
	terraform destroy -var-file="$(TFVARS)"
