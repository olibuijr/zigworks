//! Source-list sidebar (macOS). Pass it as `layout(.{ .sidebar = ... })`.
//! Wide screens: sticky glass column. Narrow screens: a popover opened by the title bar's
//! sidebar button (Popover API, no JS). Items are grouped under section headings.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-sidebar{margin:0;padding:12px 10px 24px;border:0;color:var(--label);background:var(--glass);backdrop-filter:var(--material);-webkit-backdrop-filter:var(--material)}
    \\.zw-sidebar h3{font:var(--callout);font-weight:600;color:var(--tertiary);padding:12px 10px 4px;margin:0}
    \\.zw-sidebar h3:first-child{padding-top:2px}
    \\.zw-sidebar ul{list-style:none;padding:0;margin:0}
    \\.zw-sidebar a{display:flex;align-items:center;height:28px;padding:0 10px;border-radius:6px;font:var(--body);color:var(--label);text-decoration:none}
    \\.zw-sidebar a:hover{background:var(--fill)}
    \\.zw-sidebar a[aria-current=page]{background:var(--fill-strong);font-weight:600}
    \\.zw-sidebar-toggle{display:none}
    \\@media (min-width:800px){.zw-sidebar:not(:popover-open){display:block;position:sticky;top:52px;align-self:start;height:calc(100vh - 52px);overflow-y:auto;inset:auto;
    \\width:auto;background:transparent;backdrop-filter:none;-webkit-backdrop-filter:none;border-right:1px solid var(--separator)}}
    \\@media (max-width:799px){.zw-sidebar-toggle{display:inline-flex}.zw-sidebar:popover-open{inset:52px auto 0 0;width:min(280px,85vw);height:auto;overflow-y:auto;
    \\box-shadow:0 0 0 .5px var(--separator),12px 0 40px rgba(0,0,0,.2);animation:zw-slide 200ms cubic-bezier(.2,.8,.2,1)}}
    \\@keyframes zw-slide{from{transform:translateX(-24px);opacity:0}}
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
        try w.writeAll("<nav class=\"zw-sidebar\" id=\"zw-sidebar\" popover aria-label=\"");
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
