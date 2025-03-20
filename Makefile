.PHONY: init plan apply destroy test lint format build-containers push-containers test-pdf test-excel test-all clean

# Variables
ENV ?= dev
TF_DIR = infrastructure/environments/$(ENV)
TF_VARS = -var-file=$(TF_DIR)/terraform.tfvars
CONTAINER_REGISTRY ?= 

# AWS Account ID detection
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION ?= us-east-1

# Infrastructure commands
init:
	@echo "Initializing Terraform..."
	cd $(TF_DIR) && terraform init

plan:
	@echo "Planning Terraform deployment..."
	cd $(TF_DIR) && terraform plan $(TF_VARS)

apply:
	@echo "Applying Terraform changes..."
	cd $(TF_DIR) && terraform apply $(TF_VARS)

destroy:
	@echo "Destroying infrastructure..."
	cd $(TF_DIR) && terraform destroy $(TF_VARS)

# Code quality commands
lint:
	@echo "Linting Python code..."
	find . -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" | xargs pylint
	@echo "Linting Terraform code..."
	cd infrastructure && terraform fmt -check -recursive

format:
	@echo "Formatting Python code..."
	find . -name "*.py" -not -path "*/\.*" -not -path "*/venv/*" | xargs black
	@echo "Formatting Terraform code..."
	cd infrastructure && terraform fmt -recursive

# Container build commands
build-containers:
	@echo "Building all containers..."
	for dir in containers/*; do \
		if [ -f $$dir/Dockerfile ]; then \
			echo "Building $$dir container..."; \
			docker build -t $(PROJECT_NAME)-$$(basename $$dir):latest $$dir; \
		fi \
	done

push-containers:
	@echo "Logging in to ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	@echo "Pushing all containers to ECR..."
	for dir in containers/*; do \
		if [ -f $$dir/Dockerfile ]; then \
			container=$$(basename $$dir); \
			echo "Tagging and pushing $$container container..."; \
			docker tag $(PROJECT_NAME)-$$container:latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(PROJECT_NAME)-$(ENV)-$$container:latest; \
			docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(PROJECT_NAME)-$(ENV)-$$container:latest; \
		fi \
	done

# Test commands
test:
	@echo "Running unit tests..."
	python -m pytest -xvs lambda/*/tests containers/*/tests

integration-test:
	@echo "Running integration tests..."
	python -m pytest -xvs tests/integration

test-pdf:
	@echo "Testing PDF processing pipeline..."
	python -m pytest -xvs tests/integration/test_pdf_pipeline.py

test-excel:
	@echo "Testing Excel processing pipeline..."
	python -m pytest -xvs tests/integration/test_excel_pipeline.py

test-all: test integration-test
	@echo "All tests completed."

# Utility commands
setup-dev:
	@echo "Setting up development environment..."
	python -m pip install -r requirements-dev.txt
	pre-commit install

clean:
	@echo "Cleaning up build artifacts..."
	find . -name "__pycache__" -type d -exec rm -rf {} +
	find . -name "*.pyc" -delete
	find . -name ".pytest_cache" -type d -exec rm -rf {} +
	find . -name ".coverage" -delete
	find . -name "*.egg-info" -type d -exec rm -rf {} +

# Deployment script - combines multiple steps
deploy: init build-containers push-containers apply
	@echo "Deployment completed successfully!"

# Help command
help:
	@echo "Document Processing Pipeline Makefile"
	@echo ""
	@echo "Available commands:"
	@echo "  make init              - Initialize Terraform"
	@echo "  make plan              - Plan Terraform deployment"
	@echo "  make apply             - Apply Terraform changes"
	@echo "  make destroy           - Destroy infrastructure"
	@echo "  make lint              - Lint Python and Terraform code"
	@echo "  make format            - Format Python and Terraform code"
	@echo "  make build-containers  - Build all Docker containers"
	@echo "  make push-containers   - Push containers to ECR"
	@echo "  make test              - Run unit tests"
	@echo "  make integration-test  - Run integration tests"
	@echo "  make test-pdf          - Test PDF processing pipeline"
	@echo "  make test-excel        - Test Excel processing pipeline"
	@echo "  make test-all          - Run all tests"
	@echo "  make setup-dev         - Set up development environment"
	@echo "  make clean             - Clean build artifacts"
	@echo "  make deploy            - Run full deployment"
	@echo ""
	@echo "Environment variables:"
	@echo "  ENV                    - Environment (dev, staging, prod) [default: dev]"
	@echo "  AWS_REGION             - AWS region [default: us-east-1]"
	@echo ""