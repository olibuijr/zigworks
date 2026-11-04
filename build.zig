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

    // Examples: `zig build todo`, `zig build scene`, `zig build gallery`. `zig build run` = todo.
    const examples = [_][]const u8{ "todo", "scene", "gallery" };
    for (examples) |name| {
        const mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("examples/{s}/main.zig", .{name})),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zigworks", .module = zigworks }},
        });
        const exe = b.addExecutable(.{ .name = name, .root_module = mod });
        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        run.setCwd(b.path(b.fmt("examples/{s}", .{name})));
        run.addPassthruArgs();
        b.step(name, b.fmt("Run the {s} example", .{name})).dependOn(&run.step);
        if (std.mem.eql(u8, name, "todo")) b.step("run", "Run the todo example").dependOn(&run.step);

        test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = mod })).step);
    }

    // Browser end-to-end tests and screenshots (Chromium + Node, no npm packages).
    const e2e = b.addSystemCommand(&.{ "node", "tests/e2e.mjs" });
    e2e.step.dependOn(b.getInstallStep());
    e2e.has_side_effects = true;
    b.step("e2e", "Run browser e2e tests, save screenshots to zig-out/e2e").dependOn(&e2e.step);
}
