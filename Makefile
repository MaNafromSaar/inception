# Makefile for Inception Project

# --- Variables ---
# Use the current user's login name automatically for portability.
LOGIN ?= $(shell whoami)

# Use docker compose (with a space), the modern command.
# We also prepend LOGIN=$(LOGIN) to ensure the variable is available for docker-compose.
COMPOSE = LOGIN=$(LOGIN) docker compose

COMPOSE_FILE = srcs/docker-compose.yml
ENV_FILE = srcs/.env

# Define data directories based on the current user's home.
# This ensures it works for any user (e.g., 'inception' on the VM, or your local user).
DATA_DIR = /home/$(LOGIN)/data
WP_DATA_DIR = $(DATA_DIR)/wordpress
DB_DATA_DIR = $(DATA_DIR)/mariadb

# --- ANSI color codes ---
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

# --- Rules ---

# Default target: Set up and run everything.
all: up

# The main 'up' command to build and start services.
up: dirs-check env-check
	@echo "$(BLUE)Building and starting all services...$(NC)"
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up --build -d
	@echo "$(GREEN)All services started. You can check the status with 'make status'.$(NC)"

# Check for .env file. If it doesn't exist, copy from the example.
# This no longer causes make to exit, allowing the process to continue.
env-check:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW).env file not found. Creating from .env.example...$(NC)"; \
		cp srcs/.env.example $(ENV_FILE); \
		echo "$(GREEN)Successfully created $(ENV_FILE). You may want to customize it later.$(NC)"; \
	fi

# Check if data directories exist and create them if needed.
dirs-check:
	@echo "$(BLUE)Checking data directories...$(NC)"
	@if [ ! -d $(WP_DATA_DIR) ]; then \
		echo "$(YELLOW)Creating WordPress data directory: $(WP_DATA_DIR)$(NC)"; \
		mkdir -p $(WP_DATA_DIR); \
	fi
	@if [ ! -d $(DB_DATA_DIR) ]; then \
		echo "$(YELLOW)Creating MariaDB data directory: $(DB_DATA_DIR)$(NC)"; \
		mkdir -p $(DB_DATA_DIR); \
	fi
	@echo "$(GREEN)All data directories are ready.$(NC)"

# Stop all services
down: ## Stop and remove containers, networks, and volumes
	@echo "Stopping and removing all services, networks, and volumes..."
	@$(COMPOSE) -f $(COMPOSE_FILE) down -v

# Clean: Stop and remove containers, networks, and volumes defined in compose
clean:
	@echo "$(BLUE)Cleaning containers, networks, and volumes...$(NC)"
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down -v --remove-orphans
	@echo "$(GREEN)Cleaned containers, networks, and volumes.$(NC)"

# Fclean: Clean + remove images built by compose + prune system
fclean: clean
	@echo "$(BLUE)Removing images built by compose...$(NC)"
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down --rmi all
	@echo "$(BLUE)Pruning Docker system...$(NC)"
	@docker system prune -af
	@echo "$(GREEN)Full cleanup completed.$(NC)"

# Re: Full rebuild and restart
re: fclean all ## Rebuild everything from scratch

# Status check
status:
	@echo "$(BLUE)Checking container status:$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

# Individual service controls
logs:
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f

logs-nginx:
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f nginx

logs-wordpress:
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f wordpress

logs-mariadb:
	@$(COMPOSE) -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f mariadb

# Test connectivity - checks if all services are properly connected
test:
	@echo "$(BLUE)Running connectivity tests...$(NC)"
	@./test_connectivity.sh
	@echo "$(GREEN)Testing completed.$(NC)"

# Create SSL certificate if needed (useful for development)
ssl:
	@echo "$(BLUE)Generating SSL certificate...$(NC)"
	@./srcs/requirements/nginx/tools/generate_ssl.sh
	@echo "$(GREEN)SSL certificate generated.$(NC)"

.PHONY: all up down clean fclean re logs logs-nginx logs-wordpress logs-mariadb env-check dirs-check status test ssl
