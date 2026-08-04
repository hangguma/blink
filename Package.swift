// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Blink",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BlinkCore"),
        .executableTarget(
            name: "Blink",
            dependencies: ["BlinkCore"]
        ),
        .testTarget(
            name: "BlinkCoreTests",
            dependencies: ["BlinkCore"]
        ),
    ]
)
