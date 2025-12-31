// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RetroSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "RetroSwift",
            targets: ["RetroSwift"]),
    ],
    targets: [
        .target(
            name: "RetroSwift",
            path: "RetroSwift"),
        .testTarget(
            name: "RetroSwiftTests",
            dependencies: ["RetroSwift"],
            path: "RetroSwiftTests")
    ]
)
