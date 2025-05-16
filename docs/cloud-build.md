# Construcción en la Nube

Debido a las limitaciones de espacio local (solo 25GB disponibles), puedes usar servicios en la nube para construir la ISO.

## Opción 1: GitHub Codespaces

GitHub Codespaces proporciona hasta 32GB de almacenamiento:

1. En el repositorio, click en "Code" > "Codespaces"
2. Crear nuevo codespace
3. Ejecutar build dentro del codespace:
   ```bash
   sudo ./build_nubemlinux.sh
   ```

## Opción 2: Google Cloud Shell

Cloud Shell gratuito con 5GB persistentes + almacenamiento temporal:

1. Abrir [Google Cloud Shell](https://shell.cloud.google.com)
2. Clonar repositorio:
   ```bash
   git clone https://github.com/NUbem000/NubemLinux-AICorp
   cd NubemLinux-AICorp
   ```
3. Usar el directorio temporal grande:
   ```bash
   export BUILD_DIR=/tmp/build
   export OUTPUT_DIR=$HOME/output
   ./build_nubemlinux.sh
   ```

## Opción 3: VM temporal en la nube

### Google Cloud Platform

```bash
# Crear VM con 100GB
gcloud compute instances create nubemlinux-builder \
    --machine-type=n1-standard-4 \
    --boot-disk-size=100GB \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud

# SSH a la VM
gcloud compute ssh nubemlinux-builder

# Dentro de la VM
git clone https://github.com/NUbem000/NubemLinux-AICorp
cd NubemLinux-AICorp
sudo ./build_nubemlinux.sh

# Copiar ISO de vuelta
gcloud compute scp nubemlinux-builder:~/NubemLinux-AICorp/output/*.iso ./

# Eliminar VM
gcloud compute instances delete nubemlinux-builder
```

### AWS EC2

```bash
# Lanzar instancia Ubuntu con 100GB
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --instance-type t3.xlarge \
    --block-device-mappings DeviceName=/dev/sda1,Ebs={VolumeSize=100}

# Conectar y construir
ssh -i mykey.pem ubuntu@instance-ip
git clone https://github.com/NUbem000/NubemLinux-AICorp
cd NubemLinux-AICorp
sudo ./build_nubemlinux.sh
```

## Opción 4: Docker Build

Crear imagen Docker para construcción:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    git

WORKDIR /build
VOLUME /output

CMD ["./build_nubemlinux.sh"]
```

Ejecutar:
```bash
docker build -t nubemlinux-builder .
docker run -v $(pwd)/output:/output nubemlinux-builder
```

## Opción 5: GitHub Actions con Runner Grande

Usar runners más grandes en GitHub Actions:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest-16-cores  # Runner grande
    steps:
      - uses: actions/checkout@v3
      - run: sudo ./build_nubemlinux.sh
```

## Comparación de Opciones

| Método | Espacio | Costo | Velocidad | Complejidad |
|--------|---------|-------|-----------|-------------|
| Local | 25GB ❌ | Gratis | Rápido | Simple |
| Codespaces | 32GB ⚠️ | Gratis* | Medio | Simple |
| Cloud Shell | 5GB+tmp | Gratis | Medio | Medio |
| Cloud VM | 100GB+ ✅ | ~$5 | Rápido | Medio |
| Docker | Variable | Gratis | Medio | Complejo |
| GH Actions | 14GB | Gratis* | Lento | Simple |

*Con límites mensuales

## Recomendación

Para un build completo único:
1. Usar Google Cloud VM temporal (~$0.50 por 2 horas)
2. Construir la ISO
3. Subir a Google Drive
4. Eliminar la VM

Para builds regulares:
1. Configurar GitHub Actions con almacenamiento externo
2. O usar un servidor dedicado para builds