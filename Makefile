# Makefile for Inception Project

# --- Variables ---
# Use the current user's login name automatically for portability.
LOGIN ?= $(shell whoami)
ENV_FILE = srcs/.env

# --- Compose Configuration ---
# Default: host-bind mounts at /home/$(LOGIN)/data (42 subject requirement).
# The host-bind mount configuration is applied via docker-compose.host.yml,
# which overrides the named volumes in docker-compose.yml with bind mounts.
# For Docker-managed volumes (portable/WSL2 dev), run: make up-dev

# Host-bind mode is always active for the default targets.
COMPOSE = LOGIN=$(LOGIN) docker compose --file srcs/docker-compose.yml --file srcs/docker-compose.host.yml --env-file srcs/.env

# Separate compose command without the host overlay, for development use.
COMPOSE_DEV = LOGIN=$(LOGIN) docker compose --file srcs/docker-compose.yml --env-file srcs/.env

# Define data directories for the host mode.
DATA_DIR = /home/$(LOGIN)/data
WP_DATA_DIR = $(DATA_DIR)/wordpress
DB_DATA_DIR = $(DATA_DIR)/mariadb

# --- ANSI color codes ---
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

# Docker Compose command fallback (supports both v1 and v2 syntax)
DOCKER_COMPOSE = $(shell command -v docker-compose 2>/dev/null || echo 'docker compose')

# --- Rules ---

# Default target: build and run with host-bind mounts (42 subject compliant).
all: up

# Build and start with host-bind mounts (default, 42 subject compliant).
up: env-check dirs-check
	@echo "---> (up) Starting the main build command..."
	@$(COMPOSE) up --build -d
	@echo "---> (up) Main build command finished."
	@echo "$(GREEN)Services started with host-bind mounts in $(DATA_DIR). Use 'make status' to check them.$(NC)"

# Build and start with Docker-managed volumes (portable, for development/WSL2).
up-dev: env-check
	@echo "---> (up-dev) Starting with Docker-managed volumes..."
	@$(COMPOSE_DEV) up --build -d
	@echo "---> (up-dev) Build command finished."
	@echo "$(GREEN)Services started with Docker-managed volumes. Use 'make status' to check them.$(NC)"

# Alias for backwards compatibility.
up-host: up

# Check for .env file. If it doesn't exist, copy from the example.
# This no longer causes make to exit, allowing the process to continue.
env-check:
	@echo "---> (env-check) Checking for .env file..."
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW).env file not found. Creating from .env.example...$(NC)"; \
		cp srcs/.env.example $(ENV_FILE); \
		echo "$(GREEN)Successfully created $(ENV_FILE). You may want to customize it later.$(NC)"; \
	fi
	@echo "---> (env-check) Finished checking for .env file."

# Check if data directories exist (created automatically by the default target).
dirs-check:
	@echo "$(BLUE)Ensuring host data directories exist at $(DATA_DIR)...$(NC)"
	@mkdir -p $(WP_DATA_DIR)
	@mkdir -p $(DB_DATA_DIR)
	@echo "$(GREEN)Host data directories are ready.$(NC)"

# Stop all services (host mode)
down: ## Stop and remove containers, networks
	@echo "$(YELLOW)Stopping all services and networks...$(NC)"
	@echo "$(YELLOW)Note: Host data directories at $(DATA_DIR) are preserved. Use 'make fclean' to remove them.$(NC)"
	@$(COMPOSE) down -v

# Clean: Stop and remove containers, networks, and volumes defined in compose
clean:
	@echo "$(BLUE)Cleaning containers and networks...$(NC)"
	@$(COMPOSE) down -v --remove-orphans
	@echo "$(GREEN)Cleaned containers and networks.$(NC)"

# Fclean: Clean + remove images built by compose + prune system + remove host data dirs
fclean: clean
	@echo "$(BLUE)Removing images built by compose...$(NC)"
	@$(COMPOSE) down --rmi all
	@echo "$(BLUE)Pruning Docker system...$(NC)"
	@docker system prune -af
	@echo "$(YELLOW)Do you want to remove the host data directories at $(DATA_DIR)? [y/N] $(NC)"; \
	read -r answer; \
	if [ "$$answer" = "y" ]; then \
		echo "$(RED)Removing $(DATA_DIR)...$(NC)"; \
		rm -rf $(DATA_DIR); \
	fi
	@echo "$(GREEN)Full cleanup completed.$(NC)"

# Re: Full rebuild and restart
re: fclean up

# Re-host: alias for re (kept for backwards compatibility)
re-host: re

# Status check
status:
	@echo "$(BLUE)Checking container status:$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

# Individual service controls
logs:
	@$(COMPOSE) logs -f

logs-nginx:
	@$(COMPOSE) logs -f nginx

logs-wordpress:
	@$(COMPOSE) logs -f wordpress

logs-mariadb:
	@$(COMPOSE) logs -f mariadb

logs-redis:
	@$(COMPOSE) logs -f redis

logs-adminer:
	@$(COMPOSE) logs -f adminer

# Test connectivity - checks if all services are properly connected
test:
	@echo "$(BLUE)Running connectivity tests...$(NC)"
	@./scripts/test_connectivity.sh
	@echo "$(GREEN)Testing completed.$(NC)"

# Create SSL certificate if needed (useful for development)
ssl:
	@echo "$(BLUE)Generating SSL certificate...$(NC)"
	@./srcs/requirements/nginx/tools/generate_ssl.sh
	@echo "$(GREEN)SSL certificate generated.$(NC)"

COMPOSE_FILE = srcs/docker-compose.yml

# Get the domain name from the .env file
DOMAIN_NAME = $(shell grep DOMAIN_NAME srcs/.env | cut -d '=' -f2)

# List of domains to add to /etc/hosts
DOMAINS = www.${DOMAIN_NAME} ${DOMAIN_NAME} adminer.${DOMAIN_NAME} static.${DOMAIN_NAME}

.PHONY: all up up-dev up-host down clean fclean re re-host logs logs-nginx logs-wordpress logs-mariadb logs-redis logs-adminer env-check dirs-check status test ssl

