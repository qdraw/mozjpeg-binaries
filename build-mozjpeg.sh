#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------
# Arguments
# -----------------------------
# Usage:
#   ./build-mozjpeg.sh <os> <arch> [workspace]
#
# Examples:
#   ./build-mozjpeg.sh linux x86_64
#   ./build-mozjpeg.sh linux aarch64
#   ./build-mozjpeg.sh macos arm64 /custom/workspace

OS="${1:?os required (linux|macos)}"
ARCH="${2:?arch required (x86_64|aarch64|arm64)}"
WORKSPACE="${3:-$(pwd)}"
OUT_DIR="$WORKSPACE/out/$OS-$ARCH"

# -----------------------------
# Paths
# -----------------------------
cd "$WORKSPACE"

SRC_ZIP="mozjpeg-master.zip"
SRC_DIR="mozjpeg-master"

# -----------------------------
# Fetch source
# -----------------------------
rm -rf "$SRC_ZIP" "$SRC_DIR"

wget https://codeload.github.com/mozilla/mozjpeg/zip/master -O "$SRC_ZIP"
unzip "$SRC_ZIP"
cd "$SRC_DIR"

mkdir -p build
cd build

# -----------------------------
# Parallelism
# -----------------------------
if command -v nproc >/dev/null 2>&1; then
  JOBS="$(nproc)"
else
  JOBS="$(sysctl -n hw.ncpu)"
fi

# -----------------------------
# CMake command
# -----------------------------
declare -a CMAKE_CMD=(
  cmake ..
  -G "Unix Makefiles"
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_SHARED_LIBS=OFF
  -DENABLE_SHARED=FALSE
  -DPNG_SUPPORTED=OFF
  -DWITH_JPEG8=ON
  -DCMAKE_INSTALL_PREFIX="$(pwd)/install"
)

# -----------------------------
# Cross-compilation (Linux ARM)
# -----------------------------
if [[ "$OS" == "linux" && "$ARCH" == "aarch64" ]]; then
  CMAKE_CMD+=(
    -DCMAKE_SYSTEM_NAME=Linux
    -DCMAKE_SYSTEM_PROCESSOR=aarch64
    -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc
    -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++
  )
elif [[ "$OS" == "linux" && "$ARCH" == "armhf" ]]; then
  CMAKE_CMD+=(
    -DCMAKE_SYSTEM_NAME=Linux
    -DCMAKE_SYSTEM_PROCESSOR=armv7l
    -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc
    -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++
  )
fi

# -----------------------------
# Build
# -----------------------------
"${CMAKE_CMD[@]}"
make -j"$JOBS" cjpeg-static

mkdir -p "$OUT_DIR"

if [[ ! -x "./cjpeg-static" ]]; then
  echo "error: cjpeg-static was not produced"
  ls -lah
  exit 1
fi

cp -f "./cjpeg-static" "$OUT_DIR/cjpeg"
chmod +x "$OUT_DIR/cjpeg"

cp "$OUT_DIR/cjpeg" "$OUT_DIR/mozjpeg"

# -----------------------------
# Diagnostics
# -----------------------------
echo "done"
echo "pwd"
pwd
echo "ls"
ls -lah
echo "artifact"
echo "output: " "$OUT_DIR/mozjpeg"

if [[ "$OS" == "macos" ]]; then
  echo "otool -L $OUT_DIR/cjpeg"
  otool -L "$OUT_DIR/cjpeg"
  
  echo "otool -L $OUT_DIR/mozjpeg"
  otool -L "$OUT_DIR/mozjpeg"
fi

