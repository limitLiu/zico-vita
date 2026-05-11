# C++ Tooling

The Vita C++ host is compiled from `build.zig` with `arm-vita-eabi-g++`, so
editors do not automatically know the include paths or target flags.

## Native Run

Use the desktop Borealis host when iterating on GUI code and portable Zig NES
core code from macOS:

```sh
zig build run
```

This does not build or package a VPK. It compiles `gui/desktop/main.cc` and
links it with the Zig NES module and the macOS OpenGL Borealis build.

To compile the desktop GUI without launching the window:

```sh
zig build desktop
```

Use the Vita build when producing device artifacts:

```sh
zig build vita
```

Generate a local compilation database before opening the project in clangd or
CLion:

Use `zig build compdb-desktop` for `gui/desktop/main.cc`, or
`zig build compdb-vita` for `gui/vita/main.cc`. The shorthand
`zig build compdb` currently means desktop.

This writes `compile_commands.json` at the repository root. The file is ignored
by git because it contains machine-local absolute paths.

## Neovim clangd

Open Neovim from the repository root after generating `compile_commands.json`.
clangd should pick it up automatically.

To verify the desktop database manually:

```sh
clangd --check=gui/desktop/main.cc
```

For Vita, generate `zig build compdb-vita` with `VITASDK` set, then check
`gui/vita/main.cc`.

## CLion

Use the generated `compile_commands.json` as the compilation database project,
or open the repository normally and make sure CLion detects the root compilation
database.

Regenerate the database after adding new C++ source files or changing include
paths.
