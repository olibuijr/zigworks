//! Stepper: a number field with − and + buttons (macOS NSStepper with its text field).
//! The buttons need z.js; without it the field still takes typed numbers. Each step fires
//! `input` and `change`, so a `z` request (trigger `change`) saves the value.
//! Extras: a unit label, a read-only field, wrap-around (z.js reads `data-wrap`), disabled, invalid.
//! While a `z` request is in flight (`zw-busy` on the field) the buttons dim with it.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-stepper{display:inline-flex;align-items:center;gap:6px}
    \\.zw-stepper input{-moz-appearance:textfield;width:56px;height:var(--control-h);padding:0 8px;text-align:center;font-variant-numeric:tabular-nums;
    \\&::-webkit-inner-spin-button,&::-webkit-outer-spin-button{appearance:none;margin:0}
    \\&:is([aria-invalid=true],:user-invalid):not(:focus){box-shadow:0 0 0 1px var(--red)}
    \\&:read-only:not(:focus){background:transparent;box-shadow:none}}
    \\.zw-stepper-btns{display:inline-flex;height:var(--control-h);border-radius:999px;
    \\& button{appearance:none;width:34px;height:100%;border:0;background:transparent;color:var(--label);font:500 16px/1 var(--font);cursor:default;
    \\border-radius:999px;transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy);
    \\&:hover{background:var(--fill)}
    \\&:active{scale:1.15;background:var(--fill-strong);transition-duration:var(--dur-snappy)}
    \\&+button{box-shadow:-.5px 0 0 var(--separator)}
    \\&:disabled{opacity:.35}
    \\&:focus-visible{outline-offset:-2px}}}
    \\.zw-stepper-unit{margin-inline:-2px 2px;font:var(--body);color:var(--secondary);white-space:nowrap}
    \\.zw-stepper:has(input.zw-busy) .zw-stepper-btns{opacity:.55;transition:opacity var(--speed)}
    \\.zw-stepper.is-disabled{opacity:.4;& .zw-stepper-btns{pointer-events:none}}
    \\@media (pointer:coarse){.zw-stepper input,.zw-stepper-btns{height:44px}.zw-stepper-btns button{width:44px}}
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
    /// Unit shown after the field (`"GB"`, `"pt"`). Plain text, escaped.
    unit: []const u8 = "",
    /// Dim the stepper and ignore input.
    disabled: bool = false,
    /// `false` makes the field read-only: only the buttons change the value, and they join the Tab order.
    editable: bool = true,
    /// Past `max` the value goes to `min`, and the other way round (needs z.js; the buttons never disable).
    wrap: bool = false,
    /// Red ring on the field (`aria-invalid`), for a value the server rejected. A typed value outside `min`/`max` gets the ring by itself.
    invalid: bool = false,
};

// With an editable field the arrow keys already step it, so the buttons stay out of the Tab order.
const Data = struct { p: Props, skip_tab: bool };

const src = "<span class=\"zw-stepper{#if p.disabled} is-disabled{/if}\"><input class=\"zw-input\" type=\"number\" inputmode=\"numeric\" name=\"{p.name}\" aria-label=\"{p.label}\" value=\"{p.value}\" min=\"{p.min}\" max=\"{p.max}\" step=\"{p.step}\"" ++
    "{#if !p.editable} readonly{/if}{#if p.disabled} disabled{/if}{#if p.wrap} data-wrap{/if}{#if p.invalid} aria-invalid=\"true\"{/if}{p.z}>" ++
    "{#if p.unit}<span class=\"zw-stepper-unit\">{p.unit}</span>{/if}" ++
    "<span class=\"zw-stepper-btns zw-glass\"><button type=\"button\" data-step=\"-1\" aria-label=\"Decrease {p.label}\"{#if skip_tab} tabindex=\"-1\"{/if}{#if p.disabled} disabled{/if}>−</button>" ++
    "<button type=\"button\" data-step=\"1\" aria-label=\"Increase {p.label}\"{#if skip_tab} tabindex=\"-1\"{/if}{#if p.disabled} disabled{/if}>+</button></span></span>";

pub const Stepper = zv.View(src, Data);

/// `stepper(.{ .name = "copies", .label = "Copies", .value = 1, .min = 1, .max = 99 })`
pub fn stepper(p: Props) Stepper {
    return .{ .data = .{ .p = p, .skip_tab = p.editable or p.disabled } };
}

test "stepper unit, read-only, wrap, disabled and invalid" {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try stepper(.{ .name = "n", .label = "N", .unit = "GB", .editable = false, .wrap = true }).render(&w);
    var out = w.buffered();
    for ([_][]const u8{ " readonly", " data-wrap", ">GB</span>" }) |needle| try std.testing.expect(std.mem.find(u8, out, needle) != null);
    try std.testing.expect(std.mem.find(u8, out, "tabindex") == null);
    w = .fixed(&buf);
    try stepper(.{ .name = "n", .label = "N", .disabled = true }).render(&w);
    out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "zw-stepper is-disabled") != null);
    try std.testing.expect(std.mem.find(u8, out, "tabindex=\"-1\" disabled>") != null);
    w = .fixed(&buf);
    try stepper(.{ .name = "n", .label = "N", .invalid = true }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), " aria-invalid=\"true\"") != null);
    w = .fixed(&buf);
    try stepper(.{ .name = "n", .label = "N" }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "aria-invalid") == null);
}
