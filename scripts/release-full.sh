#!/bin/bash
# Script completo de release con Google Drive

set -e

# Configuración
VERSION="${1:-1.0.0}"
ISO_NAME="nubemlinux-aicorp-${VERSION}.iso"
ISO_PATH="output/${ISO_NAME}"
GDRIVE_FOLDER="NubemLinux-AICorp/releases/v${VERSION}"

echo "=== Release Completo de NubemLinux-AICorp v${VERSION} ==="
echo

# Verificar que existe la ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO no encontrada en $ISO_PATH"
    echo "Ejecuta primero: ./build_nubemlinux.sh"
    exit 1
fi

# Mostrar información de la ISO
echo "ISO a publicar:"
echo "- Archivo: $ISO_NAME"
echo "- Tamaño: $(du -h "$ISO_PATH" | cut -f1)"
echo

# Comprimir ISO (opcional)
read -p "¿Comprimir ISO con xz? (reduce ~50% el tamaño) [s/N]: " compress
if [[ $compress =~ ^[Ss]$ ]]; then
    echo "Comprimiendo ISO..."
    if [ ! -f "${ISO_PATH}.xz" ]; then
        xz -9 -k -v "$ISO_PATH"
    fi
    UPLOAD_FILE="${ISO_PATH}.xz"
else
    UPLOAD_FILE="$ISO_PATH"
fi

# Generar checksums
echo "Generando checksums..."
sha256sum "$UPLOAD_FILE" > "${UPLOAD_FILE}.sha256"
md5sum "$UPLOAD_FILE" > "${UPLOAD_FILE}.md5"

# Verificar tamaño final
FINAL_SIZE=$(stat -c%s "$UPLOAD_FILE")
FINAL_SIZE_GB=$((FINAL_SIZE / 1024 / 1024 / 1024))

echo "Archivo final:"
echo "- Nombre: $(basename "$UPLOAD_FILE")"
echo "- Tamaño: $(du -h "$UPLOAD_FILE" | cut -f1)"
echo

# Verificar si necesita división
if [ $FINAL_SIZE_GB -gt 2 ]; then
    echo "ADVERTENCIA: El archivo es mayor a 2GB"
    echo "GitHub Release tiene límite de 2GB por archivo"
    echo
    read -p "¿Dividir archivo para GitHub? [S/n]: " split
    if [[ ! $split =~ ^[Nn]$ ]]; then
        echo "Dividiendo archivo..."
        ./scripts/split-iso.sh "$UPLOAD_FILE" "part" "1900M"
        GITHUB_UPLOAD="parts"
    fi
else
    GITHUB_UPLOAD="full"
fi

# Subir a Google Drive
echo
echo "=== Subida a Google Drive ==="
read -p "¿Subir a Google Drive? [S/n]: " gdrive
if [[ ! $gdrive =~ ^[Nn]$ ]]; then
    # Verificar rclone
    if ! command -v rclone &> /dev/null; then
        echo "Instalando rclone..."
        curl https://rclone.org/install.sh | sudo bash
    fi
    
    # Verificar configuración
    if ! rclone listremotes | grep -q "gdrive:"; then
        echo "Configurando Google Drive..."
        echo "Sigue las instrucciones para autorizar:"
        rclone config create gdrive drive
    fi
    
    # Crear carpeta
    echo "Creando carpeta en Google Drive..."
    rclone mkdir "gdrive:/$GDRIVE_FOLDER" --quiet || true
    
    # Subir archivos
    echo "Subiendo archivos..."
    rclone copy "$UPLOAD_FILE" "gdrive:/$GDRIVE_FOLDER/" --progress
    rclone copy "${UPLOAD_FILE}.sha256" "gdrive:/$GDRIVE_FOLDER/" --progress
    rclone copy "${UPLOAD_FILE}.md5" "gdrive:/$GDRIVE_FOLDER/" --progress
    
    # Generar link compartido
    echo "Generando link compartido..."
    GDRIVE_LINK=$(rclone link "gdrive:/$GDRIVE_FOLDER/$(basename "$UPLOAD_FILE")")
    echo "Link de Google Drive: $GDRIVE_LINK"
fi

# Crear release en GitHub
echo
echo "=== Release en GitHub ==="
read -p "¿Crear/actualizar release en GitHub? [S/n]: " github
if [[ ! $github =~ ^[Nn]$ ]]; then
    # Crear release notes
    cat > "release-notes-${VERSION}.md" <<EOF
# NubemLinux-AICorp v${VERSION}

## Descargas

### ISO Completa
- **Google Drive**: ${GDRIVE_LINK:-[Subir manualmente]}
- **Tamaño**: $(du -h "$UPLOAD_FILE" | cut -f1)
- **SHA256**: $(cat "${UPLOAD_FILE}.sha256" | cut -d' ' -f1)

### Verificación
\`\`\`bash
# Verificar integridad después de descargar
sha256sum -c $(basename "$UPLOAD_FILE").sha256
\`\`\`

## Cambios en esta versión
- Release inicial
- Ubuntu ${UBUNTU_VERSION} base
- Ollama con modelos Llama 3.1
- Sistema Watchdog inteligente
- Branding corporativo completo

## Instalación
1. Descargar la ISO desde Google Drive
2. Verificar checksum
3. Crear USB booteable o usar en VM
4. Seguir asistente de instalación

## Requisitos mínimos
- 4GB RAM
- 50GB disco
- CPU x86_64 con virtualización

## Soporte
- Issues: https://github.com/NUbem000/NubemLinux-AICorp/issues
- Docs: https://nubem000.github.io/NubemLinux-AICorp/
EOF
    
    # Crear o actualizar release
    if gh release view "v${VERSION}" &> /dev/null; then
        echo "Actualizando release existente..."
        gh release edit "v${VERSION}" --notes-file "release-notes-${VERSION}.md"
    else
        echo "Creando nuevo release..."
        gh release create "v${VERSION}" \
            --title "NubemLinux-AICorp v${VERSION}" \
            --notes-file "release-notes-${VERSION}.md"
    fi
    
    # Subir archivos pequeños a GitHub
    if [ "$GITHUB_UPLOAD" = "full" ] && [ $FINAL_SIZE_GB -lt 2 ]; then
        echo "Subiendo archivos a GitHub Release..."
        gh release upload "v${VERSION}" \
            "${UPLOAD_FILE}.sha256" \
            "${UPLOAD_FILE}.md5" \
            --clobber
    elif [ "$GITHUB_UPLOAD" = "parts" ]; then
        echo "Subiendo partes a GitHub Release..."
        gh release upload "v${VERSION}" part.* --clobber
    fi
fi

# Crear página de descarga
echo
echo "=== Creando página de descarga ==="
cat > "output/download-v${VERSION}.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Descargar NubemLinux-AICorp v${VERSION}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .download-box { background: #f0f0f0; padding: 20px; border-radius: 10px; margin: 20px 0; }
        .button { background: #0D7377; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
        .checksum { font-family: monospace; background: #f9f9f9; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>NubemLinux-AICorp v${VERSION}</h1>
    
    <div class="download-box">
        <h2>Descarga directa</h2>
        <a href="${GDRIVE_LINK:-#}" class="button">Descargar desde Google Drive</a>
        <p>Tamaño: $(du -h "$UPLOAD_FILE" | cut -f1)</p>
    </div>
    
    <div class="download-box">
        <h2>Verificación</h2>
        <p>SHA256:</p>
        <div class="checksum">$(cat "${UPLOAD_FILE}.sha256")</div>
        <p>MD5:</p>
        <div class="checksum">$(cat "${UPLOAD_FILE}.md5")</div>
    </div>
    
    <div class="download-box">
        <h2>Instrucciones</h2>
        <ol>
            <li>Descargar la ISO</li>
            <li>Verificar checksum: <code>sha256sum -c $(basename "$UPLOAD_FILE").sha256</code></li>
            <li>Crear USB booteable: <code>dd if=$(basename "$UPLOAD_FILE") of=/dev/sdX bs=4M</code></li>
            <li>Arrancar desde USB e instalar</li>
        </ol>
    </div>
</body>
</html>
EOF

echo
echo "=== Release Completado ==="
echo
echo "Resumen:"
echo "- Versión: ${VERSION}"
echo "- ISO: $(basename "$UPLOAD_FILE")"
echo "- Tamaño: $(du -h "$UPLOAD_FILE" | cut -f1)"
if [ ! -z "$GDRIVE_LINK" ]; then
    echo "- Google Drive: $GDRIVE_LINK"
fi
echo "- GitHub Release: https://github.com/NUbem000/NubemLinux-AICorp/releases/tag/v${VERSION}"
echo
echo "Archivos generados:"
echo "- ${UPLOAD_FILE}"
echo "- ${UPLOAD_FILE}.sha256"
echo "- ${UPLOAD_FILE}.md5"
echo "- output/download-v${VERSION}.html"
echo "- release-notes-${VERSION}.md"