#!/bin/bash
# Script para crear assets de branding por defecto

echo "Creando assets de branding por defecto..."

# Crear directorio si no existe
mkdir -p /root/NubemLinux-AICorp/assets/branding

# Generar logo con ImageMagick
convert -size 512x512 xc:transparent \
    -fill '#0D7377' -draw "circle 256,256 256,64" \
    -fill white -font DejaVu-Sans-Bold -pointsize 200 \
    -gravity center -annotate +0+0 'N' \
    logo.png

# Crear variaciones del logo
convert logo.png -resize 128x128 logo-gdm.png
convert logo.png -resize 256x256 icon.png

# Generar fondo de pantalla
convert -size 1920x1080 \
    gradient:'#1E1E1E'-'#0D7377' \
    -fill white -font DejaVu-Sans-Bold -pointsize 72 \
    -gravity center -annotate +0-200 'NubemLinux' \
    -fill '#FFB700' -font DejaVu-Sans -pointsize 36 \
    -gravity center -annotate +0-100 'AI-Powered Ubuntu' \
    wallpaper.jpg

# Crear fondo de login
convert wallpaper.jpg \
    -blur 0x8 \
    -brightness-contrast -20x0 \
    login-background.jpg

# Crear splash screen
convert -size 1920x1080 xc:'#1E1E1E' \
    -draw "image over 710,440 500,200 logo.png" \
    splash.png

# Crear barra de progreso
convert -size 400x20 xc:'#333333' \
    -fill '#0D7377' -draw "rectangle 0,0 400,20" \
    progress_bar.png

convert -size 400x20 xc:'#333333' \
    -stroke '#0D7377' -strokewidth 2 -fill none \
    -draw "rectangle 1,1 398,18" \
    progress_box.png

echo "Assets creados exitosamente en $(pwd)"