// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "IslandDock",
  defaultLocalization: "en",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "IslandDock", targets: ["IslandDock"])
  ],
  targets: [
    .target(
      name: "IslandDockCore",
      path: "Sources/IslandDockCore",
      resources: [.process("Resources")]
    ),
    .executableTarget(
      name: "IslandDock",
      dependencies: ["IslandDockCore"],
      path: "Sources/IslandDock"
    ),
    .testTarget(
      name: "IslandDockTests",
      dependencies: ["IslandDockCore"],
      path: "Tests/IslandDockTests"
    ),
  ]
)
