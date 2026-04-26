const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();

    _ = args.next() orelse return error.InvalidArguments;
    const mode = args.next() orelse return error.InvalidArguments;
    const root_dir = args.next() orelse return error.InvalidArguments;
    const borealis_dir = args.next() orelse return error.InvalidArguments;
    const desktop_build_dir = args.next() orelse return error.InvalidArguments;
    const vita_build_dir = args.next() orelse return error.InvalidArguments;
    const vitasdk = args.next() orelse return error.InvalidArguments;
    if (args.next() != null) return error.InvalidArguments;

    const path = try std.fs.path.join(allocator, &.{ root_dir, "compile_commands.json" });
    var file = try std.Io.Dir.createFileAbsolute(init.io, path, .{ .truncate = true });
    defer file.close(init.io);

    var buffer: [8192]u8 = undefined;
    var writer = file.writer(init.io, &buffer);
    const w = &writer.interface;

    if (std.mem.eql(u8, mode, "desktop")) {
        try writeDesktop(w, root_dir, borealis_dir, desktop_build_dir);
    } else if (std.mem.eql(u8, mode, "vita")) {
        if (vitasdk.len == 0) return error.MissingVitaSdk;
        try writeVita(w, root_dir, borealis_dir, vita_build_dir, vitasdk);
    } else {
        return error.InvalidMode;
    }

    try w.flush();
}

fn writeDesktop(w: *std.Io.Writer, root_dir: []const u8, borealis_dir: []const u8, build_dir: []const u8) !void {
    try w.print(
        \\[
        \\  {{
        \\    "directory": "{s}",
        \\    "file": "{s}/app/desktop/main.cpp",
        \\    "arguments": [
        \\      "c++",
        \\      "-std=c++17",
        \\      "-DZICO_DESKTOP",
        \\      "-D__GLFW__",
        \\      "-DBOREALIS_USE_OPENGL",
        \\      "-DBRLS_RESOURCES=\"{s}/resources/\"",
        \\      "-I{s}/include",
        \\      "-I{s}/library/include",
        \\      "-I{s}/library/include/borealis/extern",
        \\      "-I{s}/library/include/borealis/extern/nanovg",
        \\      "-I{s}/library/lib/extern/fmt/include",
        \\      "-I{s}/library/lib/extern/tweeny/include",
        \\      "-I{s}/library/lib/extern/glfw/include",
        \\      "-I{s}/library",
        \\      "-c",
        \\      "{s}/app/desktop/main.cpp"
        \\    ]
        \\  }}
        \\]
        \\
    , .{
        root_dir,
        root_dir,
        borealis_dir,
        root_dir,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        build_dir,
        root_dir,
    });
}

fn writeVita(w: *std.Io.Writer, root_dir: []const u8, borealis_dir: []const u8, build_dir: []const u8, vitasdk: []const u8) !void {
    try w.print(
        \\[
        \\  {{
        \\    "directory": "{s}",
        \\    "file": "{s}/app/vita/main.cpp",
        \\    "arguments": [
        \\      "{s}/bin/arm-vita-eabi-g++",
        \\      "-std=c++17",
        \\      "-D__vita__",
        \\      "-D__PSV__",
        \\      "-DBOREALIS_USE_GXM",
        \\      "-DBRLS_RESOURCES=\"app0:resources/\"",
        \\      "--target=arm-vita-eabi",
        \\      "-I{s}/include",
        \\      "-I{s}/arm-vita-eabi/include",
        \\      "-I{s}/share/gcc-arm-vita-eabi/samples/common",
        \\      "-isystem",
        \\      "{s}/arm-vita-eabi/include/c++/10.3.0",
        \\      "-isystem",
        \\      "{s}/arm-vita-eabi/include/c++/10.3.0/arm-vita-eabi",
        \\      "-I{s}/library/include",
        \\      "-I{s}/library/include/borealis/extern",
        \\      "-I{s}/library/include/borealis/extern/nanovg",
        \\      "-I{s}/library/lib/extern/fmt/include",
        \\      "-I{s}/library/lib/extern/tweeny/include",
        \\      "-I{s}/library",
        \\      "-c",
        \\      "{s}/app/vita/main.cpp"
        \\    ]
        \\  }}
        \\]
        \\
    , .{
        root_dir,
        root_dir,
        vitasdk,
        root_dir,
        vitasdk,
        vitasdk,
        vitasdk,
        vitasdk,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        borealis_dir,
        build_dir,
        root_dir,
    });
}
