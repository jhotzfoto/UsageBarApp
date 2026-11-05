// swift-tools-version:5.9
import PackageDescription

// Pure logic shared by the app and its widgets, kept here so it can be tested with `swift test`
// against temporary data only (never the real data files).
let package = Package(
    name: "UsageCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "UsageCore", targets: ["UsageCore"])],
    targets: [
        .target(name: "UsageCore"),
        .testTarget(name: "UsageCoreTests", dependencies: ["UsageCore"]),
    ]
)
