# NubemLinux-AICorp

Distribución Ubuntu personalizada con IA integrada, branding corporativo y capacidades de autogestión inteligente.

## Características principales

- **Asistente IA integrado (NubemCopilot)**
  - Procesamiento de texto, imagen y voz
  - Modelos locales con Ollama
  - Fallback a cloud cuando sea necesario
  
- **Sistema Watchdog inteligente**
  - Monitoreo continuo del sistema
  - Acciones correctivas automáticas
  - Aprendizaje de patrones
  
- **Seguridad reforzada**
  - Hardening del kernel
  - Firewall preconfigurado
  - AppArmor y AIDE
  
- **Actualizaciones autónomas**
  - Sistema operativo
  - Modelos de IA
  - Componentes propios

## Requisitos del sistema

### Mínimos:
- RAM: 4GB
- Disco: 50GB
- Procesador: x86_64 con soporte de virtualización

### Recomendados:
- RAM: 8GB+
- Disco: 100GB+
- GPU: NVIDIA con CUDA (opcional)

## Construcción

```bash
# Clonar repositorio
git clone https://github.com/aicorp/nubemlinux
cd NubemLinux-AICorp

# Ejecutar script de construcción
sudo ./build_nubemlinux.sh
```

El proceso es completamente automático y puede reanudar desde checkpoints en caso de interrupción.

## Estructura del proyecto

```
NubemLinux-AICorp/
├── build_nubemlinux.sh      # Script principal
├── checkpoint_manager.sh    # Sistema de checkpoints
├── config.env              # Configuración global
├── scripts/                # Scripts modulares
│   ├── install_ai_components.sh
│   ├── configure_watchdog.sh
│   ├── apply_branding.sh
│   ├── apply_security.sh
│   ├── configure_updates.sh
│   ├── build_iso.sh
│   └── verify_iso.sh
├── modules_ia/             # Módulos de IA
│   └── nubemcopilot_gui.py
├── assets/branding/        # Recursos visuales
├── security/              # Configuraciones de seguridad
├── updates/               # Sistema de actualizaciones
├── output/                # ISO y reportes generados
└── docs/                  # Documentación
```

## Uso

### Comandos principales

```bash
# Asistente IA (CLI)
ai "tu pregunta aquí"
ai --image captura.png
ai --voice

# Asistente IA (GUI)
nubemcopilot

# Diagnóstico del sistema
nubemdiag

# Verificación de seguridad
nubem-security

# Actualización manual
nubemlinux-update
```

### Primer arranque

1. El sistema iniciará con un asistente de configuración
2. Se creará un usuario con privilegios sudo
3. Se configurarán los componentes de IA
4. Se aplicarán las políticas de seguridad

## Desarrollo

### Agregar nuevos componentes

1. Crear script en `scripts/`
2. Añadir llamada en `build_nubemlinux.sh`
3. Documentar en `docs/`

### Personalización

- Branding: Modificar archivos en `assets/branding/`
- Configuración: Editar `config.env`
- Seguridad: Ajustar scripts en `security/`

## Seguridad

- Firewall UFW habilitado por defecto
- SSH con rate limiting
- Actualizaciones automáticas de seguridad
- Monitoreo continuo con Watchdog

## Soporte

- Email: support@aicorp.local
- Issues: https://github.com/aicorp/nubemlinux/issues
- Docs: https://docs.nubemlinux.com

## Licencia

Copyright © 2024 AICorp. Todos los derechos reservados.

## Changelog

### v1.0.0 (2024-01-XX)
- Release inicial
- Integración de Ollama y modelos Llama
- Sistema Watchdog completo
- Branding corporativo
- Seguridad reforzada