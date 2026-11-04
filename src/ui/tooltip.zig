//! Tooltip: a short glass hint shown when the pointer rests on (or focus enters) its content,
//! after the macOS delay. Replaces the browser's `title` tooltip. CSS only.
const zv = @import("../view.zig");

pub const css =
    \\.zw-tip{position:relative;display:inline-flex}
    \\.zw-tip-text{position:absolute;bottom:calc(100% + 8px);left:50%;z-index:30;width:max-content;max-width:240px;padding:5px 9px;border-radius:8px;pointer-events:none;
    \\font:var(--callout);color:var(--label);text-align:center;--glass:var(--glass-thick);opacity:0;translate:-50% 4px;scale:.92;transform-origin:bottom center;
    \\transition:opacity 120ms ease,translate var(--dur) var(--spring),scale var(--dur-bouncy) var(--spring-bouncy);transition-delay:0s}
    \\.zw-tip:hover>.zw-tip-text,.zw-tip:focus-within>.zw-tip-text{opacity:1;translate:-50% 0;scale:1;transition-delay:500ms}
    \\.zw-tip--below>.zw-tip-text{bottom:auto;top:calc(100% + 8px);translate:-50% -4px;transform-origin:top center}
    \\
;

pub const Side = enum { above, below };

pub fn Props(comptime Body: type) type {
    return struct { text: []const u8, side: Side = .above, body: Body };
}

const src = "<span class=\"zw-tip{#if below} zw-tip--below{/if}\">{p.body}<span class=\"zw-tip-text zw-glass\" role=\"tooltip\">{p.text}</span></span>";

fn Data(comptime Body: type) type {
    return struct { p: Props(Body), below: bool };
}

pub fn Tooltip(comptime Body: type) type {
    return zv.View(src, Data(Body));
}

/// `tooltip(.{ .text = "More actions", .body = ui.button(...) })`
pub fn tooltip(p: anytype) Tooltip(@FieldType(@TypeOf(p), "body")) {
    const P = Props(@FieldType(@TypeOf(p), "body"));
    const full = zv.props(P, p);
    return .{ .data = .{ .p = full, .below = full.side == .below } };
}
