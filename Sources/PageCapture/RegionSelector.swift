import AppKit

/// Covers every screen with a dimmed overlay and lets you drag out a rectangle.
/// Escape cancels.
@MainActor
final class RegionSelector {
    private var windows: [OverlayWindow] = []
    private var completion: ((Region?) -> Void)?

    func begin(completion: @escaping (Region?) -> Void) {
        self.completion = completion
        for screen in NSScreen.screens {
            guard let displayID = screen.displayID else { continue }
            let window = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.setFrame(screen.frame, display: false)
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let view = SelectionView(displayID: displayID) { [weak self] region in
                self?.finish(region)
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func finish(_ region: Region?) {
        windows.forEach { $0.orderOut(nil) }
        windows = []
        let done = completion
        completion = nil
        done?(region)
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private final class SelectionView: NSView {
    private let displayID: CGDirectDisplayID
    private let onFinish: (Region?) -> Void
    private var start: NSPoint?
    private var current: NSPoint?

    init(displayID: CGDirectDisplayID, onFinish: @escaping (Region?) -> Void) {
        self.displayID = displayID
        self.onFinish = onFinish
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    private var selection: NSRect? {
        guard let start, let current else { return nil }
        return NSRect(x: min(start.x, current.x), y: min(start.y, current.y),
                      width: abs(current.x - start.x), height: abs(current.y - start.y)).integral
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()
        guard let rect = selection else { return }
        NSColor.clear.setFill()
        rect.fill(using: .copy)
        NSColor.systemOrange.setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: -1.5, dy: -1.5))
        border.lineWidth = 3
        border.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        current = start
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        guard let rect = selection, rect.width >= 10, rect.height >= 10 else {
            start = nil; current = nil; needsDisplay = true
            return
        }
        // Flip to top-left origin, which is what ScreenCaptureKit expects.
        let flipped = CGRect(x: rect.minX, y: bounds.height - rect.maxY, width: rect.width, height: rect.height)
        onFinish(Region(displayID: displayID, rect: flipped))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onFinish(nil) } else { super.keyDown(with: event) }
    }
}
