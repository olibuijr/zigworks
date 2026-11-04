//! Content surface with optional heading. Opaque: glass belongs to controls and bars only.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-card{background:var(--content);border-radius:var(--radius);box-shadow:var(--shadow);padding:var(--space)}
    \\.zw-card-title{font:var(--headline);color:var(--secondary);margin:0 0 10px}
    \\
;

const src = "<section class=\"zw-card\"{z}>{#if title}<h2 class=\"zw-card-title\">{title}</h2>{/if}{body}</section>";

pub fn Props(comptime Body: type) type {
    return struct { title: []const u8 = "", z: Z = .{}, body: Body };
}

pub fn Card(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

/// `card(.{ .title = "Settings", .body = ... })`
pub fn card(p: anytype) Card(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}
