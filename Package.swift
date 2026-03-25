// swift-tools-version: 6.0
// Generated for mruby 3.4.0 (minimal profile) — do not edit by hand.
// https://github.com/jam/mruby-to-go
import PackageDescription

let package = Package(
    name: "mruby",
    products: [
        .library(name: "mruby", targets: ["mruby"]),
    ],
    targets: [
        // Downloads only the slice needed for your build target (SE-0482).
        .binaryTarget(
            name: "mruby",
            url: "https://github.com/jam/mruby-to-go/releases/download/v3.4.0/mruby-minimal-3.4.0.artifactbundleindex",
            checksum: "06fc3565827c4e02b7d3f1d1b7765b3c6a85d299ccb5cd59e5503844972d5bb9"
        ),
    ]
)
