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

        // 🍎 APNS for Sending Remote and PkPush Notifications
        .package(url: "https://github.com/jeffctown/APNS.git", .upToNextMajor(from: "1.0.0")),
        
        // 🤖 Xcode Releases Data (fork)
        .package(url: "https://github.com/jeffctown/data.git", .branch("master"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "APNSVapor", "XCModel"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

