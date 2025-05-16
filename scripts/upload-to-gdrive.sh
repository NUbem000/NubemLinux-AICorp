#!/bin/bash
# Script para subir ISOs a Google Drive usando rclone

set -e

# Configuración
ISO_FILE="${1}"
GDRIVE_FOLDER="${2:-NubemLinux-AICorp}"
SHARE_LINK="${3:-true}"

if [ -z "$ISO_FILE" ]; then
    echo "Uso: $0 <archivo.iso> [carpeta_gdrive] [generar_link_compartido]"
    echo "Ejemplo: $0 output/nubemlinux-aicorp-1.0.0.iso NubemLinux-AICorp true"
    exit 1
fi

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: $ISO_FILE no encontrado"
    exit 1
fi

echo "=== Subida a Google Drive ==="
echo "Archivo: $ISO_FILE"
echo "Carpeta destino: $GDRIVE_FOLDER"
echo

# Instalar rclone si no está disponible
if ! command -v rclone &> /dev/null; then
    echo "Instalando rclone..."
    curl https://rclone.org/install.sh | sudo bash
fi

# Verificar si rclone está configurado para Google Drive
if ! rclone listremotes | grep -q "gdrive:"; then
    echo "Configurando rclone para Google Drive..."
    echo "Por favor, sigue las instrucciones:"
    rclone config create gdrive drive
fi

# Crear carpeta en Google Drive si no existe
echo "Creando carpeta en Google Drive..."
rclone mkdir "gdrive:/$GDRIVE_FOLDER" 2>/dev/null || true

# Calcular checksum
echo "Calculando checksum..."
ISO_NAME=$(basename "$ISO_FILE")
sha256sum "$ISO_FILE" > "${ISO_FILE}.sha256"

# Subir archivo
echo "Subiendo $ISO_NAME a Google Drive..."
rclone copy "$ISO_FILE" "gdrive:/$GDRIVE_FOLDER/" --progress

# Subir checksum
echo "Subiendo checksum..."
rclone copy "${ISO_FILE}.sha256" "gdrive:/$GDRIVE_FOLDER/" --progress

# Generar link compartido si se solicita
if [ "$SHARE_LINK" = "true" ]; then
    echo "Generando link compartido..."
    SHARE_URL=$(rclone link "gdrive:/$GDRIVE_FOLDER/$ISO_NAME")
    
    # Crear archivo con información de descarga
    cat > "${ISO_FILE}.download-info.md" <<EOF
# Descarga de $ISO_NAME

## Información del archivo
- **Archivo**: $ISO_NAME
- **Tamaño**: $(du -h "$ISO_FILE" | cut -f1)
- **SHA256**: $(cat "${ISO_FILE}.sha256" | cut -d' ' -f1)

## Enlaces de descarga
- **Google Drive**: $SHARE_URL
- **Carpeta**: https://drive.google.com/drive/folders/$GDRIVE_FOLDER

## Verificación
Después de descargar, verifica la integridad:
\`\`\`bash
sha256sum -c ${ISO_NAME}.sha256
\`\`\`
EOF

    echo "Link compartido: $SHARE_URL"
    echo "Información guardada en: ${ISO_FILE}.download-info.md"
fi

echo
echo "=== Subida completada ==="
echo "Archivos en Google Drive:"
rclone ls "gdrive:/$GDRIVE_FOLDER/"