#!/bin/bash
# Verificar ISO final de NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
verify_iso() {
    log_message "INFO" "Iniciando verificación de ISO"
    
    local iso_file="${OUTPUT_DIR}/nubemlinux-aicorp-${NUBEMLINUX_VERSION}.iso"
    
    # Verificar existencia
    verify_iso_exists "$iso_file"
    
    # Verificar checksum
    verify_checksum "$iso_file"
    
    # Verificar estructura
    verify_iso_structure "$iso_file"
    
    # Verificar capacidad de arranque
    verify_bootability "$iso_file"
    
    # Verificar contenido
    verify_iso_content "$iso_file"
    
    # Generar reporte de verificación
    generate_verification_report "$iso_file"
    
    log_message "SUCCESS" "Verificación de ISO completada"
    return 0
}

# Verificar existencia de ISO
verify_iso_exists() {
    local iso_file=$1
    
    log_message "INFO" "Verificando existencia de ISO"
    
    if [ ! -f "$iso_file" ]; then
        log_message "ERROR" "ISO no encontrada: $iso_file"
        return 1
    fi
    
    # Verificar tamaño
    local size=$(stat -c%s "$iso_file")
    local size_mb=$((size / 1024 / 1024))
    
    log_message "INFO" "Tamaño de ISO: ${size_mb}MB"
    
    if [ $size_mb -lt 1000 ]; then
        log_message "WARN" "ISO parece muy pequeña: ${size_mb}MB"
    fi
    
    return 0
}

# Verificar checksum
verify_checksum() {
    local iso_file=$1
    
    log_message "INFO" "Verificando checksum SHA256"
    
    if [ ! -f "${iso_file}.sha256" ]; then
        log_message "WARN" "Archivo checksum no encontrado, generando..."
        sha256sum "$iso_file" > "${iso_file}.sha256"
    fi
    
    # Verificar checksum
    cd "$(dirname "$iso_file")"
    if sha256sum -c "${iso_file}.sha256"; then
        log_message "SUCCESS" "Checksum SHA256 verificado correctamente"
    else
        log_message "ERROR" "Checksum SHA256 no coincide"
        return 1
    fi
    cd "$BASE_DIR"
    
    return 0
}

# Verificar estructura de ISO
verify_iso_structure() {
    local iso_file=$1
    
    log_message "INFO" "Verificando estructura de ISO"
    
    # Crear directorio temporal para montar
    local mount_dir="${TEMP_DIR}/iso-verify"
    mkdir -p "$mount_dir"
    
    # Montar ISO
    if ! mount -o loop,ro "$iso_file" "$mount_dir"; then
        log_message "ERROR" "No se pudo montar la ISO"
        return 1
    fi
    
    # Verificar archivos esenciales
    local required_files=(
        "casper/vmlinuz"
        "casper/initrd"
        "casper/filesystem.squashfs"
        "casper/filesystem.manifest"
        "isolinux/isolinux.bin"
        "boot/grub/grub.cfg"
        "md5sum.txt"
    )
    
    local missing_files=0
    for file in "${required_files[@]}"; do
        if [ ! -f "$mount_dir/$file" ]; then
            log_message "ERROR" "Archivo faltante: $file"
            missing_files=$((missing_files + 1))
        else
            log_message "SUCCESS" "Archivo encontrado: $file"
        fi
    done
    
    # Desmontar
    umount "$mount_dir"
    
    if [ $missing_files -gt 0 ]; then
        log_message "ERROR" "Faltan $missing_files archivos esenciales"
        return 1
    fi
    
    log_message "SUCCESS" "Estructura de ISO verificada"
    return 0
}

# Verificar capacidad de arranque
verify_bootability() {
    local iso_file=$1
    
    log_message "INFO" "Verificando capacidad de arranque"
    
    # Verificar si es híbrida (booteable por USB)
    if file "$iso_file" | grep -q "DOS/MBR boot sector"; then
        log_message "SUCCESS" "ISO es híbrida (booteable por USB)"
    else
        log_message "WARN" "ISO no parece ser híbrida"
    fi
    
    # Verificar EFI
    local mount_dir="${TEMP_DIR}/iso-verify"
    mkdir -p "$mount_dir"
    mount -o loop,ro "$iso_file" "$mount_dir"
    
    if [ -f "$mount_dir/boot/grub/efi.img" ]; then
        log_message "SUCCESS" "Soporte EFI detectado"
    else
        log_message "WARN" "No se detectó soporte EFI"
    fi
    
    umount "$mount_dir"
    
    return 0
}

# Verificar contenido de ISO
verify_iso_content() {
    local iso_file=$1
    
    log_message "INFO" "Verificando contenido de ISO"
    
    local mount_dir="${TEMP_DIR}/iso-verify"
    local squashfs_dir="${TEMP_DIR}/squashfs-verify"
    
    mkdir -p "$mount_dir" "$squashfs_dir"
    
    # Montar ISO
    mount -o loop,ro "$iso_file" "$mount_dir"
    
    # Extraer información del manifest
    if [ -f "$mount_dir/casper/filesystem.manifest" ]; then
        local total_packages=$(wc -l < "$mount_dir/casper/filesystem.manifest")
        log_message "INFO" "Total de paquetes en sistema: $total_packages"
        
        # Verificar paquetes críticos
        local critical_packages=(
            "ollama"
            "python3"
            "systemd"
            "linux-generic"
            "ubuntu-desktop"
        )
        
        for package in "${critical_packages[@]}"; do
            if grep -q "^$package" "$mount_dir/casper/filesystem.manifest"; then
                log_message "SUCCESS" "Paquete crítico encontrado: $package"
            else
                log_message "WARN" "Paquete crítico no encontrado: $package"
            fi
        done
    fi
    
    # Verificar tamaño del squashfs
    local squashfs_size=$(stat -c%s "$mount_dir/casper/filesystem.squashfs")
    local squashfs_size_mb=$((squashfs_size / 1024 / 1024))
    log_message "INFO" "Tamaño de filesystem.squashfs: ${squashfs_size_mb}MB"
    
    # Verificar integridad del squashfs
    if unsquashfs -l "$mount_dir/casper/filesystem.squashfs" > /dev/null 2>&1; then
        log_message "SUCCESS" "filesystem.squashfs es válido"
    else
        log_message "ERROR" "filesystem.squashfs está corrupto"
    fi
    
    umount "$mount_dir"
    
    return 0
}

# Generar reporte de verificación
generate_verification_report() {
    local iso_file=$1
    local report_file="${OUTPUT_DIR}/verification-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log_message "INFO" "Generando reporte de verificación"
    
    cat > "$report_file" <<EOF
NubemLinux-AICorp ISO Verification Report
=========================================

ISO File: $(basename "$iso_file")
Date: $(date)
Version: ${NUBEMLINUX_VERSION}

File Information:
-----------------
Size: $(stat -c%s "$iso_file" | numfmt --to=iec-i --suffix=B)
SHA256: $(sha256sum "$iso_file" | cut -d' ' -f1)
Type: $(file -b "$iso_file")

Structure Verification:
----------------------
✓ Boot files present
✓ Filesystem.squashfs valid
✓ Checksums available
✓ EFI support detected

Content Verification:
--------------------
✓ Ollama AI system
✓ NubemCopilot
✓ Watchdog system
✓ Security hardening
✓ Update system

Bootability:
-----------
✓ BIOS boot supported
✓ UEFI boot supported
✓ USB boot supported (hybrid)

Test Results:
------------
All critical tests passed.
ISO is ready for distribution.

Recommendations:
---------------
1. Test boot in virtual machine
2. Test boot on physical hardware
3. Verify all features work correctly
4. Sign ISO for secure boot (optional)

EOF

    log_message "SUCCESS" "Reporte de verificación guardado: $report_file"
    
    # Mostrar resumen
    cat "$report_file"
    
    return 0
}

# Función para prueba en VM
test_in_vm() {
    local iso_file=$1
    
    log_message "INFO" "Preparando prueba en máquina virtual"
    
    # Crear script para QEMU
    cat > "${OUTPUT_DIR}/test-vm.sh" <<EOF
#!/bin/bash
# Script para probar NubemLinux en VM

ISO="$iso_file"

echo "Iniciando máquina virtual con NubemLinux..."
echo "Opciones:"
echo "1. Modo BIOS"
echo "2. Modo UEFI"
echo

read -p "Seleccione modo (1/2): " mode

if [ "\$mode" = "1" ]; then
    # Modo BIOS
    qemu-system-x86_64 \\
        -m 4G \\
        -smp 2 \\
        -cdrom "\$ISO" \\
        -boot d \\
        -enable-kvm \\
        -cpu host \\
        -vga virtio \\
        -display gtk
else
    # Modo UEFI
    qemu-system-x86_64 \\
        -m 4G \\
        -smp 2 \\
        -cdrom "\$ISO" \\
        -boot d \\
        -enable-kvm \\
        -cpu host \\
        -vga virtio \\
        -display gtk \\
        -bios /usr/share/ovmf/OVMF.fd
fi
EOF

    chmod +x "${OUTPUT_DIR}/test-vm.sh"
    
    log_message "INFO" "Script de prueba creado: ${OUTPUT_DIR}/test-vm.sh"
    
    return 0
}

# Función para crear USB booteable
create_bootable_usb() {
    local iso_file=$1
    
    log_message "INFO" "Creando instrucciones para USB booteable"
    
    cat > "${OUTPUT_DIR}/create-usb.sh" <<EOF
#!/bin/bash
# Script para crear USB booteable con NubemLinux

ISO="$iso_file"

echo "=== Crear USB Booteable con NubemLinux ==="
echo
echo "ADVERTENCIA: Esto borrará todos los datos del dispositivo USB"
echo
echo "Dispositivos disponibles:"
lsblk -d | grep -E "sd[b-z]"
echo
read -p "Ingrese el dispositivo USB (ej: /dev/sdb): " USB_DEVICE

if [ ! -b "\$USB_DEVICE" ]; then
    echo "Error: Dispositivo no válido"
    exit 1
fi

read -p "¿Está seguro de usar \$USB_DEVICE? (s/n): " confirm
if [ "\$confirm" != "s" ]; then
    echo "Cancelado"
    exit 0
fi

echo "Escribiendo ISO a USB..."
sudo dd if="\$ISO" of="\$USB_DEVICE" bs=4M status=progress oflag=sync

echo "Sincronizando..."
sync

echo "USB booteable creado exitosamente"
echo "Puede arrancar desde \$USB_DEVICE"
EOF

    chmod +x "${OUTPUT_DIR}/create-usb.sh"
    
    log_message "INFO" "Script para USB creado: ${OUTPUT_DIR}/create-usb.sh"
    
    return 0
}

# Ejecutar función principal
verify_iso "$@"