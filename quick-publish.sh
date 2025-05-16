#!/bin/bash
# Script rápido para publicar NubemLinux-AICorp en GitHub

echo "=== Publicación Rápida de NubemLinux-AICorp ==="
echo

# Verificar si hay token en el entorno o pedir uno
if [ -z "$GH_TOKEN" ] && [ -z "$GITHUB_TOKEN" ]; then
    echo "No se encontró token de GitHub en el entorno."
    echo "Por favor, ingresa tu token de acceso personal de GitHub:"
    echo "(Puedes crearlo en: https://github.com/settings/tokens)"
    read -s -p "Token: " github_token
    echo
    export GH_TOKEN="$github_token"
fi

# Usar GITHUB_TOKEN si existe, sino usar GH_TOKEN
[ ! -z "$GITHUB_TOKEN" ] && export GH_TOKEN="$GITHUB_TOKEN"

# Verificar que tenemos un token
if [ -z "$GH_TOKEN" ]; then
    echo "Error: No se proporcionó token de GitHub"
    exit 1
fi

# Obtener el nombre de usuario de GitHub
echo "Obteniendo información del usuario..."
USERNAME=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user | jq -r .login)

if [ "$USERNAME" = "null" ] || [ -z "$USERNAME" ]; then
    echo "Error: No se pudo obtener el nombre de usuario. Verifica tu token."
    exit 1
fi

echo "Usuario detectado: $USERNAME"
echo

# Crear el repositorio
echo "Creando repositorio NubemLinux-AICorp..."
curl -s -H "Authorization: token $GH_TOKEN" \
     -d '{"name":"NubemLinux-AICorp","description":"Ubuntu distribution with integrated AI, corporate branding, and intelligent self-management capabilities","public":true}' \
     https://api.github.com/user/repos > /dev/null

# Configurar remote
git remote remove origin 2>/dev/null
git remote add origin "https://${USERNAME}:${GH_TOKEN}@github.com/${USERNAME}/NubemLinux-AICorp.git"

# Push del código
echo "Subiendo código a GitHub..."
git push -u origin main

# Verificar que se subió correctamente
if [ $? -eq 0 ]; then
    echo
    echo "✅ Repositorio publicado exitosamente!"
    echo
    echo "📍 URL: https://github.com/${USERNAME}/NubemLinux-AICorp"
    echo
    
    # Configurar temas
    echo "Configurando temas del repositorio..."
    curl -s -X PATCH \
         -H "Authorization: token $GH_TOKEN" \
         -H "Accept: application/vnd.github.mercy-preview+json" \
         -d '{"topics":["ubuntu","ai","linux-distribution","ollama","system-monitoring","corporate"]}' \
         "https://api.github.com/repos/${USERNAME}/NubemLinux-AICorp" > /dev/null
    
    echo "✅ Temas configurados"
    echo
    
    # Preguntar si crear release
    read -p "¿Deseas crear un release v1.0.0? (s/n): " create_release
    if [[ "$create_release" =~ ^[Ss]$ ]]; then
        echo "Creando release..."
        curl -s -H "Authorization: token $GH_TOKEN" \
             -d '{
                 "tag_name": "v1.0.0",
                 "name": "NubemLinux-AICorp v1.0.0",
                 "body": "Initial release of NubemLinux-AICorp\n\n## Features\n- Integrated AI assistant (NubemCopilot)\n- Intelligent Watchdog system\n- Corporate branding\n- Enhanced security\n- Autonomous updates\n\n## Requirements\n- Minimum 4GB RAM\n- 50GB disk space\n- x86_64 processor",
                 "draft": false,
                 "prerelease": false
             }' \
             "https://api.github.com/repos/${USERNAME}/NubemLinux-AICorp/releases" > /dev/null
        
        echo "✅ Release v1.0.0 creado"
        echo "📍 URL: https://github.com/${USERNAME}/NubemLinux-AICorp/releases"
    fi
    
    echo
    echo "🎉 ¡Publicación completada!"
    echo
    echo "Próximos pasos:"
    echo "1. Visita tu repositorio: https://github.com/${USERNAME}/NubemLinux-AICorp"
    echo "2. Configura GitHub Actions en Settings > Actions"
    echo "3. Añade la ISO al release cuando esté lista"
    echo "4. Configura GitHub Pages para la documentación"
    
else
    echo "❌ Error al publicar el repositorio"
    echo "Verifica tu token y conexión a internet"
fi