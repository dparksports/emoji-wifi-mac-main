// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmojiWifi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EmojiWifi", targets: ["EmojiWifi"])
    ],
    targets: [
        .executableTarget(
            name: "EmojiWifi",
            path: "Sources/EmojiWifi",
            resources: [
                .copy("single.csv"),
                .copy("combos.csv")
            ],
        )
    ]
)
