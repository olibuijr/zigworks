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

/// Everything the template needs: the props and the flags `empty` works out from them.
pub fn Data(comptime Action: type, comptime Secondary: type) type {
    return struct {
        title: []const u8,
        text: []const u8,
        icon: []const u8,
        size: Size,
        actions: bool,
        has_action: bool,
        has_secondary: bool,
        action: Action,
        secondary: Secondary,
    };
}

const src = "<div class=\"zw-empty zw-empty--{size}\">{#if icon}<div class=\"zw-empty-icon\" aria-hidden=\"true\">{icon}</div>{/if}<h3>{title}</h3>{#if text}<p>{text}</p>{/if}" ++
    "{#if actions}<div class=\"zw-empty-actions\">{#if has_action}{action}{/if}{#if has_secondary}{secondary}{/if}</div>{/if}</div>";

pub fn EmptyOf(comptime Action: type, comptime Secondary: type) type {
    return zv.View(src, Data(Action, Secondary));
}

/// An empty state with at most one action component.
pub fn Empty(comptime Action: type) type {
    return EmptyOf(Action, []const u8);
}

const names = [_][]const u8{ "title", "text", "icon", "size", "action", "secondary" };

fn checkProps(comptime P: type) void {
    comptime {
        for (@typeInfo(P).@"struct".field_names) |n| {
            var ok = false;
            for (names) |k| ok = ok or std.mem.eql(u8, n, k);
            if (!ok) @compileError("unknown prop '" ++ n ++ "' for empty");
        }
    }
}

fn opt(p: anytype, comptime name: []const u8, default: anytype) @TypeOf(default) {
    return if (comptime @hasField(@TypeOf(p), name)) @field(p, name) else default;
}

fn SlotOf(comptime P: type, comptime name: []const u8) type {
    return if (@hasField(P, name)) @FieldType(P, name) else []const u8;
}

/// True when the slot was given and is not an empty string.
fn present(p: anytype, comptime name: []const u8) bool {
    if (comptime @hasField(@TypeOf(p), name)) {
        const v = @field(p, name);
        return if (comptime @typeInfo(@TypeOf(v)) == .pointer) v.len > 0 else true;
    } else return false;
}

/// `empty(.{ .icon = "✓", .title = "No Reminders", .text = "Add one to get started.", .action = ui.button(...) })`
pub fn empty(p: anytype) EmptyOf(SlotOf(@TypeOf(p), "action"), SlotOf(@TypeOf(p), "secondary")) {
    const P = @TypeOf(p);
    checkProps(P);
    const has_action = present(p, "action");
    const has_secondary = present(p, "secondary");
    return .{ .data = .{
        .title = p.title,
        .text = opt(p, "text", @as([]const u8, "")),
        .icon = opt(p, "icon", @as([]const u8, "")),
        .size = opt(p, "size", Size.regular),
        .actions = has_action or has_secondary,
        .has_action = has_action,
        .has_secondary = has_secondary,
        .action = if (comptime @hasField(P, "action")) p.action else "",
        .secondary = if (comptime @hasField(P, "secondary")) p.secondary else "",
    } };
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
