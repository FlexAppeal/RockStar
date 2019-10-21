// swift-tools-version:4.2
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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Rockstar",
            dependencies: ["NIO", "NIOTransportServices"]),
        .target(
            name: "RockstarCrypto",
            dependencies: ["Rockstar"]),
        .testTarget(
            name: "RockstarTests",
            dependencies: ["Rockstar"]),
    ]
)

package.targets.append(
    .target(
        name: "RockstarApple",
        dependencies: ["Rockstar"]
    )
)
package.products.append(
    .library(
        name: "RockstarApple",
        targets: ["RockstarApple"]
    )
)

package.targets.append(
    .target(
        name: "RockstarUIKit",
        dependencies: ["Rockstar", "RockstarApple"]
    )
)

/// Texture when it has a package.swift
