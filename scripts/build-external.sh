#!/bin/bash
# Script para construir usando almacenamiento externo

# Verificar si hay un disco externo montado
echo "=== Construcción con almacenamiento externo ==="
echo

# Buscar puntos de montaje con suficiente espacio
echo "Buscando ubicaciones con más de 50GB libres..."
df -h | awk '$4 ~ /[0-9]+G/ && $4+0 > 50 {print $6 " - " $4 " disponibles"}'

# Seleccionar ubicación
read -p "Ingresa la ruta donde construir (o 'exit' para salir): " BUILD_PATH

if [ "$BUILD_PATH" = "exit" ]; then
    exit 0
fi

# Verificar espacio
AVAILABLE=$(df "$BUILD_PATH" | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))

if [ $AVAILABLE_GB -lt 50 ]; then
    echo "Error: Solo hay ${AVAILABLE_GB}GB disponibles, se necesitan 50GB mínimo"
    exit 1
fi

echo "Usando $BUILD_PATH con ${AVAILABLE_GB}GB disponibles"

# Crear estructura en ubicación externa
export BUILD_DIR="$BUILD_PATH/nubemlinux-build"
export OUTPUT_DIR="$BUILD_PATH/nubemlinux-output"
export TEMP_DIR="$BUILD_PATH/nubemlinux-temp"

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$TEMP_DIR"

# Crear enlaces simbólicos
ln -sf "$BUILD_DIR" /root/NubemLinux-AICorp/build
ln -sf "$OUTPUT_DIR" /root/NubemLinux-AICorp/output
ln -sf "$TEMP_DIR" /root/NubemLinux-AICorp/tmp

echo "Estructura creada en $BUILD_PATH"
echo "Ahora puedes ejecutar: ./build_nubemlinux.sh"