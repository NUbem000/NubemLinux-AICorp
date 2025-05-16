# Makefile para NubemLinux-AICorp

.PHONY: all build clean test docs install deps help

# Variables
VERSION := 1.0.0
ISO_NAME := nubemlinux-aicorp-$(VERSION).iso
BUILD_DIR := build
OUTPUT_DIR := output

# Meta targets
all: deps build

help:
	@echo "NubemLinux-AICorp Build System"
	@echo "============================="
	@echo "Targets disponibles:"
	@echo "  make build    - Construir la ISO"
	@echo "  make test     - Ejecutar tests"
	@echo "  make clean    - Limpiar archivos temporales"
	@echo "  make docs     - Generar documentación"
	@echo "  make deps     - Instalar dependencias"
	@echo "  make install  - Instalar herramientas localmente"
	@echo "  make publish  - Publicar en GitHub"

# Construcción
build:
	@echo "Construyendo NubemLinux-AICorp v$(VERSION)"
	@sudo ./build_nubemlinux.sh

# Testing
test:
	@echo "Ejecutando tests..."
	@bash -n build_nubemlinux.sh
	@bash -n checkpoint_manager.sh
	@for script in scripts/*.sh; do \
		echo "Verificando $$script"; \
		bash -n "$$script"; \
	done
	@echo "Tests completados"

# Limpieza
clean:
	@echo "Limpiando archivos temporales..."
	@rm -rf $(BUILD_DIR) $(OUTPUT_DIR) tmp/ logs/
	@rm -f .checkpoint
	@echo "Limpieza completada"

# Documentación
docs:
	@echo "Generando documentación..."
	@cd docs && python3 -m http.server 8000

# Dependencias
deps:
	@echo "Instalando dependencias..."
	@sudo apt-get update
	@sudo apt-get install -y \
		debootstrap \
		squashfs-tools \
		xorriso \
		grub-pc-bin \
		grub-efi-amd64-bin \
		curl \
		wget \
		git \
		python3 \
		python3-pip
	@echo "Dependencias instaladas"

# Instalación local
install:
	@echo "Instalando herramientas localmente..."
	@sudo cp scripts/nubemlinux-update /usr/local/bin/
	@sudo chmod +x /usr/local/bin/nubemlinux-update
	@echo "Instalación completada"

# Publicación
publish:
	@echo "Publicando en GitHub..."
	@./publish-to-github.sh

# Verificación de ISO
verify: $(OUTPUT_DIR)/$(ISO_NAME)
	@echo "Verificando ISO..."
	@./scripts/verify_iso.sh

# Target para desarrollo
dev:
	@echo "Configurando entorno de desarrollo..."
	@git config --local core.hooksPath .githooks
	@chmod +x .githooks/*
	@echo "Entorno de desarrollo configurado"

# Información del sistema
info:
	@echo "NubemLinux-AICorp Build Information"
	@echo "=================================="
	@echo "Version: $(VERSION)"
	@echo "User: $(USER)"
	@echo "Date: $(shell date)"
	@echo "Git Branch: $(shell git branch --show-current)"
	@echo "Git Commit: $(shell git rev-parse --short HEAD)"
	@echo "Ubuntu Base: 22.04.4 LTS"