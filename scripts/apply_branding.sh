#!/bin/bash
# Aplicar branding corporativo a NubemLinux-AICorp

source "$(dirname "$0")/../config.env"
source "$(dirname "$0")/../checkpoint_manager.sh"

# Función principal
apply_branding() {
    log_message "INFO" "Aplicando branding corporativo"
    
    local chroot_dir="${BUILD_DIR}/squashfs"
    
    # Instalar dependencias de branding
    install_branding_dependencies "$chroot_dir"
    
    # Configurar Plymouth (pantalla de arranque)
    configure_plymouth "$chroot_dir"
    
    # Configurar tema de GNOME
    configure_gnome_theme "$chroot_dir"
    
    # Configurar GDM (pantalla de login)
    configure_gdm "$chroot_dir"
    
    # Instalar fondos de pantalla
    install_wallpapers "$chroot_dir"
    
    # Configurar iconos y logos
    configure_icons "$chroot_dir"
    
    # Configurar aplicaciones por defecto
    configure_default_apps "$chroot_dir"
    
    log_message "SUCCESS" "Branding corporativo aplicado correctamente"
    return 0
}

# Instalar dependencias
install_branding_dependencies() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando dependencias de branding"
    
    chroot "$chroot_dir" /bin/bash -c "
        apt-get update
        apt-get install -y \
            plymouth-themes \
            gnome-tweaks \
            gnome-shell-extensions \
            dconf-editor \
            imagemagick \
            inkscape
    "
    
    return 0
}

# Configurar Plymouth
configure_plymouth() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando Plymouth (pantalla de arranque)"
    
    # Crear directorio para tema personalizado
    mkdir -p "$chroot_dir/usr/share/plymouth/themes/nubemlinux"
    
    # Crear tema de Plymouth
    cat > "$chroot_dir/usr/share/plymouth/themes/nubemlinux/nubemlinux.plymouth" <<EOF
[Plymouth Theme]
Name=NubemLinux
Description=Tema de arranque de NubemLinux-AICorp
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/nubemlinux
ScriptFile=/usr/share/plymouth/themes/nubemlinux/nubemlinux.script
EOF

    # Crear script de Plymouth
    cat > "$chroot_dir/usr/share/plymouth/themes/nubemlinux/nubemlinux.script" <<'EOF'
# Tema Plymouth para NubemLinux
logo_image = Image("logo.png");
progress_box_image = Image("progress_box.png");
progress_bar_image = Image("progress_bar.png");

screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

# Centrar logo
logo_sprite = Sprite(logo_image);
logo_sprite.SetX(screen_width / 2 - logo_image.GetWidth() / 2);
logo_sprite.SetY(screen_height / 2 - logo_image.GetHeight() / 2 - 50);

# Barra de progreso
progress_box_sprite = Sprite(progress_box_image);
progress_box_sprite.SetX(screen_width / 2 - progress_box_image.GetWidth() / 2);
progress_box_sprite.SetY(screen_height / 2 + 50);

progress_bar_sprite = Sprite();
progress_bar_sprite.SetX(screen_width / 2 - progress_box_image.GetWidth() / 2);
progress_bar_sprite.SetY(screen_height / 2 + 50);

# Función de progreso
fun progress_callback(time, progress) {
    progress_bar_sprite.SetImage(progress_bar_image.Scale(progress_box_image.GetWidth() * progress, progress_bar_image.GetHeight()));
}

Plymouth.SetBootProgressFunction(progress_callback);

# Función de mensaje
message_sprite = Sprite();
fun message_callback(text) {
    message_image = Image.Text(text, 1, 1, 1);
    message_sprite.SetImage(message_image);
    message_sprite.SetX(screen_width / 2 - message_image.GetWidth() / 2);
    message_sprite.SetY(screen_height * 0.9);
}

Plymouth.SetMessageFunction(message_callback);
EOF

    # Copiar assets de branding
    cp "$ASSETS_DIR/branding/logo.png" "$chroot_dir/usr/share/plymouth/themes/nubemlinux/"
    cp "$ASSETS_DIR/branding/progress_box.png" "$chroot_dir/usr/share/plymouth/themes/nubemlinux/"
    cp "$ASSETS_DIR/branding/progress_bar.png" "$chroot_dir/usr/share/plymouth/themes/nubemlinux/"
    
    # Configurar tema por defecto
    chroot "$chroot_dir" /bin/bash -c "
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/nubemlinux/nubemlinux.plymouth 100
        update-alternatives --set default.plymouth /usr/share/plymouth/themes/nubemlinux/nubemlinux.plymouth
        update-initramfs -u
    "
    
    return 0
}

# Configurar tema de GNOME
configure_gnome_theme() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando tema de GNOME"
    
    # Crear directorio para extensiones
    mkdir -p "$chroot_dir/usr/share/gnome-shell/extensions/nubemlinux@aicorp"
    
    # Crear extensión personalizada
    cat > "$chroot_dir/usr/share/gnome-shell/extensions/nubemlinux@aicorp/metadata.json" <<EOF
{
    "name": "NubemLinux Customization",
    "description": "Personalización de NubemLinux-AICorp",
    "uuid": "nubemlinux@aicorp",
    "shell-version": ["42", "43", "44"],
    "version": 1
}
EOF

    # Script de configuración de GNOME
    cat > "$chroot_dir/usr/local/bin/configure-gnome-branding" <<'EOF'
#!/bin/bash
# Configurar branding de GNOME

# Configurar fondo de pantalla
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/nubemlinux/wallpaper.jpg"
gsettings set org.gnome.desktop.background picture-options "zoom"

# Configurar tema
gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru"
gsettings set org.gnome.desktop.interface cursor-theme "Yaru"

# Configurar fuentes
gsettings set org.gnome.desktop.interface font-name "Ubuntu 11"
gsettings set org.gnome.desktop.interface document-font-name "Ubuntu 11"
gsettings set org.gnome.desktop.interface monospace-font-name "Ubuntu Mono 13"

# Configurar panel superior
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'nubemcopilot.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']"

# Configurar logo en actividades
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
EOF

    chmod +x "$chroot_dir/usr/local/bin/configure-gnome-branding"
    
    # Crear archivo de autostart
    mkdir -p "$chroot_dir/etc/xdg/autostart"
    cat > "$chroot_dir/etc/xdg/autostart/nubemlinux-branding.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=NubemLinux Branding
Exec=/usr/local/bin/configure-gnome-branding
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    return 0
}

# Configurar GDM
configure_gdm() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando GDM (pantalla de login)"
    
    # Crear configuración personalizada de GDM
    mkdir -p "$chroot_dir/etc/gdm3"
    
    cat > "$chroot_dir/etc/gdm3/greeter.dconf-defaults" <<EOF
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/nubemlinux/login-background.jpg'
show-desktop-icons=false

[org/gnome/desktop/interface]
gtk-theme='Yaru-dark'
icon-theme='Yaru'
cursor-theme='Yaru'
font-name='Ubuntu 11'

[org/gnome/login-screen]
logo='/usr/share/icons/nubemlinux/logo-gdm.png'
banner-message-enable=true
banner-message-text='Bienvenido a NubemLinux-AICorp'
disable-user-list=false
EOF

    # Aplicar configuración
    chroot "$chroot_dir" dconf update
    
    return 0
}

# Instalar fondos de pantalla
install_wallpapers() {
    local chroot_dir=$1
    
    log_message "INFO" "Instalando fondos de pantalla"
    
    # Crear directorio para fondos
    mkdir -p "$chroot_dir/usr/share/backgrounds/nubemlinux"
    
    # Copiar fondos de pantalla
    cp "$ASSETS_DIR/branding/wallpaper.jpg" "$chroot_dir/usr/share/backgrounds/nubemlinux/"
    cp "$ASSETS_DIR/branding/login-background.jpg" "$chroot_dir/usr/share/backgrounds/nubemlinux/"
    
    # Crear archivo XML para fondos
    cat > "$chroot_dir/usr/share/gnome-background-properties/nubemlinux-wallpapers.xml" <<EOF
<?xml version="1.0"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
    <wallpaper deleted="false">
        <name>NubemLinux Default</name>
        <filename>/usr/share/backgrounds/nubemlinux/wallpaper.jpg</filename>
        <options>zoom</options>
        <pcolor>#000000</pcolor>
        <scolor>#000000</scolor>
    </wallpaper>
</wallpapers>
EOF

    return 0
}

# Configurar iconos
configure_icons() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando iconos y logos"
    
    # Crear directorios para iconos
    mkdir -p "$chroot_dir/usr/share/icons/nubemlinux"
    mkdir -p "$chroot_dir/usr/share/pixmaps"
    
    # Copiar iconos
    cp "$ASSETS_DIR/branding/logo.png" "$chroot_dir/usr/share/icons/nubemlinux/"
    cp "$ASSETS_DIR/branding/logo-gdm.png" "$chroot_dir/usr/share/icons/nubemlinux/"
    cp "$ASSETS_DIR/branding/icon.png" "$chroot_dir/usr/share/pixmaps/nubemlinux.png"
    
    # Crear tema de iconos personalizado
    cat > "$chroot_dir/usr/share/icons/nubemlinux/index.theme" <<EOF
[Icon Theme]
Name=NubemLinux
Comment=Tema de iconos de NubemLinux-AICorp
Inherits=Yaru
Example=folder

[scalable/apps]
Size=48
Type=Scalable
MinSize=16
MaxSize=512
EOF

    # Actualizar caché de iconos
    chroot "$chroot_dir" gtk-update-icon-cache /usr/share/icons/nubemlinux
    
    return 0
}

# Configurar aplicaciones por defecto
configure_default_apps() {
    local chroot_dir=$1
    
    log_message "INFO" "Configurando aplicaciones por defecto"
    
    # Configurar Firefox con página de inicio personalizada
    mkdir -p "$chroot_dir/usr/lib/firefox/defaults/pref"
    cat > "$chroot_dir/usr/lib/firefox/defaults/pref/nubemlinux.js" <<EOF
pref("browser.startup.homepage", "https://nubemlinux.aicorp.local");
pref("browser.startup.homepage_override.mstone", "ignore");
pref("browser.startup.firstrunSkipsHomepage", false);
pref("browser.rights.override", true);
EOF

    # Configurar Terminal con perfil personalizado
    mkdir -p "$chroot_dir/etc/skel/.config/gnome-terminal/profiles"
    cat > "$chroot_dir/etc/skel/.config/dconf/user.d/gnome-terminal" <<EOF
[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
visible-name='NubemLinux'
background-color='rgb(23,20,33)'
foreground-color='rgb(208,207,204)'
use-theme-colors=false
bold-color-same-as-fg=true
palette=['rgb(23,20,33)', 'rgb(192,28,40)', 'rgb(38,162,105)', 'rgb(162,115,76)', 'rgb(18,72,139)', 'rgb(163,71,186)', 'rgb(42,161,179)', 'rgb(208,207,204)', 'rgb(94,92,100)', 'rgb(246,97,81)', 'rgb(51,209,122)', 'rgb(233,173,12)', 'rgb(42,123,222)', 'rgb(192,97,203)', 'rgb(51,199,222)', 'rgb(255,255,255)']
EOF

    # Configurar archivos .desktop personalizados
    mkdir -p "$chroot_dir/usr/share/applications"
    
    # About NubemLinux
    cat > "$chroot_dir/usr/share/applications/about-nubemlinux.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Acerca de NubemLinux
Comment=Información sobre NubemLinux-AICorp
Exec=/usr/local/bin/about-nubemlinux
Icon=nubemlinux
Terminal=false
Categories=System;
EOF

    # Script de About
    cat > "$chroot_dir/usr/local/bin/about-nubemlinux" <<'EOF'
#!/bin/bash
zenity --info \
    --title="Acerca de NubemLinux-AICorp" \
    --text="NubemLinux-AICorp v1.0.0\n\nDistribución Ubuntu personalizada con IA integrada\n\n© 2024 AICorp\nTodos los derechos reservados\n\nSoporte: support@aicorp.local"
EOF

    chmod +x "$chroot_dir/usr/local/bin/about-nubemlinux"
    
    return 0
}

# Ejecutar función principal
apply_branding "$@"