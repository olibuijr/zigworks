//! Inset content list. Children are `<li>` rows. Give it an `id` to target it with z.js.
//! Separators start after a leading control, like macOS lists.
const zv = @import("../view.zig");

pub const css =
    \\.zw-list{list-style:none;padding:0;background:var(--content);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden}
    \\.zw-list>li{display:flex;align-items:center;gap:10px;min-height:44px;padding:6px 8px 6px 12px;position:relative;transition:background-color var(--speed)}
    \\.zw-list>li+li::before{content:"";position:absolute;top:0;left:44px;right:0;border-top:1px solid var(--separator)}
    \\.zw-list>li.zw-leave{min-height:0;padding-block:0;overflow:hidden}
    \\.zw-list:empty::after{content:attr(data-empty);display:block;padding:32px var(--space);text-align:center;color:var(--secondary);animation:zw-fade var(--dur) ease}
    \\@keyframes zw-fade{from{opacity:0}}
    \\
;

const src = "<ul class=\"zw-list\" id=\"{id}\" data-empty=\"{empty}\">{body}</ul>";

pub fn Props(comptime Body: type) type {
    return struct { id: []const u8, empty: []const u8 = "Nothing here yet", body: Body };
}

pub fn List(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

/// `list(.{ .id = "todos", .empty = "No todos yet.", .body = zw.each(todos, row) })`
pub fn list(p: anytype) List(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}
