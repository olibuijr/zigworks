//! Toast: a short glass notification that drops in at the top and leaves by itself after 4 s.
//! Send it from a handler next to your response; it is an out-of-band append into the layout's
//! toast area: `try c.html("{row}{toast}", .{ .row = ..., .toast = ui.toast(.{ .text = "Saved" }) })`.
const zv = @import("../view.zig");

pub const css =
    \\.zw-toasts{position:fixed;top:12px;left:50%;translate:-50% 0;z-index:50;display:flex;flex-direction:column;align-items:center;gap:8px;pointer-events:none;width:max-content;max-width:calc(100vw - 32px)}
    \\.zw-toast{display:flex;align-items:center;gap:10px;min-height:40px;padding:8px 16px 8px 12px;border-radius:999px;font:var(--body);font-weight:500;color:var(--label);
    \\--glass:var(--glass-thick);pointer-events:auto;animation:zw-toast-in var(--dur-bouncy) var(--spring-bouncy) both}
    \\.zw-toast::after{content:"";order:-1;flex:none;width:8px;height:8px;border-radius:50%;background:var(--c,var(--accent));box-shadow:0 0 8px var(--c,var(--accent))}
    \\.zw-toast--success{--c:var(--green)}.zw-toast--error{--c:var(--red)}
    \\.zw-toast.zw-leave{animation:zw-toast-out 260ms ease both}
    \\@keyframes zw-toast-in{from{opacity:0;translate:0 -24px;scale:.85}}
    \\@keyframes zw-toast-out{to{opacity:0;translate:0 -12px;scale:.92}}
    \\
;

pub const Kind = enum { info, success, @"error" };

pub const Props = struct { text: []const u8, kind: Kind = .info };

const src = "<div id=\"zw-toasts\" z-oob=\"beforeend\"><div class=\"zw-toast zw-toast--{kind} zw-glass\" role=\"status\">{text}</div></div>";

pub const Toast = zv.View(src, Props);

pub fn toast(p: Props) Toast {
    return .{ .data = p };
}
