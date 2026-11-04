//! Segmented control: radio inputs (form value, arrow keys) drawn as macOS segments.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-seg{position:relative;display:inline-grid;grid-auto-flow:column;grid-auto-columns:1fr;min-width:0;margin:0;padding:2px;border:0;border-radius:999px;
    \\background:var(--fill);box-shadow:inset 0 .5px 1px rgba(0,0,0,.08)}
    \\.zw-seg label{position:relative;z-index:1;display:flex;align-items:center;justify-content:center;height:calc(var(--control-h) - 4px);padding:0 14px;border-radius:999px;
    \\font:var(--body);font-weight:500;color:var(--label);cursor:default;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-seg input{position:absolute;inset:0;opacity:0;margin:0}
    \\.zw-seg label:has(:focus-visible){outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent)}
    \\.zw-seg-pill{position:absolute;top:2px;bottom:2px;left:2px;width:calc((100% - 4px) / var(--n));border-radius:999px;--glass:color-mix(in srgb,var(--control-raised) 80%,transparent);
    \\translate:calc(var(--i,0) * 100%) 0;transition:translate var(--dur-bouncy) var(--spring-bouncy),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-seg:not(:has(:checked)) .zw-seg-pill{opacity:0}
    \\.zw-seg:active .zw-seg-pill{scale:1.06 1.16;transition-duration:var(--dur-snappy),var(--dur-snappy)}
    \\.zw-seg:has(label:nth-of-type(2) :checked){--i:1}.zw-seg:has(label:nth-of-type(3) :checked){--i:2}.zw-seg:has(label:nth-of-type(4) :checked){--i:3}
    \\.zw-seg:has(label:nth-of-type(5) :checked){--i:4}.zw-seg:has(label:nth-of-type(6) :checked){--i:5}.zw-seg:has(label:nth-of-type(7) :checked){--i:6}
    \\.zw-seg:has(label:nth-of-type(8) :checked){--i:7}
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

// The glass pill slides to the checked segment (CSS `--i`, set by :has); segments share one width.
const src = "<fieldset class=\"zw-seg\" role=\"radiogroup\" aria-label=\"{p.label}\" style=\"--n:{n}\"><span class=\"zw-seg-pill zw-glass\" aria-hidden=\"true\"></span>" ++
    "{#each p.options as o}<label><input type=\"radio\" name=\"{p.name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{p.z}>{o.label}</label>{/each}</fieldset>";

const Data = struct { p: Props, n: usize };

pub const Segmented = zv.View(src, Data);

pub fn segmented(p: Props) Segmented {
    std.debug.assert(p.options.len >= 2 and p.options.len <= 8); // the pill handles up to 8 segments
    return .{ .data = .{ .p = p, .n = p.options.len } };
}
