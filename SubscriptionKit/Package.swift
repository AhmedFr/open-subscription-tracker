// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SubscriptionKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SubscriptionKit", targets: ["SubscriptionKit"])
    ],
    targets: [
        .target(name: "SubscriptionKit"),
        .testTarget(name: "SubscriptionKitTests", dependencies: ["SubscriptionKit"])
    ]
)
