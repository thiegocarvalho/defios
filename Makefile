# ==============================================================================
#                      DefiOS Live OS Build Pipeline
# ==============================================================================
# This Makefile encapsulates the live-build workflow to generate a highly
# secure, amnesic Debian Minimal Live OS focused on crypto operations.
# ==============================================================================

# Output configuration
IMAGE_NAME = defios-secure-live.iso
BUILD_DIR = .

# Styling definitions for beautiful outputs
BLUE  = \033[1;34m
GREEN = \033[1;32m
RED   = \033[1;31m
BOLD  = \033[1m
NC    = \033[0m # No Color

.PHONY: all help config build clean purge status

all: help

help:
	@echo -e "$(BLUE)$(BOLD)DefiOS Builder Pipeline$(NC)"
	@echo -e "Available commands:"
	@echo -e "  $(GREEN)make config$(NC)   - Configure live-build (initializes /config structure via auto/config)"
	@echo -e "  $(GREEN)make build$(NC)    - Start the ISO build process (requires sudo)"
	@echo -e "  $(GREEN)make clean$(NC)    - Remove build-time caches and helper directories"
	@echo -e "  $(GREEN)make purge$(NC)    - Complete cleanup of all caches, including chroot and downloads"
	@echo -e "  $(GREEN)make status$(NC)   - Check workspace and build status"

config:
	@echo -e "$(BLUE)[+] Running live-build configuration...$(NC)"
	@if [ ! -d auto ]; then \
		echo -e "$(RED)[-] Error: 'auto' directory with config scripts is missing!$(NC)" && exit 1; \
	fi
	lb config

build:
	@echo -e "$(BLUE)[+] Starting ISO construction...$(NC)"
	@echo -e "$(BLUE)[+] Checking for root privileges...$(NC)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo -e "$(RED)[-] Error: The build command requires root privileges. Please use: sudo make build$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(GREEN)[+] Building custom Debian amnesic image...$(NC)"
	lb build
	@if [ -f live-image-amd64.hybrid.iso ]; then \
		mv live-image-amd64.hybrid.iso $(IMAGE_NAME); \
		echo -e "$(GREEN)[+] Success! ISO generated as $(BOLD)$(IMAGE_NAME)$(NC)"; \
	else \
		echo -e "$(RED)[-] Error: ISO build completed but live-image-amd64.hybrid.iso not found!$(NC)"; \
		exit 1; \
	fi

clean:
	@echo -e "$(BLUE)[+] Cleaning build workspace...$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		lb clean; \
	else \
		sudo lb clean; \
	fi
	@rm -f $(IMAGE_NAME)
	@echo -e "$(GREEN)[+] Clean completed!$(NC)"

purge:
	@echo -e "$(BLUE)[+] Purging all live-build files and cache directories...$(NC)"
	@if [ "$$(id -u)" -eq 0 ]; then \
		lb clean --purge; \
	else \
		sudo lb clean --purge; \
	fi
	@rm -f $(IMAGE_NAME)
	@echo -e "$(GREEN)[+] Purge completed!$(NC)"

status:
	@echo -e "$(BLUE)$(BOLD)DefiOS Workspace Status$(NC)"
	@echo -e "Current directory: $$(pwd)"
	@echo -e "Free space: $$(df -h . | awk 'NR==2 {print $$4}')"
	@echo -e "Package list: $$(ls -la config/package-lists/ 2>/dev/null || echo 'Not configured yet')"
	@echo -e "Hooks configured: $$(ls -la config/hooks/normal/ 2>/dev/null || echo 'None')"
