DEV_DIR := development
PRD_DIR := production

.PHONY: fmt
fmt:
	cd $(DEV_DIR) && terraform fmt
	cd $(PRD_DIR) && terraform fmt

.PHONY: dev-plan
dev-plan:
	cd $(DEV_DIR) && terraform plan

.PHONY: dev-apply
dev-apply:
	cd $(DEV_DIR) && terraform apply

.PHONY: prd-plan
prd-plan:
	cd $(PRD_DIR) && terraform plan

.PHONY: prd-apply
prd-apply:
	cd $(PRD_DIR) && terraform apply
