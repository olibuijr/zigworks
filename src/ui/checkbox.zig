//! macOS checkbox: a rounded square with a visible label, for options in forms and settings.
//! (`ui.check` is the round Reminders-style check for list items.) The mark pops on a spring.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-checkbox{display:inline-flex;align-items:center;gap:8px;min-height:24px;cursor:default;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-checkbox input{appearance:none;flex:none;display:grid;place-items:center;width:16px;height:16px;margin:0;border-radius:4.5px;background:var(--content);
    \\box-shadow:inset 0 0 0 1px var(--tertiary),0 .5px 1px rgba(0,0,0,.06);transition:background-color var(--speed),box-shadow var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-checkbox input::after{content:"";width:4px;height:8px;margin-top:-2px;border:solid var(--on-accent);border-width:0 1.75px 1.75px 0;rotate:45deg;scale:0;
    \\transition:scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-checkbox input:checked{background:linear-gradient(color-mix(in srgb,var(--accent) 80%,#fff),var(--accent));box-shadow:inset 0 .5px 0 rgba(255,255,255,.4),0 0 0 .5px color-mix(in srgb,var(--accent) 70%,#000)}
    \\.zw-checkbox input:checked::after{scale:1}
    \\.zw-checkbox:active input{scale:.85;transition-duration:var(--dur-snappy)}
    \\.zw-checkbox input:focus-visible{outline:3px solid color-mix(in srgb,var(--accent) 50%,transparent);outline-offset:1px}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    /// Sent as `name=value` when checked; nothing when unchecked.
    value: []const u8 = "on",
    on: bool = false,
    z: Z = .{},
};

const src = "<label class=\"zw-checkbox\"><input type=\"checkbox\" name=\"{name}\" value=\"{value}\"{#if on} checked{/if}{z}><span>{label}</span></label>";

pub const Checkbox = zv.View(src, Props);

/// `checkbox(.{ .name = "terms", .label = "I agree to the terms" })`
pub fn checkbox(p: Props) Checkbox {
    return .{ .data = p };
}
