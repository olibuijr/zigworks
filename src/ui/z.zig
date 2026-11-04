//! z.js attributes as a value. Put it inside any tag: `<form{z}>`, or pass it to a component's `.z`.
const std = @import("std");
const writeEscaped = @import("../view.zig").writeEscaped;

pub const Swap = enum { inner, outer, beforeend, afterbegin, delete, none };

pub const Z = struct {
    get: ?[]const u8 = null,
    post: ?[]const u8 = null,
    put: ?[]const u8 = null,
    patch: ?[]const u8 = null,
    delete: ?[]const u8 = null,
    /// Element to update: a CSS selector, or "closest <selector>". Default: the element itself.
    target: ?[]const u8 = null,
    swap: ?Swap = null,
    /// Event that fires the request: "click", "submit", "change", "input", "load". Default: submit for forms, click otherwise.
    trigger: ?[]const u8 = null,
    /// Ask before sending.
    confirm: ?[]const u8 = null,
    /// Keep a form's values after a successful send (settings forms). By default a successful
    /// non-GET form is reset, which suits "add" forms.
    keep: bool = false,

    pub fn render(z: Z, w: *std.Io.Writer) std.Io.Writer.Error!void {
        const info = @typeInfo(Z).@"struct";
        inline for (info.field_names, info.field_types) |name, T| {
            if (T == bool) {
                if (@field(z, name)) try w.writeAll(" z-" ++ name);
            } else if (@field(z, name)) |v| {
                try w.writeAll(" z-" ++ name ++ "=\"");
                try writeEscaped(w, if (T == ?Swap) @tagName(v) else v);
                try w.writeByte('"');
            }
        }
    }
};

test Z {
    var buf: [128]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try (Z{ .post = "/a?x=\"1\"", .swap = .outer }).render(&w);
    try std.testing.expectEqualStrings(" z-post=\"/a?x=&quot;1&quot;\" z-swap=\"outer\"", w.buffered());
    w = .fixed(&buf);
    try (Z{ .post = "/s", .keep = true }).render(&w);
    try std.testing.expectEqualStrings(" z-post=\"/s\" z-keep", w.buffered());
}
