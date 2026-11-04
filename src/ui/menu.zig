//! Menu: a glass popover anchored to the button that opens it (`button(.{ .opens = id })`).
//! Popover API + CSS anchor positioning: light dismiss and Esc for free. z.js closes it after an item fires.
//! Items can have an icon, a shortcut hint, a checkmark, a section header, or be disabled links.
const std = @import("std");
const Writer = std.Io.Writer;
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-menu{position-area:bottom span-right;position-try-fallbacks:flip-block,flip-inline;margin:6px 0;min-width:190px;max-width:min(320px,calc(100vw - 16px));padding:6px;border:0;border-radius:var(--radius);
    \\color:var(--label);--glass:var(--glass-thick);transform-origin:top center;overflow:visible;
    \\transition:opacity 180ms ease,scale var(--dur-bouncy) var(--spring-bouncy),translate var(--dur) var(--spring),display 300ms allow-discrete,overlay 300ms allow-discrete}
    \\.zw-menu--end{position-area:bottom span-left}
    \\.zw-menu:not(:popover-open){opacity:0;scale:.9;translate:0 -6px;transition-duration:150ms}
    \\@starting-style{.zw-menu:popover-open{opacity:0;scale:.84;translate:0 -10px}}
    \\.zw-menu button,.zw-menu a,.zw-menu label{all:unset;box-sizing:border-box;display:flex;align-items:center;gap:8px;width:100%;height:26px;padding:0 10px;border-radius:8px;font:var(--body);cursor:default;
    \\transition:background-color 80ms,color 80ms}
    \\.zw-menu button:hover,.zw-menu button:focus-visible,.zw-menu a:hover,.zw-menu a:focus-visible,.zw-menu label:hover,.zw-menu label:has(:focus-visible){background:var(--accent);color:var(--on-accent)}
    \\.zw-menu button:active,.zw-menu a:active,.zw-menu label:active{background:color-mix(in srgb,var(--accent) 85%,#000)}
    \\.zw-menu .is-destructive{color:var(--red)}
    \\.zw-menu .is-destructive:hover,.zw-menu .is-destructive:focus-visible{background:var(--red);color:#fff}
    \\.zw-menu :is(button,a)[disabled],.zw-menu a[aria-disabled=true]{color:var(--tertiary);pointer-events:none}
    \\.zw-menu-label{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\.zw-menu-icon{display:inline-flex;flex:none;width:16px;justify-content:center;color:var(--secondary)}
    \\.zw-menu-icon svg{width:16px;height:16px}
    \\.zw-menu-mark{flex:none;width:12px;margin-left:-4px;font-size:12px;font-weight:600;visibility:hidden}
    \\[aria-checked=true]>.zw-menu-mark{visibility:visible}
    \\.zw-menu-kbd{flex:none;margin-left:16px;font-feature-settings:"tnum";color:var(--secondary)}
    \\.zw-menu :is(button,a):is(:hover,:focus-visible) :is(.zw-menu-icon,.zw-menu-kbd){color:inherit;opacity:.85}
    \\.zw-menu-head{padding:8px 10px 3px;font:var(--footnote);font-weight:600;color:var(--secondary)}
    \\.zw-menu hr{border:0;border-top:1px solid var(--separator);margin:5px 10px}
    \\@media (pointer:coarse){.zw-menu button,.zw-menu a,.zw-menu label{height:44px}.zw-menu-head{padding-top:12px}}
    \\
;

pub const Item = struct {
    label: []const u8,
    z: Z = .{},
    destructive: bool = false,
    /// Draw a separator above this item.
    separated: bool = false,
    /// Inline SVG markup (raw, trusted) shown before the label. Items without one are indented to match.
    icon: []const u8 = "",
    /// Shortcut hint shown at the end, as macOS menus do: "⌘D". Display only; bind the key yourself.
    shortcut: []const u8 = "",
    /// Makes this a checkable item (`menuitemcheckbox`): `false` is unchecked, `true` shows a checkmark.
    checked: ?bool = null,
    /// Greyed out and skipped by the keyboard and pointer.
    disabled: bool = false,
    /// Section header drawn above this item (after the separator, if any).
    header: []const u8 = "",
    /// Makes the item a link (`<a role="menuitem">`) instead of a button.
    href: []const u8 = "",
};

pub const Alignment = enum {
    /// The menu's left edge lines up with the button's.
    start,
    /// The menu's right edge lines up with the button's (buttons near the right edge).
    end,
};

pub const Props = struct {
    /// Must be a valid CSS identifier (it also names the anchor).
    id: []const u8,
    items: []const Item,
    /// Accessible name of the menu, e.g. the button's label.
    label: []const u8 = "",
    alignment: Alignment = .start,
};

const head_src = "<div class=\"zw-menu zw-glass{#if end} zw-menu--end{/if}\" id=\"{id}\" popover role=\"menu\"{#if label} aria-label=\"{label}\"{/if} style=\"position-anchor:--{id}\">";

const item_attrs = "role=\"{role}\"{#if aria_checked} aria-checked=\"{aria_checked}\"{/if}{#if it.destructive} class=\"is-destructive\"{/if}";

const item_inner = "{#if marks}<span class=\"zw-menu-mark\" aria-hidden=\"true\">✓</span>{/if}" ++
    "{#if icons}<span class=\"zw-menu-icon\" aria-hidden=\"true\">{@html it.icon}</span>{/if}" ++
    "<span class=\"zw-menu-label\">{it.label}</span>{#if it.shortcut}<span class=\"zw-menu-kbd\">{it.shortcut}</span>{/if}";

const lead_src = "{#if it.separated}<hr>{/if}{#if it.header}<div class=\"zw-menu-head\" role=\"presentation\">{it.header}</div>{/if}";
const button_src = "<button type=\"button\" " ++ item_attrs ++ "{#if it.disabled} disabled{/if}{it.z}>" ++ item_inner ++ "</button>";
const link_src = "<a " ++ item_attrs ++ "{#if it.disabled} aria-disabled=\"true\" tabindex=\"-1\"{:else} href=\"{it.href}\"{/if}{it.z}>" ++ item_inner ++ "</a>";

pub const Menu = struct {
    p: Props,

    pub fn render(self: Menu, w: *Writer) Writer.Error!void {
        const p = self.p;
        var marks = false;
        var icons = false;
        for (p.items) |it| {
            marks = marks or it.checked != null;
            icons = icons or it.icon.len > 0;
        }
        try zv.render(w, head_src, .{ .id = p.id, .label = p.label, .end = p.alignment == .end });
        for (p.items) |it| {
            const role: []const u8 = if (it.checked != null) "menuitemcheckbox" else "menuitem";
            const aria_checked: []const u8 = if (it.checked) |c| (if (c) "true" else "false") else "";
            const d = .{ .it = it, .role = role, .aria_checked = aria_checked, .marks = marks, .icons = icons };
            try zv.render(w, lead_src, d);
            if (it.href.len > 0) try zv.render(w, link_src, d) else try zv.render(w, button_src, d);
        }
        try w.writeAll("</div>");
    }
};

pub fn menu(p: Props) Menu {
    return .{ .p = p };
}

fn renderMenu(p: Props, buf: []u8) ![]const u8 {
    var w: Writer = .fixed(buf);
    try menu(p).render(&w);
    return w.buffered();
}

fn expectHas(out: []const u8, needle: []const u8) !void {
    if (std.mem.find(u8, out, needle) == null) {
        std.debug.print("missing '{s}' in: {s}\n", .{ needle, out });
        return error.TestExpectedEqual;
    }
}

test "plain items" {
    var buf: [2048]u8 = undefined;
    const out = try renderMenu(.{ .id = "m", .items = &.{ .{ .label = "A" }, .{ .label = "B", .destructive = true, .separated = true } } }, &buf);
    try expectHas(out, "role=\"menu\" style=\"position-anchor:--m\"><button type=\"button\" role=\"menuitem\"><span class=\"zw-menu-label\">A</span></button>");
    try expectHas(out, "<hr><button type=\"button\" role=\"menuitem\" class=\"is-destructive\">");
}

test "checkmarks, shortcuts, headers, disabled and links" {
    var buf: [4096]u8 = undefined;
    const out = try renderMenu(.{ .id = "m", .label = "View", .alignment = .end, .items = &.{
        .{ .label = "Sidebar", .checked = true, .shortcut = "⌘B", .header = "Show" },
        .{ .label = "Toolbar", .checked = false, .disabled = true },
        .{ .label = "Help", .href = "/help", .icon = "<svg/>" },
    } }, &buf);
    try expectHas(out, "zw-menu--end");
    try expectHas(out, "aria-label=\"View\"");
    try expectHas(out, "<div class=\"zw-menu-head\" role=\"presentation\">Show</div>");
    try expectHas(out, "role=\"menuitemcheckbox\" aria-checked=\"true\"");
    try expectHas(out, "aria-checked=\"false\" disabled");
    try expectHas(out, "<span class=\"zw-menu-kbd\">⌘B</span>");
    try expectHas(out, "<a role=\"menuitem\" href=\"/help\">");
}
