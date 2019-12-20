// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "XcodeReleasesApi",
    products: [
        .library(name: "XcodeReleasesApi", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "3.0.0")),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", .upToNextMajor(from: "3.0.0")),
        
        // 🤖 Xcode Models Shared with Client
        .package(url: "https://github.com/jeffctown/XcodeReleasesKit.git", .branch("master")),
        
        // 🍎 APNS for Packaging up Requests
        .package(url: "https://github.com/jeffctown/apns.git", .branch("master")),

        // 💨 Reusable Vapor Components
        .package(url: "https://github.com/jeffctown/VaporAPNS.git", .branch("master"))
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor", "APNS", "VaporAPNS", "XcodeReleasesKit"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

