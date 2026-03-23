#!/bin/bash
set -e

CONFIG=${1:-minimal}
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Gembox to use per config
case "$CONFIG" in
  minimal)  GEMBOX="default-no-stdio" ;;
  *)        GEMBOX="default" ;;
esac

echo "Building mruby with ${CONFIG} configuration for Apple platforms..."

cd "$REPO_ROOT"
rm -rf build output
mkdir -p build output

# Build one platform using MRuby::CrossBuild so mruby handles the host mrbc
# separately from the cross-compiled library (avoids CC/CFLAGS bleed-through).
build_platform() {
    local NAME=$1   # e.g. ios-arm64
    local SDK=$2    # e.g. iphoneos
    local TARGET=$3 # e.g. arm64-apple-ios16.0

    echo "Building for ${NAME} (${TARGET})..."

    local SDK_PATH CC_PATH AR_PATH TMP_CONFIG
    SDK_PATH="$(xcrun --sdk "${SDK}" --show-sdk-path)"
    CC_PATH="$(xcrun --sdk "${SDK}" --find clang)"
    AR_PATH="$(xcrun --sdk "${SDK}" --find ar)"
    TMP_CONFIG="$(mktemp /tmp/mruby-XXXXX.rb)"

    /bin/cat > "$TMP_CONFIG" << RUBY
MRuby::CrossBuild.new("${NAME}") do |conf|
  toolchain :clang
  conf.gembox "${GEMBOX}"
  conf.cc do |cc|
    cc.command = "${CC_PATH}"
    cc.flags = ["-target ${TARGET}", "-isysroot ${SDK_PATH}", "-Os"]
    cc.defines << "MRB_USE_FLOAT32"
    cc.defines << "MRB_GC_TURN_OFF_GENERATIONAL"
  end
  conf.archiver do |ar|
    ar.command = "${AR_PATH}"
  end
  conf.linker do |linker|
    linker.command = "${CC_PATH}"
  end
  conf.disable_presym
end
RUBY

    cd "$REPO_ROOT/mruby"
    MRUBY_CONFIG="$TMP_CONFIG" make clean
    MRUBY_CONFIG="$TMP_CONFIG" make -j"$(sysctl -n hw.ncpu)"

    mkdir -p "$REPO_ROOT/build/${NAME}"
    cp "build/${NAME}/lib/libmruby.a" "$REPO_ROOT/build/${NAME}/"
    if [ ! -d "$REPO_ROOT/build/include" ]; then
        cp -r include "$REPO_ROOT/build/"
    fi

    rm "$TMP_CONFIG"
    cd "$REPO_ROOT"
}

build_platform "ios-arm64"               "iphoneos"          "arm64-apple-ios16.0"
build_platform "ios-simulator-arm64"     "iphonesimulator"   "arm64-apple-ios16.0-simulator"
build_platform "tvos-arm64"              "appletvos"         "arm64-apple-tvos16.0"
build_platform "tvos-simulator-arm64"    "appletvsimulator"  "arm64-apple-tvos16.0-simulator"
build_platform "xros-arm64"              "xros"              "arm64-apple-xros1.0"
build_platform "xros-simulator-arm64"    "xrsimulator"       "arm64-apple-xros1.0-simulator"
build_platform "macos-arm64"             "macosx"            "arm64-apple-macos13.0"
build_platform "macos-x86_64"            "macosx"            "x86_64-apple-macos13.0"

# macOS universal binary
echo "Creating macOS universal binary..."
mkdir -p build/macos-universal
lipo -create \
    build/macos-arm64/libmruby.a \
    build/macos-x86_64/libmruby.a \
    -output build/macos-universal/libmruby.a

# XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -library build/ios-arm64/libmruby.a              -headers build/include \
    -library build/ios-simulator-arm64/libmruby.a    -headers build/include \
    -library build/tvos-arm64/libmruby.a             -headers build/include \
    -library build/tvos-simulator-arm64/libmruby.a   -headers build/include \
    -library build/xros-arm64/libmruby.a             -headers build/include \
    -library build/xros-simulator-arm64/libmruby.a   -headers build/include \
    -library build/macos-universal/libmruby.a        -headers build/include \
    -output "output/mruby-${CONFIG}.xcframework"

cd output
zip -r "mruby-${CONFIG}.xcframework.zip" "mruby-${CONFIG}.xcframework"
cd ..

echo "Build complete! output/mruby-${CONFIG}.xcframework.zip"
