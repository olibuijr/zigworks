const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigworks = b.addModule("zigworks", .{
        .root_source_file = b.path("src/zigworks.zig"),
        .target = target,
    });

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = zigworks })).step);

    // Apps: `zig build todo|scene|gallery` (examples) and `zig build docs` (the docs site).
    // Each runs with its own directory as cwd so `public/` resolves. `zig build run` = todo.
    const apps = [_]struct { []const u8, []const u8 }{
        .{ "todo", "examples/todo" },
        .{ "scene", "examples/scene" },
        .{ "gallery", "examples/gallery" },
        .{ "docs", "docs" },
    };
    for (apps) |app| {
        const name, const dir = app;
        const mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("{s}/main.zig", .{dir})),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zigworks", .module = zigworks }},
        });
        const exe = b.addExecutable(.{ .name = name, .root_module = mod });
        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        run.setCwd(b.path(dir));
        run.addPassthruArgs();
        b.step(name, b.fmt("Run {s}", .{dir})).dependOn(&run.step);
        if (std.mem.eql(u8, name, "todo")) b.step("run", "Run the todo example").dependOn(&run.step);

        test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = mod })).step);
    }

    // Browser end-to-end tests and screenshots (Chromium + Node, no npm packages).
    const e2e = b.addSystemCommand(&.{ "node", "tests/e2e.mjs" });
    e2e.step.dependOn(b.getInstallStep());
    e2e.has_side_effects = true;
    b.step("e2e", "Run browser e2e tests, save screenshots to zig-out/e2e").dependOn(&e2e.step);
}
