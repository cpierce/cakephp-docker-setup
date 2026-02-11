#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Parse arguments
DOMAIN=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Interactive prompts if not provided via flags
if [ -z "$DOMAIN" ]; then
    printf "${GREEN}Enter domain (e.g. myapp.com): ${NC}"
    read -r DOMAIN
fi

if [ -z "$OUTPUT_DIR" ]; then
    DEFAULT_OUTPUT="../${DOMAIN}"
    printf "${GREEN}Enter output directory [%s]: ${NC}" "$DEFAULT_OUTPUT"
    read -r OUTPUT_DIR
    OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT}"
fi

# Validate inputs
if [ -z "$DOMAIN" ]; then
    printf "${RED}Error: Domain is required${NC}\n"
    exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
    printf "${RED}Error: Output directory is required${NC}\n"
    exit 1
fi

# Derive project name and hostname
PROJECT_NAME=$(echo "$DOMAIN" | sed 's/\./-/g')
HOSTNAME="dev.${DOMAIN}"

printf "\n${YELLOW}Configuration:${NC}\n"
printf "  Domain:       %s\n" "$DOMAIN"
printf "  Project Name: %s\n" "$PROJECT_NAME"
printf "  Hostname:     %s\n" "$HOSTNAME"
printf "  Output Dir:   %s\n\n" "$OUTPUT_DIR"

# Create output directory
printf "${GREEN}Creating output directory...${NC}\n"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# Check if directory already has a CakePHP project
if [ -f "$OUTPUT_DIR/composer.json" ]; then
    printf "${RED}Error: Output directory already contains a project (composer.json exists)${NC}\n"
    exit 1
fi

# Function to process a template file
process_template() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    # Use pipe delimiter for sed to avoid conflicts with URL slashes
    sed -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
        -e "s|{{HOSTNAME}}|${HOSTNAME}|g" \
        -e "s|{{DOMAIN}}|${DOMAIN}|g" \
        "$src" > "$dest"
}

# Build the PHP image from template dockerfile (has all required extensions + composer)
printf "${GREEN}Building PHP image...${NC}\n"
docker build -t "${PROJECT_NAME}-php" -f "$TEMPLATE_DIR/dockerfile.tpl" "$TEMPLATE_DIR"

# Create CakePHP skeleton using our PHP image (output dir must be empty)
printf "${GREEN}Creating CakePHP 5.x skeleton via Docker...${NC}\n"
docker run --rm -v "$OUTPUT_DIR":/var/www/html -w /var/www/html \
    "${PROJECT_NAME}-php" \
    composer create-project --prefer-dist cakephp/app:~5.0 . --no-interaction

# Install authentication plugin via Docker
printf "${GREEN}Installing cakephp/authentication via Docker...${NC}\n"
docker run --rm -v "$OUTPUT_DIR":/var/www/html -w /var/www/html \
    "${PROJECT_NAME}-php" \
    composer require cakephp/authentication:~3.0 --no-interaction

# Install IdeHelper as a dev dependency
printf "${GREEN}Installing dereuromark/cakephp-ide-helper via Docker...${NC}\n"
docker run --rm -v "$OUTPUT_DIR":/var/www/html -w /var/www/html \
    "${PROJECT_NAME}-php" \
    composer require --dev dereuromark/cakephp-ide-helper --no-interaction

# Generate Docker infrastructure
printf "${GREEN}Generating Docker infrastructure...${NC}\n"
mkdir -p "$OUTPUT_DIR/config/docker/conf.d"
mkdir -p "$OUTPUT_DIR/config/docker/certs"

process_template "$TEMPLATE_DIR/compose.yml.tpl" "$OUTPUT_DIR/compose.yml"
process_template "$TEMPLATE_DIR/dockerfile.tpl" "$OUTPUT_DIR/config/docker/dockerfile"
process_template "$TEMPLATE_DIR/site.conf.tpl" "$OUTPUT_DIR/config/docker/conf.d/site.conf"
process_template "$TEMPLATE_DIR/custom.ini.tpl" "$OUTPUT_DIR/config/docker/custom.ini"
process_template "$TEMPLATE_DIR/init.sql.tpl" "$OUTPUT_DIR/config/docker/init.sql"

# Add VS Code debug config
printf "${GREEN}Adding VS Code debug config...${NC}\n"
process_template "$TEMPLATE_DIR/vscode/launch.json.tpl" "$OUTPUT_DIR/.vscode/launch.json"

# Generate SSL certificates with mkcert
printf "${GREEN}Generating SSL certificates with mkcert...${NC}\n"
mkcert -cert-file "$OUTPUT_DIR/config/docker/certs/${HOSTNAME}.pem" \
       -key-file "$OUTPUT_DIR/config/docker/certs/${HOSTNAME}-key.pem" \
       "$HOSTNAME"

# Create CakePHP config files
printf "${GREEN}Generating CakePHP configuration...${NC}\n"
process_template "$TEMPLATE_DIR/app_local.dev.php.tpl" "$OUTPUT_DIR/config/app_local.dev.php"
process_template "$TEMPLATE_DIR/app_local.prod.php.tpl" "$OUTPUT_DIR/config/app_local.prod.php"

# Remove the default app_local.php and create symlink
rm -f "$OUTPUT_DIR/config/app_local.php"
cd "$OUTPUT_DIR/config"
ln -s app_local.dev.php app_local.php
cd "$OUTPUT_DIR"

# Copy authentication scaffolding
printf "${GREEN}Setting up authentication scaffolding...${NC}\n"
mkdir -p "$OUTPUT_DIR/src/Controller/Admin"
mkdir -p "$OUTPUT_DIR/src/Model/Entity"
mkdir -p "$OUTPUT_DIR/src/Model/Table"
mkdir -p "$OUTPUT_DIR/templates/Admin/Users"
mkdir -p "$OUTPUT_DIR/templates/Admin/Homes"

process_template "$TEMPLATE_DIR/Application.php.tpl" "$OUTPUT_DIR/src/Application.php"
process_template "$TEMPLATE_DIR/AppController.php.tpl" "$OUTPUT_DIR/src/Controller/AppController.php"
process_template "$TEMPLATE_DIR/AdminController.php.tpl" "$OUTPUT_DIR/src/Controller/Admin/AdminController.php"
process_template "$TEMPLATE_DIR/AdminHomesController.php.tpl" "$OUTPUT_DIR/src/Controller/Admin/HomesController.php"
process_template "$TEMPLATE_DIR/UsersController.php.tpl" "$OUTPUT_DIR/src/Controller/Admin/UsersController.php"
process_template "$TEMPLATE_DIR/User.php.tpl" "$OUTPUT_DIR/src/Model/Entity/User.php"
process_template "$TEMPLATE_DIR/UsersTable.php.tpl" "$OUTPUT_DIR/src/Model/Table/UsersTable.php"
process_template "$TEMPLATE_DIR/Installer.php.tpl" "$OUTPUT_DIR/src/Console/Installer.php"
process_template "$TEMPLATE_DIR/login.php.tpl" "$OUTPUT_DIR/templates/Admin/Users/login.php"
process_template "$TEMPLATE_DIR/routes.php.tpl" "$OUTPUT_DIR/config/routes.php"

# Create admin homes index template
cat > "$OUTPUT_DIR/templates/Admin/Homes/index.php" << 'TEMPLATE'
<div class="container mt-3">
    <h3>Admin Dashboard</h3>
    <p>Welcome to the admin area.</p>
</div>
<?php $this->assign('title', 'Admin Dashboard') ?>
TEMPLATE

# Copy project Makefile
process_template "$TEMPLATE_DIR/Makefile.tpl" "$OUTPUT_DIR/Makefile"

# Create Docker network if it doesn't exist
printf "${GREEN}Ensuring Docker network 'dev' exists...${NC}\n"
docker network create dev 2>/dev/null || true

printf "\n${GREEN}Setup complete!${NC}\n\n"
printf "${YELLOW}Your CakePHP project has been generated at:${NC}\n"
printf "  Project Dir: %s\n\n" "$OUTPUT_DIR"
printf "${YELLOW}Next steps:${NC}\n"
printf "  cd %s\n" "$OUTPUT_DIR"
printf "  make build     - Build Docker containers\n"
printf "  make up        - Start Docker containers\n"
printf "\n"
printf "${YELLOW}Once running:${NC}\n"
printf "  Application: https://%s\n" "$HOSTNAME"
printf "  MailCatcher: https://%s:1080\n" "$HOSTNAME"
printf "  Database:    %s-db:3306 (my_app/secret)\n" "$PROJECT_NAME"
printf "\n"
printf "  Run 'make' in the project directory to see all available commands.\n"
