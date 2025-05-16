#!/bin/bash
# Script para liberar espacio en el sistema

echo "=== Limpieza de espacio en disco ==="
echo "Espacio antes de limpiar:"
df -h /
echo

# 1. Limpiar caché de APT
echo "Limpiando caché de APT..."
apt-get clean
apt-get autoremove -y

# 2. Limpiar logs antiguos
echo "Limpiando logs antiguos..."
find /var/log -type f -name "*.log" -mtime +30 -delete
journalctl --vacuum-time=7d

# 3. Limpiar caché de npm
echo "Limpiando caché de npm..."
npm cache clean --force

# 4. Limpiar caché de Python
echo "Limpiando caché de Python..."
find ~/.cache/pip -type f -delete

# 5. Eliminar archivos temporales
echo "Limpiando archivos temporales..."
rm -rf /tmp/*
rm -rf /var/tmp/*

# 6. Limpiar Docker (si existe)
if command -v docker &> /dev/null; then
    echo "Limpiando Docker..."
    docker system prune -af
fi

# 7. Sugerir directorios grandes
echo
echo "Directorios grandes en /root que podrías revisar:"
du -h --max-depth=1 /root | sort -rh | head -5

echo
echo "Espacio después de limpiar:"
df -h /
echo

# Calcular espacio liberado
ANTES=$(df / | tail -1 | awk '{print $4}')
apt-get clean
DESPUES=$(df / | tail -1 | awk '{print $4}')
LIBERADO=$((DESPUES - ANTES))
echo "Espacio liberado: $((LIBERADO / 1024)) MB"