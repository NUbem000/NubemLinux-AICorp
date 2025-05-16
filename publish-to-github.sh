#!/bin/bash
# Script para publicar NubemLinux-AICorp en GitHub

echo "=== Publicación de NubemLinux-AICorp en GitHub ==="
echo

# Verificar si gh está instalado
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) no está instalado. Instalando..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
fi

# Verificar autenticación
echo "Verificando autenticación en GitHub..."
if ! gh auth status &> /dev/null; then
    echo "Por favor, autentícate en GitHub:"
    gh auth login
fi

# Crear repositorio
echo "Creando repositorio en GitHub..."
gh repo create NubemLinux-AICorp \
    --public \
    --description "Ubuntu distribution with integrated AI, corporate branding, and intelligent self-management capabilities" \
    --homepage "https://nubemlinux.com" \
    -y

# Configurar remote
git remote add origin https://github.com/$(gh api user --jq .login)/NubemLinux-AICorp.git 2>/dev/null || true

# Push del código
echo "Subiendo código a GitHub..."
git push -u origin main

# Configurar temas del repositorio
echo "Configurando temas del repositorio..."
gh repo edit \
    --add-topic "ubuntu" \
    --add-topic "ai" \
    --add-topic "linux-distribution" \
    --add-topic "ollama" \
    --add-topic "system-monitoring" \
    --add-topic "corporate"

# Crear release inicial
echo "¿Deseas crear un release inicial? (s/n)"
read -r response
if [[ "$response" =~ ^[Ss]$ ]]; then
    echo "Creando release v1.0.0..."
    gh release create v1.0.0 \
        --title "NubemLinux-AICorp v1.0.0" \
        --notes "Initial release of NubemLinux-AICorp

## Features
- Integrated AI assistant (NubemCopilot) with text, image, and voice processing
- Intelligent Watchdog system for automatic monitoring and self-healing
- Corporate branding and customization
- Enhanced security with kernel hardening, firewall, and AppArmor
- Autonomous update system for OS and AI models

## Requirements
- Minimum 4GB RAM (8GB recommended)
- 50GB disk space
- x86_64 processor with virtualization support

## Installation
1. Download the ISO
2. Create bootable USB or use in VM
3. Follow the installation wizard

See deployment guide for detailed instructions." \
        --draft
fi

echo
echo "=== Publicación completada ==="
echo
echo "Repositorio: https://github.com/$(gh api user --jq .login)/NubemLinux-AICorp"
echo
echo "Próximos pasos:"
echo "1. Añadir la ISO al release cuando esté construida"
echo "2. Actualizar el README con screenshots"
echo "3. Configurar GitHub Pages para documentación"
echo "4. Habilitar GitHub Actions para CI/CD"
echo

# Abrir el repositorio en el navegador
echo "¿Abrir el repositorio en el navegador? (s/n)"
read -r response
if [[ "$response" =~ ^[Ss]$ ]]; then
    gh repo view --web
fi