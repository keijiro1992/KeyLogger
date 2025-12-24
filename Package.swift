// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyLogger",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KeyLogger", targets: ["KeyLogger"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0")
    ],
    targets: [
        .executableTarget(
            name: "KeyLogger",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "KeyLogger"
        ),
        .testTarget(
            name: "KeyLoggerTests",
            dependencies: ["KeyLogger"],
            path: "KeyLoggerTests"
        )
    ]
)
