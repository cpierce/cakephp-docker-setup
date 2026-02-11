.DEFAULT_GOAL := help
.PHONY: help prerequisites setup gha destroy

## Show available commands
help:
	@echo ""
	@echo "CakePHP Docker Setup"
	@echo "===================="
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make prerequisites  Check and install prerequisites (Docker, mkcert)"
	@echo "  make setup          Generate a new CakePHP project with Docker"
	@echo "  make destroy        Tear down a generated project (containers, volumes, images, files)"
	@echo "  make gha            Add GitHub Actions to an existing project"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make prerequisites"
	@echo "  2. make setup"
	@echo ""

## Check and install prerequisites via Homebrew
prerequisites:
	@echo "Checking prerequisites..."
	@which brew > /dev/null 2>&1 || (echo "Error: Homebrew is required. Install from https://brew.sh" && exit 1)
	@echo "Checking Docker..."
	@which docker > /dev/null 2>&1 || (echo "Installing Docker..." && brew install --cask docker)
	@echo "Checking Docker Compose..."
	@docker compose version > /dev/null 2>&1 || (echo "Error: Docker Compose is required. Please install Docker Desktop." && exit 1)
	@echo "Checking mkcert..."
	@which mkcert > /dev/null 2>&1 || (echo "Installing mkcert..." && brew install mkcert && mkcert -install)
	@echo ""
	@echo "All prerequisites are installed!"
	@echo ""
	@echo "Installed versions:"
	@docker --version
	@docker compose version
	@mkcert --version 2>&1 || true
	@echo ""
	@echo "Note: PHP and Composer run inside Docker containers - no local install needed."
	@echo ""
	@echo "Next step: make setup"

## Generate a new CakePHP project with Docker setup
setup:
	@./scripts/setup.sh

## Tear down a generated project completely
destroy:
	@read -p "Enter project directory path: " PROJECT_DIR; \
	PROJECT_DIR=$$(cd "$$PROJECT_DIR" && pwd); \
	if [ ! -f "$$PROJECT_DIR/compose.yml" ]; then \
		echo "Error: No compose.yml found in $$PROJECT_DIR"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "This will destroy:"; \
	echo "  - All Docker containers and volumes in $$PROJECT_DIR"; \
	echo "  - The built Docker image"; \
	echo "  - The entire project directory: $$PROJECT_DIR"; \
	echo ""; \
	read -p "Are you sure? [y/N] " CONFIRM; \
	if [ "$$CONFIRM" != "y" ] && [ "$$CONFIRM" != "Y" ]; then \
		echo "Aborted."; \
		exit 0; \
	fi; \
	echo "Stopping and removing containers..."; \
	cd "$$PROJECT_DIR" && docker compose down 2>/dev/null || true; \
	PROJECT_NAME=$$(basename "$$PROJECT_DIR" | sed 's/\./-/g'); \
	echo "Removing Docker image $${PROJECT_NAME}-php..."; \
	docker rmi "$${PROJECT_NAME}-php" 2>/dev/null || true; \
	echo "Removing project directory..."; \
	rm -rf "$$PROJECT_DIR"; \
	echo ""; \
	echo "Done. Project destroyed."

## Generate GitHub Actions files into an existing project
gha:
	@SCRIPT_DIR="$$(pwd)"; \
	read -p "Enter project directory path: " PROJECT_DIR; \
	read -p "Enter domain (e.g. myapp.com): " DOMAIN; \
	PROJECT_DIR=$$(cd "$$PROJECT_DIR" && pwd); \
	mkdir -p "$$PROJECT_DIR/.github/workflows"; \
	sed -e "s|{{DOMAIN}}|$$DOMAIN|g" "$$SCRIPT_DIR/templates/github/main.yml.tpl" > "$$PROJECT_DIR/.github/workflows/main.yml"; \
	cp "$$SCRIPT_DIR/templates/github/dependabot.yml" "$$PROJECT_DIR/.github/dependabot.yml"; \
	cp "$$SCRIPT_DIR/templates/github/ISSUE_TEMPLATE.md" "$$PROJECT_DIR/.github/ISSUE_TEMPLATE.md"; \
	cp "$$SCRIPT_DIR/templates/github/PULL_REQUEST_TEMPLATE.md" "$$PROJECT_DIR/.github/PULL_REQUEST_TEMPLATE.md"; \
	echo ""; \
	echo "GitHub Actions files generated in $$PROJECT_DIR/.github/"; \
	echo ""; \
	echo "Required GitHub Secrets:"; \
	echo "  DB_HOST, DB_USERNAME, DB_PASSWORD, DB_DATABASE"; \
	echo "  SES_USERNAME, SES_PASSWORD"; \
	echo "  DEPLOY_KEY (SSH private key)"; \
	echo ""; \
	echo "Required GitHub Variables:"; \
	echo "  DEPLOY_HOST, DEPLOY_DIR"
