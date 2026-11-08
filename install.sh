#!/bin/zsh
# Builds CursorRing, installs it to ~/Applications and starts it at login (LaunchAgent).
set -e
cd "$(dirname "$0")"
./build.sh
DEST="$HOME/Applications/CursorRing.app"
PLIST="$HOME/Library/LaunchAgents/local.cursorring.plist"
mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
pkill -x CursorRing 2>/dev/null || true
launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
rm -rf "$DEST" && cp -R CursorRing.app "$DEST"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>local.cursorring</string>
  <key>ProgramArguments</key>
  <array><string>$DEST/Contents/MacOS/CursorRing</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
EOF
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed to $DEST; starts at login."
echo "Uninstall: launchctl bootout gui/\$(id -u) $PLIST && rm $PLIST && rm -rf $DEST"
