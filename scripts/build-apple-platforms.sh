#!/bin/bash
set -e

# NOTE: This script is untested and will likely need fixes!
# The mruby build system is complex and this is a first attempt.

CONFIG=${1:-minimal}
VERSION=${2:-3.3.0}

echo "Building mruby ${VERSION} with ${CONFIG} configuration for Apple platforms..."

rm -rf build output
mkdir -p output

if [ ! -d "mruby-${VERSION}" ]; then
    echo "Downloading mruby ${VERSION}..."
    curl -L "https://github.com/mruby/mruby/archive/refs/tags/${VERSION}.tar.gz" -o mruby.tar.gz
    tar -xzf mruby.tar.gz
    rm mruby.tar.gz
fi

cd "mruby-${VERSION}"

build_platform() {
    local PLATFORM=$1
    local SDK=$2
    local ARCH=$3
    local MIN_VERSION=$4

    echo "Building for ${PLATFORM} (${ARCH})..."

    export MRUBY_CONFIG="../build-configs/${CONFIG}.rb"
    export CC="$(xcrun --sdk ${SDK} --find clang)"
    export AR="$(xcrun --sdk ${SDK} --find ar)"
    export LD="$CC"
    export CFLAGS="-arch ${ARCH} -isysroot $(xcrun --sdk ${SDK} --show-sdk-path) -m${PLATFORM}-version-min=${MIN_VERSION}"

    make clean
    make -j$(sysctl -n hw.ncpu)

    mkdir -p "../build/${PLATFORM}-${ARCH}"
    cp build/host/lib/libmruby.a "../build/${PLATFORM}-${ARCH}/"
    if [ ! -d "../build/include" ]; then
        cp -r include "../build/"
    fi
}

# Build for each platform
build_platform "ios" "iphoneos" "arm64" "16.0"
build_platform "ios-simulator" "iphonesimulator" "arm64" "16.0"
build_platform "tvos" "appletvos" "arm64" "16.0"
build_platform "tvos-simulator" "appletvsimulator" "arm64" "16.0"
build_platform "xros" "xros" "arm64" "1.0"
build_platform "xros-simulator" "xrsimulator" "arm64" "1.0"

# Build macOS universal binary
echo "Building macOS universal binary..."
export MRUBY_CONFIG="../build-configs/${CONFIG}.rb"
make clean

export CC="clang"
export AR="ar"
export CFLAGS="-arch arm64 -mmacosx-version-min=13.0"
make -j$(sysctl -n hw.ncpu)
mkdir -p "../build/macos-arm64"
cp build/host/lib/libmruby.a "../build/macos-arm64/"

make clean
export CFLAGS="-arch x86_64 -mmacosx-version-min=13.0"
make -j$(sysctl -n hw.ncpu)
mkdir -p "../build/macos-x86_64"
cp build/host/lib/libmruby.a "../build/macos-x86_64/"

mkdir -p "../build/macos-universal"
lipo -create \
    "../build/macos-arm64/libmruby.a" \
    "../build/macos-x86_64/libmruby.a" \
    -output "../build/macos-universal/libmruby.a"

cd ..

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -library "build/ios-arm64/libmruby.a" -headers "build/include" \
    -library "build/ios-simulator-arm64/libmruby.a" -headers "build/include" \
    -library "build/tvos-arm64/libmruby.a" -headers "build/include" \
    -library "build/tvos-simulator-arm64/libmruby.a" -headers "build/include" \
    -library "build/xros-arm64/libmruby.a" -headers "build/include" \
    -library "build/xros-simulator-arm64/libmruby.a" -headers "build/include" \
    -library "build/macos-universal/libmruby.a" -headers "build/include" \
    -output "output/mruby-${CONFIG}.xcframework"

cd output
zip -r "mruby-${CONFIG}-apple.xcframework.zip" "mruby-${CONFIG}.xcframework"
cd ..

echo "Build complete! XCFramework at: output/mruby-${CONFIG}-apple.xcframework.zip"
