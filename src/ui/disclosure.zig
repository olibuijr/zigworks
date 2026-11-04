//! Disclosure: a titled section that opens and closes (macOS disclosure triangle). Built on
//! <details>, so it works without JS; the chevron and the height spring open.
const zv = @import("../view.zig");

pub const css =
    \\.zw-disclosure{interpolate-size:allow-keywords}
    \\.zw-disclosure>summary{display:flex;align-items:center;gap:8px;min-height:30px;list-style:none;font:var(--body);font-weight:600;cursor:default;user-select:none;border-radius:var(--radius-control);padding:0 6px;margin:0 -6px}
    \\.zw-disclosure>summary::-webkit-details-marker{display:none}
    \\.zw-disclosure>summary::before{content:"";flex:none;width:6px;height:6px;margin:0 3px 0 2px;border:solid var(--secondary);border-width:0 1.75px 1.75px 0;rotate:-45deg;
    \\transition:rotate var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-disclosure[open]>summary::before{rotate:45deg}
    \\.zw-disclosure>summary:hover{background:var(--fill)}
    \\.zw-disclosure>summary:focus-visible{outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent)}
    \\.zw-disclosure::details-content{height:0;opacity:0;overflow:clip;transition:height var(--dur) var(--spring),opacity 200ms ease,content-visibility var(--dur) allow-discrete}
    \\.zw-disclosure[open]::details-content{height:auto;opacity:1}
    \\.zw-disclosure-body{padding:6px 0 4px 21px}
    \\
;

pub fn Props(comptime Body: type) type {
    return struct { title: []const u8, open: bool = false, body: Body };
}

const src = "<details class=\"zw-disclosure\"{#if open} open{/if}><summary>{title}</summary><div class=\"zw-disclosure-body\">{body}</div></details>";

pub fn Disclosure(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

/// `disclosure(.{ .title = "Advanced", .body = ... })`
pub fn disclosure(p: anytype) Disclosure(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}
