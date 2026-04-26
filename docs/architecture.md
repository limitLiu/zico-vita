# Zico Vita Architecture

The project is split into a C++ application host and a Zig NES core.

## Layers

```text
app/vita/main.cpp
  PS Vita application entry point.
  This is where Borealis should be initialized.

include/zico_nes.h
  Stable C ABI between the C++ host and Zig core.

src/nes/api.zig
  Zig implementation behind the C ABI.
  Replace the placeholder implementation with the real NES core.

src/host/main.zig
  Native development host for `zig build run`.
  This runs on the current machine and should stay independent from Vita SDK.
```

## Borealis Integration

Borealis should stay on the C++ side. It owns the app lifecycle, UI tree,
input routing, layout, animation, and rendering.

The Zig NES core should not include Borealis, Yoga, Vita SDK, or graphics
headers. Keep it portable by only accepting ROM bytes, controller state, and
returning video/audio output.

Recommended next step:

```text
app/vita/main.cpp
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
