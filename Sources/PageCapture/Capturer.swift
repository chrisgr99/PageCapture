import Foundation
import ScreenCaptureKit
import ImageIO
import UniformTypeIdentifiers

enum CaptureError: LocalizedError {
    case displayNotFound
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .displayNotFound: return "The display for this region is not connected. Select the region again."
        case .writeFailed(let name): return "Could not write \(name)."
        }
    }
}

enum Capturer {
    /// Captures the region at full pixel resolution. This app's own windows are left out.
    static func capture(_ region: Region) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == region.displayID }) else {
            throw CaptureError.displayNotFound
        }
        let ownApp = content.applications.filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
        let filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])
        let scale = CGFloat(filter.pointPixelScale)

        let config = SCStreamConfiguration()
        config.sourceRect = region.rect
        config.width = Int((region.rect.width * scale).rounded())
        config.height = Int((region.rect.height * scale).rounded())
        config.captureResolution = .best
        config.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CaptureError.writeFailed(url.lastPathComponent)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw CaptureError.writeFailed(url.lastPathComponent) }
    }
}
