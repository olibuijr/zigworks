//! Slider: native range input (keyboard, form value), fully restyled. The filled track follows
//! the value via z.js (`--zw-fill`); the server writes the starting fill too, so it renders
//! correctly without JS (the knob is then the native thumb). Optional tick marks, end labels and
//! a value readout; the readout follows the thumb with z.js.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-slider,.zw-slider-track{position:relative;display:flex;align-items:center;min-width:0;min-height:var(--control-h)}
    \\.zw-slider{--zw-b:var(--dur-bouncy) var(--spring-bouncy);--zw-ring:0 0 0 3.5px color-mix(in srgb,var(--accent) 50%,transparent);--zw-thumb:0 0 0 .5px rgba(0,0,0,.06),0 2px 6px rgba(0,0,0,.18);gap:10px}
    \\.zw-slider-track{flex:1}
    \\.zw-slider input{appearance:none;flex:1;width:100%;min-width:0;height:var(--control-h);background:transparent;cursor:default;
    \\--zw-track:linear-gradient(var(--accent),var(--accent)) 0/var(--zw-fill,50%) 100% no-repeat,var(--fill-strong);
    \\&::-webkit-slider-runnable-track{height:6px;border-radius:3px;box-shadow:inset 0 .5px 1px rgba(0,0,0,.1);background:var(--zw-track)}
    \\&::-moz-range-track{height:6px;border-radius:3px;box-shadow:inset 0 .5px 1px rgba(0,0,0,.1);background:var(--zw-track)}
    \\&::-webkit-slider-thumb{appearance:none;width:28px;height:18px;margin-top:-6px;border-radius:9px;background:var(--knob);box-shadow:var(--zw-thumb)}
    \\&::-moz-range-thumb{width:28px;height:18px;border:0;border-radius:9px;background:var(--knob);box-shadow:var(--zw-thumb)}
    \\&:focus-visible{outline:none}
    \\&:focus-visible::-webkit-slider-thumb{box-shadow:var(--zw-ring)}
    \\&:focus-visible::-moz-range-thumb{box-shadow:var(--zw-ring)}
    \\.zw-js &::-webkit-slider-thumb{opacity:0}
    \\.zw-js &::-moz-range-thumb{opacity:0}}
    \\.zw-slider-knob{display:none}
    \\.zw-js .zw-slider-knob{display:block;position:absolute;top:50%;left:calc(var(--zw-f,.5) * (100% - 28px));width:28px;height:18px;margin:-9px 0 0;border-radius:9px;pointer-events:none;
    \\background:var(--knob);box-shadow:0 0 0 .5px rgba(0,0,0,.06),0 .5px 1px rgba(0,0,0,.12),0 2px 6px rgba(0,0,0,.18);
    \\transition:width var(--zw-b),height var(--zw-b),margin var(--zw-b),border-radius var(--zw-b),background-color var(--speed),box-shadow var(--speed)}
    \\.zw-slider input:focus-visible~.zw-slider-knob{box-shadow:var(--zw-ring),0 2px 6px rgba(0,0,0,.18)}
    \\.zw-slider input:not(:disabled):active~.zw-slider-knob{width:40px;height:26px;margin:-13px 0 0 -6px;border-radius:13px;background:var(--glass-clear);
    \\box-shadow:var(--glass-rim),0 0 0 .5px rgba(0,0,0,.08),0 4px 12px rgba(0,0,0,.18);-webkit-backdrop-filter:var(--glass-filter-clear);backdrop-filter:var(--glass-filter-clear);
    \\transition-duration:var(--dur-snappy);transition-timing-function:var(--spring-snappy);
    \\.zw-refract &{backdrop-filter:url(#zw-lens-thumb) var(--glass-filter-clear)}}
    \\.zw-slider-ticks{position:absolute;left:14px;right:13px;top:calc(50% + 9px);height:5px;pointer-events:none;
    \\background:repeating-linear-gradient(90deg,var(--tertiary) 0 1px,transparent 1px calc((100% - 1px) / var(--ticks)))}
    \\.zw-slider-end,.zw-slider-value{flex:none;color:var(--secondary)}
    \\.zw-slider-end{font:var(--callout);white-space:nowrap}
    \\.zw-slider-value{min-width:3ch;text-align:end;font:var(--body);font-variant-numeric:tabular-nums}
    \\.zw-slider.is-disabled{opacity:.4}
    \\@media (pointer:coarse){.zw-slider,.zw-slider-track{min-height:44px}.zw-slider input{height:44px}}
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
    /// Dim the slider and ignore input.
    disabled: bool = false,
    /// Tick marks: the number of intervals along the track (`4` draws 5 marks). `0` draws none.
    /// Pick a count that divides the range by `step`, so the thumb lands on the marks.
    ticks: u8 = 0,
    /// Text before and after the track (`"Quiet"`, `"Loud"`). Plain text, escaped.
    min_label: []const u8 = "",
    max_label: []const u8 = "",
    /// Show the current value to the right; z.js keeps it in sync while dragging.
    show_value: bool = false,
    /// Appended to the value readout (`"%"`, `" pt"`).
    unit: []const u8 = "",
};

// The visible extras are aria-hidden: they sit inside the <label>, and the range input already announces its value.
const src = "<label class=\"zw-slider{#if p.disabled} is-disabled{/if}\"><span class=\"zw-sr\">{p.label}</span>" ++
    "{#if p.min_label}<span class=\"zw-slider-end\" aria-hidden=\"true\">{p.min_label}</span>{/if}" ++
    "<span class=\"zw-slider-track\" style=\"--zw-f:calc({pm} / 1000)\"><input type=\"range\" name=\"{p.name}\" min=\"{p.min}\" max=\"{p.max}\" step=\"{p.step}\" value=\"{p.value}\" style=\"--zw-fill:calc({pm} * .1%)\"{#if p.disabled} disabled{/if}{p.z}>" ++
    "<span class=\"zw-slider-knob\" aria-hidden=\"true\"></span>{#if p.ticks}<span class=\"zw-slider-ticks\" aria-hidden=\"true\" style=\"--ticks:{p.ticks}\"></span>{/if}</span>" ++
    "{#if p.max_label}<span class=\"zw-slider-end\" aria-hidden=\"true\">{p.max_label}</span>{/if}" ++
    "{#if p.show_value}<output class=\"zw-slider-value\" aria-hidden=\"true\" data-unit=\"{p.unit}\">{p.value}{p.unit}</output>{/if}</label>";

const Data = struct { p: Props, pm: i64 };

pub const Slider = zv.View(src, Data);

pub fn slider(p: Props) Slider {
    return .{ .data = .{ .p = p, .pm = permille(p) } };
}

/// Where the value sits between min and max, 0 to 1000 (the starting fill, before z.js runs).
fn permille(p: Props) i64 {
    if (p.max <= p.min) return 0;
    const v = std.math.clamp(p.value, p.min, p.max);
    return @intCast(@divTrunc((@as(i128, v) - p.min) * 1000, @as(i128, p.max) - p.min));
}

test "slider fill, ticks, labels and value" {
    try std.testing.expectEqual(@as(i64, 250), permille(.{ .name = "a", .label = "a", .min = 0, .max = 8, .value = 2 }));
    try std.testing.expectEqual(@as(i64, 1000), permille(.{ .name = "a", .label = "a", .value = 500 }));
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try slider(.{ .name = "v", .label = "Volume", .ticks = 4, .min_label = "Quiet", .max_label = "Loud", .show_value = true, .unit = "%", .disabled = true }).render(&w);
    const out = w.buffered();
    for ([_][]const u8{ "zw-slider is-disabled", "--ticks:4", ">Quiet<", ">Loud<", ">50%</output>", " disabled", "--zw-fill:calc(500 * .1%)" }) |needle| {
        try std.testing.expect(std.mem.find(u8, out, needle) != null);
    }
}
