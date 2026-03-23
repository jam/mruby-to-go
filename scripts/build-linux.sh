#!/bin/bash
set -e

CONFIG=${1:-minimal}
ARCH=${2:-$(uname -m)}

echo "Building mruby with ${CONFIG} configuration for Linux ${ARCH}..."

rm -rf output-linux
mkdir -p output-linux

cd mruby

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
