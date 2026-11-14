import AppKit
import QuartzCore

// MARK: - Settings

final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    var radius: CGFloat {
        get { CGFloat(d.object(forKey: "radius") as? Double ?? 40) }
        set { d.set(Double(newValue), forKey: "radius") }
    }
    var thickness: CGFloat {
        get { CGFloat(d.object(forKey: "thickness") as? Double ?? 4) }
        set { d.set(Double(newValue), forKey: "thickness") }
    }
    var opacity: CGFloat {
        get { CGFloat(d.object(forKey: "opacity") as? Double ?? 0.6) }
        set { d.set(Double(newValue), forKey: "opacity") }
    }
    var colorIndex: Int {
        get { d.object(forKey: "colorIndex") as? Int ?? 0 }
        set { d.set(newValue, forKey: "colorIndex") }
    }
    var visible: Bool {
        get { d.object(forKey: "visible") as? Bool ?? true }
        set { d.set(newValue, forKey: "visible") }
    }
}

let palette: [(String, NSColor)] = [
    ("Yellow", .systemYellow),
    ("Red", .systemRed),
    ("Blue", .systemBlue),
    ("Green", .systemGreen),
    ("White", .white),
    ("Black", .black),
]

// MARK: - Login item (LaunchAgent, same plist as install.sh)

enum LoginItem {
    static let label = "io.github.boyanangelov.cursorring"
    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool { FileManager.default.fileExists(atPath: plistURL.path) }

    /// Writes or removes the LaunchAgent. Takes effect at next login; we deliberately
    /// don't bootstrap/bootout now, which would spawn a second copy or kill this one.
    static func set(_ enabled: Bool) throws {
        if !enabled {
            try? FileManager.default.removeItem(at: plistURL)
            return
        }
        guard let exe = Bundle.main.executablePath else { return }
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [exe],
            "RunAtLoad": true,
            "KeepAlive": ["SuccessfulExit": false],
            "ProcessType": "Interactive",
        ]
        try FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL, options: .atomic)
    }
}

// MARK: - Ring window

final class RingWindow: NSWindow {
    let ring = CAShapeLayer()

    init() {
        super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let view = NSView()
        view.wantsLayer = true
        view.layer?.addSublayer(ring)
        contentView = view

        ring.fillColor = NSColor.clear.cgColor
        ring.actions = ["path": NSNull(), "position": NSNull(), "bounds": NSNull()]
        applySettings()
    }

    var size: CGFloat {
        let s = Settings.shared
        return (s.radius + s.thickness / 2 + 2) * 2
    }

    func applySettings() {
        let s = Settings.shared
        let side = size
        setContentSize(NSSize(width: side, height: side))
        let rect = CGRect(x: side / 2 - s.radius, y: side / 2 - s.radius,
                          width: s.radius * 2, height: s.radius * 2)
        ring.frame = CGRect(x: 0, y: 0, width: side, height: side)
        ring.path = CGPath(ellipseIn: rect, transform: nil)
        ring.lineWidth = s.thickness
        ring.strokeColor = palette[s.colorIndex % palette.count].1
            .withAlphaComponent(s.opacity).cgColor
        follow(force: true)
    }

    private var last = NSPoint(x: -1, y: -1)

    func follow(force: Bool = false) {
        let p = NSEvent.mouseLocation
        if !force && p == last { return }
        last = p
        let half = size / 2
        setFrameOrigin(NSPoint(x: p.x - half, y: p.y - half))
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: RingWindow!
    var statusItem: NSStatusItem!
    var timer: Timer?
    var toggleItem: NSMenuItem!
    var radiusLabel: NSTextField!
    var thicknessLabel: NSTextField!
    var opacityLabel: NSTextField!

    func applicationDidFinishLaunching(_ n: Notification) {
        window = RingWindow()
        if Settings.shared.visible { window.orderFrontRegardless() }

        timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            self?.window.follow()
        }
        RunLoop.main.add(timer!, forMode: .common)

        buildMenu()
    }

    // MARK: Menu

    func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Cursor Ring")

        let menu = NSMenu()

        toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")
        toggleItem.target = self
        updateToggleTitle()
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let s = Settings.shared
        radiusLabel = addSlider(to: menu, title: "Radius", min: 5, max: 300, value: s.radius,
                                action: #selector(radiusChanged(_:)))
        thicknessLabel = addSlider(to: menu, title: "Thickness", min: 1, max: 40, value: s.thickness,
                                   action: #selector(thicknessChanged(_:)))
        opacityLabel = addSlider(to: menu, title: "Opacity", min: 0.05, max: 1, value: s.opacity,
                                 action: #selector(opacityChanged(_:)))
        refreshLabels()

        menu.addItem(.separator())
        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for (i, (name, _)) in palette.enumerated() {
            let item = NSMenuItem(title: name, action: #selector(colorChanged(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            item.state = i == s.colorIndex ? .on : .off
            colorMenu.addItem(item)
        }
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        menu.addItem(.separator())
        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Cursor Ring", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    func addSlider(to menu: NSMenu, title: String, min: Double, max: Double, value: CGFloat,
                   action: Selector) -> NSTextField {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 44))
        let label = NSTextField(labelWithString: title)
        label.font = .menuFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: 16, y: 24, width: 208, height: 16)
        let slider = NSSlider(value: Double(value), minValue: min, maxValue: max, target: self, action: action)
        slider.isContinuous = true
        slider.frame = NSRect(x: 14, y: 2, width: 212, height: 22)
        view.addSubview(label)
        view.addSubview(slider)
        let item = NSMenuItem()
        item.view = view
        menu.addItem(item)
        return label
    }

    func refreshLabels() {
        let s = Settings.shared
        radiusLabel.stringValue = "Radius: \(Int(s.radius)) pt"
        thicknessLabel.stringValue = "Thickness: \(Int(s.thickness)) pt"
        opacityLabel.stringValue = "Opacity: \(Int((s.opacity * 100).rounded()))%"
    }

    func updateToggleTitle() {
        toggleItem.title = Settings.shared.visible ? "Hide Ring" : "Show Ring"
    }

    @objc func toggle() {
        Settings.shared.visible.toggle()
        if Settings.shared.visible { window.orderFrontRegardless() } else { window.orderOut(nil) }
        updateToggleTitle()
    }

    @objc func toggleLogin(_ item: NSMenuItem) {
        do {
            try LoginItem.set(item.state != .on)
        } catch {
            NSAlert(error: error).runModal()
        }
        item.state = LoginItem.isEnabled ? .on : .off
    }

    @objc func radiusChanged(_ s: NSSlider) {
        Settings.shared.radius = CGFloat(s.doubleValue.rounded()); window.applySettings(); refreshLabels()
    }
    @objc func thicknessChanged(_ s: NSSlider) {
        Settings.shared.thickness = CGFloat(s.doubleValue.rounded()); window.applySettings(); refreshLabels()
    }
    @objc func opacityChanged(_ s: NSSlider) {
        Settings.shared.opacity = CGFloat(s.doubleValue); window.applySettings(); refreshLabels()
    }
    @objc func colorChanged(_ item: NSMenuItem) {
        Settings.shared.colorIndex = item.tag
        item.menu?.items.forEach { $0.state = $0.tag == item.tag ? .on : .off }
        window.applySettings()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
