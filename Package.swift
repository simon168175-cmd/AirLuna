// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "AirLunaHeadControl",
  platforms: [
    .iOS(.v15),
    .macOS(.v13)
  ],
  products: [
    .library(name: "AirLunaCore", targets: ["AirLunaCore"]),
    .executable(name: "AirLunaCoreSelfCheck", targets: ["AirLunaCoreSelfCheck"])
  ],
  targets: [
    .target(
      name: "AirLunaCore",
      path: "Shared"
    ),
    .executableTarget(
      name: "AirLunaCoreSelfCheck",
      dependencies: ["AirLunaCore"],
      path: "Tools/SelfCheck"
    ),
    .testTarget(
      name: "AirLunaCoreTests",
      dependencies: ["AirLunaCore"],
      path: "Tests/AirLunaCoreTests"
    )
  ]
)
