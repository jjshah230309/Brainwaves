// swift-tools-version:5.10
import PackageDescription

var targets: [Target] = [
    .target(
        name: "BrainwavesCore",
        path: "Sources/BrainwavesCore"
    ),
    .executableTarget(
        name: "bwrender",
        dependencies: ["BrainwavesCore"],
        path: "Sources/bwrender"
    ),
    .testTarget(
        name: "BrainwavesCoreTests",
        dependencies: ["BrainwavesCore"],
        path: "Tests/BrainwavesCoreTests"
    ),
]

var products: [Product] = [
    .library(name: "BrainwavesCore", targets: ["BrainwavesCore"]),
    .executable(name: "bwrender", targets: ["bwrender"]),
]

// The SwiftUI app only exists on macOS. On Linux (CI) the package still builds
// and tests the portable core and the offline renderer.
#if os(macOS)
targets.append(
    .executableTarget(
        name: "BrainwavesApp",
        dependencies: ["BrainwavesCore"],
        path: "Sources/BrainwavesApp"
    )
)
products.append(.executable(name: "BrainwavesApp", targets: ["BrainwavesApp"]))
#endif

let package = Package(
    name: "Brainwaves",
    platforms: [.macOS(.v14)],
    products: products,
    targets: targets
)
