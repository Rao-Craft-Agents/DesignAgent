// swift-tools-version:6.0
// DesignAgent: an app's design system as Swift (brand colours and the roles views read, gradients, spacing layers,
// radii, a type scale and fonts), written from compact lines, as a Granite agent package.
// An app that links it finds the `design` agent through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "DesignAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DesignAgent", targets: ["DesignAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "DesignAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "DesignAgentTests",
            dependencies: ["DesignAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
