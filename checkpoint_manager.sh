#!/bin/bash
# Sistema de gestión de checkpoints y logging

source "$(dirname "$0")/config.env"

# Crear directorios necesarios
mkdir -p "$LOG_DIR"

# Inicializar archivo de log
init_logging() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    log_message "INFO" "Sistema de logging inicializado"
}

# Función para registrar mensajes
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${timestamp} [${GREEN}INFO${NC}] $message"
            ;;
        "WARN")
            echo -e "${timestamp} [${YELLOW}WARN${NC}] $message"
            ;;
        "ERROR")
            echo -e "${timestamp} [${RED}ERROR${NC}] $message"
            ;;
        "SUCCESS")
            echo -e "${timestamp} [${GREEN}SUCCESS${NC}] $message"
            ;;
        *)
            echo -e "${timestamp} [${BLUE}$level${NC}] $message"
            ;;
    esac
}

# Función para guardar checkpoint
save_checkpoint() {
    local stage=$1
    local status=$2
    local data=$3
    
    log_message "INFO" "Guardando checkpoint: $stage"
    
    cat > "$CHECKPOINT_FILE" <<EOF
STAGE=$stage
STATUS=$status
TIMESTAMP=$(date +%s)
DATA=$data
EOF
    
    log_message "SUCCESS" "Checkpoint guardado: $stage"
}

# Función para recuperar último checkpoint
get_last_checkpoint() {
    if [ -f "$CHECKPOINT_FILE" ]; then
        source "$CHECKPOINT_FILE"
        echo "$STAGE"
    else
        echo "NONE"
    fi
}

# Función para verificar si un stage está completado
is_stage_completed() {
    local stage=$1
    local last_checkpoint=$(get_last_checkpoint)
    
    if [ -f "$CHECKPOINT_FILE" ]; then
        source "$CHECKPOINT_FILE"
        if [[ "$STAGE" == "$stage" && "$STATUS" == "completed" ]]; then
            return 0
        fi
    fi
    return 1
}

# Función para limpiar checkpoints
clear_checkpoints() {
    log_message "INFO" "Limpiando checkpoints anteriores"
    rm -f "$CHECKPOINT_FILE"
    log_message "SUCCESS" "Checkpoints limpiados"
}

# Función para ejecutar con retry
execute_with_retry() {
    local command=$1
    local max_retries=${2:-3}
    local retry_delay=${3:-5}
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        log_message "INFO" "Ejecutando: $command (intento $((retry_count + 1))/$max_retries)"
        
        if eval "$command"; then
            log_message "SUCCESS" "Comando ejecutado exitosamente"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log_message "WARN" "Comando falló, reintentando en $retry_delay segundos..."
                sleep $retry_delay
            fi
        fi
    done
    
    log_message "ERROR" "Comando falló después de $max_retries intentos"
    return 1
}

# Función para verificar requisitos del sistema
check_system_requirements() {
    log_message "INFO" "Verificando requisitos del sistema"
    
    # Verificar RAM
    local total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ $total_ram -lt $MIN_RAM_GB ]; then
        log_message "ERROR" "RAM insuficiente: ${total_ram}GB (mínimo: ${MIN_RAM_GB}GB)"
        return 1
    fi
    log_message "SUCCESS" "RAM: ${total_ram}GB OK"
    
    # Verificar espacio en disco
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $free_space -lt $MIN_DISK_GB ]; then
        log_message "ERROR" "Espacio en disco insuficiente: ${free_space}GB (mínimo: ${MIN_DISK_GB}GB)"
        return 1
    fi
    log_message "SUCCESS" "Espacio en disco: ${free_space}GB OK"
    
    # Verificar herramientas necesarias
    local required_tools=("wget" "curl" "git" "python3" "debootstrap" "squashfs-tools" "xorriso" "grub-pc-bin" "grub-efi-amd64-bin")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            log_message "WARN" "Herramienta faltante: $tool. Instalando..."
            execute_with_retry "apt-get update && apt-get install -y $tool"
        else
            log_message "SUCCESS" "Herramienta disponible: $tool"
        fi
    done
    
    return 0
}

# Función para mostrar progreso
show_progress() {
    local stage=$1
    local total_stages=$2
    local percentage=$((stage * 100 / total_stages))
    
    echo -ne "\r["
    for ((i=0; i<50; i++)); do
        if [ $i -lt $((percentage/2)) ]; then
            echo -ne "="
        else
            echo -ne " "
        fi
    done
    echo -ne "] $percentage% - $3"
}

# Función para calcular y mostrar tiempo estimado
estimate_time_remaining() {
    local current_stage=$1
    local total_stages=$2
    local start_time=$3
    
    local elapsed=$(($(date +%s) - start_time))
    local avg_per_stage=$((elapsed / current_stage))
    local remaining_stages=$((total_stages - current_stage))
    local estimated_remaining=$((avg_per_stage * remaining_stages))
    
    local hours=$((estimated_remaining / 3600))
    local minutes=$(((estimated_remaining % 3600) / 60))
    local seconds=$((estimated_remaining % 60))
    
    log_message "INFO" "Tiempo estimado restante: ${hours}h ${minutes}m ${seconds}s"
}

# Función para generar reporte de build
generate_build_report() {
    local report_file="${OUTPUT_DIR}/build-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log_message "INFO" "Generando reporte de construcción"
    
    cat > "$report_file" <<EOF
NubemLinux-AICorp Build Report
==============================

Versión: $NUBEMLINUX_VERSION
Fecha: $(date)
Tiempo total de construcción: $1

Configuración:
- Ubuntu base: $UBUNTU_VERSION
- RAM del sistema: $(free -g | awk '/^Mem:/{print $2}')GB
- Espacio en disco usado: $(df -BG / | awk 'NR==2 {print $3}')

Módulos incluidos:
$(ls -la "$MODULES_IA_DIR/" 2>/dev/null || echo "Ninguno")

Checkpoints completados:
$(cat "$CHECKPOINT_FILE" 2>/dev/null || echo "Ninguno")

Archivos generados:
$(ls -la "$OUTPUT_DIR/" 2>/dev/null || echo "Ninguno")

EOF
    
    log_message "SUCCESS" "Reporte generado: $report_file"
}

# Exports
export -f log_message
export -f save_checkpoint
export -f get_last_checkpoint
export -f is_stage_completed
export -f execute_with_retry
export -f check_system_requirements
export -f show_progress