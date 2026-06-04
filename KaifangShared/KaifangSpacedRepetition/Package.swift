// swift-tools-version: 6.3
//
//  Package.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import PackageDescription

let package = Package(
    name: "KaifangSpacedRepetition",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KaifangSpacedRepetition", targets: ["KaifangSpacedRepetition"])
    ],
    targets: [
        .target(name: "KaifangSpacedRepetition"),
        .testTarget(
            name: "KaifangSpacedRepetitionTests",
            dependencies: ["KaifangSpacedRepetition"]
        )
    ],
    swiftLanguageModes: [.v6]
)
