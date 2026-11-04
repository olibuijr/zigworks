//! Live demos for docs/pages/components/textarea.md (```demo textarea``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "textarea", true, textarea },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/textarea/x", handler }`.
pub const routes = .{};

fn textarea(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}", .{
        .a = ui.textarea(.{ .name = "notes", .label = "Notes", .placeholder = "Add notes. The field grows as you type." }),
        .b = ui.textarea(.{ .name = "bio", .label = "Bio", .value = "Zig and glass.", .maxlength = 140, .help = "Shown on your profile.", .rows = 2, .grow = false, .resize = .vertical }),
        .c = ui.textarea(.{ .name = "reason", .label = "Reason", .rows = 2, .invalid = "Tell us why.", .required = true }),
    }).render(w);
}
