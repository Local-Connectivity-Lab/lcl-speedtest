// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lcl-speedtest",
    platforms: [
        .macOS(.v10_15), .iOS(.v14), .tvOS(.v13), .watchOS(.v6),
    ],
    products: [
        .library(name: "LCLSpeedtest", targets: ["LCLSpeedtest"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.81.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/Local-Connectivity-Lab/lcl-websocket.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "LCLSpeedtest",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "LCLWebSocket", package: "lcl-websocket"),
            ]
        ),
        .executableTarget(name: "Demo", dependencies: ["LCLSpeedtest"]),
    ]
)
