const std = @import("std");

pub const screen_width = 256;
pub const screen_height = 240;

const Button = enum(u32) {
    a = 0,
    b = 1,
    select = 2,
    start = 3,
    up = 4,
    down = 5,
    left = 6,
    right = 7,
};

pub const Nes = extern struct {
    frame_count: u64,
    buttons: [2]u8,
    framebuffer: [screen_width * screen_height]u32,
};

var singleton: Nes = .{
    .frame_count = 0,
    .buttons = .{ 0, 0 },
    .framebuffer = [_]u32{0xff101018} ** (screen_width * screen_height),
};

pub export fn zico_nes_create() ?*Nes {
    singleton = .{
        .frame_count = 0,
        .buttons = .{ 0, 0 },
        .framebuffer = [_]u32{0xff101018} ** (screen_width * screen_height),
    };
    return &singleton;
}

pub export fn zico_nes_destroy(nes: ?*Nes) void {
    _ = nes;
}

pub export fn zico_nes_load_rom(nes: ?*Nes, data: ?[*]const u8, len: usize) bool {
    _ = nes;
    return data != null and len > 0;
}

pub export fn zico_nes_step_frame(nes: ?*Nes) void {
    const state = nes orelse return;
    state.frame_count +%= 1;

    for (&state.framebuffer, 0..) |*pixel, index| {
        const x: u32 = @intCast(index % screen_width);
        const y: u32 = @intCast(index / screen_width);
        const t: u32 = @truncate(state.frame_count);
        const pressed = state.buttons[0] != 0;

        const r = (x + t) & 0xff;
        const g = (y * 2 + t) & 0xff;
        const b = if (pressed) @as(u32, 0x40) else ((x ^ y ^ t) & 0xff);
        pixel.* = 0xff000000 | (r << 16) | (g << 8) | b;
    }
}

pub export fn zico_nes_framebuffer(nes: ?*const Nes) ?[*]const u32 {
    const state = nes orelse return null;
    return &state.framebuffer;
}

pub export fn zico_nes_set_button(nes: ?*Nes, player: u32, button: u32, pressed: bool) void {
    if (player >= 2 or button > @intFromEnum(Button.right)) return;

    const state = nes orelse return;
    const mask: u8 = @as(u8, 1) << @intCast(button);
    if (pressed) {
        state.buttons[player] |= mask;
    } else {
        state.buttons[player] &= ~mask;
    }
}

test "framebuffer changes after stepping" {
    const nes = zico_nes_create().?;
    const before = nes.framebuffer[0];
    zico_nes_step_frame(nes);
    try std.testing.expect(nes.framebuffer[0] != before);
}
