//! Live demos for docs/pages/components/layout.md (```demo layout``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "layout", true, layout },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/layout/x", handler }`.
pub const routes = .{};

fn layout(w: *Writer) Writer.Error!void {
    try zw.markdown(
        \\The page you are reading is a `ui.layout` with a sidebar, a toolbar (search and badge) and a Markdown body.
        \\
        \\Reload and press Tab once to reveal this page's **Skip to content** link (`.skip_link`). `.footer` adds a line under the page, `.title_align = .center` centers the title, and `.lang` sets the document language.
    ).render(w);
}
