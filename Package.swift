// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HushCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HushCore", targets: ["HushCore"])
    ],
    targets: [
        .target(name: "HushCore"),
        .testTarget(name: "HushCoreTests", dependencies: ["HushCore"])
    ]
)
