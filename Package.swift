// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Aurora",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Aurora", targets: ["Aurora"])
    ],
    dependencies: [
        // Dependencies go here
    ],
    targets: [
        .executableTarget(
            name: "Aurora",
            dependencies: [],
            path: "Aurora"
        )
    ]
)
