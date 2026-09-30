import CoreGraphics

/// A capture region: a rectangle in points, measured from the top-left
/// corner of one display.
struct Region: Codable, Equatable {
    var displayID: CGDirectDisplayID
    var rect: CGRect

    var summary: String {
        "\(Int(rect.width)) by \(Int(rect.height)) at \(Int(rect.minX)), \(Int(rect.minY))"
    }
}
