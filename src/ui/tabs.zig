//! Tab view: a segmented control above panels; one panel shows at a time (macOS NSTabView).
//! Radio inputs and :has() switch panels, so it works without JS; the glass pill slides between
//! tabs and the panel springs in. Up to 8 tabs.
const std = @import("std");
const Writer = std.Io.Writer;
const Segmented = @import("segmented.zig");

pub const css =
    \\.zw-tabs{display:flex;flex-direction:column;align-items:center;gap:14px}
    \\.zw-tab-panel{display:none;width:100%}
    \\.zw-tabs:has(>.zw-seg label:nth-of-type(1) :checked)>.zw-tab-panel:nth-of-type(1),.zw-tabs:has(>.zw-seg label:nth-of-type(2) :checked)>.zw-tab-panel:nth-of-type(2),
    \\.zw-tabs:has(>.zw-seg label:nth-of-type(3) :checked)>.zw-tab-panel:nth-of-type(3),.zw-tabs:has(>.zw-seg label:nth-of-type(4) :checked)>.zw-tab-panel:nth-of-type(4),
    \\.zw-tabs:has(>.zw-seg label:nth-of-type(5) :checked)>.zw-tab-panel:nth-of-type(5),.zw-tabs:has(>.zw-seg label:nth-of-type(6) :checked)>.zw-tab-panel:nth-of-type(6),
    \\.zw-tabs:has(>.zw-seg label:nth-of-type(7) :checked)>.zw-tab-panel:nth-of-type(7),.zw-tabs:has(>.zw-seg label:nth-of-type(8) :checked)>.zw-tab-panel:nth-of-type(8)
    \\{display:block;animation:zw-tab-in var(--dur) var(--spring)}
    \\@keyframes zw-tab-in{from{opacity:0;translate:0 6px}}
    \\
;

/// `tabs(.{ .id = "prefs", .labels = &.{ "General", "Advanced" }, .panels = .{ general, advanced } })`
/// `panels` is a tuple of components, one per label. `selected` is the index shown first.
pub fn Tabs(comptime Panels: type) type {
    return struct {
        id: []const u8,
        labels: []const []const u8,
        panels: Panels,
        selected: usize = 0,

        pub fn render(self: @This(), w: *Writer) Writer.Error!void {
            std.debug.assert(self.labels.len == @typeInfo(Panels).@"struct".field_names.len);
            var options: [8]Segmented.Option = undefined;
            for (self.labels, 0..) |l, i| options[i] = .{ .value = l, .label = l, .selected = i == self.selected };
            try w.writeAll("<div class=\"zw-tabs\">");
            try Segmented.segmented(.{ .name = self.id, .label = self.id, .options = options[0..self.labels.len] }).render(w);
            inline for (@typeInfo(Panels).@"struct".field_names) |name| {
                try w.writeAll("<div class=\"zw-tab-panel\" role=\"tabpanel\">");
                try renderAny(w, @field(self.panels, name));
                try w.writeAll("</div>");
            }
            try w.writeAll("</div>");
        }
    };
}

fn renderAny(w: *Writer, v: anytype) Writer.Error!void {
    if (@TypeOf(v) == []const u8 or @typeInfo(@TypeOf(v)) == .pointer) return @import("../view.zig").writeEscaped(w, v);
    return v.render(w);
}

pub fn tabs(p: anytype) Tabs(@TypeOf(p.panels)) {
    const P = @TypeOf(p);
    comptime std.debug.assert(@typeInfo(@TypeOf(p.panels)).@"struct".field_names.len <= 8);
    return .{ .id = p.id, .labels = p.labels, .panels = p.panels, .selected = if (@hasField(P, "selected")) p.selected else 0 };
}
