//! Live demos for docs/pages/components/sidebar.md (```demo sidebar``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "sidebar", false, sidebar },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css = "";
/// Server routes these demos need, e.g. `.{ "POST /demo/sidebar/x", handler }`.
pub const routes = .{};

fn sidebar(w: *Writer) Writer.Error!void {
    const svg = "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'>";
    const inbox = svg ++ "<path d='M2 9.5l1.6-5.2a1 1 0 0 1 .95-.7h6.9a1 1 0 0 1 .95.7L14 9.5v2.9a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1z'/><path d='M2 9.5h3.4l.6 1.5h4l.6-1.5H14'/></svg>";
    const draft = svg ++ "<path d='M4 1.7h5l3 3v9.6H4z'/><path d='M9 1.7v3h3'/></svg>";
    const sent = svg ++ "<path d='M14 2L7 9M14 2l-4.5 12L7 9 1.5 6.5z'/></svg>";
    const today = svg ++ "<rect x='2' y='3' width='12' height='11' rx='2'/><path d='M2 6.5h12M5.5 1.5v3M10.5 1.5v3'/></svg>";
    try ui.sidebar(.{
        .current = "#inbox",
        .inline_ = true,
        .footer = "<span class=\"zw-secondary\">Signed in as ada</span>",
        .sections = &.{
            .{ .title = "Mail", .links = &.{
                .{ .label = "Inbox", .href = "#inbox", .icon = inbox, .badge = "12" },
                .{ .label = "Drafts", .href = "#drafts", .icon = draft, .badge = "2" },
                .{ .label = "Sent", .href = "#sent", .icon = sent },
            } },
            .{ .title = "Smart Mailboxes", .collapsible = true, .links = &.{.{ .label = "Today", .href = "#today", .icon = today }} },
            .{ .title = "Archive", .collapsible = true, .open = false, .links = &.{ .{ .label = "2025", .href = "#y2025" }, .{ .label = "2024", .href = "#y2024" } } },
        },
    }).render(w);
}
