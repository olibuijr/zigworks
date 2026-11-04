//! Live demos for docs/pages/components/avatar.md (```demo avatar``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "avatar", false, avatar },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/avatar/x", handler }`.
pub const routes = .{};

fn avatar(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}{f}{g}<div class=\"zw-avatars\">{s1}{s2}{s3}{s4}</div>", .{
        .a = ui.avatar(.{ .name = "Ada Lovelace", .size = 44 }),
        .b = ui.avatar(.{ .name = "Grace Hopper", .size = 44, .status = .online }),
        .c = ui.avatar(.{ .name = "Linus Torvalds", .size = 32, .status = .away }),
        .d = ui.avatar(.{ .name = "Andrew Kelley", .size = 24 }),
        .e = ui.avatar(.{ .name = "Zig Software Foundation", .size = 44, .shape = .rounded, .hue = 35 }),
        .f = ui.avatar(.{ .name = "Margaret Hamilton", .size = 44, .status = .busy }),
        .g = ui.avatar(.{ .name = "Alan Turing", .size = 44, .status = .offline }),
        .s1 = ui.avatar(.{ .name = "Ada Lovelace", .size = 36 }),
        .s2 = ui.avatar(.{ .name = "Grace Hopper", .size = 36 }),
        .s3 = ui.avatar(.{ .name = "Linus Torvalds", .size = 36 }),
        .s4 = ui.avatar(.{ .name = "More people", .size = 36, .more = 5 }),
    }).render(w);
}
