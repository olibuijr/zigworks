//! Empty state: what a view shows when it has nothing yet, with an optional next step.
const zv = @import("../view.zig");

pub const css =
    \\.zw-empty{display:flex;flex-direction:column;align-items:center;gap:6px;padding:36px var(--space);text-align:center}
    \\.zw-empty h3{font:var(--title3);font-weight:600;color:var(--label)}
    \\.zw-empty p{color:var(--secondary);max-width:36ch}
    \\.zw-empty>:last-child:not(p):not(h3){margin-top:10px}
    \\
;

pub fn Props(comptime Action: type) type {
    return struct { title: []const u8, text: []const u8 = "", action: Action };
}

const src = "<div class=\"zw-empty\"><h3>{title}</h3>{#if text}<p>{text}</p>{/if}{action}</div>";

pub fn Empty(comptime Action: type) type {
    return zv.View(src, Props(Action));
}

fn ActionOf(comptime P: type) type {
    return if (@hasField(P, "action")) @FieldType(P, "action") else []const u8;
}

/// `empty(.{ .title = "No Reminders", .text = "Add one to get started.", .action = ui.button(...) })`
pub fn empty(p: anytype) Empty(ActionOf(@TypeOf(p))) {
    const P = @TypeOf(p);
    return .{ .data = .{
        .title = p.title,
        .text = if (@hasField(P, "text")) p.text else "",
        .action = if (@hasField(P, "action")) p.action else "",
    } };
}
