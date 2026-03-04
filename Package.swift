// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SystemPulse",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SystemPulse",
            path: "SystemPulse"
        )
    ]
)
