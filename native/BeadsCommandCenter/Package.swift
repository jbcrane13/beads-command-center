// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BeadsCommandCenter",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "BeadsCommandCenter", targets: ["BeadsCommandCenter"])
    ],
    targets: [
        .executableTarget(
            name: "BeadsCommandCenter",
            path: "Sources/BeadsCommandCenter"
        )
    ]
)
