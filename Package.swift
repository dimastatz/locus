// swift-tools-version:5.9
// 5.9 keeps the manifest compatible with older toolchains (Xcode 15, early Swift 6 Command Line
// Tools) and builds in the Swift 5 language mode without `swiftLanguageModes`, which they lack.
import PackageDescription

let package = Package(
    name: "Locus",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Locus", targets: ["Locus"])
    ],
    targets: [
        // Session, timer, hold-to-exit and shortcut logic. No AppKit, so it can be unit tested.
        .target(name: "LocusCore"),
        // Menu bar app: status item, Accessibility window control, exit guard, prompts.
        .executableTarget(name: "Locus", dependencies: ["LocusCore"]),
        .testTarget(name: "LocusCoreTests", dependencies: ["LocusCore"]),
    ]
)
