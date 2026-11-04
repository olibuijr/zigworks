//! Path bar: where you are, as links from the top level down (macOS path control, breadcrumbs).
//! The last item is the current page. With `max`, a long path keeps its first and last items and
//! folds the middle into a "…" menu (a <details> popover: it needs no JS and closes on an outside tap).
const std = @import("std");
const Writer = std.Io.Writer;
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-path>ol{display:flex;flex-wrap:wrap;align-items:center;gap:2px;list-style:none;margin:0;padding:0;font:var(--callout);
    \\>li{display:inline-flex;align-items:center;gap:2px;min-width:0;
    \\&+li::before{content:"";flex:none;width:5px;height:5px;margin:0 6px 0 3px;border:solid var(--tertiary);border-width:1.5px 1.5px 0 0;rotate:45deg}}}
    \\.zw-path--slash>ol>li+li::before{width:auto;height:auto;margin:0 4px;border:0;rotate:none;content:"/";color:var(--tertiary)}
    \\.zw-path a,.zw-path-text,.zw-path [aria-current],.zw-path-more>summary{display:inline-flex;align-items:center;gap:5px;min-width:0;max-width:min(26ch,70vw);padding:2px 6px;border-radius:6px;
    \\@media (pointer:coarse){min-height:44px}}
    \\.zw-path a{color:var(--secondary);text-decoration:none;transition:background-color var(--speed),color var(--speed);
    \\&:hover{background:var(--fill);color:var(--label)}
    \\&:active{background:color-mix(in srgb,var(--fill) 70%,var(--separator))}}
    \\.zw-path-text{color:var(--secondary)}
    \\.zw-path [aria-current]{color:var(--label);font-weight:600}
    \\.zw-path-label{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.zw-path-icon{flex:none}
    \\.zw-path-more{position:relative;
    \\&>summary{list-style:none;color:var(--secondary);cursor:default;user-select:none;transition:background-color var(--speed),color var(--speed);
    \\&::-webkit-details-marker{display:none}}
    \\&>summary:hover,&[open]>summary{background:var(--fill);color:var(--label)}
    \\&[open]>summary::after{content:"";position:fixed;inset:0;z-index:30;cursor:default}}
    \\.zw-path .zw-path-menu{position:absolute;top:100%;left:0;z-index:31;display:flex;flex-direction:column;gap:1px;min-width:180px;max-width:min(320px,calc(100vw - 32px));margin:6px 0 0;padding:6px;
    \\list-style:none;border-radius:var(--radius);--glass:var(--glass-thick);animation:zw-path-in var(--dur-bouncy) var(--spring-bouncy);transform-origin:top left}
    \\@keyframes zw-path-in{from{opacity:0;scale:.92;translate:0 -6px}}
    \\.zw-path-menu a{display:flex;max-width:none;padding:4px 10px;border-radius:8px;color:var(--label);&:is(:hover,:focus-visible){background:var(--accent);color:var(--on-accent)}}
    \\
;

pub const Item = struct {
    label: []const u8,
    /// Link target. Empty: the item is shown as plain text, not a link.
    href: []const u8 = "",
    /// A short glyph (such as "⌂") shown before the label; it is decoration, hidden from screen readers.
    icon: []const u8 = "",
    /// z.js request for the link, so a click updates part of the page instead of loading it. Keep a real
    /// `href` too: it is the fallback without JS. Ignored on the last item and on plain-text items.
    z: Z = .{},
};

pub const Separator = enum { chevron, slash };

pub const Props = struct {
    items: []const Item,
    label: []const u8 = "Path",
    separator: Separator = .chevron,
    /// Most items to show. A longer path keeps the first item and the last `max - 1`, and folds the
    /// rest into a "…" menu. 0 shows everything; values below 2 are treated as 2.
    max: usize = 0,
};

const inner = "{#if it.icon}<span class=\"zw-path-icon\" aria-hidden=\"true\">{it.icon}</span>{/if}<span class=\"zw-path-label\">{it.label}</span>";
const link = "<li>{#if it.href}<a href=\"{it.href}\"{it.z}>" ++ inner ++ "</a>{:else}<span class=\"zw-path-text\">" ++ inner ++ "</span>{/if}</li>";

const src = "{#if has}<nav class=\"zw-path zw-path--{p.separator}\" aria-label=\"{p.label}\"><ol>" ++
    "{#each lead as it}" ++ link ++ "{/each}" ++
    "{#if hidden}<li><details class=\"zw-path-more\"><summary aria-label=\"{hidden.len} more\">…</summary><ul class=\"zw-path-menu zw-glass\">" ++
    "{#each hidden as it}<li>{#if it.href}<a href=\"{it.href}\"{it.z}>" ++ inner ++ "</a>{:else}<span class=\"zw-path-text\">" ++ inner ++ "</span>{/if}</li>{/each}</ul></details></li>{/if}" ++
    "{#each tail as it}" ++ link ++ "{/each}" ++
    "{#each last as it}<li><span aria-current=\"page\">" ++ inner ++ "</span></li>{/each}</ol></nav>{/if}";

const Data = struct { has: bool, p: Props, lead: []const Item, hidden: []const Item, tail: []const Item, last: []const Item };

pub const Path = zv.View(src, Data);

/// `path(.{ .items = &.{ .{ .label = "Docs", .href = "/" }, .{ .label = "Button" } } })`
/// An empty `items` renders nothing (no empty landmark).
pub fn path(p: Props) Path {
    const n = p.items.len;
    const has = n > 0;
    const last = p.items[n -| 1..];
    if (p.max != 0 and n > @max(p.max, 2)) {
        const keep = @max(p.max, 2) - 1; // trailing items shown, the current page included
        return .{ .data = .{ .has = has, .p = p, .lead = p.items[0..1], .hidden = p.items[1 .. n - keep], .tail = p.items[n - keep .. n - 1], .last = last } };
    }
    return .{ .data = .{ .has = has, .p = p, .lead = p.items[0..n -| 1], .hidden = p.items[0..0], .tail = p.items[0..0], .last = last } };
}

test path {
    const items: []const Item = &.{
        .{ .label = "Home", .href = "/", .icon = "⌂" },
        .{ .label = "A", .href = "/a" },
        .{ .label = "B & C", .href = "/b" },
        .{ .label = "D", .href = "/d" },
        .{ .label = "Here" },
    };
    var buf: [4096]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try path(.{ .items = items, .max = 3, .separator = .slash }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "zw-path zw-path--slash") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-label=\"2 more\">…</summary>") != null);
    try std.testing.expect(std.mem.find(u8, out, "B &amp; C") != null);
    try std.testing.expect(std.mem.find(u8, out, "<span aria-current=\"page\"><span class=\"zw-path-label\">Here</span>") != null);
    // "A" and "B & C" are folded into the menu; "D" stays in the bar after it
    try std.testing.expect(std.mem.find(u8, out, "</details></li><li><a href=\"/d\">") != null);

    w = .fixed(&buf);
    try path(.{ .items = items }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "zw-path-more") == null);

    // z.js attributes reach bar links and folded links, never the current page
    const zitems: []const Item = &.{
        .{ .label = "Home", .href = "/", .z = .{ .get = "/h", .target = "#main" } },
        .{ .label = "A", .href = "/a", .z = .{ .get = "/a", .target = "#main" } },
        .{ .label = "B", .href = "/b" },
        .{ .label = "Here", .href = "/here", .z = .{ .get = "/here" } },
    };
    w = .fixed(&buf);
    try path(.{ .items = zitems, .max = 3 }).render(&w);
    const zout = w.buffered();
    try std.testing.expect(std.mem.find(u8, zout, "<a href=\"/\" z-get=\"/h\" z-target=\"#main\">") != null);
    try std.testing.expect(std.mem.find(u8, zout, "<a href=\"/a\" z-get=\"/a\" z-target=\"#main\">") != null);
    try std.testing.expect(std.mem.find(u8, zout, "z-get=\"/here\"") == null);

    // no items: nothing is rendered
    w = .fixed(&buf);
    try path(.{ .items = &.{} }).render(&w);
    try std.testing.expectEqual(@as(usize, 0), w.buffered().len);
}
