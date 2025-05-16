# Instrucciones para publicar NubemLinux en GitHub

El repositorio está listo para ser publicado en GitHub. Aquí están los pasos a seguir:

## Método 1: Usando el script automatizado

1. Ejecuta el script de publicación:
   ```bash
   ./publish-to-github.sh
   ```

2. Sigue las instrucciones en pantalla para:
   - Autenticarte en GitHub (si no lo has hecho)
   - Crear el repositorio
   - Subir el código
   - Crear un release inicial (opcional)

## Método 2: Manualmente

1. Instala GitHub CLI si no lo tienes:
   ```bash
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update
   sudo apt install gh -y
   ```

2. Autentícate en GitHub:
   ```bash
   gh auth login
   ```

3. Crea el repositorio:
   ```bash
   gh repo create NubemLinux-AICorp --public --description "Ubuntu distribution with integrated AI"
   ```

4. Añade el remote y sube el código:
   ```bash
   git remote add origin https://github.com/TU-USUARIO/NubemLinux-AICorp.git
   git push -u origin main
   ```

## Método 3: A través de la web de GitHub

1. Ve a https://github.com/new
2. Nombre del repositorio: `NubemLinux-AICorp`
3. Descripción: `Ubuntu distribution with integrated AI, corporate branding, and intelligent self-management`
4. Hazlo público
5. NO inicialices con README (ya tenemos uno)
6. Crea el repositorio
7. En tu terminal local:
   ```bash
   git remote add origin https://github.com/TU-USUARIO/NubemLinux-AICorp.git
   git push -u origin main
   ```

## Después de publicar

1. Activa GitHub Actions yendo a Settings > Actions > General
2. Crea el primer release:
   ```bash
   gh release create v1.0.0 --title "NubemLinux-AICorp v1.0.0" --notes "Initial release"
   ```
3. Configura GitHub Pages para la documentación (opcional)
4. Añade colaboradores si es necesario

## Estructura del repositorio

```
NubemLinux-AICorp/
├── build_nubemlinux.sh      # Script principal
├── scripts/                 # Scripts modulares
├── modules_ia/             # Componentes de IA
├── assets/                 # Recursos de branding
├── docs/                   # Documentación
├── .github/                # Configuración de GitHub
│   ├── workflows/         # GitHub Actions
│   └── ISSUE_TEMPLATE/    # Plantillas de issues
├── README.md              # Documentación principal
├── LICENSE                # Licencia MIT
└── CONTRIBUTING.md        # Guía de contribución
```

## URLs importantes después de publicar

- Repositorio: https://github.com/TU-USUARIO/NubemLinux-AICorp
- Issues: https://github.com/TU-USUARIO/NubemLinux-AICorp/issues
- Releases: https://github.com/TU-USUARIO/NubemLinux-AICorp/releases
- Actions: https://github.com/TU-USUARIO/NubemLinux-AICorp/actions

¡El proyecto está listo para ser compartido con la comunidad!