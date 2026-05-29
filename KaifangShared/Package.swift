// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KaifangShared",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "KaifangCore",
            targets: ["KaifangCore"]
        ),
        .library(
            name: "KaifangPresentation",
            targets: ["KaifangPresentation"]
        )
    ],
    targets: [
        .target(
            name: "KaifangCore",
            resources: [
                .process("KaifangModel.xcdatamodeld"),
                .copy("Resources/cedict_ts.u8"),
            ]
        ),
        .target(
            name: "KaifangPresentation",
            dependencies: ["KaifangCore"]
        ),
        .testTarget(
            name: "KaifangCoreTests",
            dependencies: ["KaifangCore"]
        ),
        .testTarget(
            name: "KaifangPresentationTests",
            dependencies: ["KaifangPresentation"]
        )
    ],
    swiftLanguageModes: [.v6]
)
