// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EarbarApp",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "EarbarApp",
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
