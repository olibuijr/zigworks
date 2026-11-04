//! Live demos for docs/pages/components/button.md (```demo button``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "button", false, button },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/button/x", handler }`.
pub const routes = .{};

fn button(w: *Writer) Writer.Error!void {
    const plus = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\"><path d=\"M9 3.5v11M3.5 9h11\"/></svg>";
    const chevron = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M6.5 4l5 5-5 5\"/></svg>";
    try zw.view("{a}{b}{c}{d}{e}{f}{g}{h}{i}{j}{k}{l}{m}", .{
        .a = ui.button(.{ .label = "Save", .variant = .primary }),
        .b = ui.button(.{ .label = "Cancel" }),
        .c = ui.button(.{ .label = "Learn More", .variant = .plain }),
        .d = ui.button(.{ .label = "Delete", .variant = .destructive }),
        .e = ui.button(.{ .label = "Disabled", .disabled = true }),
        .f = ui.button(.{ .label = "Small", .size = .small }),
        .g = ui.button(.{ .label = "Large", .size = .large, .variant = .primary }),
        .h = ui.button(.{ .label = "New Item", .icon = plus }),
        .i = ui.button(.{ .label = "Add", .icon = plus, .icon_only = true, .variant = .primary }),
        .j = ui.button(.{ .label = "Saving…", .variant = .primary, .loading = true }),
        .k = ui.button(.{ .label = "Read the Docs", .href = "/components/layout", .icon = chevron, .icon_end = true, .variant = .plain }),
        .l = ui.button(.{ .label = "Link, disabled", .href = "/components/layout", .disabled = true }),
        .m = ui.button(.{ .label = "Continue", .variant = .primary, .full = true }),
    }).render(w);
}
