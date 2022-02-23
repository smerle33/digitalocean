# Disable CGO to avoid error "cgo: exec /missing-cc: fork/exec /missing-cc: no such file or directory"
# Ref. https://golang.org/cmd/cgo/
export CGO_ENABLED=0

BACKEND_CONFIG_FILE ?= $(CURDIR)/backend-config

help: ## Show this Makefile's help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

prepare: ## Prepare Terraform's environment by downloading and initializing its plugins and backends
	make -C $(CURDIR) .terraform/plugins/selections.json

validate: lint .terraform/plugins/selections.json ## Validate the terraform files of the current project. Might executes "make prepare" if required.
	@terraform validate
	@tfsec --exclude-downloaded-modules

lint: ## Lint the project files
	@terraform fmt -recursive -check

lint-tests: ## Lint the testings files
	@test -z "$(go fmt -l $(CURDIR)/tests/)"
	@cd $(CURDIR)/tests/ && golangci-lint run

tests: .terraform/plugins/selections.json lint-tests ## Execute the test harness
	@cd $(CURDIR)/tests/ && go test -v -timeout 30m

plan: lint .terraform/plugins/selections.json ## Deploy (apply) the terraform changes to production
	@terraform plan -compact-warnings -lock=false -no-color > terraform-plan-for-humans.txt
	@echo "Terraform plan output can be checked under the file ./terraform-plan-for-humans.txt"

deploy: lint .terraform/plugins/selections.json ## Deploy (apply) the terraform changes to production
	@terraform apply -auto-approve

clean: ## Remove any temporary artefacts generated by this Makefile
	@rm -rf $(CURDIR)/.terraform $(CURDIR)/kubeconfig*

.PHONY: clean validate prepare help tests plan deploy lint lint-tests

.terraform/plugins/selections.json:
	@terraform init -backend-config=$(BACKEND_CONFIG_FILE)