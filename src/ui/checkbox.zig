//! macOS checkbox: a rounded square with a visible label, for options in forms and settings.
//! (`ui.check` is the round Reminders-style check for list items.) The mark pops on a spring.
//! Optional description line, mixed (dash) state, disabled and invalid states.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-checkbox{display:inline-flex;align-items:flex-start;gap:8px;padding:4px 0;cursor:default;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-checkbox input{appearance:none;flex:none;display:grid;place-items:center;width:16px;height:16px;margin:0;border-radius:4.5px;background:var(--content);
    \\box-shadow:inset 0 0 0 1px var(--tertiary),0 .5px 1px rgba(0,0,0,.06);transition:background-color var(--speed),box-shadow var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-checkbox input::after{content:"";width:4px;height:8px;margin-top:-2px;border:solid var(--on-accent);border-width:0 1.75px 1.75px 0;rotate:45deg;scale:0;
    \\transition:scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-checkbox input:checked,.zw-checkbox input[data-mixed]:not(:checked),.zw-checkbox input:indeterminate{background:linear-gradient(color-mix(in srgb,var(--accent) 80%,#fff),var(--accent));box-shadow:inset 0 .5px 0 rgba(255,255,255,.4),0 0 0 .5px color-mix(in srgb,var(--accent) 70%,#000)}
    \\.zw-checkbox input:checked::after{scale:1}
    \\.zw-checkbox input[data-mixed]:not(:checked)::after,.zw-checkbox input:indeterminate:not(:checked)::after{width:8px;height:0;margin:0;border-width:0 0 2px;rotate:0;scale:1}
    \\.zw-checkbox:active input{scale:.85;transition-duration:var(--dur-snappy)}
    \\.zw-checkbox input[aria-invalid=true]:not(:checked){box-shadow:inset 0 0 0 1.5px var(--red)}
    \\.zw-checkbox input[aria-invalid=true]:focus-visible{outline-color:color-mix(in srgb,var(--red) 50%,transparent)}
    \\.zw-checkbox__txt{display:flex;flex-direction:column;min-width:0}
    \\.zw-checkbox__desc{font:var(--callout);color:var(--secondary)}
    \\.zw-checkbox--disabled{opacity:.4;pointer-events:none}
    \\@media (pointer:coarse){.zw-checkbox{min-height:44px;padding:14px 0;box-sizing:border-box}}
    \\
;

pub const Props = struct {
    name: []const u8,
    label: []const u8,
    /// Sent as `name=value` when checked; nothing when unchecked.
    value: []const u8 = "on",
    on: bool = false,
    /// Secondary line under the label.
    description: []const u8 = "",
    /// Starts in the mixed state (a dash; `aria-checked="mixed"`) for a parent of partly selected
    /// options. Overrides `on`; the first click checks it.
    mixed: bool = false,
    /// Dimmed and not interactive; not submitted.
    disabled: bool = false,
    /// Marks the box red (`aria-invalid`), e.g. an unaccepted required checkbox.
    invalid: bool = false,
    z: Z = .{},
};

const src = "<label class=\"zw-checkbox{#if disabled} zw-checkbox--disabled{/if}\"><input type=\"checkbox\" name=\"{name}\" value=\"{value}\"" ++
    "{#if on} checked{/if}{#if mixed} aria-checked=\"mixed\" data-mixed{/if}{#if invalid} aria-invalid=\"true\"{/if}{#if disabled} disabled{/if}{z}>" ++
    "<span class=\"zw-checkbox__txt\"><span>{label}</span>{#if description}<span class=\"zw-checkbox__desc\">{description}</span>{/if}</span></label>";

pub const Checkbox = zv.View(src, Props);

/// `checkbox(.{ .name = "terms", .label = "I agree to the terms" })`
pub fn checkbox(p: Props) Checkbox {
    var q = p;
    if (q.mixed) q.on = false;
    return .{ .data = q };
}

test "checkbox mixed overrides on; description and disabled render" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try checkbox(.{ .name = "a", .label = "All", .on = true, .mixed = true, .description = "Some selected", .disabled = true }).render(&w);
    const s = w.buffered();
    try std.testing.expect(std.mem.find(u8, s, " checked") == null);
    try std.testing.expect(std.mem.find(u8, s, "aria-checked=\"mixed\" data-mixed") != null);
    try std.testing.expect(std.mem.find(u8, s, "zw-checkbox__desc\">Some selected") != null);
    try std.testing.expect(std.mem.find(u8, s, "zw-checkbox--disabled") != null);
}
