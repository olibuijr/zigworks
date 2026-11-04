//! Source-list sidebar (macOS). Pass it as `layout(.{ .sidebar = ... })`.
//! It scrolls, so its glass has no refraction lens and its sheen is part of its background:
//! a lens or a sheen layer would stay put or move while the links scroll under them.
//! Wide screens: sticky glass column. Narrow screens: a popover opened by the title bar's
//! sidebar button (Popover API, no JS). Items are grouped under section headings.
//! Links take an `icon` (inline SVG) and a `badge` (count); a section can `collapsible`-fold with a
//! disclosure triangle; `size` is the macOS sidebar icon size; `footer` pins markup to the bottom.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-sidebar{--row:28px;--icon:16px;margin:0;padding:12px 10px 24px;border:0;color:var(--label);--glass:var(--glass-thick);overscroll-behavior:contain;scrollbar-width:none;
    \\background:var(--glass-sheen),var(--glass)}
    \\.zw-sidebar--small{--row:24px;--icon:14px;font:var(--callout)}
    \\.zw-sidebar--large{--row:32px;--icon:20px}
    \\.zw-sidebar::before{display:none}
    \\.zw-refract .zw-sidebar{backdrop-filter:var(--glass-filter)}
    \\.zw-sidebar h3,.zw-sidebar summary{font:var(--callout);font-weight:600;color:var(--secondary);padding:12px 10px 4px;margin:0}
    \\.zw-sidebar>h3:first-child,.zw-sidebar>details:first-child>summary{padding-top:2px}
    \\.zw-sidebar ul{list-style:none;padding:0;margin:0}
    \\.zw-sidebar a{display:flex;align-items:center;gap:8px;height:var(--row);padding:0 10px;border-radius:8px;font:inherit;color:var(--label);text-decoration:none;
    \\transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-sidebar a:focus-visible,.zw-sidebar summary:focus-visible{outline-offset:-2px}
    \\@media (hover:hover){.zw-sidebar a:hover{background:var(--fill);text-decoration:none}}
    \\.zw-sidebar a:active{scale:.97;transition-duration:var(--dur-snappy)}
    \\.zw-sidebar a[aria-current=page]{background:var(--fill-strong);font-weight:600}
    \\.zw-sidebar-icon{flex:none;display:inline-flex;width:var(--icon);height:var(--icon);color:var(--accent)}
    \\.zw-sidebar-icon svg{width:100%;height:100%}
    \\.zw-sidebar-label{flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    \\.zw-sidebar-badge{flex:none;margin-left:auto;font:var(--callout);font-variant-numeric:tabular-nums;color:var(--secondary)}
    \\.zw-sidebar a[aria-current=page] .zw-sidebar-badge{color:var(--label)}
    \\.zw-sidebar-sec{interpolate-size:allow-keywords}
    \\.zw-sidebar summary{display:flex;align-items:center;list-style:none;cursor:default;user-select:none;border-radius:8px}
    \\.zw-sidebar summary::-webkit-details-marker{display:none}
    \\.zw-sidebar summary::after{content:"";flex:none;margin-left:auto;width:5px;height:5px;border:solid currentColor;border-width:0 1.5px 1.5px 0;rotate:-45deg;
    \\transition:rotate var(--dur-bouncy) var(--spring-bouncy),opacity var(--speed)}
    \\.zw-sidebar-sec[open]>summary::after{rotate:45deg}
    \\@media (hover:hover){.zw-sidebar-sec>summary::after{opacity:0}.zw-sidebar:hover .zw-sidebar-sec>summary::after,.zw-sidebar-sec>summary:focus-visible::after{opacity:1}}
    \\.zw-sidebar-sec::details-content{height:0;opacity:0;overflow:clip;transition:height var(--dur) var(--spring),opacity 200ms ease,content-visibility var(--dur) allow-discrete}
    \\.zw-sidebar-sec[open]::details-content{height:auto;opacity:1}
    \\.zw-sidebar-footer{margin:12px -10px 0;padding:10px 20px 12px;font:var(--callout);color:var(--secondary);border-top:.5px solid var(--separator)}
    \\.zw-sidebar-toggle{display:none}
    \\.zw-sidebar--inline{display:block;width:240px;max-width:100%;border-radius:var(--radius-panel)}
    \\@media (min-width:800px){.zw-sidebar:not(:popover-open){display:block;inset:auto;position:sticky;top:calc(60px + env(safe-area-inset-top));align-self:start;height:calc(100vh - 70px - env(safe-area-inset-top));margin:0 0 10px 10px;overflow-y:auto;width:auto;
    \\border-radius:var(--radius-panel)}}
    \\@media (max-width:799px){.zw-sidebar-toggle{display:inline-flex}
    \\.zw-sidebar[popover]{inset:calc(60px + env(safe-area-inset-top)) auto 10px 10px;width:min(290px,calc(100vw - 20px));height:auto;overflow-y:auto;border-radius:var(--radius-panel);
    \\transition:translate var(--dur) var(--spring),opacity 220ms ease,display 400ms allow-discrete,overlay 400ms allow-discrete}
    \\.zw-sidebar[popover]:not(:popover-open){translate:calc(-100% - 20px) 0;opacity:0}
    \\@starting-style{.zw-sidebar[popover]:popover-open{translate:calc(-100% - 20px) 0;opacity:0}}
    \\.zw-sidebar::backdrop{background:rgba(0,0,0,.12)}}
    \\.zw-sidebar--footer{padding-bottom:0}
    \\.zw-sidebar--footer:popover-open,.zw-sidebar--footer.zw-sidebar--inline{display:flex;flex-direction:column}
    \\@media (min-width:800px){.zw-sidebar--footer:not(:popover-open){display:flex;flex-direction:column}}
    \\.zw-sidebar--footer>*{flex:none}
    \\.zw-sidebar--footer>.zw-sidebar-footer{position:sticky;bottom:0;margin-top:auto;border-top-color:var(--separator);
    \\background:color-mix(in srgb,var(--window) 55%,transparent);-webkit-backdrop-filter:blur(12px);backdrop-filter:blur(12px)}
    \\@media (pointer:coarse){.zw-sidebar{--row:44px}.zw-sidebar summary{min-height:44px}}
    \\
;

pub const Size = enum { small, medium, large };

pub const Link = struct {
    label: []const u8,
    href: []const u8,
    /// Inline SVG (use `currentColor`; it is drawn in the accent color). Trusted markup, not escaped.
    icon: []const u8 = "",
    /// Short trailing text, usually a count ("12"). Empty shows nothing.
    badge: []const u8 = "",
};

pub const Section = struct {
    /// Heading. May be empty for an untitled group (never foldable).
    title: []const u8,
    links: []const Link,
    /// The heading becomes a disclosure triangle that folds the links.
    collapsible: bool = false,
    /// Initial state of a collapsible section. A section holding the current page always opens.
    open: bool = true,
};

pub const Props = struct {
    sections: []const Section,
    /// Path of the current page; its link gets aria-current="page".
    current: []const u8,
    label: []const u8 = "Navigation",
    /// Show it inside content (a demo, a settings pane) instead of as the app's sidebar:
    /// no id, no popover, visible at every width.
    inline_: bool = false,
    /// Row height and icon size, like the macOS Sidebar Icon Size setting.
    size: Size = .medium,
    /// Trusted markup pinned to the bottom (an account row, a storage meter). Empty shows nothing.
    footer: []const u8 = "",
};

pub const Sidebar = struct {
    p: Props,
    pub fn render(self: Sidebar, w: *Writer) Writer.Error!void {
        const p = self.p;
        try w.print("<nav class=\"zw-sidebar zw-sidebar--{s}", .{@tagName(p.size)});
        if (p.inline_) try w.writeAll(" zw-sidebar--inline");
        if (p.footer.len > 0) try w.writeAll(" zw-sidebar--footer");
        try w.writeAll(" zw-glass\"");
        if (!p.inline_) try w.writeAll(" id=\"zw-sidebar\" popover");
        try w.writeAll(" aria-label=\"");
        try writeEscaped(w, p.label);
        try w.writeAll("\">");
        for (p.sections) |s| try section(w, s, p.current);
        if (p.footer.len > 0) try w.print("<div class=\"zw-sidebar-footer\">{s}</div>", .{p.footer});
        try w.writeAll("</nav>");
    }
};

fn holds(s: Section, current: []const u8) bool {
    for (s.links) |l| if (std.mem.eql(u8, l.href, current)) return true;
    return false;
}

fn section(w: *Writer, s: Section, current: []const u8) Writer.Error!void {
    const fold = s.collapsible and s.title.len > 0;
    if (fold) {
        try w.writeAll(if (s.open or holds(s, current)) "<details class=\"zw-sidebar-sec\" open><summary>" else "<details class=\"zw-sidebar-sec\"><summary>");
        try writeEscaped(w, s.title);
        try w.writeAll("</summary>");
    } else if (s.title.len > 0) {
        try w.writeAll("<h3>");
        try writeEscaped(w, s.title);
        try w.writeAll("</h3>");
    }
    try w.writeAll("<ul>");
    for (s.links) |l| {
        try w.writeAll("<li><a href=\"");
        try writeEscaped(w, l.href);
        try w.writeByte('"');
        if (std.mem.eql(u8, l.href, current)) try w.writeAll(" aria-current=\"page\"");
        try w.writeByte('>');
        if (l.icon.len > 0) try w.print("<span class=\"zw-sidebar-icon\" aria-hidden=\"true\">{s}</span>", .{l.icon});
        try w.writeAll("<span class=\"zw-sidebar-label\">");
        try writeEscaped(w, l.label);
        try w.writeAll("</span>");
        if (l.badge.len > 0) {
            try w.writeAll("<span class=\"zw-sidebar-badge\">");
            try writeEscaped(w, l.badge);
            try w.writeAll("</span>");
        }
        try w.writeAll("</a></li>");
    }
    try w.writeAll(if (fold) "</ul></details>" else "</ul>");
}

pub fn sidebar(p: Props) Sidebar {
    return .{ .p = p };
}

test "sidebar renders icons, badges, collapsible sections and footer" {
    var buf: [2048]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try sidebar(.{ .current = "/b", .size = .large, .footer = "<b>me</b>", .sections = &.{
        .{ .title = "Mail", .links = &.{.{ .label = "A & B", .href = "/a", .badge = "3", .icon = "<svg/>" }} },
        .{ .title = "Folded", .collapsible = true, .open = false, .links = &.{.{ .label = "C", .href = "/c" }} },
        .{ .title = "Holds", .collapsible = true, .open = false, .links = &.{.{ .label = "B", .href = "/b" }} },
    } }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "zw-sidebar--large zw-sidebar--footer zw-glass\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "<span class=\"zw-sidebar-icon\" aria-hidden=\"true\"><svg/></span><span class=\"zw-sidebar-label\">A &amp; B</span><span class=\"zw-sidebar-badge\">3</span>") != null);
    try std.testing.expect(std.mem.find(u8, out, "<details class=\"zw-sidebar-sec\"><summary>Folded</summary>") != null);
    try std.testing.expect(std.mem.find(u8, out, "<details class=\"zw-sidebar-sec\" open><summary>Holds</summary>") != null);
    try std.testing.expect(std.mem.find(u8, out, "aria-current=\"page\"") != null);
    try std.testing.expect(std.mem.endsWith(u8, out, "<div class=\"zw-sidebar-footer\"><b>me</b></div></nav>"));
}
