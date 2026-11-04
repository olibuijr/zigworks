//! Source-list sidebar (macOS). Pass it as `layout(.{ .sidebar = ... })`.
//! It scrolls, so its glass has no refraction lens and its sheen is part of its background:
//! a lens or a sheen layer would stay put or move while the links scroll under them.
//! Wide screens: sticky glass column. Narrow screens: a popover opened by the title bar's
//! sidebar button (Popover API, no JS). Items are grouped under section headings.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-sidebar{margin:0;padding:12px 10px 24px;border:0;color:var(--label);--glass:var(--glass-thick);overscroll-behavior:contain;scrollbar-width:none;
    \\background:var(--glass-sheen),var(--glass)}
    \\.zw-sidebar::before{display:none}
    \\.zw-refract .zw-sidebar{backdrop-filter:var(--glass-filter)}
    \\.zw-sidebar h3{font:var(--callout);font-weight:600;color:var(--tertiary);padding:12px 10px 4px;margin:0}
    \\.zw-sidebar h3:first-child{padding-top:2px}
    \\.zw-sidebar ul{list-style:none;padding:0;margin:0}
    \\.zw-sidebar a{display:flex;align-items:center;height:28px;padding:0 10px;border-radius:8px;font:var(--body);color:var(--label);text-decoration:none;
    \\transition:background-color var(--speed),scale var(--dur-bouncy) var(--spring-bouncy)}
    \\.zw-sidebar a:hover{background:var(--fill);text-decoration:none}
    \\.zw-sidebar a:active{scale:.97;transition-duration:var(--dur-snappy)}
    \\.zw-sidebar a[aria-current=page]{background:var(--fill-strong);font-weight:600}
    \\.zw-sidebar-toggle{display:none}
    \\@media (min-width:800px){.zw-sidebar:not(:popover-open){display:block;inset:auto;position:sticky;top:60px;align-self:start;height:calc(100vh - 70px);margin:0 0 10px 10px;overflow-y:auto;width:auto;
    \\border-radius:var(--radius-panel)}}
    \\@media (max-width:799px){.zw-sidebar-toggle{display:inline-flex}
    \\.zw-sidebar[popover]{inset:60px auto 10px 10px;width:min(290px,calc(100vw - 20px));height:auto;overflow-y:auto;border-radius:var(--radius-panel);
    \\transition:translate var(--dur) var(--spring),opacity 220ms ease,display 400ms allow-discrete,overlay 400ms allow-discrete}
    \\.zw-sidebar[popover]:not(:popover-open){translate:calc(-100% - 20px) 0;opacity:0}
    \\@starting-style{.zw-sidebar[popover]:popover-open{translate:calc(-100% - 20px) 0;opacity:0}}
    \\.zw-sidebar::backdrop{background:rgba(0,0,0,.12)}}
    \\
;

pub const Link = struct { label: []const u8, href: []const u8 };
pub const Section = struct { title: []const u8, links: []const Link };

pub const Props = struct {
    sections: []const Section,
    /// Path of the current page; its link gets aria-current="page".
    current: []const u8,
    label: []const u8 = "Navigation",
};

pub const Sidebar = struct {
    p: Props,
    pub fn render(self: Sidebar, w: *Writer) Writer.Error!void {
        try w.writeAll("<nav class=\"zw-sidebar zw-glass\" id=\"zw-sidebar\" popover aria-label=\"");
        try writeEscaped(w, self.p.label);
        try w.writeAll("\">");
        for (self.p.sections) |s| {
            try w.writeAll("<h3>");
            try writeEscaped(w, s.title);
            try w.writeAll("</h3><ul>");
            for (s.links) |l| {
                try w.writeAll("<li><a href=\"");
                try writeEscaped(w, l.href);
                try w.writeByte('"');
                if (std.mem.eql(u8, l.href, self.p.current)) try w.writeAll(" aria-current=\"page\"");
                try w.writeByte('>');
                try writeEscaped(w, l.label);
                try w.writeAll("</a></li>");
            }
            try w.writeAll("</ul>");
        }
        try w.writeAll("</nav>");
    }
};

pub fn sidebar(p: Props) Sidebar {
    return .{ .p = p };
}
