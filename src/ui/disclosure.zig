//! Disclosure: a titled section that opens and closes (macOS disclosure triangle). Built on
//! <details>, so it works without JS; the chevron and the height spring open. Give several the
//! same `name` and they form an accordion: opening one closes the others.
const std = @import("std");
const Writer = std.Io.Writer;
const zv = @import("../view.zig");

pub const css =
    \\.zw-disclosure{interpolate-size:allow-keywords}
    \\.zw-disclosure>summary{display:flex;align-items:center;gap:8px;min-height:30px;list-style:none;font:var(--body);font-weight:600;cursor:default;user-select:none;border-radius:var(--radius-control);padding:0 6px;margin:0 -6px;
    \\-webkit-tap-highlight-color:transparent;transition:background-color var(--speed)}
    \\.zw-disclosure>summary::-webkit-details-marker{display:none}
    \\.zw-disclosure>summary::before{content:"";flex:none;width:6px;height:6px;margin:0 3px 0 2px;border:solid var(--secondary);border-width:0 1.75px 1.75px 0;rotate:-45deg;
    \\transition:rotate var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-disclosure[open]>summary::before{rotate:45deg}
    \\.zw-disclosure>summary:hover{background:var(--fill)}
    \\.zw-disclosure>summary:active{background:color-mix(in srgb,var(--fill) 70%,var(--separator))}
    \\.zw-disclosure>summary:focus-visible{outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent)}
    \\.zw-disclosure-title{flex:1 1 auto;min-width:0;overflow-wrap:anywhere}
    \\.zw-disclosure-detail{flex:none;margin-left:auto;max-width:50%;font:var(--callout);color:var(--secondary);text-align:end;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.zw-disclosure::details-content{height:0;opacity:0;overflow:clip;transition:height var(--dur) var(--spring),opacity 200ms ease,content-visibility var(--dur) allow-discrete}
    \\.zw-disclosure[open]::details-content{height:auto;opacity:1}
    \\.zw-disclosure-body{padding:6px 0 4px 21px}
    \\.zw-disclosure--card{padding:4px;background:var(--content);border-radius:var(--radius);box-shadow:var(--shadow)}
    \\.zw-disclosure--card>summary{margin:0;padding:0 8px;min-height:36px}
    \\.zw-disclosure--card>.zw-disclosure-body{padding:6px 8px 8px 29px}
    \\.zw-disclosure--card+.zw-disclosure--card{margin-top:8px}
    \\@media (pointer:coarse){.zw-disclosure>summary{min-height:44px}}
    \\
;

pub const Style = enum {
    /// No surface: for sections inside a card or a page.
    plain,
    /// An opaque content surface, like a card, for stand-alone sections and FAQ lists.
    card,
};

pub fn Props(comptime Body: type) type {
    return struct {
        title: []const u8,
        open: bool = false,
        body: Body,
        /// Disclosures with the same name are exclusive: opening one closes the others.
        name: []const u8 = "",
        /// Secondary text at the trailing edge of the title row, such as a count or a value.
        detail: []const u8 = "",
        style: Style = .plain,
    };
}

const src = "<details class=\"zw-disclosure zw-disclosure--{style}\"{#if name} name=\"{name}\"{/if}{#if open} open{/if}><summary><span class=\"zw-disclosure-title\">{title}</span>" ++
    "{#if detail}<span class=\"zw-disclosure-detail\">{detail}</span>{/if}</summary><div class=\"zw-disclosure-body\">{body}</div></details>";

pub fn Disclosure(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

/// `disclosure(.{ .title = "Advanced", .body = ... })`
pub fn disclosure(p: anytype) Disclosure(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}

test disclosure {
    var buf: [1024]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try disclosure(.{ .title = "T & Q", .name = "faq", .detail = "3 items", .style = .card, .open = true, .body = "x" }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "class=\"zw-disclosure zw-disclosure--card\" name=\"faq\" open>") != null);
    try std.testing.expect(std.mem.find(u8, out, "<span class=\"zw-disclosure-title\">T &amp; Q</span><span class=\"zw-disclosure-detail\">3 items</span>") != null);
    w = .fixed(&buf);
    try disclosure(.{ .title = "T", .body = "x" }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "zw-disclosure--plain\"><summary>") != null);
}
