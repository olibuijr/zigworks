//! macOS switch row. A real checkbox (form value, keyboard, screen readers) drawn as a switch;
//! laid out like `setting`, so switches and settings rows stack with separators.
//! With `z`, z.js sends `name=on` when switched on and nothing when off.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-toggle{cursor:default;user-select:none}
    \\.zw-toggle input{appearance:none;flex:none;position:relative;width:38px;height:22px;margin:0;border-radius:11px;background:var(--fill-strong);
    \\box-shadow:inset 0 0 0 .5px var(--separator);transition:background var(--speed)}
    \\.zw-toggle input::after{content:"";position:absolute;top:2px;left:2px;width:18px;height:18px;border-radius:50%;background:#fff;
    \\box-shadow:0 0 0 .5px rgba(0,0,0,.06),0 1px 2px rgba(0,0,0,.2);transition:transform var(--speed) cubic-bezier(.3,.7,.4,1.2)}
    \\.zw-toggle input:checked{background:var(--accent)}
    \\.zw-toggle input:checked::after{transform:translateX(16px)}
    \\.zw-toggle input:active::after{width:22px}.zw-toggle input:checked:active::after{transform:translateX(12px)}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    on: bool = false,
    z: Z = .{},
};

const src = "<label class=\"zw-toggle zw-setting\"><span>{label}</span><input type=\"checkbox\" role=\"switch\" name=\"{name}\"{#if on} checked{/if}{z}></label>";

pub const Toggle = zv.View(src, Props);

pub fn toggle(p: Props) Toggle {
    return .{ .data = p };
}
