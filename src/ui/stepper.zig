//! Stepper: a number field with − and + buttons (macOS NSStepper with its text field).
//! The buttons need z.js; without it the field still takes typed numbers. Each step fires
//! `input` and `change`, so a `z` request (trigger `change`) saves the value.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-stepper{display:inline-flex;align-items:center;gap:6px}
    \\.zw-stepper input{appearance:none;-moz-appearance:textfield;width:56px;height:var(--control-h);padding:0 8px;border:0;border-radius:var(--radius-control);text-align:center;
    \\font:var(--body);font-variant-numeric:tabular-nums;color:var(--label);background:var(--content);box-shadow:var(--shadow);outline:none;transition:box-shadow var(--dur) var(--spring)}
    \\.zw-stepper input:focus{box-shadow:0 0 0 .5px var(--accent),0 0 0 4px color-mix(in srgb,var(--accent) 40%,transparent)}
    \\.zw-stepper input::-webkit-inner-spin-button,.zw-stepper input::-webkit-outer-spin-button{appearance:none;margin:0}
    \\.zw-stepper-btns{display:inline-flex;height:var(--control-h);border-radius:999px;padding:0}
    \\.zw-stepper-btns button{appearance:none;width:34px;height:100%;border:0;background:transparent;color:var(--label);font:500 16px/1 var(--font);cursor:default;
    \\border-radius:999px;transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-stepper-btns button:hover{background:var(--fill)}
    \\.zw-stepper-btns button:active{scale:1.15;background:var(--fill-strong);transition-duration:var(--dur-snappy)}
    \\.zw-stepper-btns button+button{box-shadow:-.5px 0 0 var(--separator)}
    \\.zw-stepper-btns button:disabled{opacity:.35}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    value: i64 = 0,
    min: i64 = 0,
    max: i64 = 100,
    step: i64 = 1,
    z: Z = .{},
};

const src = "<span class=\"zw-stepper\"><input type=\"number\" inputmode=\"numeric\" name=\"{name}\" aria-label=\"{label}\" value=\"{value}\" min=\"{min}\" max=\"{max}\" step=\"{step}\"{z}>" ++
    "<span class=\"zw-stepper-btns zw-glass\"><button type=\"button\" data-step=\"-1\" aria-label=\"Decrease {label}\" tabindex=\"-1\">−</button>" ++
    "<button type=\"button\" data-step=\"1\" aria-label=\"Increase {label}\" tabindex=\"-1\">+</button></span></span>";

pub const Stepper = zv.View(src, Props);

/// `stepper(.{ .name = "copies", .label = "Copies", .value = 1, .min = 1, .max = 99 })`
pub fn stepper(p: Props) Stepper {
    return .{ .data = p };
}
