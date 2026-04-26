# Borealis

The project uses Borealis as the C++ GUI host. Zig stays behind the C ABI in
`include/zico_nes.h`, so the NES core can be linked by both the macOS desktop
host and the PS Vita host.

## Build macOS OpenGL Borealis

Use this for local GUI/core iteration:

```sh
scripts/build-borealis-opengl.sh
zig build run
```

The script clones `xfangfang/borealis` to `vendor/borealis` if needed and
builds:

```sh
cmake -DPLATFORM_DESKTOP=ON -DUSE_GLFW=ON
```

Its default output is:

```text
vendor/borealis/build-macos-opengl
```

## Build Vita GXM Borealis

Use this for device artifacts:

```sh
scripts/build-borealis-gxm.sh
zig build vita
```

The script builds Borealis with:

```sh
cmake -DPLATFORM_PSV=ON -DUSE_GXM=ON
```

Its default output is:

```text
vendor/borealis/build-psv-gxm
```

## Override Paths

The defaults above are intended for normal use. Override paths only when using a
separate checkout/build directory:

```sh
zig build run \
  -Dborealis-dir=/path/to/borealis \
  -Dborealis-desktop-build-dir=/path/to/borealis/build-macos-opengl

zig build vita \
  -Dborealis-dir=/path/to/borealis \
  -Dborealis-vita-build-dir=/path/to/borealis/build-psv-gxm
```

## Tooling

Generate clangd/CLion flags for the desktop host:

```sh
zig build compdb-desktop
```

Generate flags for the Vita host:

```sh
zig build compdb-vita
```

Then open the repository root in the editor.
