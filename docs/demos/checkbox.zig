//! Live demos for docs/pages/components/checkbox.md (```demo checkbox``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "checkbox", true, checkbox },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/checkbox/x", handler }`.
pub const routes = .{};

fn checkbox(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\" style=\"gap:6px\">{a}{b}{c}{d}{e}{f}</div>", .{
        .a = ui.checkbox(.{ .name = "spell", .label = "Check spelling while typing", .on = true, .z = d.save }),
        .b = ui.checkbox(.{ .name = "grammar", .label = "Check grammar with spelling", .z = d.save }),
        .c = ui.checkbox(.{ .name = "caps", .label = "Capitalize words automatically", .on = true, .z = d.save }),
        .d = ui.checkbox(.{ .name = "all", .label = "Select all", .mixed = true, .description = "2 of 5 selected", .z = d.save }),
        .e = ui.checkbox(.{ .name = "beta", .label = "Beta features", .description = "Managed by your administrator", .disabled = true }),
        .f = ui.checkbox(.{ .name = "terms", .label = "I agree to the terms", .invalid = true, .z = d.save }),
    }).render(w);
}
