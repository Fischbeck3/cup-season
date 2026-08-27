// swift-tools-version: 6.0
// Cup Season — domain + data for the phone (IOS-002 §1, §12). No SwiftUI in
// here: ViewModels and views live in the app target and depend on this.
import PackageDescription

let package = Package(
  name: "CupSeasonKit",
  platforms: [.iOS(.v17)],
  products: [.library(name: "CupSeasonKit", targets: ["CupSeasonKit"])],
  dependencies: [
    // The official SDK: OTP auth, Keychain session storage, PostgREST, Realtime v2, Storage.
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.55.1"),
  ],
  targets: [
    .target(
      name: "CupSeasonKit",
      dependencies: [.product(name: "Supabase", package: "supabase-swift")],
      path: "Sources/CupSeasonKit"
    ),
    .testTarget(name: "CupSeasonKitTests", dependencies: ["CupSeasonKit"], path: "Tests/CupSeasonKitTests"),
  ]
)
