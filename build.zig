const std = @import("std");

const BorealisPaths = struct {
    source_dir: []const u8,
    vita_build_dir: []const u8,
    desktop_build_dir: []const u8,
};

const VitaArtifacts = struct {
    elf: std.Build.LazyPath,
    velf: std.Build.LazyPath,
    eboot: std.Build.LazyPath,
    sfo: std.Build.LazyPath,
    vpk: std.Build.LazyPath,
};

const CppSource = struct {
    path: []const u8,
    object_stem: []const u8,
};

const gui_cpp_sources = [_]CppSource{
    .{ .path = "gui/main.cc", .object_stem = "main" },
    .{ .path = "gui/app.cc", .object_stem = "app" },
    .{ .path = "gui/config.cc", .object_stem = "config" },
};

const macos_min_version = std.SemanticVersion{
    .major = 26,
    .minor = 0,
    .patch = 0,
};
const macos_min_version_arg = "-mmacosx-version-min=26.0";
const deprecated_literal_operator_warning_arg = "-Wno-deprecated-literal-operator";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const borealis = BorealisPaths{
        .source_dir = b.option([]const u8, "borealis-dir", "Path to xfangfang/borealis checkout") orelse b.pathFromRoot("vendor/borealis"),
        .vita_build_dir = b.option([]const u8, "borealis-vita-build-dir", "Path to Borealis PSV GXM CMake build directory") orelse b.pathFromRoot("vendor/borealis/build-psv-gxm"),
        .desktop_build_dir = b.option([]const u8, "borealis-desktop-build-dir", "Path to Borealis macOS OpenGL CMake build directory") orelse b.pathFromRoot("vendor/borealis/build-macos-opengl"),
    };

    addDesktopRunStep(b, optimize, borealis);
    if (b.graph.environ_map.get("VITASDK") != null) {
        addVitaStep(b, optimize, borealis);
    } else {
        addMissingVitaSdkStep(b);
    }
    addCompileCommandsSteps(b, optimize, borealis);
}

fn addDesktopRunStep(b: *std.Build, optimize: std.builtin.OptimizeMode, borealis: BorealisPaths) void {
    const target = b.resolveTargetQuery(.{
        .os_tag = .macos,
        .os_version_min = .{ .semver = macos_min_version },
    });
    const nes_obj = addNesObject(b, "zico_nes_desktop", target, optimize, null);

    const link = b.addSystemCommand(&.{"c++"});
    link.addArg(macos_min_version_arg);
    link.addArtifactArg(nes_obj);
    for (gui_cpp_sources) |source| {
        const object = addDesktopCppObject(b, borealis, source.path, b.fmt("desktop_{s}.o", .{source.object_stem}));
        link.addFileArg(object);
    }
    addBorealisCommonArchives(b, link, borealis.desktop_build_dir);
    link.addFileArg(.{ .cwd_relative = b.pathJoin(&.{ borealis.desktop_build_dir, "library/lib/extern/glfw/src/libglfw3.a" }) });
    addMacFramework(link, "OpenGL");
    addMacFramework(link, "Cocoa");
    addMacFramework(link, "IOKit");
    addMacFramework(link, "CoreFoundation");
    addMacFramework(link, "CoreGraphics");
    addMacFramework(link, "CoreServices");
    addMacFramework(link, "SystemConfiguration");
    addMacFramework(link, "AppKit");
    addMacFramework(link, "Foundation");
    addMacFramework(link, "CoreWLAN");
    link.addArg("-lobjc");
    const exe = link.addPrefixedOutputFileArg("-o", "zico_desktop");

    const desktop_step = b.step("desktop", "Build the macOS Borealis OpenGL desktop host");
    desktop_step.dependOn(&link.step);

    const run = b.addSystemCommand(&.{ "bash", "-c" });
    run.addArg("exe=\"$1\"; shift; exec \"$exe\" \"$@\"");
    run.addArg("zico_desktop");
    run.addFileArg(exe);
    if (b.args) |args| {
        run.addArgs(args);
    }

    const run_step = b.step("run", "Run the macOS Borealis OpenGL desktop host");
    run_step.dependOn(&run.step);
}

fn addDesktopCppObject(b: *std.Build, borealis: BorealisPaths, source_path: []const u8, object_name: []const u8) std.Build.LazyPath {
    const cmd = b.addSystemCommand(&.{"c++"});
    cmd.addArg("-std=c++20");
    cmd.addArg(macos_min_version_arg);
    cmd.addArg(deprecated_literal_operator_warning_arg);
    cmd.addArg("-D__darwin__");
    cmd.addArg("-D__GLFW__");
    cmd.addArg("-DBOREALIS_USE_OPENGL");
    cmd.addArg(b.fmt("-DBRLS_RESOURCES=\"{s}/resources/\"", .{borealis.source_dir}));
    addProjectIncludeArgs(b, cmd);
    addBorealisDesktopIncludeArgs(b, cmd, borealis);
    cmd.addArg("-c");
    cmd.addFileArg(b.path(source_path));
    return cmd.addPrefixedOutputFileArg("-o", object_name);
}

fn addVitaCppObject(
    b: *std.Build,
    borealis: BorealisPaths,
    vitasdk: []const u8,
    source_path: []const u8,
    object_name: []const u8,
    sdk_include_dir: []const u8,
    sdk_common_dir: []const u8,
    sdk_cxx_include_dir: []const u8,
    sdk_cxx_target_include_dir: []const u8,
) std.Build.LazyPath {
    const cmd = b.addSystemCommand(&.{toolPath(b, vitasdk, "bin/arm-vita-eabi-g++")});
    cmd.addArg("-std=c++20");
    cmd.addArg("-D__vita__");
    cmd.addArg("-DBOREALIS_USE_GXM");
    cmd.addArg("-DBRLS_RESOURCES=\"app0:resources/\"");
    addProjectIncludeArgs(b, cmd);
    addVitaSdkIncludeArgs(cmd, sdk_include_dir, sdk_common_dir, sdk_cxx_include_dir, sdk_cxx_target_include_dir);
    addBorealisVitaIncludeArgs(b, cmd, borealis);
    cmd.addArg("-c");
    cmd.addFileArg(b.path(source_path));
    return cmd.addPrefixedOutputFileArg("-o", object_name);
}

fn addVitaStep(b: *std.Build, optimize: std.builtin.OptimizeMode, borealis: BorealisPaths) void {
    const artifacts = addVitaBuild(b, optimize, borealis);
    const install_step = addVitaInstallStep(b, artifacts);
    const vita_step = b.step("vita", "Build PS Vita homebrew artifacts");
    vita_step.dependOn(install_step);
}

fn addMissingVitaSdkStep(b: *std.Build) void {
    const run = b.addSystemCommand(&.{ "sh", "-c", "echo 'VITASDK is required for zig build vita' >&2; exit 1" });
    const vita_step = b.step("vita", "Build PS Vita homebrew artifacts");
    vita_step.dependOn(&run.step);
}

fn addVitaBuild(b: *std.Build, optimize: std.builtin.OptimizeMode, borealis: BorealisPaths) VitaArtifacts {
    const vitasdk = vitaSdkPath(b);
    const title_id = b.option([]const u8, "vita-title-id", "PS Vita title id") orelse "ZICV00001";
    const app_name = b.option([]const u8, "vita-app-name", "PS Vita application name") orelse "Zico Vita";
    const version = b.option([]const u8, "vita-version", "PS Vita application version") orelse "01.00";

    if (title_id.len != 9) {
        std.debug.panic("vita title id must be exactly 9 characters, got '{s}'", .{title_id});
    }

    const sdk_common_dir = toolPath(b, vitasdk, "share/gcc-arm-vita-eabi/samples/common");
    const sdk_debugscreen_c = toolPath(b, vitasdk, "share/gcc-arm-vita-eabi/samples/common/debugScreen.c");
    const sdk_include_dir = toolPath(b, vitasdk, "arm-vita-eabi/include");
    const sdk_cxx_include_dir = toolPath(b, vitasdk, "arm-vita-eabi/include/c++/15.2.0");
    const sdk_cxx_target_include_dir = toolPath(b, vitasdk, "arm-vita-eabi/include/c++/15.2.0/arm-vita-eabi");

    const vita_target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .vita,
        .abi = .eabihf,
    });
    const nes_obj = addNesObject(b, "zico_nes_vita", vita_target, optimize, .{
        .sdk_include_dir = sdk_include_dir,
        .sdk_common_dir = sdk_common_dir,
        .debugscreen_c = sdk_debugscreen_c,
    });

    const link_elf = b.addSystemCommand(&.{toolPath(b, vitasdk, "bin/arm-vita-eabi-g++")});
    link_elf.addArtifactArg(nes_obj);
    for (gui_cpp_sources) |source| {
        const object_name = b.fmt("vita_{s}.o", .{source.object_stem});
        const object = addVitaCppObject(b, borealis, vitasdk, source.path, object_name, sdk_include_dir, sdk_common_dir, sdk_cxx_include_dir, sdk_cxx_target_include_dir);
        link_elf.addFileArg(object);
    }
    link_elf.addArg("-Wl,-q");
    link_elf.addArg("-Wl,-z,nocopyreloc");
    link_elf.addArg("-Wl,--gc-sections");
    link_elf.addArg("-Wl,--no-warn-execstack");
    addBorealisCommonArchives(b, link_elf, borealis.vita_build_dir);
    addBorealisVitaLinkArgs(link_elf);
    link_elf.addArg("-lSceLibKernel_stub");
    link_elf.addArg("-lSceDisplay_stub");
    link_elf.addArg("-Wl,--no-enum-size-warning");
    const elf = link_elf.addPrefixedOutputFileArg("-o", "zico_vita.elf");

    const create_velf = b.addSystemCommand(&.{toolPath(b, vitasdk, "bin/vita-elf-create")});
    create_velf.addFileArg(elf);
    const velf = create_velf.addOutputFileArg("zico_vita.velf");

    const create_self = b.addSystemCommand(&.{ toolPath(b, vitasdk, "bin/vita-make-fself"), "-c", "-s" });
    create_self.addFileArg(velf);
    const eboot = create_self.addOutputFileArg("eboot.bin");

    const create_sfo = b.addSystemCommand(&.{
        toolPath(b, vitasdk, "bin/vita-mksfoex"),
        "-d",
        "PARENTAL_LEVEL=1",
        "-s",
        b.fmt("TITLE_ID={s}", .{title_id}),
        "-s",
        b.fmt("APP_VER={s}", .{version}),
        app_name,
    });
    const sfo = create_sfo.addOutputFileArg("param.sfo");

    const create_vpk = b.addSystemCommand(&.{ toolPath(b, vitasdk, "bin/vita-pack-vpk"), "-s" });
    create_vpk.addFileArg(sfo);
    create_vpk.addArg("-b");
    create_vpk.addFileArg(eboot);
    create_vpk.addArg("-a");
    create_vpk.addArg(b.fmt("{s}=sce_sys/icon0.png", .{b.pathFromRoot("sce_sys/icon0.png")}));
    create_vpk.addArg("-a");
    create_vpk.addArg(b.fmt("{s}=sce_sys/livearea/contents/bg.png", .{b.pathFromRoot("sce_sys/livearea/contents/bg.png")}));
    create_vpk.addArg("-a");
    create_vpk.addArg(b.fmt("{s}=sce_sys/livearea/contents/startup.png", .{b.pathFromRoot("sce_sys/livearea/contents/startup.png")}));
    create_vpk.addArg("-a");
    create_vpk.addArg(b.fmt("{s}=sce_sys/livearea/contents/template.xml", .{b.pathFromRoot("sce_sys/livearea/contents/template.xml")}));
    create_vpk.addArg("-a");
    create_vpk.addArg(b.fmt("{s}=resources", .{b.pathJoin(&.{ borealis.source_dir, "resources" })}));
    const vpk = create_vpk.addOutputFileArg("zico_vita.vpk");

    return .{
        .elf = elf,
        .velf = velf,
        .eboot = eboot,
        .sfo = sfo,
        .vpk = vpk,
    };
}

fn addVitaInstallStep(b: *std.Build, artifacts: VitaArtifacts) *std.Build.Step {
    const install_dir: std.Build.InstallDir = .{ .custom = "vita" };

    const install_elf = b.addInstallFileWithDir(artifacts.elf, install_dir, "zico_vita.elf");
    const install_velf = b.addInstallFileWithDir(artifacts.velf, install_dir, "zico_vita.velf");
    const install_eboot = b.addInstallFileWithDir(artifacts.eboot, install_dir, "eboot.bin");
    const install_sfo = b.addInstallFileWithDir(artifacts.sfo, install_dir, "param.sfo");
    const install_vpk = b.addInstallFileWithDir(artifacts.vpk, install_dir, "zico_vita.vpk");

    const step = b.step("install-vita-artifacts", "Install generated PS Vita artifacts");
    step.dependOn(&install_elf.step);
    step.dependOn(&install_velf.step);
    step.dependOn(&install_eboot.step);
    step.dependOn(&install_sfo.step);
    step.dependOn(&install_vpk.step);
    return step;
}

const VitaSdkPaths = struct {
    sdk_include_dir: []const u8,
    sdk_common_dir: []const u8,
    debugscreen_c: []const u8,
};

fn addNesObject(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    vita_sdk: ?VitaSdkPaths,
) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .root_source_file = b.path("src/nes/api.zig"),
        .target = target,
        .optimize = optimize,
        .sanitize_c = .off,
        .stack_check = false,
    });
    if (vita_sdk) |sdk| {
        mod.addSystemIncludePath(.{ .cwd_relative = sdk.sdk_include_dir });
        mod.addIncludePath(.{ .cwd_relative = sdk.sdk_common_dir });
        mod.addCSourceFile(.{
            .file = .{ .cwd_relative = sdk.debugscreen_c },
            .flags = &.{ "-std=gnu11", "-D__vita__" },
        });
    }

    return b.addObject(.{
        .name = name,
        .root_module = mod,
    });
}

fn addCompileCommandsSteps(b: *std.Build, optimize: std.builtin.OptimizeMode, borealis: BorealisPaths) void {
    const desktop = addCompileCommandsRun(b, optimize, "desktop", borealis);
    const default_step = b.step("compdb", "Generate compile_commands.json for macOS Borealis OpenGL");
    default_step.dependOn(desktop);

    const vita = addCompileCommandsRun(b, optimize, "vita", borealis);
    const vita_step = b.step("compdb-vita", "Generate compile_commands.json for PS Vita Borealis GXM");
    vita_step.dependOn(vita);
}

fn addCompileCommandsRun(b: *std.Build, optimize: std.builtin.OptimizeMode, mode: []const u8, borealis: BorealisPaths) *std.Build.Step {
    const tool_mod = b.createModule(.{
        .root_source_file = b.path("tools/gen_compile_commands.zig"),
        .target = b.resolveTargetQuery(.{}),
        .optimize = optimize,
    });
    const tool = b.addExecutable(.{
        .name = b.fmt("gen_compile_commands_{s}", .{mode}),
        .root_module = tool_mod,
    });

    const vitasdk = b.graph.environ_map.get("VITASDK") orelse "";
    const run = b.addRunArtifact(tool);
    run.addArg(mode);
    run.addArg(b.pathFromRoot("."));
    run.addArg(borealis.source_dir);
    run.addArg(borealis.desktop_build_dir);
    run.addArg(borealis.vita_build_dir);
    run.addArg(vitasdk);
    return &run.step;
}

fn addProjectIncludeArgs(b: *std.Build, cmd: *std.Build.Step.Run) void {
    cmd.addArg("-I");
    cmd.addArg(b.pathFromRoot("include"));
}

fn addVitaSdkIncludeArgs(
    cmd: *std.Build.Step.Run,
    sdk_include_dir: []const u8,
    sdk_common_dir: []const u8,
    sdk_cxx_include_dir: []const u8,
    sdk_cxx_target_include_dir: []const u8,
) void {
    cmd.addArg("-I");
    cmd.addArg(sdk_include_dir);
    cmd.addArg("-I");
    cmd.addArg(sdk_common_dir);
    cmd.addArg("-isystem");
    cmd.addArg(sdk_cxx_include_dir);
    cmd.addArg("-isystem");
    cmd.addArg(sdk_cxx_target_include_dir);
}

fn addBorealisDesktopIncludeArgs(b: *std.Build, cmd: *std.Build.Step.Run, borealis: BorealisPaths) void {
    const include_dirs = [_][]const u8{
        b.pathJoin(&.{ borealis.source_dir, "library/include" }),
        b.pathJoin(&.{ borealis.source_dir, "library/include/borealis/extern" }),
        b.pathJoin(&.{ borealis.source_dir, "library/include/borealis/extern/nanovg" }),
        b.pathJoin(&.{ borealis.source_dir, "library/lib/extern/fmt/include" }),
        b.pathJoin(&.{ borealis.source_dir, "library/lib/extern/tweeny/include" }),
        b.pathJoin(&.{ borealis.source_dir, "library/lib/extern/glfw/include" }),
        b.pathJoin(&.{ borealis.desktop_build_dir, "library" }),
    };
    for (include_dirs) |dir| {
        cmd.addArg("-I");
        cmd.addArg(dir);
    }
}

fn addBorealisVitaIncludeArgs(b: *std.Build, cmd: *std.Build.Step.Run, borealis: BorealisPaths) void {
    const include_dirs = [_][]const u8{
        b.pathJoin(&.{ borealis.source_dir, "library/include" }),
        b.pathJoin(&.{ borealis.source_dir, "library/include/borealis/extern" }),
        b.pathJoin(&.{ borealis.source_dir, "library/include/borealis/extern/nanovg" }),
        b.pathJoin(&.{ borealis.source_dir, "library/lib/extern/fmt/include" }),
        b.pathJoin(&.{ borealis.source_dir, "library/lib/extern/tweeny/include" }),
        b.pathJoin(&.{ borealis.vita_build_dir, "library" }),
    };
    for (include_dirs) |dir| {
        cmd.addArg("-I");
        cmd.addArg(dir);
    }
}

fn addBorealisCommonArchives(b: *std.Build, cmd: *std.Build.Step.Run, build_dir: []const u8) void {
    cmd.addFileArg(.{ .cwd_relative = b.pathJoin(&.{ build_dir, "library/libborealis.a" }) });
    cmd.addFileArg(.{ .cwd_relative = b.pathJoin(&.{ build_dir, "library/lib/extern/fmt/libfmt.a" }) });
    cmd.addFileArg(.{ .cwd_relative = b.pathJoin(&.{ build_dir, "library/lib/extern/yoga/yoga/libyogacore.a" }) });
    cmd.addFileArg(.{ .cwd_relative = b.pathJoin(&.{ build_dir, "library/libtinyxml2.a" }) });
}

fn addBorealisVitaLinkArgs(cmd: *std.Build.Step.Run) void {
    cmd.addArg("-lSceGxm_stub");
    cmd.addArg("-lSceCtrl_stub");
    cmd.addArg("-lSceCommonDialog_stub");
    cmd.addArg("-lSceTouch_stub");
    cmd.addArg("-lSceAppUtil_stub");
    cmd.addArg("-lSceIme_stub");
    cmd.addArg("-lScePower_stub");
    cmd.addArg("-lSceAVConfig_stub");
    cmd.addArg("-lSceRegistryMgr_stub");
    cmd.addArg("-Wl,--whole-archive");
    cmd.addArg("-lpthread");
    cmd.addArg("-Wl,--no-whole-archive");
    cmd.addArg("-lm");
}

fn addMacFramework(cmd: *std.Build.Step.Run, name: []const u8) void {
    cmd.addArg("-framework");
    cmd.addArg(name);
}

fn vitaSdkPath(b: *std.Build) []const u8 {
    return b.graph.environ_map.get("VITASDK") orelse {
        std.debug.panic("VITASDK is required to build PS Vita artifacts", .{});
    };
}

fn toolPath(b: *std.Build, vitasdk: []const u8, suffix: []const u8) []const u8 {
    return b.pathJoin(&.{ vitasdk, suffix });
}
