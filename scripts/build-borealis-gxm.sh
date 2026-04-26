#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BOREALIS_DIR="${BOREALIS_DIR:-$ROOT_DIR/vendor/borealis}"
BOREALIS_BUILD_DIR="${BOREALIS_BUILD_DIR:-$BOREALIS_DIR/build-psv-gxm}"

if [ -z "${VITASDK:-}" ]; then
    echo "VITASDK is required" >&2
    exit 1
fi

if [ ! -d "$BOREALIS_DIR/.git" ]; then
    git clone --depth 1 --recurse-submodules https://github.com/xfangfang/borealis.git "$BOREALIS_DIR"
else
    git -C "$BOREALIS_DIR" submodule update --init --recursive
fi

cmake -S "$BOREALIS_DIR" -B "$BOREALIS_BUILD_DIR" \
    -DPLATFORM_PSV=ON \
    -DUSE_GXM=ON \
    -DBRLS_UNITY_BUILD=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5

cmake --build "$BOREALIS_BUILD_DIR" --target borealis --parallel
