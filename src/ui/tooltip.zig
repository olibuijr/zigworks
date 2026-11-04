//! Tooltip: a short glass hint shown when the pointer rests on (or keyboard focus enters) its content,
//! after the macOS delay. Replaces the browser's `title` tooltip. CSS only. Touch screens never show it.
//! Give it an `id` and the trigger's `describedby` so assistive tech reads it as the description.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-tip{position:relative;display:inline-flex}
    \\.zw-tip-text{position:absolute;bottom:calc(100% + 8px);left:50%;z-index:30;width:max-content;max-width:min(240px,calc(100vw - 32px));padding:5px 9px;border-radius:8px;pointer-events:none;
    \\font:var(--callout);color:var(--label);text-align:center;--glass:var(--glass-thick);--px:-50%;--py:0%;--nx:0px;--ny:4px;
    \\opacity:0;translate:calc(var(--px) + var(--nx)) calc(var(--py) + var(--ny));scale:.92;transform-origin:bottom center;
    \\transition:opacity 120ms ease,translate var(--dur) var(--spring),scale var(--dur-bouncy) var(--spring-bouncy);transition-delay:0s}
    \\.zw-tip--below>.zw-tip-text{bottom:auto;top:calc(100% + 8px);--ny:-4px;transform-origin:top center}
    \\.zw-tip--left>.zw-tip-text{bottom:auto;left:auto;top:50%;right:calc(100% + 8px);--px:0%;--py:-50%;--nx:4px;--ny:0px;transform-origin:right center}
    \\.zw-tip--right>.zw-tip-text{bottom:auto;top:50%;left:calc(100% + 8px);--px:0%;--py:-50%;--nx:-4px;--ny:0px;transform-origin:left center}
    \\.zw-tip:has(:focus-visible)>.zw-tip-text{opacity:1;--nx:0px;--ny:0px;scale:1;transition-delay:var(--zw-tip-delay,500ms)}
    \\@media (hover:hover){.zw-tip:hover>.zw-tip-text{opacity:1;--nx:0px;--ny:0px;scale:1;transition-delay:var(--zw-tip-delay,500ms)}}
    \\.zw-tip-detail{display:block;margin-top:2px;color:var(--secondary)}
    \\.zw-tip-kbd{margin-left:8px;padding:0 4px;border-radius:4px;background:var(--fill);color:var(--secondary);font-weight:500}
    \\
;

pub const Side = enum { above, below, left, right };

pub fn Props(comptime Body: type) type {
    return struct {
        text: []const u8,
        side: Side = .above,
        body: Body,
        /// Milliseconds the pointer or focus must rest before the tip appears (macOS: 500). 0 shows it at once.
        delay: u16 = 500,
        /// Second line in secondary color, for a short explanation.
        detail: []const u8 = "",
        /// Shortcut hint after the text, e.g. "⌘S".
        shortcut: []const u8 = "",
        /// Id of the tip. Pass the same string as the trigger's `describedby` (see `ui.button`).
        id: []const u8 = "",
    };
}

const src = "<span class=\"zw-tip zw-tip--{p.side}\"{#if custom_delay} style=\"--zw-tip-delay:{p.delay}ms\"{/if}>{p.body}" ++
    "<span class=\"zw-tip-text zw-glass\" role=\"tooltip\"{#if p.id} id=\"{p.id}\"{/if}>{p.text}" ++
    "{#if p.shortcut}<span class=\"zw-tip-kbd\">{p.shortcut}</span>{/if}{#if p.detail}<span class=\"zw-tip-detail\">{p.detail}</span>{/if}</span></span>";

fn Data(comptime Body: type) type {
    return struct { p: Props(Body), custom_delay: bool };
}

pub fn Tooltip(comptime Body: type) type {
    return zv.View(src, Data(Body));
}

/// `tooltip(.{ .text = "More actions", .body = ui.button(...) })`
pub fn tooltip(p: anytype) Tooltip(@FieldType(@TypeOf(p), "body")) {
    const P = Props(@FieldType(@TypeOf(p), "body"));
    const full = zv.props(P, p);
    return .{ .data = .{ .p = full, .custom_delay = full.delay != 500 } };
}

fn expectHas(t: anytype, needle: []const u8) !void {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try t.render(&w);
    if (std.mem.find(u8, w.buffered(), needle) == null) {
        std.debug.print("missing '{s}' in: {s}\n", .{ needle, w.buffered() });
        return error.TestExpectedEqual;
    }
}

test "side, delay and rich body render" {
    const body = zv.view("<b>x</b>", .{});
    try expectHas(tooltip(.{ .text = "Hi", .body = body }), "<span class=\"zw-tip zw-tip--above\"><b>x</b><span class=\"zw-tip-text zw-glass\" role=\"tooltip\">Hi</span></span>");
    try expectHas(tooltip(.{ .text = "Hi", .side = .left, .delay = 200, .body = body }), "zw-tip--left\" style=\"--zw-tip-delay:200ms\"");
    try expectHas(tooltip(.{ .text = "Hi", .id = "t1", .shortcut = "⌘S", .detail = "Saves now", .body = body }), "id=\"t1\">Hi<span class=\"zw-tip-kbd\">⌘S</span><span class=\"zw-tip-detail\">Saves now</span>");
}
