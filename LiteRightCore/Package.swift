// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "LiteRightCore", platforms: [.macOS(.v15)], products: [.library(name: "LiteRightCore", targets: ["LiteRightCore"])], targets: [.target(name: "LiteRightCore"), .testTarget(name: "LiteRightCoreTests", dependencies: ["LiteRightCore"])])