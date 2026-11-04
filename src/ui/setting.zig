//! Settings row: label on the leading side, any control on the trailing side (macOS System Settings).
//! Consecutive rows (and switches, which share the style) get hairline separators.
//! `description` adds a second line, `icon` a leading tile, `disabled` dims and disables the controls,
//! `href` makes a navigation row (value text plus chevron) like a System Settings pane link.
const std = @import("std");
const zv = @import("../view.zig");

pub const css =
    \\.zw-setting{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:6px 16px;min-height:36px;
    \\  &>:last-child:not(.zw-setting-text){margin-left:auto}
    \\  &+.zw-setting{border-top:1px solid var(--separator);margin-top:6px;padding-top:6px}
    \\  & .zw-slider{flex:0 1 240px}
    \\  @media (pointer:coarse){min-height:44px}}
    \\.zw-setting-text{min-width:0;margin-right:auto}
    \\.zw-setting-desc{display:block;font:var(--callout);margin-top:1px}
    \\.zw-setting-desc,.zw-setting-value{color:var(--secondary)}
    \\.zw-setting-icon{flex:none;display:grid;place-items:center;width:28px;height:28px;margin-right:-4px;border-radius:7px;background:var(--accent);color:var(--on-accent);font-size:15px;line-height:1}
    \\fieldset.zw-setting{border:0;padding:0;min-inline-size:0}
    \\.zw-setting--disabled{opacity:.4;pointer-events:none}
    \\a.zw-setting{color:inherit;text-decoration:none;-webkit-tap-highlight-color:transparent;transition:opacity var(--speed);
    \\  &:active{opacity:.6}}
    \\.zw-setting--link{flex-wrap:nowrap;cursor:default;
    \\  &>.zw-setting-text{flex:1}
    \\  &::after{content:"";flex:none;width:7px;height:7px;margin-left:-4px;border:solid var(--tertiary);border-width:2px 2px 0 0;rotate:45deg;transition:border-color var(--speed)}
    \\  &:hover::after{border-color:var(--secondary)}}
    \\
;

pub fn Props(comptime Control: type) type {
    return struct {
        label: []const u8,
        control: ?Control = null,
        description: []const u8 = "",
        icon: []const u8 = "",
        href: []const u8 = "",
        disabled: bool = false,
    };
}

/// The props plus the flags `setting` works out from them.
pub fn Data(comptime Control: type) type {
    return struct { p: Props(Control), tag: []const u8, link: bool, ctl: bool, ctl_text: bool };
}

const src = "<{tag} class=\"zw-setting{#if link} zw-setting--link{/if}{#if p.disabled} zw-setting--disabled{/if}\"{#if link} href=\"{p.href}\"{/if}{#if p.disabled} disabled{/if}>" ++
    "{#if p.icon}<span class=\"zw-setting-icon\" aria-hidden=\"true\">{p.icon}</span>{/if}" ++
    "<span class=\"zw-setting-text\">{p.label}{#if p.description}<small class=\"zw-setting-desc\">{p.description}</small>{/if}</span>" ++
    "{#if ctl}{#if ctl_text}<span class=\"zw-setting-value\">{p.control}</span>{:else}{p.control}{/if}{/if}</{tag}>";

pub fn Setting(comptime Control: type) type {
    return zv.View(src, Data(Control));
}

/// `setting(.{ .label = "Theme", .description = "Applies to all windows", .control = ui.segmented(...) })`
/// `setting(.{ .label = "Wi-Fi", .icon = "📶", .href = "/wifi", .control = "Home" })`
pub fn setting(p: anytype) Setting(zv.Slot(@TypeOf(p), "control")) {
    const Control = zv.Slot(@TypeOf(p), "control");
    const q = zv.props(Props(Control), p);
    return .{ .data = .{
        .p = q,
        // A disabled row is a fieldset: it disables the controls inside but keeps them readable.
        .tag = if (q.disabled) "fieldset" else if (q.href.len > 0) "a" else "div",
        .link = q.href.len > 0 and !q.disabled,
        .ctl = zv.filled(q.control),
        .ctl_text = @typeInfo(Control) == .pointer,
    } };
}

test "setting renders description, icon and link rows" {
    var buf: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buf);
    try setting(.{ .label = "Theme", .control = zv.view("<i>{x}</i>", .{ .x = "c" }) }).render(&w);
    try std.testing.expectEqualStrings(
        "<div class=\"zw-setting\"><span class=\"zw-setting-text\">Theme</span><i>c</i></div>",
        w.buffered(),
    );

    w = .fixed(&buf);
    try setting(.{ .label = "Wi-Fi", .description = "Home", .icon = "W", .href = "/wifi", .control = "On" }).render(&w);
    try std.testing.expectEqualStrings(
        "<a class=\"zw-setting zw-setting--link\" href=\"/wifi\"><span class=\"zw-setting-icon\" aria-hidden=\"true\">W</span>" ++
            "<span class=\"zw-setting-text\">Wi-Fi<small class=\"zw-setting-desc\">Home</small></span><span class=\"zw-setting-value\">On</span></a>",
        w.buffered(),
    );

    w = .fixed(&buf);
    try setting(.{ .label = "Sync", .disabled = true, .href = "/x" }).render(&w);
    try std.testing.expectEqualStrings(
        "<fieldset class=\"zw-setting zw-setting--disabled\" disabled><span class=\"zw-setting-text\">Sync</span></fieldset>",
        w.buffered(),
    );
}
