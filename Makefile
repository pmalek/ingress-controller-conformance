MKDIR_P := mkdir -p
RM_F := rm -rf

export GO111MODULE=on

PROGRAMS := \
	echoserver \
	ingress-controller-conformance \
	ingress-conformance-tests

DEPLOYMENT_YAML := \
	$(wildcard deployments/*.yaml)

build: $(PROGRAMS) ## Build the conformance tool

.PHONY: echoserver
echoserver:
	go build -o $@ tools/echoserver.go

.PHONY: ingress-controller-conformance
ingress-controller-conformance: internal/pkg/assets/assets.go
	go build -o $@ .

internal/pkg/assets/assets.go: $(DEPLOYMENT_YAML)
	@$(MKDIR_P) $$(dirname $@)
	@./hack/go-bindata.sh -pkg assets -o $@ $^

.PHONY: ingress-conformance-tests
ingress-conformance-tests:
	go test -c -o $@ conformance_test.go

.PHONY: clean
clean: ## Remove build artifacts
	$(RM_F) internal/pkg/assets/assets.go
	$(RM_F) $(PROGRAMS)

.PHONY: codegen
codegen: ## Generate or update missing Go code defined in feature files
	@go run hack/codegen.go -update -conformance-path=test/conformance features

.PHONY: verify-codegen
verify-codegen: ## Verify if generated Go code is in sync with feature files
	@go run hack/codegen.go -conformance-path=test/conformance features

.PHONY: help
help: ## Display this help
	@echo Targets:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
