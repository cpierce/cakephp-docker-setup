.DEFAULT_GOAL := help
.PHONY: help up down build shell cake composer db logs clean

## Show available commands
help:
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make up              Start containers"
	@echo "  make down            Stop containers"
	@echo "  make build           Rebuild containers"
	@echo "  make shell           Open PHP container shell"
	@echo "  make cake CMD=\"...\"  Run CakePHP CLI commands"
	@echo "  make composer CMD=\"...\"  Run Composer commands"
	@echo "  make db              Connect to MySQL CLI"
	@echo "  make logs            Tail container logs"
	@echo "  make clean           Remove containers and volumes"
	@echo ""

## Start containers
up:
	docker compose up -d

## Stop containers
down:
	docker compose down

## Rebuild containers
build:
	docker compose build

## Open a shell in the PHP container
shell:
	docker compose exec app sh

## Run CakePHP CLI commands (e.g. make cake CMD="migrations migrate")
cake:
	docker compose exec app bin/cake $(CMD)

## Run composer commands (e.g. make composer CMD="require foo/bar")
composer:
	docker compose exec app composer $(CMD)

## Connect to MySQL CLI
db:
	docker compose exec db mysql -u my_app -psecret my_app

## Tail container logs
logs:
	docker compose logs -f

## Remove containers and volumes
clean:
	docker compose down -v
