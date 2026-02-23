# EmojiWifi

EmojiWifi is a fun, streamlined macOS menu bar & window application to instantly generate WiFi names (SSIDs) and passwords strictly based on Emojis!

## ✨ Features (v2.0)

- **Pure Emoji Generation**: Go wild with WiFi names made from a variety of emoji combinations, single emojis, or strictly randomly assembled strings!
- **Persistent History**: The app remembers all your generated combinations and scanned codes. 
- **QR Code Generator & Scanner**: Instantly generate scannable QR codes for your WiFi networks and scan them back using either your Mac's built-in camera or an imported image.
- **Auto Join**: Automatically connect to the Wi-Fi network that you've just generated or scanned.
- **No Gatekeeper warnings!**: We now distribute a signed `.app` bundle, resolving any macOS warnings about unverified software.

## ⬇️ Download & Install

**[Download EmojiWifi v2.0 here](https://github.com/dparksports/emoji-wifi-mac-main/releases/download/v2.0.0/EmojiWifi.zip)**

1. Download the `EmojiWifi.zip` file from the link above.
2. Double click to extract it.
3. Drag the `EmojiWifi.app` to your `/Applications` folder.
4. Open the app and start generating!

## 🛠️ Building from Source

EmojiWifi is built with SwiftUI and Swift Package Manager.

1. Clone this repository:
   ```bash
   git clone https://github.com/dparksports/emoji-wifi-mac-main.git
   ```
2. Run the build script to compile and create the `.app` bundle:
   ```bash
   ./build-app.sh
   ```
3. Open the resulting `EmojiWifi.app`!

## 📜 License
Apache License 2.0. Feel free to use and modify it!
