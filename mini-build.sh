#!/bin/bash
# Mini build para sistemas con espacio limitado - Solo componentes esenciales

set -e

echo "=== Mini Build de NubemLinux-AICorp ==="
echo "ADVERTENCIA: Esta es una versión reducida para pruebas"
echo

# Cargar configuración
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/checkpoint_manager.sh"

# Sobrescribir requisitos mínimos para prueba
MIN_DISK_GB=20

# Crear estructura mínima
mkdir -p "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR/iso-contents"

# 1. Crear estructura de ISO mínima
echo "Creando estructura ISO mínima..."
mkdir -p "$BUILD_DIR/iso-contents/casper"
mkdir -p "$BUILD_DIR/iso-contents/isolinux"
mkdir -p "$BUILD_DIR/iso-contents/boot/grub"

# 2. Crear archivos de configuración básicos
cat > "$BUILD_DIR/iso-contents/isolinux/isolinux.cfg" <<EOF
default live
label live
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---
EOF

cat > "$BUILD_DIR/iso-contents/boot/grub/grub.cfg" <<EOF
menuentry "NubemLinux-AICorp Mini" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}
EOF

# 3. Crear README
cat > "$BUILD_DIR/iso-contents/README.txt" <<EOF
NubemLinux-AICorp v${NUBEMLINUX_VERSION} - Mini Build
===============================================

Esta es una versión reducida para pruebas.
Para la versión completa, ejecute build_nubemlinux.sh

Características incluidas:
- Configuración básica
- Scripts de instalación
- Documentación

Características NO incluidas:
- Sistema completo Ubuntu
- Modelos de IA
- Interfaz gráfica

Para más información: https://github.com/NUbem000/NubemLinux-AICorp
EOF

# 4. Copiar scripts y documentación
echo "Copiando scripts y documentación..."
cp -r scripts "$BUILD_DIR/iso-contents/"
cp -r docs "$BUILD_DIR/iso-contents/"
cp README.md "$BUILD_DIR/iso-contents/"
cp LICENSE "$BUILD_DIR/iso-contents/"

# 5. Crear ISO mínima
echo "Creando ISO mínima..."
cd "$BUILD_DIR/iso-contents"

# Crear ISO simple (sin bootloader completo)
genisoimage -r -V "NUBEMLINUX_MINI" \
    -cache-inodes \
    -J -l \
    -o "$OUTPUT_DIR/nubemlinux-mini-${NUBEMLINUX_VERSION}.iso" \
    .

cd "$BASE_DIR"

# 6. Generar checksums
echo "Generando checksums..."
cd "$OUTPUT_DIR"
sha256sum nubemlinux-mini-${NUBEMLINUX_VERSION}.iso > nubemlinux-mini-${NUBEMLINUX_VERSION}.iso.sha256

echo
echo "=== Mini Build Completado ==="
echo "ISO: $OUTPUT_DIR/nubemlinux-mini-${NUBEMLINUX_VERSION}.iso"
echo "SHA256: $(cat $OUTPUT_DIR/nubemlinux-mini-${NUBEMLINUX_VERSION}.iso.sha256)"
echo
echo "NOTA: Esta es una ISO de prueba que contiene solo scripts y documentación."
echo "Para construir la ISO completa con Ubuntu, ejecute ./build_nubemlinux.sh"
echo