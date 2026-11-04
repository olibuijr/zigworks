//! Slider: native range input (keyboard, form value), fully restyled. The filled track follows
//! the value via z.js (`--zw-fill`), so it renders correctly without JS too, just unfilled.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-slider{position:relative;display:flex;align-items:center;min-height:var(--control-h)}
    \\.zw-slider input{appearance:none;flex:1;height:6px;margin:0;border-radius:3px;box-shadow:inset 0 .5px 1px rgba(0,0,0,.1);
    \\background:linear-gradient(var(--accent),var(--accent)) 0/var(--zw-fill,50%) 100% no-repeat,var(--fill-strong)}
    \\.zw-slider input::-webkit-slider-thumb{appearance:none;width:28px;height:18px;border-radius:9px;background:var(--knob);box-shadow:0 0 0 .5px rgba(0,0,0,.06),0 2px 6px rgba(0,0,0,.18)}
    \\.zw-slider input::-moz-range-thumb{width:28px;height:18px;border:0;border-radius:9px;background:var(--knob);box-shadow:0 0 0 .5px rgba(0,0,0,.06),0 2px 6px rgba(0,0,0,.18)}
    \\.zw-slider input:focus-visible{outline:none}
    \\.zw-slider input:focus-visible::-webkit-slider-thumb{box-shadow:0 0 0 3.5px color-mix(in srgb,var(--accent) 50%,transparent)}
    \\.zw-slider-knob{display:none}
    \\.zw-js .zw-slider input::-webkit-slider-thumb{opacity:0}
    \\.zw-js .zw-slider input::-moz-range-thumb{opacity:0}
    \\.zw-js .zw-slider-knob{display:block;position:absolute;top:50%;left:calc(var(--zw-f,.5) * (100% - 28px));width:28px;height:18px;margin:-9px 0 0;border-radius:9px;pointer-events:none;
    \\background:var(--knob);box-shadow:0 0 0 .5px rgba(0,0,0,.06),0 .5px 1px rgba(0,0,0,.12),0 2px 6px rgba(0,0,0,.18);
    \\transition:width var(--dur-bouncy) var(--spring-bouncy),height var(--dur-bouncy) var(--spring-bouncy),margin var(--dur-bouncy) var(--spring-bouncy),
    \\border-radius var(--dur-bouncy) var(--spring-bouncy),background-color var(--speed),box-shadow var(--speed)}
    \\.zw-slider input:focus-visible~.zw-slider-knob{box-shadow:0 0 0 3.5px color-mix(in srgb,var(--accent) 50%,transparent),0 2px 6px rgba(0,0,0,.18)}
    \\.zw-slider input:active~.zw-slider-knob{width:40px;height:26px;margin:-13px 0 0 -6px;border-radius:13px;background:var(--glass-clear);
    \\box-shadow:var(--glass-rim),0 0 0 .5px rgba(0,0,0,.08),0 4px 12px rgba(0,0,0,.18);-webkit-backdrop-filter:var(--glass-filter-clear);backdrop-filter:var(--glass-filter-clear);
    \\transition-duration:var(--dur-snappy);transition-timing-function:var(--spring-snappy)}
    \\.zw-refract .zw-slider input:active~.zw-slider-knob{backdrop-filter:url(#zw-lens-thumb) var(--glass-filter-clear)}
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

const src = "<label class=\"zw-slider\"><span class=\"zw-sr\">{label}</span><input type=\"range\" name=\"{name}\" min=\"{min}\" max=\"{max}\" step=\"{step}\" value=\"{value}\"{z}><span class=\"zw-slider-knob\" aria-hidden=\"true\"></span></label>";

pub const Slider = zv.View(src, Props);

pub fn slider(p: Props) Slider {
    return .{ .data = p };
}
