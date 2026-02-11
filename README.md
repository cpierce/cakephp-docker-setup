# CakePHP Docker Setup

CakePHP 5.x Docker Setup made simple. Generates a complete CakePHP development environment with Docker, including authentication scaffolding, SSL, and email testing.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Homebrew](https://brew.sh/) (macOS)
- [mkcert](https://github.com/FiloSottile/mkcert)

PHP and Composer run inside Docker containers - no local install needed.

Install all prerequisites automatically:

```bash
make prerequisites
```

## Quick Start

```bash
make setup
```

You'll be prompted for:
- **Domain** (e.g. `myapp.com`) - used to derive the project name and hostname
- **Output directory** (e.g. `../myapp.com`) - where the project is created

The setup script will:
1. Create a fresh CakePHP 5.x skeleton
2. Install and configure `cakephp/authentication`
3. Generate Docker infrastructure (PHP-FPM, Nginx, MySQL, MailCatcher)
4. Generate trusted SSL certificates via mkcert
5. Set up development and production config files
6. Build and start all containers

### What Gets Generated

| Component | Details |
|-----------|---------|
| PHP | 8.3 FPM Alpine |
| Web Server | Nginx with HTTPS |
| Database | MySQL 8.4 (my_app/secret) |
| Email | MailCatcher for testing |
| Auth | Email/password login with admin panel |

### Naming Convention

From the domain, everything is auto-derived:

| Input | `myapp.com` |
|-------|-------------|
| Project Name | `myapp-com` |
| Hostname | `dev.myapp.com` |
| PHP Container | `myapp-com-php_app` |
| DB Container | `myapp-com-db` |
| Nginx Container | `myapp-com-nginx` |
| MailCatcher Container | `myapp-com-mailcatcher` |

### Config Files

- `config/app_local.dev.php` - Development config (Docker service hostnames, MailCatcher)
- `config/app_local.prod.php` - Production config (placeholder secrets for CI/CD)
- `config/app_local.php` - Symlink to `app_local.dev.php` (created by Docker, or copied from prod by Composer in CI/CD)

## Project Make Commands

After setup, these commands are available in the generated project directory:

| Command | Description |
|---------|-------------|
| `make up` | Start containers |
| `make down` | Stop containers |
| `make build` | Rebuild containers |
| `make shell` | Open PHP container shell |
| `make cake CMD="..."` | Run CakePHP CLI commands |
| `make composer CMD="..."` | Run Composer commands |
| `make db` | Connect to MySQL CLI |
| `make logs` | Tail container logs |
| `make clean` | Remove containers and volumes |

## GitHub Actions

Generate CI/CD deployment files for an existing project:

```bash
make gha
```

This creates `.github/` with:
- Deployment workflow (rsync to production server)
- Dependabot config
- Issue and PR templates

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `DB_HOST` | Production database host |
| `DB_USERNAME` | Production database username |
| `DB_PASSWORD` | Production database password |
| `DB_DATABASE` | Production database name |
| `SES_USERNAME` | AWS SES SMTP username |
| `SES_PASSWORD` | AWS SES SMTP password |
| `DEPLOY_KEY` | SSH private key for deployment |

### Required GitHub Variables

| Variable | Description |
|----------|-------------|
| `DEPLOY_HOST` | Production server hostname |
| `DEPLOY_DIR` | Deployment directory name |

## Authentication

Every generated project includes a complete authentication system:

- Email/password login at `/login`
- Session-based authentication
- Admin panel at `/admin`
- User model with password hashing, soft-delete, and `findActive` finder
- Base admin controller with generic CRUD operations

## Docker Network

All projects share an external Docker network named `dev`. This is created automatically during setup if it doesn't exist. This allows multiple projects to communicate with each other if needed.

## License

MIT
