//! Segmented control: radio inputs (form value, arrow keys) drawn as macOS segments.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-seg{display:inline-flex;padding:2px;gap:2px;border:0;border-radius:var(--radius-control);background:var(--fill)}
    \\.zw-seg label{position:relative;display:flex;align-items:center;height:calc(var(--control-h) - 4px);padding:0 12px;border-radius:calc(var(--radius-control) - 2px);
    \\font:var(--body);font-weight:500;color:var(--label);cursor:default;user-select:none;transition:background var(--speed),box-shadow var(--speed)}
    \\.zw-seg input{position:absolute;inset:0;opacity:0;margin:0}
    \\.zw-seg label:has(:checked){background:var(--control-raised);box-shadow:0 0 0 .5px rgba(0,0,0,.06),0 1px 2px rgba(0,0,0,.14)}
    \\.zw-seg label:has(:focus-visible){outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent)}
    \\
;

pub const Option = struct { value: []const u8, label: []const u8, selected: bool = false };

pub const Props = struct {
    name: []const u8,
    /// Accessible name of the whole group.
    label: []const u8,
    options: []const Option,
    z: Z = .{},
};

const src = "<fieldset class=\"zw-seg\" role=\"radiogroup\" aria-label=\"{label}\">{#each options as o}" ++
    "<label><input type=\"radio\" name=\"{name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{z}>{o.label}</label>{/each}</fieldset>";

pub const Segmented = zv.View(src, Props);

pub fn segmented(p: Props) Segmented {
    return .{ .data = p };
}
