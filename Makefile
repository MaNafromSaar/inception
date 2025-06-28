# Makefile for Inception Project

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
LOGIN = mnaumann
DATA_DIR = /home/$(LOGIN)/data
WP_DATA_DIR = $(DATA_DIR)/wordpress
DB_DATA_DIR = $(DATA_DIR)/mariadb

# ANSI color codes
BLUE=\033[0;34m
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

# Check if .env file exists, create from example if not
env-check:
	@if [ ! -f srcs/.env ]; then \
		echo "$(YELLOW)No .env file found.$(NC)"; \
		if [ -f srcs/.env.example ]; then \
			echo "$(BLUE)Creating .env from .env.example...$(NC)"; \
			cp srcs/.env.example srcs/.env; \
			echo "$(GREEN)Created .env file. Please edit it with your settings before continuing.$(NC)"; \
			echo "$(YELLOW)Run 'nano srcs/.env' to edit the file.$(NC)"; \
			exit 1; \
		else \
			echo "$(RED)No .env.example file found. Cannot create .env.$(NC)"; \
			exit 1; \
		fi; \
	fi

# Check if data directories exist and create them if needed
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
	@echo "$(BLUE)Setting permissions...$(NC)"
	@chmod 755 $(WP_DATA_DIR) $(DB_DATA_DIR)
	@echo "$(GREEN)Permissions set.$(NC)"

# Check dependencies
check-deps:
	@./check_deps.sh

# Default target
all: check-deps env-check dirs-check
	@echo "$(BLUE)Building and starting all services...$(NC)"
	docker compose -f $(COMPOSE_FILE) --env-file srcs/.env up --build -d
	@echo "$(GREEN)All services started. Please wait a moment for them to initialize.$(NC)"
	@echo "$(BLUE)You can check the status with 'make status'.$(NC)"

# Stop all services
down:
	@echo "$(BLUE)Stopping all services...$(NC)"
	docker compose -f $(COMPOSE_FILE) --env-file srcs/.env down
	@echo "$(GREEN)All services stopped.$(NC)"

# Clean: Stop and remove containers, networks, and volumes defined in compose
clean:
	@echo "$(BLUE)Cleaning containers, networks, and volumes...$(NC)"
	docker compose -f $(COMPOSE_FILE) --env-file srcs/.env down -v --remove-orphans
	@echo "$(GREEN)Cleaned containers, networks, and volumes.$(NC)"

# Fclean: Clean + remove images built by compose + prune system
fclean: clean
	@echo "$(BLUE)Removing images built by compose...$(NC)"
	docker compose -f $(COMPOSE_FILE) --env-file srcs/.env down --rmi local
	@echo "$(BLUE)Pruning Docker system...$(NC)"
	docker system prune -af
	@echo "$(BLUE)Removing project network if it exists...$(NC)"
	@docker network rm inception_network || true
	@echo "$(GREEN)Full cleanup completed.$(NC)"

# Re: Full rebuild and restart
re: fclean all

# Status check
status:
	@echo "$(BLUE)Checking container status:$(NC)"
	@docker ps
	@echo "\n$(BLUE)Container health status:$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v "NAMES"

# Individual service controls
logs:
	@docker compose -f $(COMPOSE_FILE) --env-file srcs/.env logs -f

logs-nginx:
	@docker compose -f $(COMPOSE_FILE) --env-file srcs/.env logs -f nginx

logs-wordpress:
	@docker compose -f $(COMPOSE_FILE) --env-file srcs/.env logs -f wordpress

logs-mariadb:
	@docker compose -f $(COMPOSE_FILE) --env-file srcs/.env logs -f mariadb

# Test connectivity - checks if all services are properly connected
test: test-all

# Test all connections
test-all:
	@echo "$(BLUE)Running complete connectivity tests...$(NC)"
	@./test_connectivity.sh
	@echo "$(GREEN)Testing completed.$(NC)"

# Create SSL certificate if needed (useful for development)
ssl:
	@echo "$(BLUE)Generating SSL certificate...$(NC)"
	@./srcs/requirements/nginx/tools/generate_ssl.sh
	@echo "$(GREEN)SSL certificate generated.$(NC)"

.PHONY: all down clean fclean re logs logs-nginx logs-wordpress logs-mariadb check-deps env-check dirs-check status test test-all ssl
