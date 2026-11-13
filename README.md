# CursorRing

A tiny macOS menu-bar app that draws a circular band around the mouse cursor at an adjustable radius.

## Build & run

```sh
./build.sh
open CursorRing.app
```

Use the menu-bar icon to adjust radius, thickness, opacity and color, or to hide the ring.

## Start at login

Tick **Start at Login** in the menu-bar menu. It writes a LaunchAgent (`~/Library/LaunchAgents/local.cursorring.plist`) pointing at the running copy of the app, and unticking removes it. The change applies from your next login.

Or install it into `~/Applications` and register it for login in one go:

```sh
./install.sh
```

Installs to `~/Applications` and registers a LaunchAgent (`~/Library/LaunchAgents/local.cursorring.plist`). The script prints the uninstall command.
