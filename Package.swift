// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PageCapture",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "PageCapture", path: "Sources/PageCapture")
    ]
)
