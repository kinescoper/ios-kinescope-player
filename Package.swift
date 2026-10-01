// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KinescopeSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "KinescopeSDK",
            type: .dynamic,
            targets: ["KinescopeSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Exact pins: M3U8Parser 1.2.0 renamed its SPM product to `M3U8Kit`, so ranges must not float.
        .package(url: "https://github.com/M3U8Kit/M3U8Parser.git", exact: "1.2.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.38.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "KinescopeSDK",
            dependencies: [
                .product(name: "M3U8Kit", package: "M3U8Parser"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Sources/KinescopeSDK",
            exclude: ["Info.plist"]),
        .testTarget(
            name: "KinescopeSDKTests",
            dependencies: [
                "KinescopeSDK"
            ],
            path: "Sources/KinescopeSDKTests",
            exclude: ["Info.plist"])
    ]
)
