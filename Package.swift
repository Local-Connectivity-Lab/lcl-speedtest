// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lcl-speedtest",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.14.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "LCLSpeedTest",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "WebSocketKit", package: "websocket-kit")
            ]
        ),
    ]
)
