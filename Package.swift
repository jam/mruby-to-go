// swift-tools-version: 6.0
// Generated for mruby 3.3.0 (minimal profile) — do not edit by hand.
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
            url: "https://github.com/jam/mruby-to-go/releases/download/v3.3.0/mruby-minimal-3.3.0.artifactbundleindex",
            checksum: "44c7df17f704c4e7e73f68847be46458fcd4f9c7cfcae47594c0e24b78482825"
        ),
    ]
)
