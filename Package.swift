// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Maggo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Maggo", targets: ["Maggo"]),
        .library(name: "MaggoCore", targets: ["MaggoCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MaggoCore",
            dependencies: [],
            path: "Sources/MaggoCore"
        ),
        .executableTarget(
            name: "Maggo",
            dependencies: ["MaggoCore"],
            path: "Sources/MaggoApp"
        ),
        .testTarget(
            name: "MaggoTests",
            dependencies: ["MaggoCore"],
            path: "Tests/MaggoTests"
        )
    ]
)
