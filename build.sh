#!/bin/zsh
# Builds CursorRing.app in this folder.
set -e
cd "$(dirname "$0")"
APP=CursorRing.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -o "$APP/Contents/MacOS/CursorRing" main.swift -framework AppKit -framework QuartzCore
cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>CursorRing</string>
  <key>CFBundleIdentifier</key><string>io.github.boyanangelov.cursorring</string>
  <key>CFBundleExecutable</key><string>CursorRing</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict>
</plist>
EOF
codesign --force -s - "$APP" >/dev/null 2>&1 || true
echo "Built $APP — run with: open $APP"
