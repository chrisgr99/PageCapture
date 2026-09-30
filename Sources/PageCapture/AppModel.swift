import AppKit
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var region: Region? { didSet { saveRegion(); outline.show(region) } }
    @Published var folder: URL? { didSet { UserDefaults.standard.set(folder?.path, forKey: "folder") } }
    @Published var status = "Select a region and a folder, then capture a test page."
    @Published var busy = false

    private let selector = RegionSelector()
    private let outline = RegionOutline()

    init() {
        if let data = UserDefaults.standard.data(forKey: "region") {
            region = try? JSONDecoder().decode(Region.self, from: data)
        }
        if let path = UserDefaults.standard.string(forKey: "folder") {
            folder = URL(fileURLWithPath: path, isDirectory: true)
        }
        outline.show(region)
    }

    private func saveRegion() {
        UserDefaults.standard.set(try? JSONEncoder().encode(region), forKey: "region")
    }

    func selectRegion() {
        let previousApp = NSWorkspace.shared.frontmostApplication
        let panels = NSApp.windows.filter { $0 is FloatingPanel && $0.isVisible }
        panels.forEach { $0.orderOut(nil) }
        outline.hide()
        selector.begin { [weak self] picked in
            guard let self else { return }
            if let picked {
                self.region = picked
                self.status = "Region selected."
            } else {
                self.outline.show(self.region)
            }
            panels.forEach { $0.orderFrontRegardless() }
            // Give focus back to the app you were selecting in, usually Chrome.
            if let previousApp, previousApp != NSRunningApplication.current {
                previousApp.activate()
            }
        }
    }

    func clearRegion() {
        region = nil
        status = "Region cleared."
    }

    func chooseFolder() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            folder = url
            status = "Next page will be \(fileName(for: nextPageNumber()))."
        }
    }

    /// One more than the highest page number already in the folder.
    func nextPageNumber() -> Int {
        guard let folder,
              let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else { return 1 }
        let numbers = names.compactMap { name -> Int? in
            guard name.hasPrefix("page-"), name.hasSuffix(".png") else { return nil }
            return Int(name.dropFirst(5).dropLast(4))
        }
        return (numbers.max() ?? 0) + 1
    }

    func fileName(for number: Int) -> String {
        String(format: "page-%04d.png", number)
    }

    func captureOne() async {
        guard let region, let folder else { return }
        busy = true
        defer { busy = false }
        do {
            let image = try await Capturer.capture(region)
            let name = fileName(for: nextPageNumber())
            try Capturer.writePNG(image, to: folder.appendingPathComponent(name))
            status = "Saved \(name), \(image.width) by \(image.height) pixels."
        } catch {
            status = "Capture failed: \(error.localizedDescription)"
        }
    }
}
