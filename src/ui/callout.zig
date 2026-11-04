//! Inline callout for notes, tips and warnings. Markdown `> [!TIP]` renders the same markup.
const zv = @import("../view.zig");

pub const css =
    \\.zw-callout{display:flex;gap:10px;padding:10px 14px;border-radius:var(--radius-control);background:color-mix(in srgb,var(--c) 10%,transparent);
    \\box-shadow:inset 3px 0 0 var(--c);color:var(--label);--c:var(--accent)}
    \\.zw-callout--tip{--c:var(--green)}.zw-callout--warning{--c:var(--orange)}
    \\.zw-callout p{margin:0}
    \\.zw-callout strong:first-child{color:var(--c)}
    \\
;

pub const Kind = enum { note, tip, warning };

pub fn Props(comptime Body: type) type {
    return struct { kind: Kind = .note, title: []const u8 = "", body: Body };
}

const src = "<aside class=\"zw-callout zw-callout--{kind}\"><p>{#if title}<strong>{title}</strong> {/if}{body}</p></aside>";

pub fn Callout(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

/// `callout(.{ .kind = .tip, .title = "Tip", .body = "Run zig build e2e." })`
pub fn callout(p: anytype) Callout(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}
