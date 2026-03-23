#!/bin/bash
set -e

CONFIG=${1:-minimal}
VERSION=${2:-3.3.0}
ARCH=${3:-$(uname -m)}

echo "Building mruby ${VERSION} with ${CONFIG} configuration for Linux ${ARCH}..."

rm -rf build-linux output-linux
mkdir -p output-linux

if [ ! -d "mruby-${VERSION}" ]; then
    echo "Downloading mruby ${VERSION}..."
    curl -L "https://github.com/mruby/mruby/archive/refs/tags/${VERSION}.tar.gz" -o mruby.tar.gz
    tar -xzf mruby.tar.gz
    rm mruby.tar.gz
fi

cd "mruby-${VERSION}"

export MRUBY_CONFIG="../build-configs/${CONFIG}.rb"
export CC="gcc"
export AR="ar"
export LD="gcc"

make clean
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

mkdir -p "../output-linux/linux-${ARCH}"
cp build/host/lib/libmruby.a "../output-linux/linux-${ARCH}/"
cp -r include "../output-linux/linux-${ARCH}/"

cd ..

cd output-linux
tar -czf "mruby-${CONFIG}-linux-${ARCH}.tar.gz" "linux-${ARCH}"
cd ..

echo "Build complete! Archive at: output-linux/mruby-${CONFIG}-linux-${ARCH}.tar.gz"
