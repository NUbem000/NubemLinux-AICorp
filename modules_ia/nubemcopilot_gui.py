#!/usr/bin/env python3
# Interfaz gráfica para NubemCopilot

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk, GdkPixbuf
import os
import sys
import threading
import json
from pathlib import Path

class NubemCopilotGUI(Gtk.Window):
    def __init__(self):
        super().__init__(title="NubemCopilot - Asistente IA")
        self.set_default_size(800, 600)
        self.set_border_width(10)
        
        # Cargar configuración
        self.config = self.load_config()
        
        # Importar módulo principal
        sys.path.insert(0, '/opt/nubemcopilot')
        from nubemcopilot import NubemCopilot
        self.copilot = NubemCopilot()
        
        # Crear interfaz
        self.init_ui()
        
    def load_config(self):
        """Cargar configuración de usuario"""
        config_path = Path.home() / ".config" / "nubemcopilot" / "config.json"
        if config_path.exists():
            with open(config_path, 'r') as f:
                return json.load(f)
        return {
            "theme": "dark",
            "font_size": 12,
            "language": "es"
        }
    
    def init_ui(self):
        """Inicializar interfaz de usuario"""
        # Caja principal vertical
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)
        
        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        vbox.pack_start(header, False, False, 0)
        
        # Logo
        try:
            logo = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                "/usr/share/icons/nubemlinux/logo.png", 48, 48, True
            )
            image = Gtk.Image.new_from_pixbuf(logo)
            header.pack_start(image, False, False, 0)
        except:
            pass
        
        # Título
        label = Gtk.Label(label="NubemCopilot")
        label.set_markup("<span size='large' weight='bold'>NubemCopilot</span>")
        header.pack_start(label, False, False, 0)
        
        # Área de conversación (scrollable)
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        vbox.pack_start(scrolled, True, True, 0)
        
        # Vista de texto para conversación
        self.textview = Gtk.TextView()
        self.textview.set_editable(False)
        self.textview.set_wrap_mode(Gtk.WrapMode.WORD)
        self.textview.set_left_margin(10)
        self.textview.set_right_margin(10)
        self.textbuffer = self.textview.get_buffer()
        scrolled.add(self.textview)
        
        # Separador
        vbox.pack_start(Gtk.Separator(), False, False, 0)
        
        # Área de entrada
        input_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        vbox.pack_start(input_box, False, False, 0)
        
        # Campo de entrada
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Escribe tu pregunta aquí...")
        self.entry.connect("activate", self.on_send_clicked)
        input_box.pack_start(self.entry, True, True, 0)
        
        # Botones
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        input_box.pack_start(button_box, False, False, 0)
        
        # Botón enviar
        send_button = Gtk.Button.new_with_label("Enviar")
        send_button.connect("clicked", self.on_send_clicked)
        button_box.pack_start(send_button, False, False, 0)
        
        # Botón imagen
        image_button = Gtk.Button.new_with_label("📷")
        image_button.set_tooltip_text("Adjuntar imagen")
        image_button.connect("clicked", self.on_image_clicked)
        button_box.pack_start(image_button, False, False, 0)
        
        # Botón voz
        voice_button = Gtk.Button.new_with_label("🎤")
        voice_button.set_tooltip_text("Entrada de voz")
        voice_button.connect("clicked", self.on_voice_clicked)
        button_box.pack_start(voice_button, False, False, 0)
        
        # Botón configuración
        settings_button = Gtk.Button.new_with_label("⚙")
        settings_button.set_tooltip_text("Configuración")
        settings_button.connect("clicked", self.on_settings_clicked)
        button_box.pack_start(settings_button, False, False, 0)
        
        # Barra de estado
        self.statusbar = Gtk.Statusbar()
        vbox.pack_start(self.statusbar, False, False, 0)
        self.statusbar.push(0, "Listo")
        
        # Aplicar tema
        self.apply_theme()
        
        # Mensaje de bienvenida
        self.add_message("Asistente", "¡Hola! Soy NubemCopilot, tu asistente IA. ¿En qué puedo ayudarte?")
    
    def apply_theme(self):
        """Aplicar tema a la interfaz"""
        if self.config.get("theme") == "dark":
            css = b"""
            window {
                background-color: #2b2b2b;
            }
            textview {
                background-color: #1e1e1e;
                color: #ffffff;
                font-size: 14px;
            }
            entry {
                background-color: #3c3c3c;
                color: #ffffff;
                border: 1px solid #555555;
                padding: 8px;
            }
            button {
                background-color: #0d7377;
                color: #ffffff;
                border: none;
                padding: 8px 16px;
            }
            button:hover {
                background-color: #14a1a5;
            }
            """
            css_provider = Gtk.CssProvider()
            css_provider.load_from_data(css)
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
    
    def add_message(self, sender, message):
        """Añadir mensaje a la conversación"""
        end_iter = self.textbuffer.get_end_iter()
        
        # Añadir timestamp
        timestamp = GLib.DateTime.new_now_local().format("%H:%M")
        self.textbuffer.insert_with_tags_by_name(
            end_iter, f"[{timestamp}] ", "timestamp"
        )
        
        # Añadir remitente
        self.textbuffer.insert_with_tags_by_name(
            end_iter, f"{sender}: ", "sender"
        )
        
        # Añadir mensaje
        self.textbuffer.insert(end_iter, f"{message}\n\n")
        
        # Auto-scroll
        self.textview.scroll_to_iter(end_iter, 0.0, False, 0.0, 0.0)
        
        # Crear tags si no existen
        tag_table = self.textbuffer.get_tag_table()
        if not tag_table.lookup("timestamp"):
            tag = self.textbuffer.create_tag("timestamp", foreground="#888888", scale=0.9)
        if not tag_table.lookup("sender"):
            tag = self.textbuffer.create_tag("sender", weight=700)
    
    def on_send_clicked(self, widget):
        """Manejar envío de mensaje"""
        text = self.entry.get_text().strip()
        if not text:
            return
        
        # Limpiar entrada
        self.entry.set_text("")
        
        # Añadir mensaje del usuario
        self.add_message("Tú", text)
        
        # Actualizar estado
        self.statusbar.push(0, "Procesando...")
        
        # Procesar en thread separado
        thread = threading.Thread(target=self.process_query, args=(text,))
        thread.daemon = True
        thread.start()
    
    def process_query(self, query):
        """Procesar consulta en thread separado"""
        try:
            response = self.copilot.process_text(query)
            GLib.idle_add(self.add_message, "NubemCopilot", response)
            GLib.idle_add(self.statusbar.push, 0, "Listo")
        except Exception as e:
            GLib.idle_add(self.add_message, "Error", str(e))
            GLib.idle_add(self.statusbar.push, 0, "Error")
    
    def on_image_clicked(self, widget):
        """Manejar carga de imagen"""
        dialog = Gtk.FileChooserDialog(
            title="Seleccionar imagen",
            parent=self,
            action=Gtk.FileChooserAction.OPEN
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN, Gtk.ResponseType.OK
        )
        
        # Filtro de imágenes
        filter_image = Gtk.FileFilter()
        filter_image.set_name("Imágenes")
        filter_image.add_mime_type("image/*")
        dialog.add_filter(filter_image)
        
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            filename = dialog.get_filename()
            self.process_image(filename)
        
        dialog.destroy()
    
    def process_image(self, filename):
        """Procesar imagen seleccionada"""
        self.add_message("Tú", f"[Imagen: {os.path.basename(filename)}]")
        self.statusbar.push(0, "Procesando imagen...")
        
        thread = threading.Thread(target=self._process_image_thread, args=(filename,))
        thread.daemon = True
        thread.start()
    
    def _process_image_thread(self, filename):
        """Procesar imagen en thread separado"""
        try:
            response = self.copilot.process_image(filename)
            GLib.idle_add(self.add_message, "NubemCopilot", response)
            GLib.idle_add(self.statusbar.push, 0, "Listo")
        except Exception as e:
            GLib.idle_add(self.add_message, "Error", str(e))
            GLib.idle_add(self.statusbar.push, 0, "Error")
    
    def on_voice_clicked(self, widget):
        """Manejar entrada de voz"""
        dialog = VoiceDialog(self)
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            audio_file = dialog.get_audio_file()
            if audio_file:
                self.process_voice(audio_file)
        
        dialog.destroy()
    
    def process_voice(self, audio_file):
        """Procesar audio"""
        self.add_message("Tú", "[Grabación de voz]")
        self.statusbar.push(0, "Procesando audio...")
        
        thread = threading.Thread(target=self._process_voice_thread, args=(audio_file,))
        thread.daemon = True
        thread.start()
    
    def _process_voice_thread(self, audio_file):
        """Procesar audio en thread separado"""
        try:
            text = self.copilot.process_voice(audio_file)
            GLib.idle_add(self.add_message, "Transcripción", text)
            
            # Procesar la transcripción
            response = self.copilot.process_text(text)
            GLib.idle_add(self.add_message, "NubemCopilot", response)
            GLib.idle_add(self.statusbar.push, 0, "Listo")
        except Exception as e:
            GLib.idle_add(self.add_message, "Error", str(e))
            GLib.idle_add(self.statusbar.push, 0, "Error")
    
    def on_settings_clicked(self, widget):
        """Abrir diálogo de configuración"""
        dialog = SettingsDialog(self, self.config)
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            self.config = dialog.get_config()
            self.save_config()
            self.apply_theme()
        
        dialog.destroy()
    
    def save_config(self):
        """Guardar configuración"""
        config_dir = Path.home() / ".config" / "nubemcopilot"
        config_dir.mkdir(parents=True, exist_ok=True)
        
        with open(config_dir / "config.json", 'w') as f:
            json.dump(self.config, f, indent=4)


class VoiceDialog(Gtk.Dialog):
    """Diálogo para grabación de voz"""
    def __init__(self, parent):
        super().__init__(title="Grabación de voz", parent=parent)
        self.set_default_size(300, 150)
        
        self.audio_file = None
        
        content = self.get_content_area()
        content.set_spacing(10)
        content.set_border_width(10)
        
        # Label
        label = Gtk.Label(label="Presione el botón para grabar")
        content.pack_start(label, False, False, 0)
        
        # Botón de grabación
        self.record_button = Gtk.ToggleButton(label="🎤 Grabar")
        self.record_button.connect("toggled", self.on_record_toggled)
        content.pack_start(self.record_button, False, False, 0)
        
        # Añadir botones
        self.add_button(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL)
        self.add_button(Gtk.STOCK_OK, Gtk.ResponseType.OK)
        
        self.show_all()
    
    def on_record_toggled(self, button):
        """Manejar inicio/fin de grabación"""
        if button.get_active():
            button.set_label("⏹ Detener")
            # Iniciar grabación
            self.start_recording()
        else:
            button.set_label("🎤 Grabar")
            # Detener grabación
            self.stop_recording()
    
    def start_recording(self):
        """Iniciar grabación de audio"""
        # Implementar grabación con pyaudio
        self.audio_file = "/tmp/nubemcopilot_audio.wav"
    
    def stop_recording(self):
        """Detener grabación de audio"""
        # Implementar detención de grabación
        pass
    
    def get_audio_file(self):
        """Obtener archivo de audio grabado"""
        return self.audio_file


class SettingsDialog(Gtk.Dialog):
    """Diálogo de configuración"""
    def __init__(self, parent, config):
        super().__init__(title="Configuración", parent=parent)
        self.set_default_size(400, 300)
        
        self.config = config.copy()
        
        content = self.get_content_area()
        content.set_spacing(10)
        content.set_border_width(10)
        
        # Tema
        theme_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        content.pack_start(theme_box, False, False, 0)
        
        theme_label = Gtk.Label(label="Tema:")
        theme_box.pack_start(theme_label, False, False, 0)
        
        self.theme_combo = Gtk.ComboBoxText()
        self.theme_combo.append("light", "Claro")
        self.theme_combo.append("dark", "Oscuro")
        self.theme_combo.set_active_id(self.config.get("theme", "dark"))
        theme_box.pack_start(self.theme_combo, False, False, 0)
        
        # Modelo de IA
        model_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        content.pack_start(model_box, False, False, 0)
        
        model_label = Gtk.Label(label="Modelo de IA:")
        model_box.pack_start(model_label, False, False, 0)
        
        self.model_combo = Gtk.ComboBoxText()
        self.model_combo.append("llama3.1", "Llama 3.1")
        self.model_combo.append("llama2", "Llama 2")
        self.model_combo.set_active_id(self.config.get("model", "llama3.1"))
        model_box.pack_start(self.model_combo, False, False, 0)
        
        # Añadir botones
        self.add_button(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL)
        self.add_button(Gtk.STOCK_OK, Gtk.ResponseType.OK)
        
        self.show_all()
    
    def get_config(self):
        """Obtener configuración actualizada"""
        self.config["theme"] = self.theme_combo.get_active_id()
        self.config["model"] = self.model_combo.get_active_id()
        return self.config


def launch_gui():
    """Lanzar interfaz gráfica"""
    app = NubemCopilotGUI()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()


if __name__ == "__main__":
    launch_gui()