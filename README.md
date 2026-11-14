# CursorRing

A tiny macOS menu-bar app that draws a circular band around the mouse cursor at an adjustable radius.

![CursorRing around the mouse cursor](docs/screenshot.png)

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

## Screenshots

`scripts/snap.swift` captures the area around the cursor over a clean backdrop, so no other windows end up in the shot. It works for any app that draws on top of other windows:

```sh
swift scripts/snap.swift docs/screenshot.png 640 400 dark   # or light
```

Your terminal needs Screen Recording permission.
