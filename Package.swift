
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "VimeoNetworking",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "VimeoNetworking",
            targets: ["VimeoNetworking"]),
    ],
    targets: [
        .binaryTarget(
            name: "VimeoNetworking",
            url: "https://github.com/meech-ward/VimeoNetworking/releases/download/5.1.0-package/VimeoNetworking.xcframework.zip",
            checksum: "877d039716953845c60e3a2645c3532fbe8a2de951342d4dde891a214123c126"
        )
    ]
)