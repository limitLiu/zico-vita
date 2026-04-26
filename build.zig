const std = @import("std");

const VitaArtifacts = struct {
    elf: std.Build.LazyPath,
    velf: std.Build.LazyPath,
    eboot: std.Build.LazyPath,
    sfo: std.Build.LazyPath,
    vpk: std.Build.LazyPath,
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const artifacts = addVitaBuild(b, optimize);
    const vita_step = addVitaInstallStep(b, artifacts);

    b.getInstallStep().dependOn(vita_step);
}

fn addVitaBuild(b: *std.Build, optimize: std.builtin.OptimizeMode) VitaArtifacts {
    const vitasdk = viteSdkPath(b);
    const title_id = b.option([]const u8, "vita-title-id", "PS Vita title id") orelse "ZICV00001";
    const app_name = b.option([]const u8, "vita-app-name", "PS Vita application name") orelse "Zico Vita";
    const version = b.option([]const u8, "vita-version", "PS Vita application version") orelse "01.00";

    if (title_id.len != 9) {
        std.debug.panic("vita title id must be exactly 9 characters, got '{s}'", .{title_id});
    }

    const sdk_common_dir = toolPath(b, vitasdk, "share/gcc-arm-vita-eabi/samples/common");
    const sdk_debugscreen_c = toolPath(b, vitasdk, "share/gcc-arm-vita-eabi/samples/common/debugScreen.c");
    const sdk_include_dir = toolPath(b, vitasdk, "arm-vita-eabi/include");

    const vita_root = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .arm,
            .os_tag = .vita,
            .abi = .eabihf,
        }),
        .optimize = optimize,
        .sanitize_c = .off,
    });
    vita_root.addSystemIncludePath(.{ .cwd_relative = sdk_include_dir });
    vita_root.addIncludePath(.{ .cwd_relative = sdk_common_dir });
    vita_root.addCSourceFile(.{
        .file = .{ .cwd_relative = sdk_debugscreen_c },
        .flags = &.{ "-std=gnu11", "-D__vita__" },
    });

    const vita_obj = b.addObject(.{
        .name = "zico_vita",
        .root_module = vita_root,
    });

    const link_elf = b.addSystemCommand(&.{toolPath(b, vitasdk, "bin/arm-vita-eabi-gcc")});
    link_elf.addArtifactArg(vita_obj);
    link_elf.addArg("-Wl,-q");
    link_elf.addArg("-Wl,-z,nocopyreloc");
    link_elf.addArg("-Wl,--gc-sections");
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

    const vita_step = b.step("vita", "Build PS Vita homebrew artifacts");
    vita_step.dependOn(&install_elf.step);
    vita_step.dependOn(&install_velf.step);
    vita_step.dependOn(&install_eboot.step);
    vita_step.dependOn(&install_sfo.step);
    vita_step.dependOn(&install_vpk.step);
    return vita_step;
}

fn viteSdkPath(b: *std.Build) []const u8 {
    return b.graph.environ_map.get("VITASDK") orelse {
        std.debug.panic("VITASDK is required to build PS Vita artifacts", .{});
    };
}

fn toolPath(b: *std.Build, vitasdk: []const u8, suffix: []const u8) []const u8 {
    return b.pathJoin(&.{ vitasdk, suffix });
}
