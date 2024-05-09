// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TileRepository",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TileRepository",
            targets: ["TileRepository"])
    ],
    dependencies: [
        .package(name: "DataSourceDefinition", path: "../DataSourceDefinition"),
        .package(name: "UIImageExtensions", path: "../UIImageExtensions"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TileRepository",
            dependencies: ["DataSourceDefinition", "UIImageExtensions", "Kingfisher"]),
        .testTarget(
            name: "TileRepositoryTests",
            dependencies: ["TileRepository"])
    ]
)
