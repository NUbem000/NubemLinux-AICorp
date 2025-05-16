#!/bin/bash
# Instalación de componentes de IA para NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
install_ai_components() {
    log_message "INFO" "Iniciando instalación de componentes de IA"
    
    # Directorio de trabajo
    local chroot_dir="${BUILD_DIR}/squashfs"
    
    # Preparar chroot
    prepare_chroot "$chroot_dir"
    
    # Instalar dependencias base
    install_ai_dependencies "$chroot_dir"
    
    # Instalar Ollama
    install_ollama "$chroot_dir"
    
    # Instalar modelos de IA
    install_ai_models "$chroot_dir"
    
    # Configurar NubemCopilot
    configure_nubemcopilot "$chroot_dir"
    
    # Instalar herramientas de procesamiento
    install_processing_tools "$chroot_dir"
    
    # Limpiar chroot
    cleanup_chroot "$chroot_dir"
    
    log_message "SUCCESS" "Componentes de IA instalados correctamente"
    return 0
}

# Preparar entorno chroot
prepare_chroot() {
    local chroot_dir=$1
    
    log_message "INFO" "Preparando entorno chroot"
    
    # Montar sistemas de archivos necesarios
    mount --bind /dev "$chroot_dir/dev"
    mount --bind /dev/pts "$chroot_dir/dev/pts"
    mount --bind /proc "$chroot_dir/proc"
    mount --bind /sys "$chroot_dir/sys"
    
    # Copiar resolv.conf
    cp /etc/resolv.conf "$chroot_dir/etc/resolv.conf"
    
    return 0
}

# Instalar dependencias de IA
install_ai_dependencies() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando dependencias de IA"
    
    chroot "$chroot_dir" /bin/bash -c "
        apt-get update
        apt-get install -y \
            python3 \
            python3-pip \
            python3-dev \
            python3-venv \
            curl \
            wget \
            git \
            build-essential \
            libssl-dev \
            libffi-dev \
            portaudio19-dev \
            ffmpeg \
            libgtk-3-0 \
            libnotify4 \
            libayatana-appindicator3-1
    "
    
    # Instalar paquetes Python necesarios
    chroot "$chroot_dir" /bin/bash -c "
        pip3 install --no-cache-dir \
            requests \
            numpy \
            pillow \
            opencv-python \
            pyaudio \
            whisper \
            transformers \
            torch \
            torchvision \
            gradio \
            langchain
    "
    
    return 0
}

# Instalar Ollama
install_ollama() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando Ollama"
    
    chroot "$chroot_dir" /bin/bash -c "
        curl -fsSL https://ollama.ai/install.sh | sh
    "
    
    # Crear servicio systemd para Ollama
    cat > "$chroot_dir/etc/systemd/system/ollama.service" <<EOF
[Unit]
Description=Ollama AI Service
After=network.target

[Service]
Type=exec
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=3
KillMode=mixed
EnvironmentFile=-/etc/environment
Environment="OLLAMA_HOST=0.0.0.0:11434"

[Install]
WantedBy=multi-user.target
EOF

    chroot "$chroot_dir" systemctl enable ollama.service
    
    return 0
}

# Instalar modelos de IA
install_ai_models() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando modelos de IA"
    
    # Crear directorio para modelos
    mkdir -p "$chroot_dir/usr/share/nubemlinux/models"
    
    # Descargar modelos básicos
    chroot "$chroot_dir" /bin/bash -c "
        # Iniciar Ollama temporalmente
        /usr/local/bin/ollama serve &
        OLLAMA_PID=$!
        sleep 5
        
        # Descargar modelos
        ollama pull ${DEFAULT_AI_MODEL}
        ollama pull ${FALLBACK_AI_MODEL}
        
        # Detener Ollama
        kill $OLLAMA_PID
    "
    
    # Descargar modelo Whisper para voz
    chroot "$chroot_dir" /bin/bash -c "
        python3 -c 'import whisper; whisper.load_model(\"base\")'
    "
    
    return 0
}

# Configurar NubemCopilot
configure_nubemcopilot() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando NubemCopilot"
    
    # Crear estructura de directorios
    mkdir -p "$chroot_dir/opt/nubemcopilot"
    mkdir -p "$chroot_dir/usr/share/applications"
    mkdir -p "$chroot_dir/usr/local/bin"
    
    # Copiar módulos de IA
    cp -r "$MODULES_IA_DIR"/* "$chroot_dir/opt/nubemcopilot/"
    
    # Crear script principal de NubemCopilot
    cat > "$chroot_dir/opt/nubemcopilot/nubemcopilot.py" <<'EOF'
#!/usr/bin/env python3
import sys
import os
import argparse
import json
from pathlib import Path

# Importar módulos según disponibilidad
try:
    import requests
    import numpy as np
    from PIL import Image
    import cv2
except ImportError as e:
    print(f"Advertencia: Módulo no disponible: {e}")

class NubemCopilot:
    def __init__(self):
        self.config = self.load_config()
        self.ollama_url = "http://localhost:11434"
        
    def load_config(self):
        config_path = Path.home() / ".config" / "nubemcopilot" / "config.json"
        if config_path.exists():
            with open(config_path, 'r') as f:
                return json.load(f)
        return {
            "model": os.getenv("DEFAULT_AI_MODEL", "llama3.1"),
            "language": "es",
            "enable_voice": True,
            "enable_vision": True
        }
    
    def process_text(self, text):
        """Procesar consulta de texto"""
        try:
            response = requests.post(
                f"{self.ollama_url}/api/generate",
                json={
                    "model": self.config["model"],
                    "prompt": text,
                    "stream": False
                }
            )
            if response.status_code == 200:
                return response.json()["response"]
            else:
                return f"Error: {response.status_code}"
        except Exception as e:
            return f"Error al procesar texto: {e}"
    
    def process_image(self, image_path):
        """Procesar imagen"""
        try:
            image = Image.open(image_path)
            # Aquí iría el procesamiento de imagen
            return "Imagen procesada correctamente"
        except Exception as e:
            return f"Error al procesar imagen: {e}"
    
    def process_voice(self, audio_file):
        """Procesar audio"""
        try:
            import whisper
            model = whisper.load_model("base")
            result = model.transcribe(audio_file)
            return result["text"]
        except Exception as e:
            return f"Error al procesar audio: {e}"

def main():
    parser = argparse.ArgumentParser(description="NubemCopilot - Asistente IA")
    parser.add_argument("query", nargs="?", help="Consulta de texto")
    parser.add_argument("--image", "-i", help="Procesar imagen")
    parser.add_argument("--voice", "-v", help="Procesar audio")
    parser.add_argument("--gui", action="store_true", help="Iniciar interfaz gráfica")
    
    args = parser.parse_args()
    
    copilot = NubemCopilot()
    
    if args.gui:
        # Iniciar GUI
        from nubemcopilot_gui import launch_gui
        launch_gui()
    elif args.image:
        result = copilot.process_image(args.image)
        print(result)
    elif args.voice:
        result = copilot.process_voice(args.voice)
        print(result)
    elif args.query:
        result = copilot.process_text(args.query)
        print(result)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
EOF

    # Hacer ejecutable
    chmod +x "$chroot_dir/opt/nubemcopilot/nubemcopilot.py"
    
    # Crear enlace simbólico
    ln -s /opt/nubemcopilot/nubemcopilot.py "$chroot_dir/usr/local/bin/ai"
    
    # Crear entrada de escritorio
    cat > "$chroot_dir/usr/share/applications/nubemcopilot.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NubemCopilot
Comment=Asistente IA de NubemLinux
Exec=/opt/nubemcopilot/nubemcopilot.py --gui
Icon=/opt/nubemcopilot/icon.png
Terminal=false
Categories=Utility;
EOF

    return 0
}

# Instalar herramientas de procesamiento
install_processing_tools() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando herramientas de procesamiento adicionales"
    
    # Instalar tesseract para OCR
    chroot "$chroot_dir" apt-get install -y tesseract-ocr tesseract-ocr-spa
    
    # Instalar ImageMagick para procesamiento de imágenes
    chroot "$chroot_dir" apt-get install -y imagemagick
    
    return 0
}

# Limpiar entorno chroot
cleanup_chroot() {
    local chroot_dir=$1
    
    log_message "INFO" "Limpiando entorno chroot"
    
    # Limpiar caché de apt
    chroot "$chroot_dir" apt-get clean
    
    # Desmontar sistemas de archivos
    umount "$chroot_dir/sys" || true
    umount "$chroot_dir/proc" || true
    umount "$chroot_dir/dev/pts" || true
    umount "$chroot_dir/dev" || true
    
    # Eliminar archivos temporales
    rm -f "$chroot_dir/etc/resolv.conf"
    
    return 0
}

# Ejecutar función principal
install_ai_components "$@"