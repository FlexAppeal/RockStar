// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "Rockstar",
    products: [
        .library(
            name: "Rockstar",
            targets: ["Rockstar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.9.1"),
    ],
    targets: [
        .target(
            name: "Rockstar",
            dependencies: []),
        .target(
            name: "RockstarCrypto",
            dependencies: ["Rockstar"]),
        .testTarget(
            name: "RockstarTests",
            dependencies: ["Rockstar"]),
    ]
)

#if os(Linux)
    package.targets.append(
        .target(
            name: "RockstarNIO",
            dependencies: ["NIO", "Rockstar"]
        )
    )
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.2.0")
    )
    package.products.append(
        .library(
            name: "RockstarNIO",
            targets: ["RockstarNIO", "NIOOpenSSL"]
        )
    )
#endif

#if os(macOS) || os(iOS)
    package.targets.append(
        .target(
            name: "RockstarApple",
            dependencies: ["Rockstar"]
        )
    )
    package.products.append(
        .library(
            name: "RockstarNIO",
            targets: ["RockstarNIO"]
        )
    )
    package.products.append(
        .library(
            name: "RockstarApple",
            targets: ["RockstarApple"]
        )
    )
#endif

#if os(macOS)
    package.targets.append(
        .target(
            name: "RockstarAppKit",
            dependencies: ["Rockstar", "RockstarApple"]
        )
    )
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.2.0")
    )
    package.products.append(
        .library(
            name: "RockstarAppKit",
            targets: ["RockstarAppKit"]
        )
    )

    var NIOdeps: [Target.Dependency] = ["NIO", "Rockstar", "NIOOpenSSL"]
        
    if #available(iOS 12.0, *) {
        package.dependencies.append(
            .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "0.2.0")
        )
        NIOdeps.append("NIOTransportServices")
    }

    if #available(macOS 10.14, *) {
        package.dependencies.append(
            .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "0.2.0")
        )
        NIOdeps.append("NIOTransportServices")
    }

    package.targets.append(
        .target(
            name: "RockstarNIO",
            dependencies: NIOdeps
        )
    )
    package.targets.append(
        .target(
            name: "RockstarUIKit",
            dependencies: ["Rockstar", "RockstarApple"]
        )
    )
    package.products.append(
        .library(
            name: "RockstarUIKit",
            targets: ["RockstarUIKit"]
        )
    )

    /// Texture when it has a package.swift
#endif
