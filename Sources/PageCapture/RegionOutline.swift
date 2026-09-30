import AppKit

/// An orange line drawn just outside the capture region, so you can see what will be captured.
/// It ignores the mouse and, as one of this app's windows, is left out of the captures.
@MainActor
final class RegionOutline {
    private static let gap: CGFloat = 2
    private static let lineWidth: CGFloat = 3

    private var window: NSWindow?

    func show(_ region: Region?) {
        guard let region, let screen = NSScreen.screens.first(where: { $0.displayID == region.displayID }) else {
            hide()
            return
        }
        // Region is measured from the display's top-left; Cocoa windows from the bottom-left.
        let local = region.rect
        let global = NSRect(x: screen.frame.minX + local.minX,
                            y: screen.frame.maxY - local.maxY,
                            width: local.width, height: local.height)
        let frame = global.insetBy(dx: -(Self.gap + Self.lineWidth), dy: -(Self.gap + Self.lineWidth))

        let window = self.window ?? makeWindow()
        window.setFrame(frame, display: true)
        window.orderFrontRegardless()
        self.window = window
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = OutlineView(lineWidth: Self.lineWidth)
        return window
    }
}

private final class OutlineView: NSView {
    private let lineWidth: CGFloat

    init(lineWidth: CGFloat) {
        self.lineWidth = lineWidth
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(rect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2))
        path.lineWidth = lineWidth
        NSColor.systemOrange.setStroke()
        path.stroke()
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
