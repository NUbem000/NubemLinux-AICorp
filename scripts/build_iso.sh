#!/bin/bash
# Construir ISO final de NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
build_iso() {
    log_message "INFO" "Iniciando construcción de ISO"
    
    local chroot_dir="${BUILD_DIR}/squashfs"
    local iso_dir="${BUILD_DIR}/custom"
    local output_iso="${OUTPUT_DIR}/nubemlinux-aicorp-${NUBEMLINUX_VERSION}.iso"
    
    # Preparar filesystem
    prepare_filesystem "$chroot_dir" "$iso_dir"
    
    # Actualizar archivos de arranque
    update_boot_files "$iso_dir"
    
    # Crear nuevo squashfs
    create_squashfs "$chroot_dir" "$iso_dir"
    
    # Actualizar checksums
    update_checksums "$iso_dir"
    
    # Construir ISO
    build_final_iso "$iso_dir" "$output_iso"
    
    log_message "SUCCESS" "ISO construida: $output_iso"
    return 0
}

# Preparar filesystem
prepare_filesystem() {
    local chroot_dir=$1
    local iso_dir=$2
    
    log_message "INFO" "Preparando filesystem para ISO"
    
    # Limpiar archivos temporales del chroot
    rm -rf "$chroot_dir/tmp/*"
    rm -rf "$chroot_dir/var/cache/apt/archives/*"
    
    # Actualizar /etc/resolv.conf
    echo "nameserver 8.8.8.8" > "$chroot_dir/etc/resolv.conf"
    
    # Establecer hostname
    echo "$NUBEMLINUX_CODENAME" > "$chroot_dir/etc/hostname"
    
    # Actualizar /etc/hosts
    cat > "$chroot_dir/etc/hosts" <<EOF
127.0.0.1       localhost
127.0.1.1       $NUBEMLINUX_CODENAME
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

    # Crear archivo de versión
    cat > "$chroot_dir/etc/nubemlinux-release" <<EOF
NUBEMLINUX_VERSION="$NUBEMLINUX_VERSION"
NUBEMLINUX_CODENAME="$NUBEMLINUX_CODENAME"
UBUNTU_BASE="$UBUNTU_VERSION"
BUILD_DATE="$(date +%Y%m%d)"
BUILD_TIME="$(date +%H%M%S)"
EOF

    # Configurar usuario por defecto
    configure_default_user "$chroot_dir"
    
    return 0
}

# Configurar usuario por defecto
configure_default_user() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando usuario por defecto"
    
    # Crear script de configuración inicial
    cat > "$chroot_dir/usr/local/bin/nubemlinux-first-run" <<'EOF'
#!/bin/bash
# Script de configuración inicial de NubemLinux

# Verificar si es la primera ejecución
if [ -f /etc/nubemlinux-configured ]; then
    exit 0
fi

# Mostrar diálogo de bienvenida
zenity --info --title="Bienvenido a NubemLinux-AICorp" \
    --text="Bienvenido a NubemLinux-AICorp v1.0.0\n\nEste asistente le ayudará a configurar su sistema."

# Configurar nombre de usuario
while true; do
    USERNAME=$(zenity --entry --title="Configuración de Usuario" \
        --text="Ingrese el nombre de usuario:")
    
    if [ -n "$USERNAME" ]; then
        break
    fi
done

# Configurar contraseña
while true; do
    PASSWORD=$(zenity --password --title="Configuración de Contraseña")
    PASSWORD2=$(zenity --password --title="Confirmar Contraseña")
    
    if [ "$PASSWORD" = "$PASSWORD2" ] && [ -n "$PASSWORD" ]; then
        break
    else
        zenity --error --text="Las contraseñas no coinciden o están vacías"
    fi
done

# Crear usuario
useradd -m -s /bin/bash -G sudo,audio,video,plugdev "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Configurar autologin (opcional)
if zenity --question --text="¿Desea habilitar el inicio de sesión automático?"; then
    sed -i "s/#  AutomaticLoginEnable = true/AutomaticLoginEnable = true/" /etc/gdm3/custom.conf
    sed -i "s/#  AutomaticLogin = user1/AutomaticLogin = $USERNAME/" /etc/gdm3/custom.conf
fi

# Configurar IA
zenity --info --text="Configurando componentes de IA..."

# Inicializar Ollama
systemctl start ollama
sleep 5

# Configurar NubemCopilot
mkdir -p "/home/$USERNAME/.config/nubemcopilot"
cat > "/home/$USERNAME/.config/nubemcopilot/config.json" <<EOL
{
    "username": "$USERNAME",
    "model": "llama3.1",
    "language": "es",
    "enable_voice": true,
    "enable_vision": true
}
EOL

chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config"

# Marcar como configurado
touch /etc/nubemlinux-configured

zenity --info --text="Configuración completada.\n\nEl sistema se reiniciará ahora."

# Reiniciar
reboot
EOF

    chmod +x "$chroot_dir/usr/local/bin/nubemlinux-first-run"
    
    # Crear servicio para primera ejecución
    cat > "$chroot_dir/etc/systemd/system/nubemlinux-first-run.service" <<EOF
[Unit]
Description=NubemLinux First Run Configuration
After=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nubemlinux-first-run
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

    chroot "$chroot_dir" systemctl enable nubemlinux-first-run.service
    
    return 0
}

# Actualizar archivos de arranque
update_boot_files() {
    local iso_dir=$1
    
    log_message "INFO" "Actualizando archivos de arranque"
    
    # Actualizar isolinux.cfg
    cat > "$iso_dir/isolinux/isolinux.cfg" <<EOF
default vesamenu.c32
prompt 0
timeout 100

menu title NubemLinux-AICorp Boot Menu
menu background splash.png
menu color border 30;44 #40ffffff #a0000000 std
menu color title 1;36;44 #c0ffffff #a0000000 std
menu color sel 7;37;40 #e0ffffff #20ffffff all
menu color unsel 37;44 #50ffffff #a0000000 std
menu color help 37;40 #c0ffffff #a0000000 std
menu color timeout_msg 37;40 #80ffffff #00000000 std
menu color timeout 1;37;40 #c0ffffff #00000000 std
menu color msg07 37;40 #90ffffff #a0000000 std
menu color tabmsg 31;40 #30ffffff #00000000 std

label live
  menu label ^Probar NubemLinux-AICorp
  kernel /casper/vmlinuz
  append  file=/cdrom/preseed/ubuntu.seed boot=casper initrd=/casper/initrd quiet splash ---

label install
  menu label ^Instalar NubemLinux-AICorp
  kernel /casper/vmlinuz
  append  file=/cdrom/preseed/ubuntu.seed boot=casper only-ubiquity initrd=/casper/initrd quiet splash ---

label memtest
  menu label Test de ^memoria
  kernel /install/memtest

label hd
  menu label ^Arrancar desde disco duro
  localboot 0x80
EOF

    # Actualizar grub.cfg
    cat > "$iso_dir/boot/grub/grub.cfg" <<EOF
set default=0
set timeout=10

menuentry "Probar NubemLinux-AICorp" {
    linux /casper/vmlinuz file=/cdrom/preseed/ubuntu.seed boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Instalar NubemLinux-AICorp" {
    linux /casper/vmlinuz file=/cdrom/preseed/ubuntu.seed boot=casper only-ubiquity quiet splash ---
    initrd /casper/initrd
}

menuentry "Verificar disco" {
    linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
    initrd /casper/initrd
}

menuentry "Test de memoria" {
    linux16 /install/memtest
}
EOF

    # Copiar splash screens
    cp "$ASSETS_DIR/branding/splash.png" "$iso_dir/isolinux/"
    
    # Actualizar README.diskdefines
    cat > "$iso_dir/README.diskdefines" <<EOF
#define DISKNAME  NubemLinux-AICorp ${NUBEMLINUX_VERSION}
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

    return 0
}

# Crear nuevo squashfs
create_squashfs() {
    local chroot_dir=$1
    local iso_dir=$2
    
    log_message "INFO" "Creando nuevo filesystem.squashfs"
    
    # Crear manifest
    chroot "$chroot_dir" dpkg-query -W > "$iso_dir/casper/filesystem.manifest"
    
    # Crear squashfs
    mksquashfs "$chroot_dir" "$iso_dir/casper/filesystem.squashfs" \
        -comp xz -b 1M -noappend
    
    # Crear filesystem.size
    du -sx --block-size=1 "$chroot_dir" | cut -f1 > "$iso_dir/casper/filesystem.size"
    
    return 0
}

# Actualizar checksums
update_checksums() {
    local iso_dir=$1
    
    log_message "INFO" "Actualizando checksums"
    
    cd "$iso_dir"
    
    # Eliminar archivos antiguos
    rm -f md5sum.txt SHA256SUMS
    
    # Generar nuevos checksums
    find . -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt
    find . -type f -print0 | xargs -0 sha256sum | grep -v isolinux/boot.cat > SHA256SUMS
    
    cd "$BASE_DIR"
    
    return 0
}

# Construir ISO final
build_final_iso() {
    local iso_dir=$1
    local output_iso=$2
    
    log_message "INFO" "Construyendo ISO final"
    
    # Crear ISO con xorriso
    xorriso -as mkisofs \
        -D \
        -r \
        -V "NUBEMLINUX_${NUBEMLINUX_VERSION}" \
        -cache-inodes \
        -J \
        -l \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -o "$output_iso" \
        "$iso_dir"
    
    # Hacer ISO híbrida para USB
    isohybrid --uefi "$output_iso"
    
    # Calcular checksum de la ISO final
    sha256sum "$output_iso" > "${output_iso}.sha256"
    
    # Establecer permisos
    chmod 644 "$output_iso"
    chmod 644 "${output_iso}.sha256"
    
    log_message "SUCCESS" "ISO creada: $output_iso"
    log_message "INFO" "SHA256: $(cat ${output_iso}.sha256)"
    
    return 0
}

# Función para personalización adicional con Cubic
use_cubic_customization() {
    local iso_file=$1
    
    log_message "INFO" "Preparando para personalización con Cubic"
    
    # Crear proyecto Cubic
    cat > "${OUTPUT_DIR}/cubic-project.txt" <<EOF
Proyecto Cubic para NubemLinux-AICorp
====================================

ISO Original: $iso_file
Versión: ${NUBEMLINUX_VERSION}

Instrucciones para personalización adicional:

1. Abrir Cubic
2. Cargar la ISO: $iso_file
3. Aplicar personalizaciones adicionales:
   - Instalar aplicaciones adicionales
   - Configurar temas adicionales
   - Ajustar configuraciones específicas

4. Generar ISO final
5. Guardar como: nubemlinux-aicorp-${NUBEMLINUX_VERSION}-final.iso

Notas:
- Los componentes base ya están instalados
- La configuración de seguridad está aplicada
- Los servicios de IA están configurados
EOF

    log_message "INFO" "Instrucciones para Cubic guardadas en: ${OUTPUT_DIR}/cubic-project.txt"
    
    return 0
}

# Ejecutar función principal
build_iso "$@"