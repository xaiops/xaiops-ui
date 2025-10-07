# xAIOps UI - Container Build and Deploy Makefile

# Variables
IMAGE_NAME = xaiops-ui
IMAGE_TAG = latest
REGISTRY ?= quay.io/rbrhssa
NAMESPACE ?= xaiops-ui
APP_NAME = xaiops-ui

# Default target
.PHONY: help
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Build targets
.PHONY: build
build: ## Build container image with Podman
	podman build -t $(IMAGE_NAME):$(IMAGE_TAG) -f Containerfile .

.PHONY: build-docker
build-docker: ## Build container image with Docker
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) -f Containerfile .

# Local run targets
.PHONY: run
run: ## Run container locally with Podman
	podman run -d --name $(APP_NAME) \
		-p 8080:8080 \
		-e NODE_ENV=production \
		-e LANGGRAPH_API_URL=https://your-api.example.com \
		$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: run-docker
run-docker: ## Run container locally with Docker
	docker run -d --name $(APP_NAME) \
		-p 8080:8080 \
		-e NODE_ENV=production \
		-e LANGGRAPH_API_URL=https://your-api.example.com \
		$(IMAGE_NAME):$(IMAGE_TAG)

# Registry targets
.PHONY: tag
tag: ## Tag image for registry
	podman tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: push
push: tag ## Push image to registry
	podman push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# OpenShift targets
.PHONY: oc-login
oc-login: ## Login to OpenShift (requires OC_SERVER and OC_TOKEN env vars)
	@if [ -z "$$OC_SERVER" ] || [ -z "$$OC_TOKEN" ]; then \
		echo "Please set OC_SERVER and OC_TOKEN environment variables"; \
		exit 1; \
	fi
	oc login $$OC_SERVER --token=$$OC_TOKEN

.PHONY: oc-create-project
oc-create-project: ## Create OpenShift project
	oc new-project $(NAMESPACE) --display-name="xAIOps UI" || oc project $(NAMESPACE)

.PHONY: oc-deploy
oc-deploy: ## Deploy to OpenShift
	@echo "Applying Kubernetes manifests..."
	oc apply -f k8s/deployment.yaml
	oc apply -f k8s/route.yaml

.PHONY: oc-config
oc-config: ## Create/update application configuration
	@echo "Creating ConfigMap..."
	@if [ -z "$$LANGGRAPH_API_URL" ]; then \
		echo "Please set LANGGRAPH_API_URL environment variable"; \
		exit 1; \
	fi
	oc create configmap app-config \
		--from-literal=langgraph-api-url=$$LANGGRAPH_API_URL \
		--from-literal=api-base-url=$${API_BASE_URL:-} \
		--dry-run=client -o yaml | oc apply -f -

.PHONY: oc-full-deploy
oc-full-deploy: oc-create-project oc-config oc-deploy ## Full OpenShift deployment (project + config + deploy)

# Status and management targets
.PHONY: status
status: ## Show local container status
	@echo "=== Podman Status ==="
	podman ps -a --filter name=$(APP_NAME) 2>/dev/null || echo "No containers found"
	@echo ""
	@echo "=== Docker Status ==="
	docker ps -a --filter name=$(APP_NAME) 2>/dev/null || echo "No containers found"

.PHONY: oc-status
oc-status: ## Show OpenShift deployment status
	@echo "=== OpenShift Status ==="
	@echo "Namespace: $$(oc project -q)"
	@echo ""
	@echo "Deployments:"
	oc get deployments -l app=$(APP_NAME)
	@echo ""
	@echo "Pods:"
	oc get pods -l app=$(APP_NAME)
	@echo ""
	@echo "Services:"
	oc get services -l app=$(APP_NAME)
	@echo ""
	@echo "Routes:"
	oc get routes -l app=$(APP_NAME)
	@echo ""
	@echo "Application URL:"
	@oc get route $(APP_NAME)-route -o jsonpath='{.spec.host}' 2>/dev/null && echo "" || echo "Route not found"

.PHONY: logs
logs: ## Show local container logs
	podman logs $(APP_NAME) 2>/dev/null || docker logs $(APP_NAME) 2>/dev/null || echo "No container logs found"

.PHONY: oc-logs
oc-logs: ## Show OpenShift pod logs
	oc logs -l app=$(APP_NAME) --tail=100 -f

# Cleanup targets
.PHONY: clean
clean: ## Clean up local containers
	@echo "Stopping and removing local containers..."
	podman stop $(APP_NAME) 2>/dev/null || true
	podman rm $(APP_NAME) 2>/dev/null || true
	docker stop $(APP_NAME) 2>/dev/null || true
	docker rm $(APP_NAME) 2>/dev/null || true

.PHONY: clean-images
clean-images: ## Remove local images
	podman rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true

.PHONY: oc-clean
oc-clean: ## Clean up OpenShift resources
	@echo "Removing OpenShift resources..."
	oc delete -f k8s/ --ignore-not-found=true
	oc delete configmap app-config --ignore-not-found=true

# Development targets
.PHONY: dev-build-run
dev-build-run: build run ## Build and run locally for development

.PHONY: dev-test
dev-test: ## Test the application locally
	@echo "Testing health endpoint..."
	curl -s http://localhost:8080/api/health | jq . || echo "Health check failed or jq not installed"
	@echo ""
	@echo "Testing main page..."
	curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/

# Environment-specific targets
.PHONY: staging-deploy
staging-deploy: ## Deploy to staging environment
	$(MAKE) oc-full-deploy NAMESPACE=xaiops-ui-staging

.PHONY: prod-deploy  
prod-deploy: ## Deploy to production environment
	$(MAKE) oc-full-deploy NAMESPACE=xaiops-ui-prod

# Scale targets
.PHONY: oc-scale-up
oc-scale-up: ## Scale up to 3 replicas
	oc scale deployment/$(APP_NAME) --replicas=3

.PHONY: oc-scale-down
oc-scale-down: ## Scale down to 1 replica
	oc scale deployment/$(APP_NAME) --replicas=1
