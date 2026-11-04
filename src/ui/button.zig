//! Push button (macOS). Variants: primary (default action, accent fill), secondary (bezel),
//! plain (borderless), destructive. `opens` shows a popover (menu, sheet) by id; no JS needed.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-btn{appearance:none;height:var(--control-h);padding:0 14px;border:0;border-radius:var(--radius-control);font:var(--body);font-weight:500;letter-spacing:-.08px;
    \\cursor:default;display:inline-flex;align-items:center;justify-content:center;gap:6px;white-space:nowrap;user-select:none;transition:background var(--speed),filter var(--speed),box-shadow var(--speed)}
    \\.zw-btn:active{filter:brightness(.9)}
    \\.zw-btn:disabled{opacity:.4}
    \\.zw-btn--primary{background:linear-gradient(var(--accent),color-mix(in srgb,var(--accent) 88%,#000));color:var(--on-accent);box-shadow:inset 0 .5px 0 rgba(255,255,255,.3),0 0 0 .5px color-mix(in srgb,var(--accent) 60%,#000),0 1px 2px rgba(0,0,0,.15)}
    \\.zw-btn--secondary{background:var(--control);color:var(--label);box-shadow:var(--shadow)}
    \\.zw-btn--plain{background:transparent;color:var(--accent);padding:0 8px}
    \\.zw-btn--plain:hover{background:var(--fill)}
    \\.zw-btn--destructive{background:transparent;color:var(--red);padding:0 8px}
    \\.zw-btn--destructive:hover{background:color-mix(in srgb,var(--red) 12%,transparent)}
    \\
;

pub const Variant = enum { primary, secondary, plain, destructive };
pub const Type = enum { submit, button };

pub const Props = struct {
    label: []const u8,
    variant: Variant = .secondary,
    type: Type = .button,
    /// Accessible name when `label` is a symbol.
    aria: []const u8 = "",
    /// Id of a popover (menu, sheet) to toggle.
    opens: []const u8 = "",
    disabled: bool = false,
    z: Z = .{},
};

const src = "<button class=\"zw-btn zw-btn--{variant}\" type=\"{type}\"{#if aria} aria-label=\"{aria}\"{/if}" ++
    "{#if opens} popovertarget=\"{opens}\" style=\"anchor-name:--{opens}\"{/if}{#if disabled} disabled{/if}{z}>{label}</button>";

pub const Button = zv.View(src, Props);

/// `button(.{ .label = "Save", .variant = .primary, .type = .submit })`
pub fn button(p: Props) Button {
    return .{ .data = p };
}
