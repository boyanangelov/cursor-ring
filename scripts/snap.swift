// snap.swift — screenshot the area around the mouse cursor over a clean backdrop.
//
// Opens a full-screen backdrop window (below overlays such as CursorRing),
// moves the cursor to the middle of the screen, captures a region centred on
// it, then closes the backdrop and puts the cursor back where it was.
// Works for any app that draws something on top of other windows.
//
// Usage: swift scripts/snap.swift [out.png] [width] [height] [dark|light]
// Needs Screen Recording permission for your terminal (System Settings ▸
// Privacy & Security ▸ Screen Recording).
import AppKit

let args = CommandLine.arguments
let out = args.count > 1 ? args[1] : "screenshot.png"
let w = args.count > 2 ? Double(args[2]) ?? 640 : 640
let h = args.count > 3 ? Double(args[3]) ?? 400 : 400
let light = args.count > 4 && args[4] == "light"

guard let screen = NSScreen.main else { fatalError("no screen") }
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Backdrop: a borderless window with a soft gradient, covering the screen.
let win = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
win.level = .floating
win.isOpaque = true
let view = NSView(frame: screen.frame)
view.wantsLayer = true
let g = CAGradientLayer()
g.frame = view.bounds
g.colors = light
    ? [NSColor(white: 0.97, alpha: 1).cgColor, NSColor(white: 0.86, alpha: 1).cgColor]
    : [NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.24, alpha: 1).cgColor,
       NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.11, alpha: 1).cgColor]
view.layer?.addSublayer(g)
win.contentView = view
win.orderFrontRegardless()

// Remember the cursor (CG coordinates: origin top-left), move it to the centre.
let oldPos = CGEvent(source: nil)?.location ?? .zero
let centre = CGPoint(x: screen.frame.midX, y: screen.frame.height - screen.frame.midY)
CGWarpMouseCursorPosition(centre)
CGAssociateMouseAndMouseCursorPosition(1)

DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
    let x = Int(centre.x - w / 2), y = Int(centre.y - h / 2)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    p.arguments = ["-x", "-C", "-R", "\(x),\(y),\(Int(w)),\(Int(h))", out]
    try? p.run()
    p.waitUntilExit()
    win.orderOut(nil)
    CGWarpMouseCursorPosition(oldPos)
    CGAssociateMouseAndMouseCursorPosition(1)
    print(p.terminationStatus == 0 ? "Saved \(out)" : "screencapture failed")
    exit(p.terminationStatus)
}
app.run()
