//! Live demos for docs/pages/components/menu.md (```demo menu``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "menu", false, menu },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/menu/x", handler }`.
pub const routes = .{};

fn menu(w: *Writer) Writer.Error!void {
    const copy = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linejoin=\"round\"><rect x=\"6\" y=\"6\" width=\"9\" height=\"9\" rx=\"2\"/><path d=\"M12 4.5V4a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v7a1 1 0 0 0 1 1h.5\"/></svg>";
    const share = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M9 11V2.5M6 5l3-3 3 3M4.5 8H4a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V9a1 1 0 0 0-1-1h-.5\"/></svg>";
    const trash = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 5h12M7 5V3h4v2M5 5l.7 10h6.6L13 5\"/></svg>";
    try zw.view("{b}{m}{b2}{m2}", .{
        .b = ui.button(.{ .label = "Actions", .opens = "demo-menu" }),
        .m = ui.menu(.{ .id = "demo-menu", .label = "Actions", .items = &.{
            .{ .label = "Duplicate", .icon = copy, .shortcut = "⌘D", .z = d.save },
            .{ .label = "Share…", .icon = share, .z = d.save },
            .{ .label = "Archive", .disabled = true },
            .{ .label = "Move to Trash", .icon = trash, .shortcut = "⌘⌫", .z = d.save, .destructive = true, .separated = true },
        } }),
        .b2 = ui.button(.{ .label = "View", .opens = "demo-menu-view" }),
        .m2 = ui.menu(.{ .id = "demo-menu-view", .label = "View", .alignment = .end, .items = &.{
            .{ .label = "Show Sidebar", .checked = true, .shortcut = "⌘B", .header = "Layout", .z = d.save },
            .{ .label = "Show Toolbar", .checked = true, .z = d.save },
            .{ .label = "Show Status Bar", .checked = false, .z = d.save },
            .{ .label = "Sort by Name", .checked = true, .header = "Sort", .separated = true, .z = d.save },
            .{ .label = "Sort by Date", .checked = false, .z = d.save },
            .{ .label = "Documentation", .href = "/components/layout", .separated = true },
        } }),
    }).render(w);
}
