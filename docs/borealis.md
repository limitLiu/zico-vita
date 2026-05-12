# Borealis

The project uses Borealis as the C++ GUI host. Zig stays behind the C ABI in
`include/zico_nes.h`, so the NES core can be linked by both the macOS desktop
host and the PS Vita host.

## Requirements

- Zig 0.16
- A macOS Borealis OpenGL build at `vendor/borealis/build-macos-opengl`
- A PS Vita Borealis GXM build at `vendor/borealis/build-psv-gxm`
- VitaSDK available through `VITASDK` when building Vita artifacts

The Vita C++ build expects the active GCC C++ include directory to be available
through a stable `version` symlink:

```sh
ln -s 15.2.0 "$VITASDK/arm-vita-eabi/include/c++/version"
```

The target-specific include directory should resolve through that symlink as
well:

```sh
test -d "$VITASDK/arm-vita-eabi/include/c++/version/arm-vita-eabi"
```

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

See [C++ Tooling](tooling.md) for `compile_commands.json`, clangd, and CLion
setup.
