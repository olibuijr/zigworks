//! Data table: text cells, header row, zebra-free hairlines (macOS). Scrolls sideways on narrow screens.
//! Markdown tables render the same markup. Optional caption, column alignment, stripes, compact
//! rows, a row-header column and an empty state.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;

pub const css =
    \\.zw-table-wrap{overflow-x:auto;border-radius:var(--radius-control);box-shadow:inset 0 0 0 .5px var(--separator);
    \\  @media (forced-colors:active){box-shadow:none;border:1px solid CanvasText}}
    \\.zw-table{width:100%;border-collapse:collapse;font:var(--body);
    \\  & caption{padding:8px 12px;text-align:left;font:var(--callout);color:var(--secondary);border-bottom:1px solid var(--separator)}
    \\  & th{font:var(--callout);font-weight:600;color:var(--secondary);text-align:left;background:var(--fill)}
    \\  & thead th{white-space:nowrap}
    \\  & tbody th{font:var(--body);font-weight:600;color:var(--label);background:transparent}
    \\  & :is(th,td){padding:7px 12px;border-bottom:1px solid var(--separator);vertical-align:top}
    \\  & tr:last-child :is(td,th){border-bottom:0}
    \\  & code{white-space:nowrap}
    \\  & .zw-ta-center{text-align:center}
    \\  & .zw-ta-right{text-align:right;font-variant-numeric:tabular-nums}
    \\  & .zw-table-empty{padding:28px 12px;text-align:center;color:var(--secondary)}}
    \\.zw-table--striped tbody tr:nth-child(even){background:var(--fill)}
    \\.zw-table--compact :is(th,td){padding:3px 10px}
    \\
;

pub const Align = enum { left, center, right };

pub const Props = struct {
    head: []const []const u8,
    rows: []const []const []const u8,
    /// Alignment per column; missing columns are left-aligned. Right suits numbers.
    aligns: []const Align = &.{},
    /// Title above the table, also its accessible name.
    caption: []const u8 = "",
    /// Shade every other row.
    striped: bool = false,
    /// Tighter rows for dense data.
    compact: bool = false,
    /// Make the first column a row header (bold, announced as the row's name).
    row_header: bool = false,
    /// Shown across the table when there are no rows.
    empty: []const u8 = "",

    fn alignOf(p: Props, i: usize) Align {
        return if (i < p.aligns.len) p.aligns[i] else .left;
    }
};

pub const Table = struct {
    p: Props,
    pub fn render(self: Table, w: *Writer) Writer.Error!void {
        const p = self.p;
        try w.writeAll("<div class=\"zw-table-wrap\" tabindex=\"0\"><table class=\"zw-table");
        if (p.striped) try w.writeAll(" zw-table--striped");
        if (p.compact) try w.writeAll(" zw-table--compact");
        try w.writeAll("\">");
        if (p.caption.len > 0) {
            try w.writeAll("<caption>");
            try writeEscaped(w, p.caption);
            try w.writeAll("</caption>");
        }
        try w.writeAll("<thead><tr>");
        for (p.head, 0..) |h, i| try cell(w, "th", " scope=\"col\"", p.alignOf(i), h);
        try w.writeAll("</tr></thead><tbody>");
        for (p.rows) |row| {
            try w.writeAll("<tr>");
            for (row, 0..) |c, i| {
                if (i == 0 and p.row_header) try cell(w, "th", " scope=\"row\"", p.alignOf(i), c) else try cell(w, "td", "", p.alignOf(i), c);
            }
            try w.writeAll("</tr>");
        }
        if (p.rows.len == 0 and p.empty.len > 0) {
            try w.print("<tr><td class=\"zw-table-empty\" colspan=\"{d}\">", .{@max(p.head.len, 1)});
            try writeEscaped(w, p.empty);
            try w.writeAll("</td></tr>");
        }
        try w.writeAll("</tbody></table></div>");
    }
};

fn alignClass(a: Align) []const u8 {
    return switch (a) {
        .left => "",
        .center => " class=\"zw-ta-center\"",
        .right => " class=\"zw-ta-right\"",
    };
}

fn cell(w: *Writer, tag: []const u8, scope: []const u8, a: Align, text: []const u8) Writer.Error!void {
    try w.print("<{s}{s}{s}>", .{ tag, scope, alignClass(a) });
    try writeEscaped(w, text);
    try w.print("</{s}>", .{tag});
}

pub fn table(p: Props) Table {
    return .{ .p = p };
}

test "alignment, caption, row header, empty state" {
    var buf: [2048]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try table(.{
        .head = &.{ "Name", "Size" },
        .rows = &.{&.{ "a<b", "3" }},
        .aligns = &.{ .left, .right },
        .caption = "Files",
        .striped = true,
        .row_header = true,
    }).render(&w);
    try std.testing.expectEqualStrings(
        "<div class=\"zw-table-wrap\" tabindex=\"0\"><table class=\"zw-table zw-table--striped\"><caption>Files</caption>" ++
            "<thead><tr><th scope=\"col\">Name</th><th scope=\"col\" class=\"zw-ta-right\">Size</th></tr></thead>" ++
            "<tbody><tr><th scope=\"row\">a&lt;b</th><td class=\"zw-ta-right\">3</td></tr></tbody></table></div>",
        w.buffered(),
    );
    w = .fixed(&buf);
    try table(.{ .head = &.{ "A", "B" }, .rows = &.{}, .empty = "Nothing yet" }).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), "colspan=\"2\">Nothing yet</td>") != null);
}
