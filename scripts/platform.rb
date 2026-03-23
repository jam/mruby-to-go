# Canonical platform definitions shared by all build and assembly scripts.

REPO_ROOT = File.expand_path('..', __dir__)

APPLE_PLATFORMS = [
  { name: "ios-arm64",             sdk: "iphoneos",         target: "arm64-apple-ios16.0",                triple: "arm64-apple-ios"             },
  { name: "ios-simulator-arm64",   sdk: "iphonesimulator",  target: "arm64-apple-ios16.0-simulator",      triple: "arm64-apple-ios-simulator"   },
  { name: "tvos-arm64",            sdk: "appletvos",        target: "arm64-apple-tvos16.0",               triple: "arm64-apple-tvos"            },
  { name: "tvos-simulator-arm64",  sdk: "appletvsimulator", target: "arm64-apple-tvos16.0-simulator",     triple: "arm64-apple-tvos-simulator"  },
  { name: "xros-arm64",            sdk: "xros",             target: "arm64-apple-xros1.0",                triple: "arm64-apple-xros"            },
  { name: "xros-simulator-arm64",  sdk: "xrsimulator",      target: "arm64-apple-xros1.0-simulator",      triple: "arm64-apple-xros-simulator"  },
  { name: "macos-arm64",           sdk: "macosx",           target: "arm64-apple-macos13.0",              triple: "arm64-apple-macosx"          },
  { name: "macos-x86_64",          sdk: "macosx",           target: "x86_64-apple-macos13.0",             triple: "x86_64-apple-macosx"         },
].freeze

LINUX_PLATFORMS = [
  { name: "linux-x86_64", arch: "amd64", triple: "x86_64-unknown-linux-gnu"   },
  { name: "linux-arm64",  arch: "arm64", triple: "aarch64-unknown-linux-gnu"  },
].freeze

ALL_PLATFORMS = (APPLE_PLATFORMS + LINUX_PLATFORMS).freeze
