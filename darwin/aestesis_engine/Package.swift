// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aestesis_engine",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
    ],
    products: [
        .library(name: "aestesis-engine", targets: ["aestesis_engine"])
    ],
    dependencies: [
        //.package(url: "https://github.com/aestesis/aestesis_alib.git", branch: "main"),
        .package(path: "/Users/renanyoy/git/aestesis_alib"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "aestesis_engine",
            dependencies: [
                "aestesis_alib",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            resources: [
                .process("shaders/default.metal"),
                .copy("assets/")
            ]
        )
    ]
)
