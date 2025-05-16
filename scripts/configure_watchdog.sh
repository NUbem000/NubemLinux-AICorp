#!/bin/bash
# Configuración del sistema Watchdog para NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
configure_watchdog() {
    log_message "INFO" "Configurando sistema Watchdog"
    
    local chroot_dir="${BUILD_DIR}/squashfs"
    
    # Instalar dependencias del watchdog
    install_watchdog_dependencies "$chroot_dir"
    
    # Crear servicio watchdog
    create_watchdog_service "$chroot_dir"
    
    # Configurar monitores
    configure_monitors "$chroot_dir"
    
    # Configurar acciones correctivas
    configure_corrective_actions "$chroot_dir"
    
    # Configurar notificaciones
    configure_notifications "$chroot_dir"
    
    log_message "SUCCESS" "Sistema Watchdog configurado correctamente"
    return 0
}

# Instalar dependencias
install_watchdog_dependencies() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando dependencias del Watchdog"
    
    chroot "$chroot_dir" /bin/bash -c "
        apt-get update
        apt-get install -y \
            python3-psutil \
            python3-systemd \
            python3-requests \
            python3-yaml \
            lm-sensors \
            smartmontools \
            sysstat
    "
    
    return 0
}

# Crear servicio watchdog
create_watchdog_service() {
    local chroot_dir=$1
    
    log_message "INFO" "Creando servicio Watchdog"
    
    # Crear directorio para el watchdog
    mkdir -p "$chroot_dir/opt/nubem-watchdog"
    
    # Crear script principal del watchdog
    cat > "$chroot_dir/opt/nubem-watchdog/watchdog.py" <<'EOF'
#!/usr/bin/env python3
import time
import psutil
import systemd.daemon
import logging
import json
import subprocess
import os
from datetime import datetime
from pathlib import Path

class NubemWatchdog:
    def __init__(self):
        self.config = self.load_config()
        self.setup_logging()
        self.monitors = []
        self.actions = []
        self.history = []
        
    def load_config(self):
        """Cargar configuración del watchdog"""
        config_path = Path("/etc/nubem-watchdog/config.json")
        if config_path.exists():
            with open(config_path, 'r') as f:
                return json.load(f)
        return self.default_config()
    
    def default_config(self):
        """Configuración por defecto"""
        return {
            "intervals": {
                "system": 60,     # Verificar sistema cada 60s
                "services": 120,  # Verificar servicios cada 2 min
                "updates": 3600   # Verificar actualizaciones cada hora
            },
            "thresholds": {
                "cpu_percent": 90,
                "memory_percent": 85,
                "disk_percent": 90,
                "load_average": 4.0
            },
            "services": [
                "ollama",
                "ssh",
                "systemd-resolved"
            ],
            "actions": {
                "high_cpu": ["log", "notify", "optimize"],
                "high_memory": ["log", "notify", "free_memory"],
                "high_disk": ["log", "notify", "clean_disk"],
                "service_down": ["log", "notify", "restart_service"]
            }
        }
    
    def setup_logging(self):
        """Configurar sistema de logs"""
        log_dir = Path("/var/log/nubem-watchdog")
        log_dir.mkdir(exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_dir / "watchdog.log"),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def monitor_system(self):
        """Monitorear recursos del sistema"""
        try:
            # CPU
            cpu_percent = psutil.cpu_percent(interval=1)
            if cpu_percent > self.config["thresholds"]["cpu_percent"]:
                self.trigger_action("high_cpu", {"value": cpu_percent})
            
            # Memoria
            memory = psutil.virtual_memory()
            if memory.percent > self.config["thresholds"]["memory_percent"]:
                self.trigger_action("high_memory", {"value": memory.percent})
            
            # Disco
            disk = psutil.disk_usage('/')
            if disk.percent > self.config["thresholds"]["disk_percent"]:
                self.trigger_action("high_disk", {"value": disk.percent})
            
            # Load average
            load_avg = os.getloadavg()[0]
            if load_avg > self.config["thresholds"]["load_average"]:
                self.trigger_action("high_load", {"value": load_avg})
                
        except Exception as e:
            self.logger.error(f"Error monitoreando sistema: {e}")
    
    def monitor_services(self):
        """Monitorear servicios críticos"""
        for service in self.config["services"]:
            try:
                result = subprocess.run(
                    ["systemctl", "is-active", service],
                    capture_output=True,
                    text=True
                )
                if result.stdout.strip() != "active":
                    self.trigger_action("service_down", {"service": service})
            except Exception as e:
                self.logger.error(f"Error verificando servicio {service}: {e}")
    
    def trigger_action(self, trigger, data):
        """Ejecutar acciones correctivas"""
        actions = self.config["actions"].get(trigger, ["log"])
        
        for action in actions:
            try:
                if action == "log":
                    self.logger.warning(f"Trigger: {trigger}, Data: {data}")
                
                elif action == "notify":
                    self.send_notification(trigger, data)
                
                elif action == "optimize":
                    self.optimize_system()
                
                elif action == "free_memory":
                    self.free_memory()
                
                elif action == "clean_disk":
                    self.clean_disk()
                
                elif action == "restart_service":
                    self.restart_service(data.get("service"))
                    
            except Exception as e:
                self.logger.error(f"Error ejecutando acción {action}: {e}")
    
    def send_notification(self, trigger, data):
        """Enviar notificación al usuario"""
        try:
            subprocess.run([
                "notify-send",
                "NubemLinux Watchdog",
                f"Alerta: {trigger}\nDatos: {data}"
            ])
        except Exception as e:
            self.logger.error(f"Error enviando notificación: {e}")
    
    def optimize_system(self):
        """Optimizar uso de CPU"""
        try:
            # Ajustar nice de procesos intensivos
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
                if proc.info['cpu_percent'] > 50:
                    os.nice(proc.info['pid'])
        except Exception as e:
            self.logger.error(f"Error optimizando sistema: {e}")
    
    def free_memory(self):
        """Liberar memoria"""
        try:
            # Limpiar caché de memoria
            subprocess.run(["sync"])
            subprocess.run(["echo", "3", ">", "/proc/sys/vm/drop_caches"], shell=True)
        except Exception as e:
            self.logger.error(f"Error liberando memoria: {e}")
    
    def clean_disk(self):
        """Limpiar espacio en disco"""
        try:
            # Limpiar logs antiguos
            subprocess.run(["find", "/var/log", "-type", "f", "-mtime", "+30", "-delete"])
            # Limpiar caché de apt
            subprocess.run(["apt-get", "clean"])
            # Limpiar /tmp
            subprocess.run(["find", "/tmp", "-type", "f", "-atime", "+7", "-delete"])
        except Exception as e:
            self.logger.error(f"Error limpiando disco: {e}")
    
    def restart_service(self, service):
        """Reiniciar servicio caído"""
        if not service:
            return
        try:
            subprocess.run(["systemctl", "restart", service])
            self.logger.info(f"Servicio {service} reiniciado")
        except Exception as e:
            self.logger.error(f"Error reiniciando servicio {service}: {e}")
    
    def run(self):
        """Bucle principal del watchdog"""
        self.logger.info("NubemLinux Watchdog iniciado")
        
        # Notificar a systemd que estamos listos
        systemd.daemon.notify("READY=1")
        
        last_system_check = 0
        last_service_check = 0
        last_update_check = 0
        
        while True:
            current_time = time.time()
            
            # Verificar sistema
            if current_time - last_system_check > self.config["intervals"]["system"]:
                self.monitor_system()
                last_system_check = current_time
            
            # Verificar servicios
            if current_time - last_service_check > self.config["intervals"]["services"]:
                self.monitor_services()
                last_service_check = current_time
            
            # Notificar a systemd que seguimos vivos
            systemd.daemon.notify("WATCHDOG=1")
            
            time.sleep(10)

if __name__ == "__main__":
    watchdog = NubemWatchdog()
    watchdog.run()
EOF

    # Hacer ejecutable
    chmod +x "$chroot_dir/opt/nubem-watchdog/watchdog.py"
    
    # Crear servicio systemd
    cat > "$chroot_dir/etc/systemd/system/nubem-watchdog.service" <<EOF
[Unit]
Description=NubemLinux Watchdog Service
After=multi-user.target

[Service]
Type=notify
ExecStart=/opt/nubem-watchdog/watchdog.py
Restart=always
RestartSec=10
WatchdogSec=30
StartLimitInterval=5min
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

    # Habilitar servicio
    chroot "$chroot_dir" systemctl enable nubem-watchdog.service
    
    return 0
}

# Configurar monitores
configure_monitors() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando monitores del sistema"
    
    # Crear directorio de configuración
    mkdir -p "$chroot_dir/etc/nubem-watchdog"
    
    # Crear configuración por defecto
    cat > "$chroot_dir/etc/nubem-watchdog/config.json" <<EOF
{
    "intervals": {
        "system": 60,
        "services": 120,
        "updates": 3600
    },
    "thresholds": {
        "cpu_percent": 85,
        "memory_percent": 85,
        "disk_percent": 90,
        "load_average": 4.0,
        "temperature": 80
    },
    "services": [
        "ollama",
        "ssh",
        "systemd-resolved",
        "NetworkManager"
    ],
    "actions": {
        "high_cpu": ["log", "notify", "optimize"],
        "high_memory": ["log", "notify", "free_memory"],
        "high_disk": ["log", "notify", "clean_disk"],
        "service_down": ["log", "notify", "restart_service"],
        "high_temperature": ["log", "notify", "throttle_cpu"]
    },
    "notifications": {
        "enabled": true,
        "desktop": true,
        "email": false,
        "webhook": null
    }
}
EOF

    return 0
}

# Configurar acciones correctivas
configure_corrective_actions() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando acciones correctivas"
    
    # Crear scripts de acciones adicionales
    mkdir -p "$chroot_dir/opt/nubem-watchdog/actions"
    
    # Script para throttle de CPU
    cat > "$chroot_dir/opt/nubem-watchdog/actions/throttle_cpu.sh" <<'EOF'
#!/bin/bash
# Reducir frecuencia de CPU para bajar temperatura
cpupower frequency-set -g powersave
echo "CPU throttled to powersave mode"
EOF

    chmod +x "$chroot_dir/opt/nubem-watchdog/actions/throttle_cpu.sh"
    
    return 0
}

# Configurar notificaciones
configure_notifications() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando sistema de notificaciones"
    
    # Script para notificaciones
    cat > "$chroot_dir/opt/nubem-watchdog/notify.py" <<'EOF'
#!/usr/bin/env python3
import subprocess
import requests
import json
from datetime import datetime

class NotificationManager:
    def __init__(self, config):
        self.config = config
    
    def send_desktop_notification(self, title, message):
        """Enviar notificación de escritorio"""
        try:
            subprocess.run([
                "notify-send",
                "-i", "/usr/share/icons/nubemlinux/alert.png",
                title,
                message
            ])
        except Exception as e:
            print(f"Error enviando notificación de escritorio: {e}")
    
    def send_email_notification(self, subject, body):
        """Enviar notificación por email"""
        # Implementar si está habilitado
        pass
    
    def send_webhook_notification(self, data):
        """Enviar notificación a webhook"""
        if self.config.get("webhook"):
            try:
                requests.post(self.config["webhook"], json=data)
            except Exception as e:
                print(f"Error enviando webhook: {e}")
    
    def notify(self, event_type, data):
        """Enviar notificación según configuración"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        title = f"NubemLinux Alert: {event_type}"
        message = f"{timestamp}\n{json.dumps(data, indent=2)}"
        
        if self.config.get("desktop"):
            self.send_desktop_notification(title, message)
        
        if self.config.get("email"):
            self.send_email_notification(title, message)
        
        if self.config.get("webhook"):
            self.send_webhook_notification({
                "event": event_type,
                "timestamp": timestamp,
                "data": data
            })
EOF

    chmod +x "$chroot_dir/opt/nubem-watchdog/notify.py"
    
    return 0
}

# Ejecutar función principal
configure_watchdog "$@"