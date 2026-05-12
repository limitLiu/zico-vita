# Zico Vita Architecture

The project is split into a C++ application host and a Zig NES core.

## Layers

```text
gui/main.cc, gui/app.cc
  Shared Borealis C++ application entry point and app shell.
  The same sources are compiled for macOS and PS Vita with target-specific
  compiler flags from build.zig.

gui/config.cc
  Platform-specific configuration paths behind the shared C++ host layer.

include/zico_nes.h
  Stable C ABI between the C++ host and Zig core.

src/nes/api.zig
  Zig implementation behind the C ABI.
  Replace the placeholder implementation with the real NES core.
```

## Borealis Integration

Borealis should stay on the C++ side. It owns the app lifecycle, UI tree,
input routing, layout, animation, and rendering.

The Zig NES core should not include Borealis, Yoga, Vita SDK, or graphics
headers. Keep it portable by only accepting ROM bytes, controller state, and
returning video/audio output.

Recommended next step:

```text
gui/app.cc
  initialize brls::Application
  mount/copy Borealis resources
  install a custom NES view

NES view
  calls zico_nes_step_frame()
  reads zico_nes_framebuffer()
  draws the 256x240 framebuffer into the view bounds
```

Yoga is already used internally by Borealis, so the NES core should not depend
on Yoga directly. The custom Borealis view only needs to use the bounds computed
by Borealis/Yoga and scale the NES framebuffer into that rectangle.
