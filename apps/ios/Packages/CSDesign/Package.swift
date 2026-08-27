// swift-tools-version: 6.0
// Cup Season — the design system (IOS-003). Generated tokens and markers
// live under Sources/CSDesign/Generated and are written by tools/build-*.mjs;
// preflight fails the push if they drift from packages/tokens and index.html.
import PackageDescription

let package = Package(
  name: "CSDesign",
  platforms: [.iOS(.v17)],
  products: [.library(name: "CSDesign", targets: ["CSDesign"])],
  targets: [
    .target(name: "CSDesign", path: "Sources/CSDesign"),
    .testTarget(name: "CSDesignTests", dependencies: ["CSDesign"], path: "Tests/CSDesignTests"),
  ]
)
