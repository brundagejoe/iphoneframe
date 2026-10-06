// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "iPhoneFrame", platforms: [.macOS(.v13)],
    products: [.library(name: "IPhoneFrameCore", targets: ["IPhoneFrameCore"]),
               .executable(name: "iphoneframe", targets: ["iphoneframe"])],
    targets: [.target(name: "IPhoneFrameCore"),
              .executableTarget(name: "iphoneframe", dependencies: ["IPhoneFrameCore"]),
              .testTarget(name: "IPhoneFrameCoreTests", dependencies: ["IPhoneFrameCore"])])
