//! Empty state: what a view shows when it has nothing yet, with an optional next step.
//! `icon` is a decorative symbol above the title, `size` fits it to a popover, a card or a whole
//! page, and `action` plus `secondary` are the buttons underneath.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-empty{display:flex;flex-direction:column;align-items:center;gap:6px;padding:36px var(--space);text-align:center;animation:zw-empty-in var(--dur) ease}
    \\.zw-empty h3{font:var(--title3);font-weight:600;color:var(--label)}
    \\.zw-empty p{color:var(--secondary);max-width:36ch}
    \\.zw-empty-icon{font-size:40px;line-height:1;color:var(--tertiary);margin-bottom:4px;user-select:none}
    \\.zw-empty-actions{display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:8px;margin-top:10px}
    \\.zw-empty--compact{padding:16px var(--space);gap:4px}
    \\.zw-empty--compact h3{font:var(--body);font-weight:600}
    \\.zw-empty--compact .zw-empty-icon{font-size:28px}
    \\.zw-empty--large{padding:72px var(--space);gap:8px}
    \\.zw-empty--large h3{font:var(--title2);font-weight:700}
    \\.zw-empty--large p{font:var(--title3);max-width:44ch}
    \\.zw-empty--large .zw-empty-icon{font-size:56px}
    \\@media (max-width:599px){.zw-empty--large{padding-block:48px}}
    \\@keyframes zw-empty-in{from{opacity:0}}
    \\
;

pub const Size = enum { regular, compact, large };

pub fn Props(comptime Action: type, comptime Secondary: type) type {
    return struct {
        title: []const u8,
        text: []const u8 = "",
        icon: []const u8 = "",
        size: Size = .regular,
        action: ?Action = null,
        secondary: ?Secondary = null,
    };
}

/// The props plus the flag `empty` works out from them.
pub fn Data(comptime Action: type, comptime Secondary: type) type {
    return struct { p: Props(Action, Secondary), actions: bool };
}

const src = "<div class=\"zw-empty zw-empty--{p.size}\">{#if p.icon}<div class=\"zw-empty-icon\" aria-hidden=\"true\">{p.icon}</div>{/if}<h3>{p.title}</h3>{#if p.text}<p>{p.text}</p>{/if}" ++
    "{#if actions}<div class=\"zw-empty-actions\">{p.action}{p.secondary}</div>{/if}</div>";

pub fn EmptyOf(comptime Action: type, comptime Secondary: type) type {
    return zv.View(src, Data(Action, Secondary));
}

/// An empty state with at most one action component.
pub fn Empty(comptime Action: type) type {
    return EmptyOf(Action, []const u8);
}

/// `empty(.{ .icon = "✓", .title = "No Reminders", .text = "Add one to get started.", .action = ui.button(...) })`
pub fn empty(p: anytype) EmptyOf(zv.Slot(@TypeOf(p), "action"), zv.Slot(@TypeOf(p), "secondary")) {
    const q = zv.props(Props(zv.Slot(@TypeOf(p), "action"), zv.Slot(@TypeOf(p), "secondary")), p);
    return .{ .data = .{ .p = q, .actions = zv.filled(q.action) or zv.filled(q.secondary) } };
}

test "empty renders icon, size and actions" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try empty(.{ .title = "None", .text = "Add one." }).render(&w);
    try std.testing.expectEqualStrings("<div class=\"zw-empty zw-empty--regular\"><h3>None</h3><p>Add one.</p></div>", w.buffered());

    w = .fixed(&buf);
    try empty(.{ .title = "None", .icon = "i", .size = .compact, .secondary = zv.view("<b>{x}</b>", .{ .x = "s" }) }).render(&w);
    try std.testing.expectEqualStrings(
        "<div class=\"zw-empty zw-empty--compact\"><div class=\"zw-empty-icon\" aria-hidden=\"true\">i</div><h3>None</h3>" ++
            "<div class=\"zw-empty-actions\"><b>s</b></div></div>",
        w.buffered(),
    );
}
