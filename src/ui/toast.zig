//! Toast: a short glass notification that drops in at the top and leaves by itself after 4 s.
//! Send it from a handler next to your response; it is an out-of-band append into the layout's
//! toast area: `try c.html("{row}{toast}", .{ .row = ..., .toast = ui.toast(.{ .text = "Saved" }) })`.
//! It can carry one action button (Undo) and, with `sticky`, stays until dismissed.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-toasts{position:fixed;top:12px;left:50%;translate:-50% 0;z-index:50;display:flex;flex-direction:column;align-items:center;gap:8px;pointer-events:none;width:max-content;max-width:calc(100vw - 32px)}
    \\.zw-toast{display:flex;align-items:center;gap:10px;min-height:40px;max-width:100%;padding:8px 16px 8px 12px;border-radius:999px;font:var(--body);font-weight:500;color:var(--label);
    \\--glass:var(--glass-thick);pointer-events:auto;animation:zw-toast-in var(--dur-bouncy) var(--spring-bouncy) both}
    \\.zw-toast-host{display:contents}
    \\.zw-toast-text{min-width:0;overflow-wrap:anywhere}
    \\.zw-toast-icon{position:relative;flex:none;width:16px;height:16px;border-radius:50%;background:var(--c,var(--accent));box-shadow:0 0 8px color-mix(in srgb,var(--c,var(--accent)) 55%,transparent)}
    \\.zw-toast-icon::before{content:"";position:absolute;inset:0;background:#fff;mask:var(--g) center/100% no-repeat}
    \\.zw-toast--info{--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='black' stroke-width='1.8' stroke-linecap='round'%3E%3Cpath d='M8 7.4v4M8 4.9v.1'/%3E%3C/svg%3E")}
    \\.zw-toast--success{--c:var(--green);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='black' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M4.7 8.3l2.2 2.2 4.4-4.8'/%3E%3C/svg%3E")}
    \\.zw-toast--warning{--c:var(--orange);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='black' stroke-width='1.8' stroke-linecap='round'%3E%3Cpath d='M8 4.4v4M8 11.2v.1'/%3E%3C/svg%3E")}
    \\.zw-toast--error{--c:var(--red);--g:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='black' stroke-width='1.8' stroke-linecap='round'%3E%3Cpath d='M5.6 5.6l4.8 4.8M10.4 5.6l-4.8 4.8'/%3E%3C/svg%3E")}
    \\.zw-toast-action{appearance:none;flex:none;height:28px;margin:-4px -8px -4px 0;padding:0 10px;border:0;border-radius:999px;background:transparent;color:var(--accent);font:inherit;font-weight:600;cursor:default;white-space:nowrap}
    \\.zw-toast-action:hover{background:var(--fill)}
    \\.zw-toast-x{appearance:none;position:relative;flex:none;width:28px;height:28px;margin:-4px -8px -4px -4px;border:0;border-radius:50%;background:transparent;cursor:default}
    \\.zw-toast-x::before{content:"";position:absolute;left:50%;top:50%;width:22px;height:22px;translate:-50% -50%;border-radius:50%;transition:background-color var(--speed);
    \\background:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10' fill='none' stroke='%23888' stroke-width='1.6' stroke-linecap='round'%3E%3Cpath d='M2.5 2.5l5 5M7.5 2.5l-5 5'/%3E%3C/svg%3E") center/10px no-repeat var(--fill)}
    \\.zw-toast-x:hover::before{background-color:var(--fill-strong)}
    \\.zw-toast:has(.zw-toast-x:checked){display:none}
    \\@media (pointer:coarse){.zw-toast{min-height:44px}.zw-toast-action{height:44px;margin-block:-8px}.zw-toast-x{width:44px;height:44px;margin-block:-8px}}
    \\.zw-toast.zw-leave{animation:zw-toast-out 260ms ease both}
    \\@keyframes zw-toast-in{from{opacity:0;translate:0 -24px;scale:.85}}
    \\@keyframes zw-toast-out{to{opacity:0;translate:0 -12px;scale:.92}}
    \\
;

pub const Kind = enum { info, success, warning, @"error" };

pub const Props = struct {
    text: []const u8,
    kind: Kind = .info,
    /// Label of an action button, such as "Undo". It fires `z`.
    action: []const u8 = "",
    /// What the action button does. To close the toast afterwards, use
    /// `.swap = .delete, .target = "closest .zw-toast"`.
    z: Z = .{},
    /// Stay until dismissed: no auto-dismiss, and a close button is shown.
    sticky: bool = false,
};

const Data = struct { p: Props, role: []const u8 };

const src = "<div id=\"zw-toasts\" z-oob=\"beforeend\">{#if p.sticky}<div class=\"zw-toast-host\">{/if}" ++
    "<div class=\"zw-toast zw-toast--{p.kind} zw-glass\" role=\"{role}\"><span class=\"zw-toast-icon\" aria-hidden=\"true\"></span><span class=\"zw-toast-text\">{p.text}</span>" ++
    "{#if p.action}<button type=\"button\" class=\"zw-toast-action zw-press\"{p.z}>{p.action}</button>{/if}" ++
    "{#if p.sticky}<input type=\"checkbox\" role=\"button\" class=\"zw-toast-x\" aria-label=\"Dismiss\">{/if}</div>{#if p.sticky}</div>{/if}</div>";

pub const Toast = zv.View(src, Data);

/// Errors are announced at once (`alert`); everything else politely (`status`).
pub fn toast(p: Props) Toast {
    return .{ .data = .{ .p = p, .role = if (p.kind == .@"error") "alert" else "status" } };
}

fn expectHas(p: Props, needle: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try toast(p).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), needle) != null);
}

test "kinds, action and sticky" {
    try expectHas(.{ .text = "x", .kind = .warning }, "zw-toast--warning zw-glass\" role=\"status\"");
    try expectHas(.{ .text = "x", .kind = .@"error" }, "role=\"alert\"");
    try expectHas(.{ .text = "x", .action = "Undo", .z = .{ .post = "/undo" } }, "<button type=\"button\" class=\"zw-toast-action zw-press\" z-post=\"/undo\">Undo</button>");
    try expectHas(.{ .text = "x", .sticky = true }, "class=\"zw-toast-host\"");
}
