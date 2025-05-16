# Configuración de Google Drive para NubemLinux-AICorp

Esta guía explica cómo configurar Google Drive para almacenar las ISOs grandes del proyecto.

## Requisitos

1. Cuenta de Google con espacio suficiente (15GB gratis o más con Google One)
2. Acceso a la terminal
3. Conexión a internet

## Método 1: Usando rclone (Recomendado)

### Instalación

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash
```

### Configuración inicial

1. Ejecutar configuración:
   ```bash
   rclone config
   ```

2. Crear nueva configuración:
   - Seleccionar `n` para nuevo remote
   - Nombre: `gdrive`
   - Tipo: `drive` (Google Drive)
   - Client ID: dejar en blanco (usar default)
   - Client Secret: dejar en blanco (usar default)
   - Scope: `1` (acceso completo)
   - Root folder: dejar en blanco
   - Service Account: dejar en blanco
   - Autorizar en el navegador

### Uso básico

```bash
# Listar archivos
rclone ls gdrive:/

# Crear carpeta
rclone mkdir gdrive:/NubemLinux-AICorp

# Subir archivo
rclone copy archivo.iso gdrive:/NubemLinux-AICorp/

# Descargar archivo
rclone copy gdrive:/NubemLinux-AICorp/archivo.iso ./
```

### Script automatizado

Usa el script incluido:
```bash
./scripts/upload-to-gdrive.sh output/nubemlinux-aicorp-1.0.0.iso
```

## Método 2: Usando gdrive CLI

### Instalación

```bash
# Descargar gdrive
wget -O gdrive https://github.com/prasmussen/gdrive/releases/download/2.1.1/gdrive_2.1.1_linux_amd64
chmod +x gdrive
sudo mv gdrive /usr/local/bin/
```

### Configuración

```bash
# Primera ejecución para autorizar
gdrive list
# Seguir enlace y pegar código de autorización
```

### Uso

```bash
# Subir archivo
gdrive upload archivo.iso

# Crear carpeta
gdrive mkdir NubemLinux-AICorp

# Subir a carpeta específica
gdrive upload -p FOLDER_ID archivo.iso

# Compartir archivo
gdrive share FILE_ID
```

## Método 3: API de Python

### Instalación

```bash
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

### Script Python

```python
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import pickle
import os.path

SCOPES = ['https://www.googleapis.com/auth/drive.file']

def authenticate():
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    
    return build('drive', 'v3', credentials=creds)

def upload_file(service, file_path, folder_id=None):
    file_metadata = {'name': os.path.basename(file_path)}
    if folder_id:
        file_metadata['parents'] = [folder_id]
    
    media = MediaFileUpload(file_path, resumable=True)
    file = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id,name,size,webViewLink'
    ).execute()
    
    return file

# Uso
service = authenticate()
file_info = upload_file(service, 'nubemlinux-aicorp-1.0.0.iso')
print(f"Archivo subido: {file_info['webViewLink']}")
```

## Integración con GitHub Actions

### Workflow para subir ISOs automáticamente

```yaml
name: Upload ISO to Google Drive

on:
  release:
    types: [created]

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Download ISO artifact
      uses: actions/download-artifact@v3
      with:
        name: iso-artifact
    
    - name: Setup rclone
      uses: animosity22/rclone-action@v1
      with:
        config: ${{ secrets.RCLONE_CONFIG }}
    
    - name: Upload to Google Drive
      run: |
        rclone copy *.iso gdrive:/NubemLinux-AICorp/releases/
        rclone link gdrive:/NubemLinux-AICorp/releases/*.iso
```

## Configuración de carpeta compartida

### Crear estructura de carpetas

```
NubemLinux-AICorp/
├── releases/
│   ├── v1.0.0/
│   ├── v1.0.1/
│   └── latest/
├── docs/
└── assets/
```

### Permisos de compartición

1. Compartir carpeta principal:
   ```bash
   rclone link gdrive:/NubemLinux-AICorp --share
   ```

2. Configurar permisos:
   - Lectura pública para releases
   - Escritura restringida para colaboradores

## Límites y consideraciones

### Google Drive Free (15GB)
- Suficiente para 3-4 ISOs
- Considerar rotación de versiones antiguas

### Google One (100GB-2TB)
- Ideal para múltiples versiones
- Backups completos
- Assets sin comprimir

### Optimizaciones

1. **Compresión**:
   ```bash
   xz -9 nubemlinux-aicorp-1.0.0.iso
   # Reduce 50-60% del tamaño
   ```

2. **Deduplicación**:
   - Subir solo archivos cambiados
   - Usar hardlinks para archivos comunes

3. **Versionado**:
   - Mantener últimas 3 versiones
   - Archivar versiones antiguas

## Automatización completa

### Script de release completo

```bash
#!/bin/bash
# release-to-gdrive.sh

VERSION=$1
ISO_FILE="output/nubemlinux-aicorp-${VERSION}.iso"

# 1. Comprimir ISO
echo "Comprimiendo ISO..."
xz -9 -c "$ISO_FILE" > "${ISO_FILE}.xz"

# 2. Generar checksums
sha256sum "${ISO_FILE}.xz" > "${ISO_FILE}.xz.sha256"

# 3. Subir a Google Drive
echo "Subiendo a Google Drive..."
rclone copy "${ISO_FILE}.xz" "gdrive:/NubemLinux-AICorp/releases/${VERSION}/"
rclone copy "${ISO_FILE}.xz.sha256" "gdrive:/NubemLinux-AICorp/releases/${VERSION}/"

# 4. Generar link público
LINK=$(rclone link "gdrive:/NubemLinux-AICorp/releases/${VERSION}/${ISO_FILE}.xz")

# 5. Actualizar README
echo "- [v${VERSION}]($LINK)" >> RELEASES.md

echo "Release completo: $LINK"
```

## Troubleshooting

### Error de autenticación
```bash
rm ~/.config/rclone/rclone.conf
rclone config
```

### Límite de velocidad
```bash
# Limitar ancho de banda a 10MB/s
rclone copy archivo.iso gdrive:/ --bwlimit 10M
```

### Timeout en archivos grandes
```bash
# Aumentar timeout
rclone copy archivo.iso gdrive:/ --timeout 1h
```