#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BOREALIS_DIR="${BOREALIS_DIR:-$ROOT_DIR/vendor/borealis}"
BOREALIS_BUILD_DIR="${BOREALIS_BUILD_DIR:-$BOREALIS_DIR/build-macos-opengl}"

if [ ! -d "$BOREALIS_DIR/.git" ]; then
    git clone --depth 1 --recurse-submodules https://github.com/xfangfang/borealis.git "$BOREALIS_DIR"
else
    git -C "$BOREALIS_DIR" submodule update --init --recursive
fi

cmake -S "$BOREALIS_DIR" -B "$BOREALIS_BUILD_DIR" \
    -DPLATFORM_DESKTOP=ON \
    -DUSE_GLFW=ON \
    -DBRLS_RESOURCES_DIR="$BOREALIS_DIR" \
    -DBRLS_UNITY_BUILD=ON \
    -DCMAKE_BUILD_TYPE=Release

cmake --build "$BOREALIS_BUILD_DIR" --target borealis --parallel
