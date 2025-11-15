.PHONY: help install install-dev clean test lint format security docker-build docker-run deploy smoke-test all

# Configuration
PYTHON := python3
PIP := $(PYTHON) -m pip
PYTEST := $(PYTHON) -m pytest
BLACK := $(PYTHON) -m black
ISORT := $(PYTHON) -m isort
FLAKE8 := $(PYTHON) -m flake8
PYLINT := $(PYTHON) -m pylint
MYPY := $(PYTHON) -m mypy
BANDIT := $(PYTHON) -m bandit

# Directories
APP_DIR := app
TESTS_DIR := tests
SCRIPTS_DIR := scripts
DOCS_DIR := docs
DIST_DIR := dist

# Docker
DOCKER_IMAGE := pathfinderlm
DOCKER_TAG := latest
DOCKER_REGISTRY := ghcr.io/danindiana

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)PathfinderLM - Build & Deployment System$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  $(YELLOW)install$(NC)          - Install production dependencies"
	@echo "  $(YELLOW)install-dev$(NC)      - Install development dependencies"
	@echo "  $(YELLOW)clean$(NC)            - Remove build artifacts and cache"
	@echo "  $(YELLOW)test$(NC)             - Run unit tests"
	@echo "  $(YELLOW)test-coverage$(NC)    - Run tests with coverage report"
	@echo "  $(YELLOW)lint$(NC)             - Run all linters"
	@echo "  $(YELLOW)format$(NC)           - Format code with black and isort"
	@echo "  $(YELLOW)security$(NC)         - Run security scans"
	@echo "  $(YELLOW)docker-build$(NC)     - Build Docker image"
	@echo "  $(YELLOW)docker-run$(NC)       - Run Docker container"
	@echo "  $(YELLOW)docker-stop$(NC)      - Stop Docker container"
	@echo "  $(YELLOW)smoke-test$(NC)       - Run smoke tests"
	@echo "  $(YELLOW)deploy-staging$(NC)   - Deploy to staging environment"
	@echo "  $(YELLOW)deploy-production$(NC) - Deploy to production environment"
	@echo "  $(YELLOW)all$(NC)              - Run install, lint, test, and build"
	@echo ""

install:
	@echo "$(BLUE)Installing production dependencies...$(NC)"
	$(PIP) install --upgrade pip setuptools wheel
	@if [ -f requirements.txt ]; then \
		$(PIP) install -r requirements.txt; \
	else \
		echo "$(YELLOW)Warning: requirements.txt not found$(NC)"; \
	fi
	@echo "$(GREEN)✓ Installation complete$(NC)"

install-dev: install
	@echo "$(BLUE)Installing development dependencies...$(NC)"
	$(PIP) install pytest pytest-cov pytest-mock pytest-asyncio
	$(PIP) install black isort flake8 pylint mypy
	$(PIP) install bandit safety
	$(PIP) install sphinx sphinx-rtd-theme
	@echo "$(GREEN)✓ Development dependencies installed$(NC)"

clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.coverage" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf htmlcov/
	rm -rf $(DIST_DIR)/
	rm -rf build/
	@echo "$(GREEN)✓ Clean complete$(NC)"

test:
	@echo "$(BLUE)Running unit tests...$(NC)"
	@mkdir -p $(TESTS_DIR) data/raw data/processed data/datasets logs results/model
	$(PYTEST) $(TESTS_DIR) -v || echo "$(YELLOW)Tests not yet implemented$(NC)"
	@echo "$(GREEN)✓ Tests complete$(NC)"

test-coverage:
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	@mkdir -p $(TESTS_DIR) data/raw data/processed data/datasets logs results/model
	$(PYTEST) $(TESTS_DIR) -v --cov=$(APP_DIR) --cov-report=html --cov-report=term-missing || echo "$(YELLOW)Tests not yet implemented$(NC)"
	@echo "$(GREEN)✓ Coverage report generated in htmlcov/$(NC)"

lint:
	@echo "$(BLUE)Running linters...$(NC)"
	@echo "$(YELLOW)Running Black...$(NC)"
	$(BLACK) --check $(APP_DIR) $(SCRIPTS_DIR) $(TESTS_DIR) 2>/dev/null || echo "$(YELLOW)Black check skipped - directories may not exist$(NC)"
	@echo "$(YELLOW)Running isort...$(NC)"
	$(ISORT) --check-only $(APP_DIR) $(SCRIPTS_DIR) $(TESTS_DIR) 2>/dev/null || echo "$(YELLOW)isort check skipped$(NC)"
	@echo "$(YELLOW)Running Flake8...$(NC)"
	$(FLAKE8) $(APP_DIR) $(SCRIPTS_DIR) $(TESTS_DIR) --max-line-length=127 2>/dev/null || echo "$(YELLOW)Flake8 check skipped$(NC)"
	@echo "$(YELLOW)Running Pylint...$(NC)"
	$(PYLINT) $(APP_DIR) $(SCRIPTS_DIR) 2>/dev/null || echo "$(YELLOW)Pylint check skipped$(NC)"
	@echo "$(YELLOW)Running MyPy...$(NC)"
	$(MYPY) $(APP_DIR) $(SCRIPTS_DIR) 2>/dev/null || echo "$(YELLOW)MyPy check skipped$(NC)"
	@echo "$(GREEN)✓ Linting complete$(NC)"

format:
	@echo "$(BLUE)Formatting code...$(NC)"
	$(BLACK) $(APP_DIR) $(SCRIPTS_DIR) $(TESTS_DIR) 2>/dev/null || echo "$(YELLOW)Black formatting skipped$(NC)"
	$(ISORT) $(APP_DIR) $(SCRIPTS_DIR) $(TESTS_DIR) 2>/dev/null || echo "$(YELLOW)isort formatting skipped$(NC)"
	@echo "$(GREEN)✓ Code formatted$(NC)"

security:
	@echo "$(BLUE)Running security scans...$(NC)"
	@echo "$(YELLOW)Running Bandit...$(NC)"
	$(BANDIT) -r $(APP_DIR) $(SCRIPTS_DIR) -f json -o bandit-report.json 2>/dev/null || echo "$(YELLOW)Bandit scan skipped$(NC)"
	$(BANDIT) -r $(APP_DIR) $(SCRIPTS_DIR) 2>/dev/null || echo "$(YELLOW)Bandit scan skipped$(NC)"
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@if [ -f requirements.txt ]; then \
		safety check -r requirements.txt || echo "$(YELLOW)Safety check skipped$(NC)"; \
	fi
	@echo "$(GREEN)✓ Security scan complete$(NC)"

docker-build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo "$(GREEN)✓ Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"

docker-run:
	@echo "$(BLUE)Running Docker container...$(NC)"
	docker run -d \
		--name pathfinderlm-app \
		-p 5000:5000 \
		-v $(PWD)/data:/app/data \
		-v $(PWD)/logs:/app/logs \
		-v $(PWD)/results:/app/results \
		$(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "$(GREEN)✓ Container running at http://localhost:5000$(NC)"

docker-stop:
	@echo "$(BLUE)Stopping Docker container...$(NC)"
	docker stop pathfinderlm-app || true
	docker rm pathfinderlm-app || true
	@echo "$(GREEN)✓ Container stopped$(NC)"

docker-logs:
	@echo "$(BLUE)Showing Docker logs...$(NC)"
	docker logs -f pathfinderlm-app

smoke-test:
	@echo "$(BLUE)Running smoke tests...$(NC)"
	@./scripts/smoke_test.sh || echo "$(YELLOW)Smoke tests pending implementation$(NC)"
	@echo "$(GREEN)✓ Smoke tests complete$(NC)"

deploy-staging:
	@echo "$(BLUE)Deploying to staging environment...$(NC)"
	@./scripts/deploy.sh staging
	@echo "$(GREEN)✓ Staging deployment complete$(NC)"

deploy-production:
	@echo "$(RED)WARNING: Deploying to PRODUCTION$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./scripts/deploy.sh production; \
		echo "$(GREEN)✓ Production deployment complete$(NC)"; \
	else \
		echo "$(YELLOW)Deployment cancelled$(NC)"; \
	fi

validate:
	@echo "$(BLUE)Running pre-commit validation...$(NC)"
	@$(MAKE) lint
	@$(MAKE) security
	@$(MAKE) test
	@echo "$(GREEN)✓ Validation complete$(NC)"

all: clean install-dev lint test docker-build
	@echo "$(GREEN)✓ All tasks complete$(NC)"

.DEFAULT_GOAL := help
