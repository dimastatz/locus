// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Locus",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Locus", targets: ["Locus"])
    ],
    targets: [
        // Session, timer, password and shortcut logic. No AppKit, so it can be unit tested.
        .target(name: "LocusCore"),
        // Menu bar app: status item, Accessibility window control, exit guard, prompts.
        .executableTarget(name: "Locus", dependencies: ["LocusCore"]),
        .testTarget(name: "LocusCoreTests", dependencies: ["LocusCore"]),
    ],
    swiftLanguageModes: [.v5]
)
