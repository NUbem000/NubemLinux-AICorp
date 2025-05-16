#!/bin/bash
# Aplicar configuraciones de seguridad a NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
apply_security() {
    log_message "INFO" "Aplicando configuraciones de seguridad"
    
    local chroot_dir="${BUILD_DIR}/squashfs"
    
    # Instalar herramientas de seguridad
    install_security_tools "$chroot_dir"
    
    # Configurar hardening del kernel
    configure_kernel_hardening "$chroot_dir"
    
    # Configurar firewall (UFW)
    configure_firewall "$chroot_dir"
    
    # Configurar AppArmor
    configure_apparmor "$chroot_dir"
    
    # Configurar AIDE
    configure_aide "$chroot_dir"
    
    # Configurar políticas de contraseñas
    configure_password_policies "$chroot_dir"
    
    # Configurar auditoría
    configure_audit "$chroot_dir"
    
    # Deshabilitar servicios innecesarios
    disable_unnecessary_services "$chroot_dir"
    
    log_message "SUCCESS" "Configuraciones de seguridad aplicadas"
    return 0
}

# Instalar herramientas de seguridad
install_security_tools() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando herramientas de seguridad"
    
    chroot "$chroot_dir" /bin/bash -c "
        apt-get update
        apt-get install -y \
            ufw \
            apparmor \
            apparmor-utils \
            aide \
            aide-common \
            auditd \
            audispd-plugins \
            fail2ban \
            rkhunter \
            chkrootkit \
            libpam-tmpdir \
            libpam-pwquality \
            apt-listchanges \
            debsums \
            needrestart
    "
    
    return 0
}

# Configurar hardening del kernel
configure_kernel_hardening() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando hardening del kernel"
    
    # Configurar parámetros sysctl
    cat >> "$chroot_dir/etc/sysctl.d/99-nubemlinux-security.conf" <<EOF
# NubemLinux Security Hardening

# Protección contra IP spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Deshabilitar redirecciones ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Deshabilitar source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Registro de martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Deshabilitar ping broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Protección contra SYN floods
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Desactivar timestamp
net.ipv4.tcp_timestamps = 0

# Protección de memoria
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1

# Deshabilitar core dumps para SUID
fs.suid_dumpable = 0

# Restricciones de kernel
kernel.kexec_load_disabled = 1
kernel.sysrq = 0

# Protección contra desbordamiento de buffer
kernel.exec-shield = 1
EOF

    # Configurar módulos del kernel
    cat >> "$chroot_dir/etc/modules" <<EOF
# Módulos de seguridad
tcp_syncookies
EOF

    # Blacklist de módulos innecesarios
    cat > "$chroot_dir/etc/modprobe.d/blacklist-nubemlinux.conf" <<EOF
# Módulos blacklisted por seguridad
blacklist rare_protocol
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
EOF

    return 0
}

# Configurar firewall
configure_firewall() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando firewall UFW"
    
    # Configuración básica de UFW
    chroot "$chroot_dir" /bin/bash -c "
        # Configurar políticas por defecto
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        
        # Permitir SSH (con rate limiting)
        ufw limit 22/tcp
        
        # Permitir Ollama (IA local)
        ufw allow 11434/tcp comment 'Ollama AI Service'
        
        # Permitir mDNS
        ufw allow in on any to any port 5353 comment 'mDNS'
        
        # Logging
        ufw logging low
        
        # Habilitar UFW
        echo 'y' | ufw enable
    "
    
    # Configurar reglas adicionales
    cat > "$chroot_dir/etc/ufw/before.rules.add" <<EOF
# Protección contra ataques comunes
-A ufw-before-input -p tcp --tcp-flags ALL NONE -j DROP
-A ufw-before-input -p tcp --tcp-flags ALL ALL -j DROP
-A ufw-before-input -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
-A ufw-before-input -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
EOF

    return 0
}

# Configurar AppArmor
configure_apparmor() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando AppArmor"
    
    # Crear perfil para NubemCopilot
    cat > "$chroot_dir/etc/apparmor.d/opt.nubemcopilot" <<EOF
#include <tunables/global>

/opt/nubemcopilot/nubemcopilot.py {
  #include <abstractions/base>
  #include <abstractions/python>
  #include <abstractions/nameservice>
  
  # Permitir acceso a archivos necesarios
  /opt/nubemcopilot/** r,
  /usr/share/nubemlinux/** r,
  @{HOME}/.config/nubemcopilot/** rw,
  @{HOME}/.cache/nubemcopilot/** rw,
  
  # Permitir conexiones de red
  network inet stream,
  network inet6 stream,
  
  # Permitir ejecución de Ollama
  /usr/local/bin/ollama rix,
  
  # Logs
  /var/log/nubemcopilot/*.log w,
}
EOF

    # Crear perfil para Watchdog
    cat > "$chroot_dir/etc/apparmor.d/opt.nubem-watchdog" <<EOF
#include <tunables/global>

/opt/nubem-watchdog/watchdog.py {
  #include <abstractions/base>
  #include <abstractions/python>
  
  # Capacidades necesarias
  capability sys_nice,
  capability sys_resource,
  capability sys_admin,
  
  # Acceso a archivos
  /opt/nubem-watchdog/** r,
  /etc/nubem-watchdog/** r,
  /var/log/nubem-watchdog/** rw,
  
  # Acceso a /proc y /sys
  @{PROC}/** r,
  @{sys}/** r,
  
  # Permitir systemctl
  /bin/systemctl rix,
  /usr/bin/systemctl rix,
}
EOF

    # Activar perfiles
    chroot "$chroot_dir" /bin/bash -c "
        apparmor_parser -r /etc/apparmor.d/opt.nubemcopilot
        apparmor_parser -r /etc/apparmor.d/opt.nubem-watchdog
    "
    
    return 0
}

# Configurar AIDE
configure_aide() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando AIDE (detección de intrusiones)"
    
    # Configurar AIDE
    cat >> "$chroot_dir/etc/aide/aide.conf" <<EOF

# Configuración adicional para NubemLinux
/opt/nubemcopilot p+i+n+u+g+s+m+c+md5+sha256
/opt/nubem-watchdog p+i+n+u+g+s+m+c+md5+sha256
/etc/nubem-watchdog p+i+n+u+g+s+m+c+md5+sha256
EOF

    # Inicializar base de datos AIDE
    chroot "$chroot_dir" /bin/bash -c "
        aideinit
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    "
    
    # Crear cron para verificación diaria
    cat > "$chroot_dir/etc/cron.daily/aide-check" <<'EOF'
#!/bin/bash
# Verificación diaria de AIDE

/usr/bin/aide.wrapper --check > /var/log/aide/aide-check.log 2>&1

if [ $? -ne 0 ]; then
    # Notificar si se detectan cambios
    echo "AIDE detectó cambios en el sistema" | mail -s "Alerta AIDE - $(hostname)" root
fi
EOF

    chmod +x "$chroot_dir/etc/cron.daily/aide-check"
    
    return 0
}

# Configurar políticas de contraseñas
configure_password_policies() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando políticas de contraseñas"
    
    # Configurar PAM para contraseñas fuertes
    cat > "$chroot_dir/etc/security/pwquality.conf" <<EOF
# Configuración de calidad de contraseñas
minlen = 12
minclass = 3
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
maxrepeat = 3
maxsequence = 3
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
EOF

    # Configurar límites de intentos de login
    cat >> "$chroot_dir/etc/pam.d/common-auth" <<EOF

# Bloqueo después de 5 intentos fallidos
auth required pam_tally2.so deny=5 unlock_time=1800 onerr=fail
EOF

    # Configurar expiración de contraseñas
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' "$chroot_dir/etc/login.defs"
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' "$chroot_dir/etc/login.defs"
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' "$chroot_dir/etc/login.defs"
    
    return 0
}

# Configurar auditoría
configure_audit() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando sistema de auditoría"
    
    # Configurar reglas de auditoría
    cat > "$chroot_dir/etc/audit/rules.d/nubemlinux.rules" <<EOF
# Reglas de auditoría para NubemLinux

# Monitorear cambios en archivos de configuración
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity

# Monitorear uso de privilegios
-w /usr/bin/sudo -p x -k privilege
-w /usr/bin/su -p x -k privilege

# Monitorear acceso a archivos sensibles
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/nubem-watchdog/ -p wa -k watchdog_config

# Monitorear cambios en el kernel
-w /etc/sysctl.conf -p wa -k sysctl
-w /etc/modprobe.conf -p wa -k modprobe

# Monitorear inicio/parada de servicios
-w /usr/bin/systemctl -p x -k systemctl

# Registrar todas las ejecutables
-a always,exit -F arch=b64 -S execve -k exec
EOF

    # Habilitar servicio de auditoría
    chroot "$chroot_dir" systemctl enable auditd.service
    
    return 0
}

# Deshabilitar servicios innecesarios
disable_unnecessary_services() {
    local chroot_dir=$1
    
    log_message "INFO" "Deshabilitando servicios innecesarios"
    
    # Lista de servicios a deshabilitar
    local services_to_disable=(
        "cups"
        "avahi-daemon"
        "bluetooth"
        "isc-dhcp-server"
        "isc-dhcp-server6"
        "slapd"
        "nfs-server"
        "rpcbind"
        "bind9"
        "vsftpd"
        "apache2"
        "nginx"
        "snmpd"
        "telnet"
    )
    
    for service in "${services_to_disable[@]}"; do
        if chroot "$chroot_dir" systemctl list-unit-files | grep -q "$service"; then
            chroot "$chroot_dir" systemctl disable "$service" || true
            chroot "$chroot_dir" systemctl mask "$service" || true
            log_message "INFO" "Servicio deshabilitado: $service"
        fi
    done
    
    # Configurar fail2ban
    cat > "$chroot_dir/etc/fail2ban/jail.local" <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = security@nubemlinux.local

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[sshd-ddos]
enabled = true
port = 22
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 6
EOF

    chroot "$chroot_dir" systemctl enable fail2ban
    
    return 0
}

# Script de verificación de seguridad
create_security_check_script() {
    local chroot_dir=$1
    
    cat > "$chroot_dir/usr/local/bin/nubem-security" <<'EOF'
#!/bin/bash
# Script de verificación de seguridad de NubemLinux

echo "=== Verificación de Seguridad de NubemLinux ==="
echo

# Verificar estado del firewall
echo "Estado del Firewall:"
ufw status verbose
echo

# Verificar servicios activos
echo "Servicios activos:"
systemctl list-units --type=service --state=active
echo

# Verificar últimos logins
echo "Últimos logins:"
last -n 10
echo

# Verificar intentos de login fallidos
echo "Intentos de login fallidos:"
journalctl -u ssh.service | grep "Failed password" | tail -n 10
echo

# Verificar actualizaciones de seguridad
echo "Actualizaciones de seguridad pendientes:"
apt list --upgradable 2>/dev/null | grep -i security
echo

# Verificar integridad con AIDE
echo "Verificando integridad del sistema..."
aide --check --config=/etc/aide/aide.conf
echo

echo "=== Verificación completada ==="
EOF

    chmod +x "$chroot_dir/usr/local/bin/nubem-security"
    
    return 0
}

# Ejecutar función principal
apply_security "$@"