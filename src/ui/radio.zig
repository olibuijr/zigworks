//! Radio group: a vertical list of mutually exclusive choices with visible labels (macOS radio
//! buttons). For two to five short choices in a row, prefer `ui.segmented`.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-radio{display:flex;flex-direction:column;gap:6px;margin:0;padding:0;border:0;min-width:0}
    \\.zw-radio label{display:inline-flex;align-items:center;gap:8px;min-height:22px;cursor:default;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-radio input{appearance:none;flex:none;display:grid;place-items:center;width:16px;height:16px;margin:0;border-radius:50%;background:var(--content);
    \\box-shadow:inset 0 0 0 1px var(--tertiary),0 .5px 1px rgba(0,0,0,.06);transition:background-color var(--speed),box-shadow var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-radio input::after{content:"";width:6px;height:6px;border-radius:50%;background:var(--on-accent);scale:0;transition:scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-radio input:checked{background:linear-gradient(color-mix(in srgb,var(--accent) 80%,#fff),var(--accent));box-shadow:inset 0 .5px 0 rgba(255,255,255,.4),0 0 0 .5px color-mix(in srgb,var(--accent) 70%,#000)}
    \\.zw-radio input:checked::after{scale:1}
    \\.zw-radio label:active input{scale:.85;transition-duration:var(--dur-snappy)}
    \\.zw-radio input:focus-visible{outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent);outline-offset:1px}
    \\
;

pub const Option = struct { value: []const u8, label: []const u8, selected: bool = false };

pub const Props = struct {
    name: []const u8,
    /// Accessible name of the group.
    label: []const u8,
    options: []const Option,
    z: Z = .{},
};

const src = "<fieldset class=\"zw-radio\" role=\"radiogroup\" aria-label=\"{label}\">{#each options as o}" ++
    "<label><input type=\"radio\" name=\"{name}\" value=\"{o.value}\"{#if o.selected} checked{/if}{z}><span>{o.label}</span></label>{/each}</fieldset>";

pub const Radio = zv.View(src, Props);

pub fn radio(p: Props) Radio {
    return .{ .data = p };
}
