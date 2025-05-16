# Documentación de NubemLinux-AICorp

Bienvenido a la documentación oficial de NubemLinux-AICorp.

## Contenido

- [Instalación](installation.md)
- [Despliegue](deployment.md)
- [Configuración](configuration.md)
- [Uso del Asistente IA](ai-assistant.md)
- [Sistema Watchdog](watchdog.md)
- [Seguridad](security.md)
- [Actualizaciones](updates.md)
- [Troubleshooting](troubleshooting.md)

## Guías Rápidas

### Primera Instalación

1. Descargar la ISO desde [releases](https://github.com/tu-usuario/NubemLinux-AICorp/releases)
2. Crear USB booteable o configurar VM
3. Arrancar desde el medio de instalación
4. Seguir el asistente de configuración

### Comandos Básicos

```bash
# Asistente IA
ai "tu pregunta aquí"

# Diagnóstico del sistema
nubemdiag

# Verificación de seguridad
nubem-security

# Actualización manual
nubemlinux-update
```

## Arquitectura

NubemLinux-AICorp está construido sobre Ubuntu 22.04 LTS e incluye:

- **Capa Base**: Ubuntu con optimizaciones
- **Capa IA**: Ollama + Modelos Llama
- **Capa Seguridad**: Hardening + Firewall + AppArmor
- **Capa Gestión**: Watchdog + Actualizaciones automáticas
- **Capa UI**: GNOME personalizado + NubemCopilot GUI

## Soporte

- [Issues en GitHub](https://github.com/tu-usuario/NubemLinux-AICorp/issues)
- Email: support@nubemlinux.com
- [FAQ](faq.md)