#!/bin/bash
# Script principal de construcción de NubemLinux-AICorp

set -euo pipefail

# Directorio base
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

# Cargar configuración y checkpoint manager
source "${BASE_DIR}/config.env"
source "${BASE_DIR}/checkpoint_manager.sh"

# Tiempo de inicio
BUILD_START_TIME=$(date +%s)

# Inicializar logging
init_logging

# Banner de bienvenida
print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                  NubemLinux-AICorp Builder v${NUBEMLINUX_VERSION}                  ║"
    echo "║                    Building AI-Powered Ubuntu                      ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función principal
main() {
    print_banner
    
    log_message "INFO" "Iniciando construcción de NubemLinux-AICorp v${NUBEMLINUX_VERSION}"
    
    # Verificar si estamos recuperando desde un checkpoint
    local last_checkpoint=$(get_last_checkpoint)
    if [ "$last_checkpoint" != "NONE" ]; then
        log_message "WARN" "Checkpoint detectado: $last_checkpoint"
        read -p "¿Continuar desde el último checkpoint? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_message "INFO" "Iniciando construcción desde cero"
            clear_checkpoints
            last_checkpoint="NONE"
        fi
    fi
    
    # Etapas de construcción
    local stages=(
        "check_requirements"
        "setup_directories"
        "download_ubuntu_iso"
        "extract_iso"
        "install_ai_components"
        "configure_watchdog"
        "apply_branding"
        "apply_security"
        "configure_updates"
        "build_iso"
        "verify_iso"
        "generate_report"
    )
    
    local total_stages=${#stages[@]}
    local current_stage=0
    
    # Ejecutar cada etapa
    for stage in "${stages[@]}"; do
        current_stage=$((current_stage + 1))
        
        # Verificar si la etapa ya está completada
        if is_stage_completed "$stage"; then
            log_message "INFO" "Etapa ya completada: $stage"
            continue
        fi
        
        log_message "INFO" "Ejecutando etapa: $stage ($current_stage/$total_stages)"
        show_progress $current_stage $total_stages "$stage"
        
        # Ejecutar la función correspondiente
        if execute_stage "$stage"; then
            save_checkpoint "$stage" "completed" ""
            log_message "SUCCESS" "Etapa completada: $stage"
        else
            save_checkpoint "$stage" "failed" ""
            log_message "ERROR" "Fallo en etapa: $stage"
            return 1
        fi
        
        estimate_time_remaining $current_stage $total_stages $BUILD_START_TIME
    done
    
    # Tiempo total de construcción
    local build_end_time=$(date +%s)
    local total_time=$((build_end_time - BUILD_START_TIME))
    local hours=$((total_time / 3600))
    local minutes=$(((total_time % 3600) / 60))
    local seconds=$((total_time % 60))
    
    log_message "SUCCESS" "Construcción completada en: ${hours}h ${minutes}m ${seconds}s"
    generate_build_report "${hours}h ${minutes}m ${seconds}s"
    
    log_message "INFO" "ISO disponible en: ${OUTPUT_DIR}/nubemlinux-aicorp-${NUBEMLINUX_VERSION}.iso"
}

# Función para ejecutar etapas
execute_stage() {
    local stage=$1
    
    case $stage in
        "check_requirements")
            check_system_requirements
            ;;
        "setup_directories")
            setup_directories
            ;;
        "download_ubuntu_iso")
            download_ubuntu_iso
            ;;
        "extract_iso")
            extract_iso
            ;;
        "install_ai_components")
            install_ai_components
            ;;
        "configure_watchdog")
            configure_watchdog
            ;;
        "apply_branding")
            apply_branding
            ;;
        "apply_security")
            apply_security
            ;;
        "configure_updates")
            configure_updates
            ;;
        "build_iso")
            build_iso
            ;;
        "verify_iso")
            verify_iso
            ;;
        "generate_report")
            generate_final_report
            ;;
        *)
            log_message "ERROR" "Etapa desconocida: $stage"
            return 1
            ;;
    esac
}

# Función para configurar directorios
setup_directories() {
    log_message "INFO" "Configurando directorios de trabajo"
    
    local dirs=(
        "$BUILD_DIR"
        "$OUTPUT_DIR"
        "$TEMP_DIR"
        "$LOG_DIR"
        "${BUILD_DIR}/iso"
        "${BUILD_DIR}/squashfs"
        "${BUILD_DIR}/custom"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log_message "SUCCESS" "Directorio creado: $dir"
    done
    
    return 0
}

# Función para descargar ISO de Ubuntu
download_ubuntu_iso() {
    log_message "INFO" "Descargando ISO de Ubuntu ${UBUNTU_VERSION}"
    
    local iso_file="${TEMP_DIR}/ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso"
    local sha256_file="${TEMP_DIR}/SHA256SUMS"
    
    # Descargar ISO si no existe
    if [ ! -f "$iso_file" ]; then
        execute_with_retry "wget -c -O '$iso_file' '$UBUNTU_ISO_URL'" 5 10
    else
        log_message "INFO" "ISO ya descargada, verificando integridad"
    fi
    
    # Verificar SHA256
    execute_with_retry "wget -O '$sha256_file' '$UBUNTU_ISO_SHA256'" 3 5
    
    log_message "INFO" "Verificando checksum SHA256"
    cd "$TEMP_DIR"
    if sha256sum -c "$sha256_file" --ignore-missing | grep -q "OK"; then
        log_message "SUCCESS" "ISO verificada correctamente"
    else
        log_message "ERROR" "Checksum SHA256 no coincide"
        return 1
    fi
    cd "$BASE_DIR"
    
    return 0
}

# Función para extraer ISO
extract_iso() {
    log_message "INFO" "Extrayendo ISO de Ubuntu"
    
    local iso_file="${TEMP_DIR}/ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso"
    local iso_mount="${BUILD_DIR}/iso"
    
    # Montar ISO
    execute_with_retry "mount -o loop '$iso_file' '$iso_mount'" 3 5
    
    # Copiar contenido
    log_message "INFO" "Copiando contenido de la ISO"
    rsync -av --exclude=/casper/filesystem.squashfs "$iso_mount/" "${BUILD_DIR}/custom/"
    
    # Desmontar ISO
    umount "$iso_mount"
    
    # Extraer squashfs
    log_message "INFO" "Extrayendo sistema de archivos squashfs"
    unsquashfs -d "${BUILD_DIR}/squashfs" "${iso_mount}/casper/filesystem.squashfs"
    
    return 0
}

# Las demás funciones se implementarán en archivos separados en la carpeta scripts/
install_ai_components() {
    "${SCRIPTS_DIR}/install_ai_components.sh"
}

configure_watchdog() {
    "${SCRIPTS_DIR}/configure_watchdog.sh"
}

apply_branding() {
    "${SCRIPTS_DIR}/apply_branding.sh"
}

apply_security() {
    "${SCRIPTS_DIR}/apply_security.sh"
}

configure_updates() {
    "${SCRIPTS_DIR}/configure_updates.sh"
}

build_iso() {
    "${SCRIPTS_DIR}/build_iso.sh"
}

verify_iso() {
    "${SCRIPTS_DIR}/verify_iso.sh"
}

generate_final_report() {
    log_message "INFO" "Generando reporte final de construcción"
    
    # El reporte ya se genera en checkpoint_manager.sh
    return 0
}

# Manejo de señales para limpieza
cleanup() {
    log_message "WARN" "Interrupción detectada, limpiando..."
    
    # Desmontar si está montado
    if mountpoint -q "${BUILD_DIR}/iso"; then
        umount "${BUILD_DIR}/iso"
    fi
    
    # Guardar checkpoint de interrupción
    save_checkpoint "interrupted" "failed" "Build interrupted by user"
    
    exit 1
}

trap cleanup SIGINT SIGTERM

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    log_message "ERROR" "Este script debe ejecutarse como root"
    exit 1
fi

# Ejecutar función principal
main "$@"