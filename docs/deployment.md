# Guía de Despliegue de NubemLinux-AICorp

## Métodos de despliegue

### 1. USB Booteable

```bash
# Usar el script generado
./output/create-usb.sh

# O manualmente
sudo dd if=output/nubemlinux-aicorp-1.0.0.iso of=/dev/sdX bs=4M status=progress
```

### 2. Máquina Virtual

```bash
# Probar con QEMU
./output/test-vm.sh

# VirtualBox
1. Crear nueva VM Ubuntu 64-bit
2. Asignar mínimo 4GB RAM
3. Crear disco de 50GB+
4. Montar ISO y arrancar
```

### 3. Despliegue PXE

```bash
# Configurar servidor PXE
sudo apt install dnsmasq pxelinux

# Copiar archivos necesarios
cp output/nubemlinux-aicorp-1.0.0.iso /srv/tftp/
mkdir -p /srv/tftp/nubemlinux
mount -o loop output/nubemlinux-aicorp-1.0.0.iso /mnt
cp /mnt/casper/vmlinuz /srv/tftp/nubemlinux/
cp /mnt/casper/initrd /srv/tftp/nubemlinux/
umount /mnt
```

Configuración de dnsmasq:
```
dhcp-range=192.168.1.100,192.168.1.200,12h
dhcp-boot=pxelinux.0
enable-tftp
tftp-root=/srv/tftp
```

### 4. Cloud (GCP/AWS/Azure)

#### Google Cloud Platform

```bash
# Subir ISO a bucket
gsutil cp output/nubemlinux-aicorp-1.0.0.iso gs://mi-bucket/

# Crear imagen personalizada
gcloud compute images create nubemlinux-aicorp-v1 \
    --source-uri gs://mi-bucket/nubemlinux-aicorp-1.0.0.iso \
    --guest-os-features MULTI_IP_SUBNET,UEFI_COMPATIBLE
```

#### AWS

```bash
# Subir a S3
aws s3 cp output/nubemlinux-aicorp-1.0.0.iso s3://mi-bucket/

# Importar como AMI
aws ec2 import-image \
    --description "NubemLinux AICorp v1.0.0" \
    --disk-containers file://import.json
```

import.json:
```json
{
    "Description": "NubemLinux AICorp",
    "Format": "raw",
    "UserBucket": {
        "S3Bucket": "mi-bucket",
        "S3Key": "nubemlinux-aicorp-1.0.0.iso"
    }
}
```

## Post-instalación

### 1. Verificación inicial

```bash
# Verificar servicios
systemctl status ollama
systemctl status nubem-watchdog

# Verificar IA
ai "test de funcionamiento"

# Verificar seguridad
nubem-security
```

### 2. Configuración de red

```bash
# Configurar IP estática (si es necesario)
sudo nmcli con mod "Wired connection 1" \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns "8.8.8.8,8.8.4.4"
```

### 3. Integración corporativa

```bash
# Unir a dominio Active Directory
sudo realm join -U admin@corp.local corp.local

# Configurar proxy corporativo
export http_proxy=http://proxy.corp.local:8080
export https_proxy=$http_proxy
```

### 4. Personalización adicional

```bash
# Instalar software adicional
sudo apt update
sudo apt install -y paquete1 paquete2

# Configurar repositorios corporativos
sudo add-apt-repository ppa:mi-repo/ppa
```

## Automatización con Ansible

Playbook ejemplo:
```yaml
---
- name: Deploy NubemLinux
  hosts: nubemlinux
  become: yes
  
  tasks:
    - name: Update system
      apt:
        update_cache: yes
        upgrade: dist
    
    - name: Configure network
      nmcli:
        conn_name: eth0
        type: ethernet
        ip4: 192.168.1.100/24
        gw4: 192.168.1.1
    
    - name: Start services
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - ollama
        - nubem-watchdog
    
    - name: Configure firewall
      ufw:
        rule: allow
        port: 22
        proto: tcp
```

## Monitoreo

### Prometheus/Grafana

```bash
# Instalar node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar xzf node_exporter-1.5.0.linux-amd64.tar.gz
sudo cp node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/

# Crear servicio
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now node_exporter
```

### Logs centralizados

```bash
# Configurar rsyslog para envío remoto
echo "*.* @@syslog.corp.local:514" | sudo tee -a /etc/rsyslog.conf
sudo systemctl restart rsyslog
```

## Backup y recuperación

### Backup del sistema

```bash
# Crear snapshot con Timeshift
sudo timeshift --create --comments "Pre-update backup"

# Backup de configuración
tar czf nubemlinux-config-$(date +%Y%m%d).tar.gz \
    /etc/nubem-watchdog \
    /etc/nubemlinux-release \
    /opt/nubemcopilot/config.json
```

### Recuperación

```bash
# Restaurar snapshot
sudo timeshift --restore --snapshot '2024-01-15_12-00-00'

# Restaurar configuración
tar xzf nubemlinux-config-20240115.tar.gz -C /
```

## Troubleshooting

### Problemas comunes

1. **Ollama no inicia**
   ```bash
   # Verificar logs
   journalctl -u ollama -f
   
   # Reinstalar
   curl -fsSL https://ollama.ai/install.sh | sh
   ```

2. **Watchdog consume muchos recursos**
   ```bash
   # Ajustar intervalos
   sudo nano /etc/nubem-watchdog/config.json
   # Aumentar intervalos de verificación
   ```

3. **Problemas de red**
   ```bash
   # Reiniciar NetworkManager
   sudo systemctl restart NetworkManager
   
   # Verificar DNS
   dig google.com
   ```

## Soporte

- Email: support@nubemlinux.com
- Chat: https://chat.nubemlinux.com
- Docs: https://docs.nubemlinux.com