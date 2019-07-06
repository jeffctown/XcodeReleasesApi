// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "XcodeReleasesApi",
    products: [
        .library(name: "XcodeReleasesApi", targets: ["App"]),
        .library(name: "XcodeReleasesApiModel", targets: ["XcodeReleasesApiModel"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
        .package(url: "git@github.com:jeffctown/XcodeReleasesKit.git", .branch("master"))
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor", "JWT", "XcodeReleasesKit", "XcodeReleasesApiModel"]),
        .target(name: "Run", dependencies: ["App"]),
        .target(name: "XcodeReleasesApiModel", dependencies: []),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

