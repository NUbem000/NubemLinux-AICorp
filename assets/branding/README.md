# Assets de Branding para NubemLinux-AICorp

Este directorio debe contener los siguientes archivos de branding:

## Archivos requeridos:

### Imágenes principales:
- `logo.png` - Logo principal (512x512 px, PNG transparente)
- `logo-gdm.png` - Logo para pantalla de login GDM (128x128 px)
- `icon.png` - Icono de aplicación (256x256 px)

### Fondos de pantalla:
- `wallpaper.jpg` - Fondo de pantalla principal (1920x1080 px mínimo)
- `login-background.jpg` - Fondo para pantalla de login (1920x1080 px)

### Plymouth (pantalla de arranque):
- `splash.png` - Imagen de splash para arranque (1920x1080 px)
- `progress_box.png` - Caja de progreso (400x20 px)
- `progress_bar.png` - Barra de progreso (400x20 px)

## Paleta de colores sugerida:

- Principal: #0D7377 (Verde azulado)
- Secundario: #14A1A5 (Turquesa)
- Acento: #FFB700 (Dorado)
- Fondo: #1E1E1E (Gris oscuro)
- Texto: #FFFFFF (Blanco)

## Formato de archivos:

- Logos e iconos: PNG con transparencia
- Fondos: JPG de alta calidad
- Resolución mínima: 1920x1080 para fondos
- Tamaño máximo por archivo: 5MB

## Generación automática:

Si no se proporcionan estos archivos, el script puede generar versiones básicas usando ImageMagick:

```bash
# Generar logo básico
convert -size 512x512 xc:transparent \
    -fill '#0D7377' -draw "circle 256,256 256,64" \
    -fill white -font Ubuntu-Bold -pointsize 200 \
    -gravity center -annotate +0+0 'N' \
    logo.png

# Generar fondo básico
convert -size 1920x1080 \
    gradient:'#1E1E1E'-'#0D7377' \
    wallpaper.jpg
```

## Notas:

- Todos los archivos deben estar optimizados para web
- Usar compresión sin pérdida para PNG
- Los fondos deben verse bien en diferentes resoluciones
- Considerar modo oscuro/claro si es aplicable