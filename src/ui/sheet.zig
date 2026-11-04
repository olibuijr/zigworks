//! Sheet: a modal-style panel opened by `button(.{ .opens = id })`. Popover API: Esc and
//! outside click dismiss it, no JS. Put a form in `body`; z.js closes the sheet after it submits.
const zv = @import("../view.zig");

pub const css =
    \\.zw-sheet{inset:0 0 auto;margin:68px auto 0;width:min(480px,calc(100vw - 32px));padding:22px;border:0;border-radius:var(--radius-panel);color:var(--label);--glass:var(--glass-thick);
    \\transform-origin:top center;transition:opacity 200ms ease,scale var(--dur-bouncy) var(--spring-bouncy),translate var(--dur) var(--spring),display 320ms allow-discrete,overlay 320ms allow-discrete}
    \\.zw-sheet:not(:popover-open){opacity:0;scale:.94;translate:0 -12px;transition-duration:180ms}
    \\@starting-style{.zw-sheet:popover-open{opacity:0;scale:.9;translate:0 -28px}}
    \\.zw-sheet::backdrop{background:rgba(0,0,0,.18);transition:background-color 250ms,display 320ms allow-discrete,overlay 320ms allow-discrete}
    \\.zw-sheet:not(:popover-open)::backdrop{background:transparent}
    \\@starting-style{.zw-sheet:popover-open::backdrop{background:transparent}}
    \\.zw-sheet h2{font:var(--headline);margin-bottom:14px}
    \\.zw-sheet-actions{display:flex;justify-content:flex-end;gap:8px;margin-top:20px}
    \\
;

const src = "<div class=\"zw-sheet zw-glass\" id=\"{id}\" popover role=\"dialog\" aria-label=\"{title}\"><h2>{title}</h2>{body}</div>";

pub fn Props(comptime Body: type) type {
    return struct { id: []const u8, title: []const u8, body: Body };
}

pub fn Sheet(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

pub fn sheet(p: anytype) Sheet(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}
