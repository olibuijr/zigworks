//! Slider: native range input (keyboard, form value), fully restyled. The filled track follows
//! the value via z.js (`--zw-fill`), so it renders correctly without JS too, just unfilled.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-slider{display:flex;align-items:center;gap:12px;min-height:var(--control-h)}
    \\.zw-slider input{appearance:none;flex:1;height:4px;margin:0;border-radius:2px;background:linear-gradient(var(--accent),var(--accent)) 0/var(--zw-fill,0%) 100% no-repeat,var(--fill-strong)}
    \\.zw-slider input::-webkit-slider-thumb{appearance:none;width:20px;height:20px;border-radius:50%;background:#fff;box-shadow:0 0 0 .5px rgba(0,0,0,.1),0 1px 3px rgba(0,0,0,.25)}
    \\.zw-slider input::-moz-range-thumb{width:20px;height:20px;border:0;border-radius:50%;background:#fff;box-shadow:0 0 0 .5px rgba(0,0,0,.1),0 1px 3px rgba(0,0,0,.25)}
    \\.zw-slider input:focus-visible{outline:none}
    \\.zw-slider input:focus-visible::-webkit-slider-thumb{box-shadow:0 0 0 3.5px color-mix(in srgb,var(--accent) 50%,transparent)}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    min: i64 = 0,
    max: i64 = 100,
    step: i64 = 1,
    value: i64 = 50,
    z: Z = .{},
};

const src = "<label class=\"zw-slider\"><span class=\"zw-sr\">{label}</span><input type=\"range\" name=\"{name}\" min=\"{min}\" max=\"{max}\" step=\"{step}\" value=\"{value}\"{z}></label>";

pub const Slider = zv.View(src, Props);

pub fn slider(p: Props) Slider {
    return .{ .data = p };
}
