// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "XcodeReleasesApi",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "XcodeReleasesApi", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "3.0.0")),
        
        // 🤖 Xcode Models Shared with Client
        .package(url: "https://github.com/jeffctown/XcodeReleasesKit.git", .upToNextMajor(from: "1.0.0")),

        // 🍎 APNS for Packaging up Requests
        .package(url: "https://github.com/jeffctown/APNS.git", .upToNextMajor(from: "1.0.0")),

        // 🔵 APNS Fluent Extensions
        .package(url: "https://github.com/jeffctown/APNSFluent.git", .upToNextMajor(from: "1.0.0")),

        // 💨 Reusable Vapor Components
        .package(url: "https://github.com/jeffctown/APNSVapor.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "APNS", "APNSFluent", "APNSVapor", "XcodeReleasesKit"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

