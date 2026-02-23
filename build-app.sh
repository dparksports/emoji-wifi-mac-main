#!/bin/bash
set -e

APP_NAME="EmojiWifi"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"

echo "🔨 Building ${APP_NAME}..."
swift build -c release 2>&1

echo "📦 Creating app bundle..."

# Clean previous build
rm -rf "$APP_DIR"

# Create bundle structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Copy SPM resource bundle (SPM generates this alongside the binary)
RESOURCE_BUNDLE="${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP_DIR/Contents/Resources/"
    echo "   Copied resource bundle"
fi

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>EmojiWifi</string>
    <key>CFBundleIdentifier</key>
    <string>com.emojiwifi.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>EmojiWifi</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSCameraUsageDescription</key>
    <string>EmojiWifi needs camera access to scan WiFi QR codes.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# Sign the app bundle
echo "🔐 Signing app bundle..."
codesign --force --sign - "$APP_DIR"

echo ""
echo "✅ Built successfully: ${APP_DIR}"
echo "   To run:  open ${APP_DIR}"
echo "   To install: cp -R ${APP_DIR} /Applications/"
