# Zico Vita

Zico Vita is a Zig NES core experiment with a shared Borealis C++ GUI host for
macOS and PS Vita.

## Quick Commands

| Task | Command |
| --- | --- |
| Run the macOS desktop host | `zig build run` |
| Build the macOS desktop host | `zig build desktop` |
| Build Vita artifacts | `zig build vita` |
| Generate macOS `compile_commands.json` | `zig build compdb` |
| Generate Vita `compile_commands.json` | `zig build compdb-vita` |

## Documentation

- [Architecture](docs/architecture.md) describes the C++ host / Zig core split.
- [Borealis](docs/borealis.md) covers requirements, local Borealis builds, Vita
  SDK setup, and path overrides.
- [C++ Tooling](docs/tooling.md) covers `compile_commands.json`, clangd, and
  CLion setup.
