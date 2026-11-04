//! Live demos for docs/pages/components/search.md (```demo search``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "search", false, search },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/search/x", handler }`.
pub const routes = .{};

fn search(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}", .{
        .a = ui.search(.{ .action = "/search", .id = "demo-results", .label = "Search docs", .placeholder = "Try “button”", .shortcut = "k" }),
        .b = ui.search(.{ .action = "/search", .id = "demo-results-small", .label = "Search docs (small)", .placeholder = "Small", .size = .small }),
        .c = ui.search(.{ .action = "/search", .id = "demo-results-large", .label = "Search docs (large)", .placeholder = "Large, no clear button", .size = .large, .clear = false }),
    }).render(w);
}
