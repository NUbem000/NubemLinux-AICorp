#!/bin/bash
# Configurar sistema de actualizaciones automáticas para NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
configure_updates() {
    log_message "INFO" "Configurando sistema de actualizaciones"
    
    local chroot_dir="${BUILD_DIR}/squashfs"
    
    # Instalar herramientas de actualización
    install_update_tools "$chroot_dir"
    
    # Configurar actualizaciones automáticas
    configure_auto_updates "$chroot_dir"
    
    # Configurar actualización de modelos de IA
    configure_ai_updates "$chroot_dir"
    
    # Crear servicio de actualización personalizado
    create_update_service "$chroot_dir"
    
    # Configurar notificaciones de actualizaciones
    configure_update_notifications "$chroot_dir"
    
    # Crear repositorio local
    create_local_repository "$chroot_dir"
    
    log_message "SUCCESS" "Sistema de actualizaciones configurado"
    return 0
}

# Instalar herramientas de actualización
install_update_tools() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando herramientas de actualización"
    
    chroot "$chroot_dir" /bin/bash -c "
        apt-get update
        apt-get install -y \
            unattended-upgrades \
            apt-transport-https \
            ca-certificates \
            gnupg \
            lsb-release \
            software-properties-common \
            python3-apt \
            python3-gi \
            update-notifier \
            update-manager
    "
    
    return 0
}

# Configurar actualizaciones automáticas
configure_auto_updates() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando actualizaciones automáticas"
    
    # Configurar unattended-upgrades
    cat > "$chroot_dir/etc/apt/apt.conf.d/50unattended-upgrades" <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}:\${distro_codename}-updates";
    "\${distro_id}:\${distro_codename}-proposed";
    "\${distro_id}:\${distro_codename}-backports";
    "NubemLinux:stable";
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "${ENABLE_AUTO_UPDATES}";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Mail "${CORP_SUPPORT_EMAIL}";
EOF

    # Configurar periodicidad
    cat > "$chroot_dir/etc/apt/apt.conf.d/20auto-upgrades" <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Configurar repositorio personalizado
    cat > "$chroot_dir/etc/apt/sources.list.d/nubemlinux.list" <<EOF
# Repositorio oficial de NubemLinux
deb [arch=amd64 signed-by=/usr/share/keyrings/nubemlinux-archive-keyring.gpg] https://repo.nubemlinux.com/ubuntu jammy main
# deb-src [arch=amd64 signed-by=/usr/share/keyrings/nubemlinux-archive-keyring.gpg] https://repo.nubemlinux.com/ubuntu jammy main
EOF

    return 0
}

# Configurar actualización de modelos de IA
configure_ai_updates() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando actualización de modelos de IA"
    
    # Script para actualizar modelos de IA
    cat > "$chroot_dir/opt/nubem-watchdog/update-ai-models.py" <<'EOF'
#!/usr/bin/env python3
import subprocess
import json
import logging
import requests
from datetime import datetime
from pathlib import Path

class AIModelUpdater:
    def __init__(self):
        self.config = self.load_config()
        self.setup_logging()
        
    def load_config(self):
        config_path = Path("/etc/nubem-watchdog/ai-update-config.json")
        if config_path.exists():
            with open(config_path, 'r') as f:
                return json.load(f)
        return {
            "models": ["llama3.1", "llama2"],
            "check_interval": 86400,  # 24 horas
            "auto_update": True,
            "max_model_size": "10GB"
        }
    
    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/nubem-watchdog/ai-updates.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def check_ollama_updates(self):
        """Verificar actualizaciones de Ollama"""
        try:
            # Verificar versión actual
            result = subprocess.run(
                ["ollama", "version"],
                capture_output=True,
                text=True
            )
            current_version = result.stdout.strip()
            
            # Verificar última versión disponible
            response = requests.get("https://api.github.com/repos/ollama/ollama/releases/latest")
            if response.status_code == 200:
                latest_version = response.json()["tag_name"]
                
                if current_version != latest_version:
                    self.logger.info(f"Nueva versión de Ollama disponible: {latest_version}")
                    return True
                    
        except Exception as e:
            self.logger.error(f"Error verificando actualizaciones de Ollama: {e}")
        
        return False
    
    def update_ollama(self):
        """Actualizar Ollama"""
        try:
            self.logger.info("Actualizando Ollama...")
            subprocess.run(["curl", "-fsSL", "https://ollama.ai/install.sh", "|", "sh"], shell=True)
            self.logger.info("Ollama actualizado correctamente")
        except Exception as e:
            self.logger.error(f"Error actualizando Ollama: {e}")
    
    def check_model_updates(self):
        """Verificar actualizaciones de modelos"""
        updates_available = []
        
        for model in self.config["models"]:
            try:
                # Verificar información del modelo
                result = subprocess.run(
                    ["ollama", "show", model],
                    capture_output=True,
                    text=True
                )
                
                # Aquí verificaríamos contra un repositorio de versiones
                # Por ahora, simulamos la verificación
                if "update available" in result.stdout.lower():
                    updates_available.append(model)
                    
            except Exception as e:
                self.logger.error(f"Error verificando modelo {model}: {e}")
        
        return updates_available
    
    def update_models(self, models):
        """Actualizar modelos específicos"""
        for model in models:
            try:
                self.logger.info(f"Actualizando modelo: {model}")
                subprocess.run(["ollama", "pull", model], check=True)
                self.logger.info(f"Modelo {model} actualizado correctamente")
            except Exception as e:
                self.logger.error(f"Error actualizando modelo {model}: {e}")
    
    def run_update_check(self):
        """Ejecutar verificación completa de actualizaciones"""
        self.logger.info("Iniciando verificación de actualizaciones de IA")
        
        # Verificar Ollama
        if self.check_ollama_updates() and self.config["auto_update"]:
            self.update_ollama()
        
        # Verificar modelos
        models_to_update = self.check_model_updates()
        if models_to_update and self.config["auto_update"]:
            self.update_models(models_to_update)
        
        # Guardar timestamp de última verificación
        with open("/var/lib/nubem-watchdog/last-ai-update-check", "w") as f:
            f.write(str(datetime.now().timestamp()))
        
        self.logger.info("Verificación de actualizaciones completada")

if __name__ == "__main__":
    updater = AIModelUpdater()
    updater.run_update_check()
EOF

    chmod +x "$chroot_dir/opt/nubem-watchdog/update-ai-models.py"
    
    # Configuración de actualización de IA
    mkdir -p "$chroot_dir/etc/nubem-watchdog"
    cat > "$chroot_dir/etc/nubem-watchdog/ai-update-config.json" <<EOF
{
    "models": ["${DEFAULT_AI_MODEL}", "${FALLBACK_AI_MODEL}"],
    "check_interval": 86400,
    "auto_update": true,
    "max_model_size": "10GB",
    "update_schedule": "03:30",
    "notify_updates": true
}
EOF

    return 0
}

# Crear servicio de actualización personalizado
create_update_service() {
    local chroot_dir=$1
    
    log_message "INFO" "Creando servicio de actualización NubemLinux"
    
    # Script principal de actualización
    cat > "$chroot_dir/usr/local/bin/nubemlinux-update" <<'EOF'
#!/bin/bash
# Sistema de actualización de NubemLinux

set -e

LOGFILE="/var/log/nubemlinux-update.log"
LOCKFILE="/var/lock/nubemlinux-update.lock"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Verificar si ya está ejecutándose
if [ -f "$LOCKFILE" ]; then
    log "ERROR: Actualización ya en progreso"
    exit 1
fi

# Crear lockfile
echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

log "Iniciando actualización de NubemLinux"

# Actualizar lista de paquetes
log "Actualizando lista de paquetes..."
apt-get update >> "$LOGFILE" 2>&1

# Verificar actualizaciones del sistema
log "Verificando actualizaciones del sistema..."
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

if [ "$UPDATES" -gt 0 ]; then
    log "Se encontraron $UPDATES actualizaciones disponibles"
    
    # Actualizar paquetes
    log "Instalando actualizaciones..."
    apt-get upgrade -y >> "$LOGFILE" 2>&1
    
    # Limpiar paquetes no necesarios
    apt-get autoremove -y >> "$LOGFILE" 2>&1
    apt-get autoclean >> "$LOGFILE" 2>&1
else
    log "Sistema actualizado, no hay nuevas actualizaciones"
fi

# Actualizar modelos de IA
log "Verificando actualizaciones de IA..."
/opt/nubem-watchdog/update-ai-models.py >> "$LOGFILE" 2>&1

# Actualizar configuraciones de NubemLinux
log "Actualizando configuraciones de NubemLinux..."
if [ -d "/opt/nubemlinux/updates" ]; then
    for update in /opt/nubemlinux/updates/*.sh; do
        if [ -x "$update" ]; then
            log "Aplicando: $(basename "$update")"
            "$update" >> "$LOGFILE" 2>&1
        fi
    done
fi

# Verificar si necesita reinicio
if [ -f /var/run/reboot-required ]; then
    log "AVISO: Se requiere reinicio del sistema"
    
    # Notificar al usuario
    notify-send -i system-software-update \
        "NubemLinux Update" \
        "Actualización completada. Se requiere reinicio."
fi

log "Actualización de NubemLinux completada"

# Generar reporte
cat > "/var/log/nubemlinux-update-report-$(date +%Y%m%d).txt" <<EOL
NubemLinux Update Report
========================
Fecha: $(date)
Actualizaciones aplicadas: $UPDATES
Estado: Completado
EOL

exit 0
EOF

    chmod +x "$chroot_dir/usr/local/bin/nubemlinux-update"
    
    # Servicio systemd
    cat > "$chroot_dir/etc/systemd/system/nubemlinux-update.service" <<EOF
[Unit]
Description=NubemLinux Update Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nubemlinux-update
StandardOutput=journal
StandardError=journal
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    # Timer para ejecución diaria
    cat > "$chroot_dir/etc/systemd/system/nubemlinux-update.timer" <<EOF
[Unit]
Description=Daily NubemLinux Update
Requires=nubemlinux-update.service

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=30min

[Install]
WantedBy=timers.target
EOF

    # Habilitar timer
    chroot "$chroot_dir" systemctl enable nubemlinux-update.timer
    
    return 0
}

# Configurar notificaciones de actualizaciones
configure_update_notifications() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando notificaciones de actualizaciones"
    
    # Script de notificación
    cat > "$chroot_dir/usr/local/bin/nubemlinux-update-notify" <<'EOF'
#!/usr/bin/env python3
import subprocess
import gi
import json
from pathlib import Path

gi.require_version('Gtk', '3.0')
gi.require_version('Notify', '0.7')
from gi.repository import Gtk, Notify, GLib

class UpdateNotifier:
    def __init__(self):
        Notify.init("NubemLinux Update Notifier")
        self.check_updates()
    
    def check_updates(self):
        """Verificar actualizaciones disponibles"""
        try:
            # Verificar actualizaciones del sistema
            result = subprocess.run(
                ["apt", "list", "--upgradable"],
                capture_output=True,
                text=True
            )
            
            updates = [line for line in result.stdout.split('\n') 
                      if line and not line.startswith('Listing')]
            
            if updates:
                self.show_notification(len(updates))
            
        except Exception as e:
            print(f"Error verificando actualizaciones: {e}")
    
    def show_notification(self, count):
        """Mostrar notificación de actualizaciones"""
        notification = Notify.Notification.new(
            "Actualizaciones de NubemLinux",
            f"{count} actualizaciones disponibles.\n"
            f"Haga clic para ver detalles.",
            "system-software-update"
        )
        
        notification.set_urgency(Notify.Urgency.NORMAL)
        notification.add_action(
            "view_updates",
            "Ver Actualizaciones",
            self.open_update_manager
        )
        
        notification.show()
    
    def open_update_manager(self, notification, action):
        """Abrir gestor de actualizaciones"""
        subprocess.Popen(["update-manager"])

if __name__ == "__main__":
    notifier = UpdateNotifier()
    # Mantener el programa ejecutándose para manejar acciones
    GLib.MainLoop().run()
EOF

    chmod +x "$chroot_dir/usr/local/bin/nubemlinux-update-notify"
    
    # Autostart para notificaciones
    cat > "$chroot_dir/etc/xdg/autostart/nubemlinux-update-notify.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=NubemLinux Update Notifier
Exec=/usr/local/bin/nubemlinux-update-notify
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Notificador de actualizaciones de NubemLinux
EOF

    return 0
}

# Crear repositorio local
create_local_repository() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando repositorio local"
    
    # Crear estructura de repositorio
    mkdir -p "$chroot_dir/opt/nubemlinux/repo/pool/main"
    mkdir -p "$chroot_dir/opt/nubemlinux/repo/dists/stable/main/binary-amd64"
    
    # Script para mantener repositorio local
    cat > "$chroot_dir/usr/local/bin/nubemlinux-repo-update" <<'EOF'
#!/bin/bash
# Actualizar repositorio local de NubemLinux

REPO_DIR="/opt/nubemlinux/repo"
PACKAGES_FILE="$REPO_DIR/dists/stable/main/binary-amd64/Packages"

cd "$REPO_DIR"

# Generar archivo Packages
dpkg-scanpackages pool/main /dev/null > "$PACKAGES_FILE"
gzip -c "$PACKAGES_FILE" > "$PACKAGES_FILE.gz"

# Generar Release
cat > "$REPO_DIR/dists/stable/Release" <<EOL
Origin: NubemLinux
Label: NubemLinux
Suite: stable
Codename: stable
Version: 1.0
Architectures: amd64
Components: main
Description: NubemLinux AICorp Repository
EOL

# Firmar Release (si hay clave GPG disponible)
if [ -f /etc/nubemlinux/repo-key.gpg ]; then
    gpg --default-key nubemlinux@aicorp.local \
        --armor --detach-sign \
        -o "$REPO_DIR/dists/stable/Release.gpg" \
        "$REPO_DIR/dists/stable/Release"
fi

echo "Repositorio local actualizado"
EOF

    chmod +x "$chroot_dir/usr/local/bin/nubemlinux-repo-update"
    
    return 0
}

# Ejecutar función principal
configure_updates "$@"