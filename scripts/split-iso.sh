#!/bin/bash
# Script para dividir ISOs grandes para GitHub releases

ISO_FILE="$1"
PREFIX="${2:-nubemlinux}"
CHUNK_SIZE="${3:-1900M}"  # Menos de 2GB para estar seguros

if [ -z "$ISO_FILE" ]; then
    echo "Uso: $0 <archivo.iso> [prefijo] [tamaño_chunk]"
    echo "Ejemplo: $0 nubemlinux.iso nubemlinux 1900M"
    exit 1
fi

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: $ISO_FILE no encontrado"
    exit 1
fi

echo "Dividiendo $ISO_FILE en partes de $CHUNK_SIZE..."
split -b $CHUNK_SIZE "$ISO_FILE" "${PREFIX}.part"

echo "Generando checksums..."
sha256sum ${PREFIX}.part* > "${PREFIX}.sha256"

echo "Creando script de unión..."
cat > "join-${PREFIX}.sh" <<EOF
#!/bin/bash
# Script para unir las partes de $ISO_FILE
echo "Uniendo partes de $ISO_FILE..."
cat ${PREFIX}.part* > "$ISO_FILE"
echo "Verificando integridad..."
sha256sum -c "${PREFIX}.sha256"
echo "ISO reconstruida: $ISO_FILE"
EOF

chmod +x "join-${PREFIX}.sh"

echo "Archivos generados:"
ls -la ${PREFIX}.part*
echo
echo "Para unir las partes en el destino, ejecuta:"
echo "./join-${PREFIX}.sh"