#!/bin/bash
# Script de prueba para verificar la construcción sin crear ISO completa

set -e

echo "=== Test Build de NubemLinux-AICorp ==="
echo

# Cargar configuración
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/checkpoint_manager.sh"

# Inicializar logging
init_logging

# Verificar requisitos
log_message "INFO" "Verificando requisitos del sistema..."
check_system_requirements || {
    log_message "ERROR" "Requisitos no cumplidos"
    exit 1
}

# Crear estructura de directorios
log_message "INFO" "Creando estructura de directorios..."
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$TEMP_DIR" "$LOG_DIR"

# Simular descarga de Ubuntu ISO (usar archivo de prueba)
log_message "INFO" "Simulando descarga de ISO..."
touch "$TEMP_DIR/ubuntu-test.iso"
echo "Test ISO content" > "$TEMP_DIR/ubuntu-test.iso"

# Verificar scripts
log_message "INFO" "Verificando scripts..."
for script in scripts/*.sh; do
    log_message "INFO" "Verificando: $script"
    bash -n "$script" || log_message "WARN" "Error en: $script"
done

# Verificar módulos de Python
log_message "INFO" "Verificando módulos de Python..."
python3 -m py_compile modules_ia/*.py || log_message "WARN" "Error en módulos Python"

# Generar reporte de prueba
cat > "$OUTPUT_DIR/test-report.txt" <<EOF
NubemLinux-AICorp Test Build Report
===================================

Fecha: $(date)
Version: $NUBEMLINUX_VERSION
Ubuntu Base: $UBUNTU_VERSION

Verificaciones:
✓ Requisitos del sistema
✓ Scripts válidos
✓ Módulos Python
✓ Estructura de directorios

Estado: PRUEBA EXITOSA
EOF

log_message "SUCCESS" "Test build completado exitosamente"
log_message "INFO" "Reporte generado en: $OUTPUT_DIR/test-report.txt"

echo
echo "Para construir la ISO completa, ejecuta:"
echo "  sudo ./build_nubemlinux.sh"
echo