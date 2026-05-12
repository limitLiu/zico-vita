# C++ Tooling

The shared Borealis C++ host is compiled from `build.zig` with different
toolchains:

- macOS uses `c++` with the OpenGL/GLFW Borealis build.
- PS Vita uses `arm-vita-eabi-g++` with the GXM Borealis build.

Editors do not automatically know those include paths or target flags.

## Native Run

Use the desktop Borealis host when iterating on GUI code and portable Zig NES
core code from macOS:

```sh
zig build run
```

This does not build or package a VPK. It compiles the shared `gui/*.cc` sources
and links them with the Zig NES module and the macOS OpenGL Borealis build.

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

Use `zig build compdb` for the default macOS database, or
`zig build compdb-vita` for the Vita database.

This writes `compile_commands.json` at the repository root. The file is ignored
by git because it contains machine-local absolute paths.

## Neovim clangd

Open Neovim from the repository root after generating `compile_commands.json`.
clangd should pick it up automatically.

To verify the desktop database manually:

```sh
clangd --check=gui/main.cc
```

For Vita, generate `zig build compdb-vita` with `VITASDK` set, then check
`gui/main.cc`.

## CLion

Use the generated `compile_commands.json` as the compilation database project,
or open the repository normally and make sure CLion detects the root compilation
database.

Regenerate the database after adding new C++ source files or changing include
paths.
