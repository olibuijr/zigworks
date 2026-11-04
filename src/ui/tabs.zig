//! Tab view: a segmented control above panels; one panel shows at a time (macOS NSTabView).
//! Radio inputs and :has() switch panels, so it works without JS (arrow keys move between tabs);
//! the glass pill slides between tabs and the panel springs in. Up to 8 tabs. The strip reuses
//! the segmented control's markup and CSS, with per-tab badges and disabled tabs on top.
const std = @import("std");
const Writer = std.Io.Writer;
const zv = @import("../view.zig");
const Z = @import("z.zig").Z;

pub const css =
    \\.zw-tabs{display:flex;flex-direction:column;align-items:center;gap:14px;
    \\&>.zw-seg label{&:has(:disabled){pointer-events:none}
    \\@media (max-width:480px){padding:0 8px}}}
    \\.zw-tabs--full{align-items:stretch}
    \\.zw-tab-badge{flex:none;min-width:18px;padding:0 6px;border-radius:999px;background:var(--accent);color:var(--on-accent);font-size:12px;line-height:18px;font-weight:600;font-variant-numeric:tabular-nums;text-align:center}
    \\.zw-tab-panel{display:none;width:100%}
    \\.zw-tabs{
    \\&:has(>.zw-seg label:nth-of-type(1) :checked)>.zw-tab-panel:nth-of-type(1),&:has(>.zw-seg label:nth-of-type(2) :checked)>.zw-tab-panel:nth-of-type(2),
    \\&:has(>.zw-seg label:nth-of-type(3) :checked)>.zw-tab-panel:nth-of-type(3),&:has(>.zw-seg label:nth-of-type(4) :checked)>.zw-tab-panel:nth-of-type(4),
    \\&:has(>.zw-seg label:nth-of-type(5) :checked)>.zw-tab-panel:nth-of-type(5),&:has(>.zw-seg label:nth-of-type(6) :checked)>.zw-tab-panel:nth-of-type(6),
    \\&:has(>.zw-seg label:nth-of-type(7) :checked)>.zw-tab-panel:nth-of-type(7),&:has(>.zw-seg label:nth-of-type(8) :checked)>.zw-tab-panel:nth-of-type(8)
    \\{display:block;animation:zw-tab-in var(--dur) var(--spring)}}
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
        /// Accessible name of the tab strip; the `id` when empty.
        label: []const u8 = "",
        /// Badge text per tab, by position (a count such as "3"); empty or missing means none.
        badges: []const []const u8 = &.{},
        /// Indexes of tabs that can't be chosen.
        disabled: []const usize = &.{},
        /// Stretch the strip to the full width instead of fitting its labels.
        full_width: bool = false,
        /// z.js attributes, put on every tab's radio input: choosing a tab sends `id=Label`. Give it a
        /// `target` (the tabs have no id of their own); a panel's id is `<id>-panel-<index>`, so a tab can
        /// fetch its own content on demand.
        z: Z = .{},
        /// Include the chosen tab as `id=Label` when the tabs sit in a form. `false` keeps it out.
        submit: bool = true,

        pub fn render(self: @This(), w: *Writer) Writer.Error!void {
            const names = @typeInfo(Panels).@"struct".field_names;
            std.debug.assert(self.labels.len == names.len);
            const selected = if (self.selected < self.labels.len) self.selected else 0; // out of range: the first tab
            try w.writeAll(if (self.full_width) "<div class=\"zw-tabs zw-tabs--full\"><fieldset class=\"zw-seg zw-seg--full\"" else "<div class=\"zw-tabs\"><fieldset class=\"zw-seg\"");
            try w.writeAll(" role=\"radiogroup\" aria-label=\"");
            try zv.writeEscaped(w, if (self.label.len > 0) self.label else self.id);
            try w.print("\" style=\"--n:{d}\"><span class=\"zw-seg-pill zw-glass\" aria-hidden=\"true\"></span>", .{self.labels.len});
            for (self.labels, 0..) |l, i| {
                try w.writeAll("<label><input type=\"radio\" name=\"");
                try zv.writeEscaped(w, self.id);
                try w.writeAll("\" value=\"");
                try zv.writeEscaped(w, l);
                try w.writeAll("\" aria-controls=\"");
                try zv.writeEscaped(w, self.id);
                try w.print("-panel-{d}\"", .{i});
                if (!self.submit) try w.writeAll(" form=\"zw-none\""); // no such form: the input belongs to none
                if (i == selected) try w.writeAll(" checked");
                if (std.mem.findScalar(usize, self.disabled, i) != null) try w.writeAll(" disabled");
                try self.z.render(w);
                try w.writeAll("><span class=\"zw-seg-text\">");
                try zv.writeEscaped(w, l);
                try w.writeAll("</span>");
                if (i < self.badges.len and self.badges[i].len > 0) {
                    try w.writeAll("<span class=\"zw-tab-badge\">");
                    try zv.writeEscaped(w, self.badges[i]);
                    try w.writeAll("</span>");
                }
                try w.writeAll("</label>");
            }
            try w.writeAll("</fieldset>");
            inline for (names, 0..) |name, i| {
                try w.writeAll("<div class=\"zw-tab-panel\" role=\"tabpanel\" id=\"");
                try zv.writeEscaped(w, self.id);
                try w.print("-panel-{d}\" aria-label=\"", .{i});
                try zv.writeEscaped(w, self.labels[i]);
                try w.writeAll("\">");
                try zv.writeValue(w, @field(self.panels, name));
                try w.writeAll("</div>");
            }
            try w.writeAll("</div>");
        }
    };
}

pub fn tabs(p: anytype) Tabs(@TypeOf(p.panels)) {
    comptime std.debug.assert(@typeInfo(@TypeOf(p.panels)).@"struct".field_names.len <= 8);
    return zv.props(Tabs(@TypeOf(p.panels)), p);
}

test tabs {
    var buf: [4096]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try tabs(.{ .id = "t", .labels = &.{ "A", "B <b>" }, .panels = .{ "one", "two" }, .badges = &.{ "", "3" }, .disabled = &.{1}, .full_width = true }).render(&w);
    const out = w.buffered();
    try std.testing.expect(std.mem.find(u8, out, "class=\"zw-tabs zw-tabs--full\"") != null);
    try std.testing.expect(std.mem.find(u8, out, "value=\"A\" aria-controls=\"t-panel-0\" checked><span class=\"zw-seg-text\">A</span></label>") != null);
    try std.testing.expect(std.mem.find(u8, out, "value=\"B &lt;b&gt;\" aria-controls=\"t-panel-1\" disabled>") != null);
    try std.testing.expect(std.mem.find(u8, out, "<span class=\"zw-tab-badge\">3</span>") != null);
    try std.testing.expect(std.mem.find(u8, out, "id=\"t-panel-0\" aria-label=\"A\">one</div>") != null);
    try std.testing.expect(std.mem.find(u8, out, "form=") == null);

    // z goes on every radio; submit = false detaches them from a surrounding form.
    w = .fixed(&buf);
    try tabs(.{ .id = "t", .labels = &.{ "A", "B" }, .panels = .{ "one", "two" }, .z = .{ .get = "/x", .target = "#p" }, .submit = false }).render(&w);
    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, w.buffered(), " form=\"zw-none\""));
    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, w.buffered(), " z-get=\"/x\" z-target=\"#p\">"));

    // A selected index out of range falls back to the first tab.
    w = .fixed(&buf);
    try tabs(.{ .id = "t", .labels = &.{ "A", "B" }, .panels = .{ "one", "two" }, .selected = 5 }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "t-panel-0\" checked>") != null);
    try std.testing.expectEqual(@as(usize, 1), std.mem.count(u8, w.buffered(), " checked"));
}
