//! Push button (macOS). Variants: primary (default action, accent fill), secondary (bezel),
//! plain (borderless), destructive. `opens` shows a popover (menu, sheet) by id; no JS needed.
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-btn{appearance:none;position:relative;height:var(--control-h);padding:0 15px;border:0;border-radius:999px;font:var(--body);font-weight:500;letter-spacing:-.08px;
    \\color:var(--label);background:transparent;cursor:default;display:inline-flex;align-items:center;justify-content:center;gap:6px;white-space:nowrap;user-select:none;-webkit-tap-highlight-color:transparent}
    \\.zw-btn:disabled{opacity:.4;pointer-events:none}
    \\.zw-btn--primary{color:var(--on-accent);background:color-mix(in srgb,var(--accent) 88%,transparent);
    \\box-shadow:inset 0 1px 0 rgba(255,255,255,.45),inset 0 -1px 1px rgba(0,0,0,.12),inset 0 0 0 .5px rgba(255,255,255,.22),0 0 0 .5px color-mix(in srgb,var(--accent) 70%,#000),0 4px 14px color-mix(in srgb,var(--accent) 32%,transparent)}
    \\.zw-btn--plain{color:var(--accent);padding:0 10px}
    \\.zw-btn--plain:hover,.zw-btn--plain[aria-expanded=true]{background:var(--fill)}
    \\.zw-btn--destructive{color:var(--red);padding:0 10px}
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

const src = "<button class=\"zw-btn zw-btn--{p.variant}{#if glass} zw-glass{/if} zw-press\" type=\"{p.type}\"{#if p.aria} aria-label=\"{p.aria}\"{/if}" ++
    "{#if p.opens} popovertarget=\"{p.opens}\" style=\"anchor-name:--{p.opens}\"{/if}{#if p.disabled} disabled{/if}{p.z}>{p.label}</button>";

/// Primary and secondary buttons are glass; plain and destructive stay borderless.
const Data = struct { p: Props, glass: bool };

pub const Button = zv.View(src, Data);

/// `button(.{ .label = "Save", .variant = .primary, .type = .submit })`
pub fn button(p: Props) Button {
    return .{ .data = .{ .p = p, .glass = p.variant == .primary or p.variant == .secondary } };
}
