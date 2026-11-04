//! Push button (macOS). Variants: primary (default action, accent fill), secondary (bezel),
//! plain (borderless), destructive. `opens` shows a popover (menu, sheet) by id; no JS needed.
//! Sizes follow AppKit control sizes; `icon` adds an SVG, `loading` a spinner; `href` makes it a link.
const std = @import("std");
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-btn{appearance:none;position:relative;height:var(--zw-btn-h,var(--control-h));padding:0 var(--zw-btn-px,15px);border:0;border-radius:999px;font:var(--body);font-weight:500;letter-spacing:-.08px;
    \\color:var(--label);background:transparent;cursor:default;display:inline-flex;align-items:center;justify-content:center;gap:6px;white-space:nowrap;user-select:none;-webkit-tap-highlight-color:transparent;touch-action:manipulation;text-decoration:none}
    \\.zw-btn:hover{text-decoration:none}
    \\.zw-btn:disabled,.zw-btn[aria-disabled=true]{opacity:.4;pointer-events:none}
    \\.zw-btn.is-loading:disabled{opacity:.7}
    \\.zw-btn--small{--zw-btn-h:calc(var(--control-h) - 6px);--zw-btn-px:10px;font:var(--callout);font-weight:500}
    \\.zw-btn--large{--zw-btn-h:calc(var(--control-h) + 8px);--zw-btn-px:20px;font:var(--title3);font-weight:500;letter-spacing:-.23px}
    \\.zw-btn--primary{color:var(--on-accent);background:color-mix(in srgb,var(--accent) 88%,transparent);
    \\box-shadow:inset 0 1px 0 rgba(255,255,255,.45),inset 0 -1px 1px rgba(0,0,0,.12),inset 0 0 0 .5px rgba(255,255,255,.22),0 0 0 .5px color-mix(in srgb,var(--accent) 70%,#000),0 4px 14px color-mix(in srgb,var(--accent) 32%,transparent)}
    \\.zw-btn--plain,.zw-btn--destructive{padding-inline:calc(var(--zw-btn-px,15px) - 5px)}
    \\.zw-btn--plain{color:var(--accent)}
    \\.zw-btn--plain:hover,.zw-btn--plain[aria-expanded=true]{background:var(--fill)}
    \\.zw-btn--destructive{color:var(--red)}
    \\.zw-btn--destructive:hover{background:color-mix(in srgb,var(--red) 12%,transparent)}
    \\.zw-btn svg{width:1.15em;height:1.15em;flex:none}
    \\.zw-btn-icon{display:inline-flex;flex:none}
    \\.zw-btn-icon--end{order:1}
    \\.zw-btn-label{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%);white-space:nowrap}
    \\.zw-btn-spin{flex:none;width:1.05em;height:1.05em;border-radius:50%;border:2px solid currentColor;border-top-color:transparent;opacity:.85;animation:zw-btn-spin .7s linear infinite}
    \\@keyframes zw-btn-spin{to{rotate:360deg}}
    \\.zw-btn--full{display:flex;width:100%}
    \\.zw-btn--icon{padding:0;width:var(--zw-btn-h,var(--control-h))}
    \\@media (pointer:coarse){.zw-btn{min-height:44px}.zw-btn--icon{min-width:44px}}
    \\
;

pub const Variant = enum { primary, secondary, plain, destructive };
pub const Type = enum { submit, button };
/// AppKit control sizes: small and large step the height and text size either side of regular.
pub const Size = enum { small, regular, large };

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
    size: Size = .regular,
    /// Inline SVG markup (raw, trusted) drawn with `currentColor`, before the label.
    icon: []const u8 = "",
    /// Put the icon after the label (chevrons, external links).
    icon_end: bool = false,
    /// Show only the icon, in a square. `label` stays as the accessible name (visually hidden).
    icon_only: bool = false,
    /// Show a spinner and disable the button until the work is done; sets aria-busy.
    loading: bool = false,
    /// Render a link (`<a>`) that looks like a button. With `disabled` or `loading` the link is inert.
    href: []const u8 = "",
    /// Stretch to the full width of the container.
    full: bool = false,
    /// Id of an element that describes this button, such as a tooltip's `id`.
    describedby: []const u8 = "",
};

const attrs = "class=\"zw-btn zw-btn--{p.variant} zw-btn--{p.size}{#if glass} zw-glass{/if}{#if p.icon_only} zw-btn--icon{/if}{#if p.full} zw-btn--full{/if}{#if p.loading} is-loading{/if} zw-press\"" ++
    "{#if p.aria} aria-label=\"{p.aria}\"{/if}{#if p.describedby} aria-describedby=\"{p.describedby}\"{/if}{#if p.loading} aria-busy=\"true\"{/if}";

const inner = "{#if p.loading}<span class=\"zw-btn-spin\" aria-hidden=\"true\"></span>{:else}{#if p.icon}<span class=\"zw-btn-icon{#if p.icon_end} zw-btn-icon--end{/if}\" aria-hidden=\"true\">{@html p.icon}</span>{/if}{/if}" ++
    "{#if p.icon_only}<span class=\"zw-btn-label\">{p.label}</span>{:else}{p.label}{/if}";

const src = "{#if p.href}<a " ++ attrs ++ "{#if inert} role=\"link\" aria-disabled=\"true\" tabindex=\"-1\"{:else} href=\"{p.href}\"{/if}{p.z}>" ++ inner ++ "</a>" ++
    "{:else}<button " ++ attrs ++ " type=\"{p.type}\"{#if p.opens} popovertarget=\"{p.opens}\" style=\"anchor-name:--{p.opens}\"{/if}{#if inert} disabled{/if}{p.z}>" ++ inner ++ "</button>{/if}";

/// Primary and secondary buttons are glass; plain and destructive stay borderless.
const Data = struct { p: Props, glass: bool, inert: bool };

pub const Button = zv.View(src, Data);

/// `button(.{ .label = "Save", .variant = .primary, .type = .submit })`
pub fn button(p: Props) Button {
    return .{ .data = .{ .p = p, .glass = p.variant == .primary or p.variant == .secondary, .inert = p.disabled or p.loading } };
}

fn expectHas(p: Props, needle: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try button(p).render(&w);
    if (std.mem.find(u8, w.buffered(), needle) == null) {
        std.debug.print("missing '{s}' in: {s}\n", .{ needle, w.buffered() });
        return error.TestExpectedEqual;
    }
}

test "size, icon and loading render" {
    try expectHas(.{ .label = "A", .size = .large }, "zw-btn--large");
    try expectHas(.{ .label = "A", .icon = "<svg/>", .icon_end = true }, "zw-btn-icon zw-btn-icon--end\" aria-hidden=\"true\"><svg/></span>A");
    try expectHas(.{ .label = "Back", .icon = "<svg/>", .icon_only = true }, "<span class=\"zw-btn-label\">Back</span>");
    try expectHas(.{ .label = "Save", .loading = true }, "aria-busy=\"true\"");
    try expectHas(.{ .label = "Save", .loading = true }, "<span class=\"zw-btn-spin\"");
    try expectHas(.{ .label = "Save", .loading = true }, " disabled");
}

test "href renders a link, inert when disabled" {
    try expectHas(.{ .label = "Docs", .href = "/docs" }, "<a class=\"zw-btn");
    try expectHas(.{ .label = "Docs", .href = "/docs" }, "href=\"/docs\"");
    try expectHas(.{ .label = "Docs", .href = "/docs", .disabled = true }, "aria-disabled=\"true\" tabindex=\"-1\"");
}
