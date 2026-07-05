// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SymLinker",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SymLinker",
            path: "Sources"
        )
    ]
)
