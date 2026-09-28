// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Packages",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Localization", targets: ["Localization"]),
        .library(name: "GitWorktreeServiceClient", targets: ["GitWorktreeServiceClient"]),
        .library(name: "GitWorktreeServiceLive", targets: ["GitWorktreeServiceLive"]),
        .library(name: "UserDefaultsClient", targets: ["UserDefaultsClient"]),
        .library(name: "UserDefaultsLive", targets: ["UserDefaultsLive"]),
        .library(name: "WorktreeFeature", targets: ["WorktreeFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
    ],
    targets: [
        .target(name: "Models"),

        .target(name: "Localization"),

        // IF-only: the DependencyKey/DependencyValues wiring, no `git` process access.
        .target(
            name: "GitWorktreeServiceClient",
            dependencies: [
                "Models",
                "Localization",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies")
            ]
        ),

        // Live implementation (shells out to `git`). Not imported directly by WorktreeFeature
        // source files, but must still be listed as a target dependency below so its
        // `liveValue` conformance gets linked.
        .target(
            name: "GitWorktreeServiceLive",
            dependencies: [
                "GitWorktreeServiceClient",
                "Models",
                "Localization",
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),

        // IF-only: the DependencyKey/DependencyValues wiring, no concrete UserDefaults access.
        .target(
            name: "UserDefaultsClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies")
            ]
        ),

        // Live implementation. Not imported directly by WorktreeFeature source files, but must
        // still be listed as a target dependency below so its `liveValue` conformance gets linked.
        .target(
            name: "UserDefaultsLive",
            dependencies: [
                "UserDefaultsClient",
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),

        .target(
            name: "WorktreeFeature",
            dependencies: [
                "Models",
                "Localization",
                "GitWorktreeServiceClient",
                "GitWorktreeServiceLive",
                "UserDefaultsClient",
                "UserDefaultsLive",
                .product(name: "Dependencies", package: "swift-dependencies")
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        .testTarget(name: "ModelsTests", dependencies: ["Models"]),
        .testTarget(
            name: "GitWorktreeServiceLiveTests",
            dependencies: ["GitWorktreeServiceLive", "Models"]
        )
    ]
)
