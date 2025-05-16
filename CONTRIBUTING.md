# Contribuyendo a NubemLinux-AICorp

¡Gracias por tu interés en contribuir a NubemLinux-AICorp! Este documento proporciona pautas para contribuir al proyecto.

## Código de Conducta

Al participar en este proyecto, aceptas adherirte a nuestro código de conducta basado en respeto mutuo y colaboración constructiva.

## Cómo Contribuir

### Reportando Bugs

1. Verifica que el bug no haya sido reportado previamente
2. Abre un issue describiendo:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Comportamiento esperado vs actual
   - Versión de NubemLinux
   - Hardware y configuración

### Sugiriendo Mejoras

1. Abre un issue con la etiqueta "enhancement"
2. Describe claramente la mejora propuesta
3. Explica por qué sería útil para el proyecto

### Pull Requests

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código

- Bash: Sigue las Google Shell Style Guide
- Python: Sigue PEP 8
- Documenta tu código adecuadamente
- Incluye tests cuando sea posible

### Proceso de Review

1. Todos los PRs requieren al menos una aprobación
2. Los tests deben pasar
3. El código debe seguir los estándares del proyecto
4. La documentación debe estar actualizada

## Desarrollo Local

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/NubemLinux-AICorp
cd NubemLinux-AICorp

# Crear rama de desarrollo
git checkout -b mi-feature

# Hacer cambios y probar
./build_nubemlinux.sh --test

# Commit y push
git add .
git commit -m "Descripción de cambios"
git push origin mi-feature
```

## Testing

- Prueba tu código en diferentes configuraciones
- Verifica que no rompes funcionalidad existente
- Añade tests para nuevas características

## Documentación

- Actualiza README.md si es necesario
- Documenta nuevas características en docs/
- Mantén los comentarios del código actualizados

## Licencia

Al contribuir, aceptas que tus contribuciones se licencien bajo la misma licencia MIT del proyecto.

## Preguntas

Si tienes preguntas, abre un issue o contacta a los mantenedores.

¡Gracias por contribuir a NubemLinux-AICorp!