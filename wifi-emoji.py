import os
# os.environ['KIVY_NO_CONSOLELOG'] = '1'  # Disable Kivy's console output

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.image import Image
from kivy.uix.slider import Slider
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.core.clipboard import Clipboard
from kivy.graphics.texture import Texture
from kivy.properties import StringProperty, NumericProperty, ObjectProperty, BooleanProperty
from kivy.metrics import inch, dp
from kivy.core.text import LabelBase
from kivy.config import Config
from kivy.clock import Clock
import io
import secrets
import string
import emoji
from wifi_qrcode_generator import generator
from PIL import Image as PILImage
from functools import partial
import logging
import cv2
import zxingcpp
import numpy as np
import re

# Configure logging and window settings
Config.set('kivy', 'log_level', 'critical')
logging.getLogger('kivy').setLevel(logging.CRITICAL)
Config.set('graphics', 'minimum_width', '600')
Config.set('graphics', 'minimum_height', '500')

# Common emojis to choose from
COMMON_EMOJIS = ["📶", "🏠", "💻", "📱", "🔒", "🌐", "🚀", "✨", "🔑", "🛡️"]

class EmojiFontManager:
    @staticmethod
    def register_emoji_font():
        emoji_font_paths = [
            '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',  # Linux
            'C:/Windows/Fonts/seguiemj.ttf',  # Windows
            '/System/Library/Fonts/Apple Color Emoji.ttc',  # Mac
            '/Library/Fonts/Apple Color Emoji.ttc'  # Alternative Mac
        ]
        for path in emoji_font_paths:
            try:
                LabelBase.register(name='EmojiFont', fn_regular=path)
                return True
            except:
                continue
        try:
            LabelBase.register(name='EmojiFont', fn_regular='Arial')
            return True
        except:
            return False

emoji_font_available = EmojiFontManager.register_emoji_font()

class WiFiUtils:
    @staticmethod
    def get_random_emoji():
        all_emojis = [c for c in emoji.EMOJI_DATA if len(c) == 1 and c not in ['️', '⃣']]
        return secrets.choice(all_emojis) if all_emojis else "📶"

    @staticmethod
    def generate_wpa3_password(length=62):
        if length < 8 or length > 63:
            raise ValueError("Password must be 8-63 characters")
        
        special_chars = "!@$%^&*()-_=+[]{}|,.<>?`~"
        char_sets = [string.ascii_lowercase, string.ascii_uppercase, string.digits, special_chars]
        
        while True:
            password = [secrets.choice(s) for s in char_sets]
            remaining = length - len(password)
            all_chars = ''.join(char_sets)
            password.extend(secrets.choice(all_chars) for _ in range(remaining))
            secrets.SystemRandom().shuffle(password)
            password = ''.join(password)
            
            # Validation checks
            has_lower = any(c.islower() for c in password)
            has_upper = any(c.isupper() for c in password)
            has_digit = any(c.isdigit() for c in password)
            has_special = any(not c.isalnum() for c in password)
            
            if has_lower and has_upper and has_digit and has_special:
                return password

    @staticmethod
    def generate_qr_code(ssid, password, size_pixels):
        qr_code = generator.wifi_qrcode(
            ssid=ssid,
            password=password,
            authentication_type='WPA',
            hidden=False
        )
        img = qr_code.make_image()
        img = img.resize((size_pixels, size_pixels), PILImage.Resampling.LANCZOS)
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='PNG')
        img_bytes.seek(0)
        return img_bytes

class EmojiChooser(Popup):
    def __init__(self, callback, **kwargs):
        super().__init__(**kwargs)
        self.title = 'Choose an Emoji'
        self.size_hint = (0.9, 0.9)
        self.callback = callback
        
        main_layout = BoxLayout(orientation='vertical', spacing=dp(10))
        
        # Common emojis section
        common_label = Label(text="Common Emojis:", size_hint_y=None, height=dp(30))
        main_layout.add_widget(common_label)
        
        emoji_grid = GridLayout(cols=10, spacing=dp(2), size_hint_y=None, height=dp(70))
        for emoji_char in COMMON_EMOJIS:
            btn = Button(
                text=emoji_char,
                font_size='24sp',
                font_name='EmojiFont' if emoji_font_available else None,
                size_hint=(None, None),
                size=(dp(32), dp(32)),
                on_press=partial(self.choose_emoji, emoji_char)
            )
            emoji_grid.add_widget(btn)
        main_layout.add_widget(emoji_grid)
        
        # All emojis section with scroll
        all_label = Label(text="All Emojis:", size_hint_y=None, height=dp(30))
        main_layout.add_widget(all_label)
        
        scroll = ScrollView(do_scroll_x=False)
        emoji_scroll_grid = GridLayout(cols=12, spacing=dp(2), size_hint_y=None, padding=dp(2))
        emoji_scroll_grid.bind(minimum_height=emoji_scroll_grid.setter('height'))
        
        all_emojis = [c for c in emoji.EMOJI_DATA if len(c) == 1 and c not in ['️', '⃣']]
        
        for emoji_char in all_emojis:
            btn = Button(
                text=emoji_char,
                font_size='20sp',
                font_name='EmojiFont' if emoji_font_available else None,
                size_hint=(None, None),
                size=(dp(32), dp(32)),
                on_press=partial(self.choose_emoji, emoji_char)
            )
            emoji_scroll_grid.add_widget(btn)
        
        scroll.add_widget(emoji_scroll_grid)
        main_layout.add_widget(scroll)
        
        random_btn = Button(
            text='Random Emoji',
            size_hint_y=None,
            height=dp(40),
            on_press=lambda x: self.choose_emoji(WiFiUtils.get_random_emoji())
        )
        main_layout.add_widget(random_btn)
        
        self.content = main_layout
    
    def choose_emoji(self, emoji_char, *args):
        self.dismiss()
        self.callback(emoji_char)

class WiFiNamePopup(Popup):
    def __init__(self, current_name, callback, **kwargs):
        super().__init__(**kwargs)
        self.title = 'Enter WiFi Name'
        self.size_hint = (0.8, 0.4)
        self.callback = callback
        
        layout = BoxLayout(orientation='vertical', spacing=dp(10), padding=dp(20))
        
        self.name_input = TextInput(
            text=current_name,
            multiline=False,
            size_hint_y=None,
            height=dp(40)
        )
        layout.add_widget(self.name_input)
        
        btn_layout = BoxLayout(size_hint_y=None, height=dp(50), spacing=dp(10))
        btn_layout.add_widget(Button(
            text='Cancel',
            on_press=lambda x: self.dismiss()
        ))
        btn_layout.add_widget(Button(
            text='Save',
            on_press=self.save_name
        ))
        layout.add_widget(btn_layout)
        
        self.content = layout
    
    def save_name(self, instance):
        self.callback(self.name_input.text)
        self.dismiss()

class QRScannerPopup(Popup):
    def __init__(self, callback, **kwargs):
        super().__init__(**kwargs)
        self.title = 'QR Code Scanner'
        self.size_hint = (0.9, 0.9)
        self.callback = callback
        self.scanning = False
        self.capture = None
        
        layout = BoxLayout(orientation='vertical', spacing=dp(10))
        
        self.camera_view = Image(size_hint=(1, 0.8))
        layout.add_widget(self.camera_view)
        
        self.status_label = Label(
            text="Point camera at a WiFi QR code",
            size_hint_y=None,
            height=dp(30)
        )
        layout.add_widget(self.status_label)
        
        btn_layout = BoxLayout(size_hint_y=None, height=dp(50), spacing=dp(10))
        btn_layout.add_widget(Button(
            text='Cancel',
            on_press=self.stop_and_dismiss
        ))
        layout.add_widget(btn_layout)
        
        self.content = layout
    
    def on_open(self):
        self.start_scanning()
    
    def start_scanning(self):
        self.scanning = True
        self.capture = cv2.VideoCapture(0)
        if not self.capture.isOpened():
            self.status_label.text = "Error: Could not access camera"
            self.scanning = False
            return
        
        Clock.schedule_interval(self.update_camera_view, 1.0/30.0)
    
    def stop_scanning(self):
        self.scanning = False
        if self.capture and self.capture.isOpened():
            self.capture.release()
        self.capture = None
    
    def stop_and_dismiss(self, *args):
        self.stop_scanning()
        self.dismiss()
    
    def parse_wifi_config(self, text):
        """Parse both standard and Samsung-style WiFi QR codes"""
        # Standard format: WIFI:S:<SSID>;T:<TYPE>;P:<PASSWORD>;;
        # Samsung format: WIFI:S:<SSID>;P:<PASSWORD>;T:<TYPE>;H:<true/false>;;
        
        # Remove WIFI: prefix if present
        if text.startswith("WIFI:"):
            text = text[5:]
        
        # Split into components
        parts = text.split(';')
        ssid = None
        password = None
        security_type = None
        hidden = False
        
        for part in parts:
            if part.startswith('S:'):
                ssid = part[2:]
            elif part.startswith('P:'):
                password = part[2:]
            elif part.startswith('T:'):
                security_type = part[2:]
            elif part.startswith('H:'):
                hidden = part[2:].lower() == 'true'
        
        if not ssid:
            raise ValueError("SSID not found in QR code")
        
        # Samsung sometimes includes quotes around values
        if ssid.startswith('"') and ssid.endswith('"'):
            ssid = ssid[1:-1]
        if password and password.startswith('"') and password.endswith('"'):
            password = password[1:-1]
        
        return {
            'ssid': ssid,
            'password': password,
            'security_type': security_type,
            'hidden': hidden
        }
    
    def update_camera_view(self, dt):
        if not self.scanning or not self.capture or not self.capture.isOpened():
            return
            
        ret, frame = self.capture.read()
        if ret:
            # Convert to texture for display
            buf = cv2.flip(frame, 0).tobytes()
            texture = Texture.create(size=(frame.shape[1], frame.shape[0]), colorfmt='bgr')
            texture.blit_buffer(buf, colorfmt='bgr', bufferfmt='ubyte')
            self.camera_view.texture = texture
            
            # Try to decode QR code
            results = zxingcpp.read_barcodes(frame)
            if results:
                try:
                    wifi_config = self.parse_wifi_config(results[0].text)
                    self.stop_scanning()
                    self.callback(wifi_config)
                    self.dismiss()
                except Exception as e:
                    self.status_label.text = f"Error: {str(e)}"
                    Clock.schedule_once(lambda dt: setattr(self.status_label, 'text', 
                                      "Point camera at a WiFi QR code"), 2)
    
    def on_dismiss(self):
        self.stop_scanning()

class WiFiQRApp(App):
    ssid = StringProperty(WiFiUtils.get_random_emoji())
    password = StringProperty(WiFiUtils.generate_wpa3_password(62))
    qr_size = NumericProperty(inch(3))
    password_length = NumericProperty(62)
    qr_img = ObjectProperty(None)
    
    def build(self):
        # Main layout
        main_layout = BoxLayout(orientation='vertical', spacing=dp(10), padding=dp(10))
        
        # Title at top
        main_layout.add_widget(Label(
            text="WiFi QR Code Generator & Scanner",
            font_size='24sp',
            size_hint_y=None,
            height=dp(50))
        )
        
        # Emoji section at the top
        emoji_section = BoxLayout(orientation='vertical',
                                size_hint_y=None,
                                height=dp(150),
                                spacing=dp(5))
        
        self.ssid_display = Label(
            text=self.ssid,
            font_size='80sp',
            font_name='EmojiFont' if emoji_font_available else None,
            halign='center',
            valign='middle',
            size_hint_y=None,
            height=dp(100),
            text_size=(None, None)
        )
        
        emoji_buttons = BoxLayout(orientation='horizontal',
                                size_hint_y=None,
                                height=dp(40),
                                spacing=dp(10))
        
        copy_emoji_btn = Button(
            text='Copy Emoji',
            on_press=self.copy_ssid
        )
        
        change_name_btn = Button(
            text='Change WiFi Name',
            on_press=self.show_name_popup
        )
        
        change_emoji_btn = Button(
            text='Change Emoji',
            on_press=self.show_emoji_chooser
        )
        
        emoji_buttons.add_widget(copy_emoji_btn)
        emoji_buttons.add_widget(change_name_btn)
        emoji_buttons.add_widget(change_emoji_btn)
        
        emoji_section.add_widget(self.ssid_display)
        emoji_section.add_widget(emoji_buttons)
        main_layout.add_widget(emoji_section)
        
        # Content area (QR + controls)
        content_layout = BoxLayout(orientation='horizontal',
                                 spacing=dp(20))
        
        # QR Code (60% width)
        qr_container = BoxLayout(orientation='vertical',
                               size_hint=(0.6, 1))
        self.qr_img = Image(size_hint=(1, 1))
        qr_container.add_widget(self.qr_img)
        content_layout.add_widget(qr_container)
        
        # Controls (40% width)
        control_layout = BoxLayout(orientation='vertical',
                                  size_hint=(0.4, 1),
                                  spacing=dp(15))
        
        # Password Length Controls
        length_container = BoxLayout(orientation='vertical',
                                   size_hint_y=None,
                                   height=dp(180),
                                   spacing=dp(5))
        
        length_box = BoxLayout(orientation='horizontal',
                             size_hint_y=None,
                             height=dp(40))
        length_box.add_widget(Label(
            text="Length:",
            size_hint_x=None,
            width=dp(60))
        )
        self.length_slider = Slider(
            min=8,
            max=63,
            value=62,
            step=1
        )
        self.length_slider.bind(value=self.on_length_change)
        length_box.add_widget(self.length_slider)
        
        self.length_input = TextInput(
            text=str(62),
            input_filter='int',
            size_hint_x=None,
            width=dp(50),
            multiline=False
        )
        self.length_input.bind(text=self.on_length_input)
        length_box.add_widget(self.length_input)
        length_container.add_widget(length_box)
        
        # Password Display
        self.pw_display = Label(
            text=self.password,
            font_size='14sp',
            halign='center',
            valign='middle',
            size_hint_y=None,
            text_size=(dp(200), None),
            padding=(dp(5), dp(5)),
            height=dp(80)
        )
        length_container.add_widget(self.pw_display)
        
        copy_pw_btn = Button(
            text="Copy Password",
            size_hint_y=None,
            height=dp(40),
            on_press=self.copy_password
        )
        length_container.add_widget(copy_pw_btn)
        control_layout.add_widget(length_container)
        
        content_layout.add_widget(control_layout)
        main_layout.add_widget(content_layout)
        
        # Bottom button row
        btn_row = BoxLayout(orientation='horizontal',
                          size_hint_y=None,
                          height=dp(50),
                          spacing=dp(10))
        
        btn_row.add_widget(Button(
            text="Generate New",
            on_press=self.generate_new
        ))
        btn_row.add_widget(Button(
            text="Scan QR Code",
            on_press=self.show_scanner
        ))
        btn_row.add_widget(Button(
            text="Quit",
            on_press=self.quit_app
        ))
        
        main_layout.add_widget(btn_row)
        
        # Initial setup
        self.update_qr_code()
        return main_layout
    
    def show_emoji_chooser(self, instance):
        popup = EmojiChooser(self.set_emoji)
        popup.open()
    
    def show_name_popup(self, instance):
        popup = WiFiNamePopup(self.ssid, self.set_wifi_name)
        popup.open()
    
    def show_scanner(self, instance):
        popup = QRScannerPopup(self.handle_scanned_qr)
        popup.open()
    
    def handle_scanned_qr(self, wifi_config):
        try:
            # Update the UI with scanned values
            self.ssid = wifi_config['ssid']
            self.password = wifi_config['password'] if wifi_config['password'] else ""
            self.ssid_display.text = wifi_config['ssid']
            self.pw_display.text = wifi_config['password'] if wifi_config['password'] else ""
            self.update_qr_code()  # Generate new QR code with scanned data
            
            # Show success message
            success_popup = Popup(title='Success',
                                content=Label(text='WiFi details imported successfully!'),
                                size_hint=(0.7, 0.3))
            success_popup.open()
        except Exception as e:
            # Show error message if parsing fails
            error_popup = Popup(title='Error',
                              content=Label(text=f'Failed to parse QR code: {str(e)}'),
                              size_hint=(0.7, 0.3))
            error_popup.open()
    
    def set_emoji(self, emoji_char):
        self.ssid = emoji_char
        self.ssid_display.text = emoji_char
        self.update_qr_code()
    
    def set_wifi_name(self, name):
        if name.strip():
            self.ssid = name
            self.ssid_display.text = name
            self.update_qr_code()
    
    def on_start(self):
        self.root_window.bind(size=self.on_window_resize)
    
    def on_window_resize(self, window, size):
        new_size = min(size[0] * 0.6 - dp(40), size[1] - dp(150))
        self.qr_size = max(new_size, inch(3))
        self.update_qr_code()
    
    def on_length_change(self, instance, value):
        length = int(value)
        self.password_length = length
        self.length_input.text = str(length)
        self.password = WiFiUtils.generate_wpa3_password(length)
        self.pw_display.text = self.password
        self.update_qr_code()
    
    def on_length_input(self, instance, value):
        try:
            length = int(value) if value else 8
            length = max(8, min(63, length))
            self.password_length = length
            self.length_slider.value = length
            self.password = WiFiUtils.generate_wpa3_password(length)
            self.pw_display.text = self.password
            self.update_qr_code()
        except ValueError:
            pass
    
    def update_qr_code(self):
        try:
            size_pixels = int(self.qr_size * (96 / inch(1)))
            img_bytes = WiFiUtils.generate_qr_code(self.ssid, self.password, size_pixels)
            pil_img = PILImage.open(img_bytes)
            if pil_img.mode != 'RGBA':
                pil_img = pil_img.convert('RGBA')
            texture = Texture.create(size=pil_img.size, colorfmt='rgba')
            texture.blit_buffer(pil_img.tobytes(), colorfmt='rgba', bufferfmt='ubyte')
            self.qr_img.texture = texture
            self.qr_img.size = (self.qr_size, self.qr_size)
        except Exception as e:
            print(f"Error updating QR code: {e}")
    
    def copy_ssid(self, instance):
        try:
            Clipboard.copy(self.ssid)
        except Exception as e:
            print(f"Error copying SSID: {e}")
    
    def copy_password(self, instance):
        try:
            Clipboard.copy(self.password)
        except Exception as e:
            print(f"Error copying password: {e}")
    
    def generate_new(self, instance):
        self.password = WiFiUtils.generate_wpa3_password(self.password_length)
        self.pw_display.text = self.password
        self.update_qr_code()
    
    def quit_app(self, instance):
        App.get_running_app().stop()

if __name__ == "__main__":
    WiFiQRApp().run()
