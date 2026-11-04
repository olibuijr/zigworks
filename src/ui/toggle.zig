//! macOS switch row. A real checkbox (form value, keyboard, screen readers) drawn as a switch;
//! laid out like `setting`, so switches and settings rows stack with separators.
//! With `z`, z.js sends `name=on` when switched on and nothing when off.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-toggle{cursor:default;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-toggle input{appearance:none;flex:none;position:relative;width:46px;height:26px;margin:0;border-radius:13px;background:var(--fill-strong);overflow:visible;
    \\box-shadow:inset 0 0 0 .5px var(--separator),inset 0 1px 2px rgba(0,0,0,.08);transition:background-color var(--speed)}
    \\.zw-toggle input::after{content:"";position:absolute;top:2px;left:2px;width:28px;height:22px;border-radius:11px;background:var(--knob);
    \\box-shadow:0 0 0 .5px rgba(0,0,0,.04),0 .5px 1px rgba(0,0,0,.12),0 2px 6px rgba(0,0,0,.16);
    \\transition:translate var(--dur-bouncy) var(--spring-bouncy),inset var(--dur-bouncy) var(--spring-bouncy),width var(--dur-bouncy) var(--spring-bouncy),height var(--dur-bouncy) var(--spring-bouncy),
    \\border-radius var(--dur-bouncy) var(--spring-bouncy),background-color var(--speed),box-shadow var(--speed)}
    \\.zw-toggle input:checked{background:var(--accent)}
    \\.zw-toggle input:checked::after{translate:14px 0}
    \\.zw-toggle:active input::after{top:-2px;left:-3px;width:38px;height:30px;border-radius:15px;background:var(--glass-clear);box-shadow:var(--glass-rim),0 0 0 .5px rgba(0,0,0,.08),0 4px 12px rgba(0,0,0,.18);
    \\-webkit-backdrop-filter:var(--glass-filter-clear);backdrop-filter:var(--glass-filter-clear);transition-duration:var(--dur-snappy);transition-timing-function:var(--spring-snappy)}
    \\.zw-refract .zw-toggle:active input::after{backdrop-filter:url(#zw-lens-knob) var(--glass-filter-clear)}
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
