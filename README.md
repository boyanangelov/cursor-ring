# CursorRing

A tiny macOS menu-bar app that draws a circular band around the mouse cursor at an adjustable radius.

## Build & run

```sh
./build.sh
open CursorRing.app
```

Use the menu-bar icon to adjust radius, thickness, opacity and color, or to hide the ring.

## Start at login

```sh
./install.sh
```

Installs to `~/Applications` and registers a LaunchAgent (`~/Library/LaunchAgents/local.cursorring.plist`). The script prints the uninstall command.
