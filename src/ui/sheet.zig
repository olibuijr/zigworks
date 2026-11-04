//! Sheet: a modal-style panel opened by `button(.{ .opens = id })`. Popover API: Esc and
//! outside click dismiss it, no JS. Put a form in `body`; z.js closes the sheet after it submits.
const zv = @import("../view.zig");

pub const css =
    \\.zw-sheet{inset:0 0 auto;margin:52px auto 0;width:min(480px,calc(100vw - 32px));padding:20px;border:0;border-radius:0 0 calc(var(--radius) + 4px) calc(var(--radius) + 4px);
    \\color:var(--label);background:var(--content);box-shadow:0 0 0 .5px rgba(0,0,0,.15),0 20px 50px rgba(0,0,0,.25)}
    \\.zw-sheet:popover-open{animation:zw-sheet 220ms cubic-bezier(.2,.8,.2,1)}
    \\@keyframes zw-sheet{from{transform:translateY(-16px);opacity:0}}
    \\.zw-sheet::backdrop{background:rgba(0,0,0,.18)}
    \\.zw-sheet h2{font:var(--headline);margin-bottom:14px}
    \\.zw-sheet-actions{display:flex;justify-content:flex-end;gap:8px;margin-top:20px}
    \\
;

const src = "<div class=\"zw-sheet\" id=\"{id}\" popover role=\"dialog\" aria-label=\"{title}\"><h2>{title}</h2>{body}</div>";

pub fn Props(comptime Body: type) type {
    return struct { id: []const u8, title: []const u8, body: Body };
}

pub fn Sheet(comptime Body: type) type {
    return zv.View(src, Props(Body));
}

pub fn sheet(p: anytype) Sheet(@FieldType(@TypeOf(p), "body")) {
    return .{ .data = zv.props(Props(@FieldType(@TypeOf(p), "body")), p) };
}
