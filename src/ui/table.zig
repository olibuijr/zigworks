//! Data table: text cells, header row, zebra-free hairlines (macOS). Scrolls sideways on narrow screens.
//! Markdown tables render the same markup. Optional caption, column alignment, stripes, compact
//! rows, a row-header column, a footer row, sort and selection marks, trusted-HTML columns
//! (badges, buttons) and an empty state.
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
    \\  & tfoot :is(th,td){font-weight:600;border-top:1px solid var(--separator)}
    \\  & tfoot th{font:var(--body);font-weight:600;color:var(--label);background:transparent}
    \\  & th[aria-sort]{color:var(--label);&::after{content:"\2191";content:"\2191"/"";margin-left:4px}
    \\    &[aria-sort=descending]::after{content:"\2193";content:"\2193"/""}}
    \\  & code{white-space:nowrap}
    \\  & .zw-ta-center{text-align:center}
    \\  & .zw-ta-right{text-align:right;font-variant-numeric:tabular-nums}
    \\  & .zw-table-empty{padding:28px 12px;text-align:center;color:var(--secondary)}}
    \\.zw-table--striped tbody tr:nth-child(even){background:var(--fill)}
    \\.zw-table tbody tr[aria-current=true]{background:color-mix(in srgb,var(--accent) 16%,transparent);
    \\  @media (forced-colors:active){outline:2px solid Highlight;outline-offset:-2px}}
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
    /// Id of the frame, so it can be a `z-target` or a link anchor.
    id: []const u8 = "",
    /// Columns (by index) whose body cells are trusted HTML, not text: a rendered badge or button.
    /// Never put user input in these cells without escaping it. Header and footer stay text.
    html: []const bool = &.{},
    /// Footer row (totals): the first cell is a bold row header. Text only, aligned like the columns.
    foot: []const []const u8 = &.{},
    /// Column the rows are sorted by; its header gets `aria-sort` and an arrow. The sorting itself is yours.
    sort_col: ?usize = null,
    /// The sort runs high to low (the arrow points down).
    sort_desc: bool = false,
    /// Index of the highlighted row; it gets `aria-current="true"`.
    selected: ?usize = null,

    fn alignOf(p: Props, i: usize) Align {
        return if (i < p.aligns.len) p.aligns[i] else .left;
    }

    fn isHtml(p: Props, i: usize) bool {
        return i < p.html.len and p.html[i];
    }
};

pub const Table = struct {
    p: Props,
    pub fn render(self: Table, w: *Writer) Writer.Error!void {
        const p = self.p;
        try w.writeAll("<div class=\"zw-table-wrap\"");
        if (p.id.len > 0) {
            try w.writeAll(" id=\"");
            try writeEscaped(w, p.id);
            try w.writeAll("\"");
        }
        try w.writeAll(" tabindex=\"0\"><table class=\"zw-table");
        if (p.striped) try w.writeAll(" zw-table--striped");
        if (p.compact) try w.writeAll(" zw-table--compact");
        try w.writeAll("\">");
        if (p.caption.len > 0) {
            try w.writeAll("<caption>");
            try writeEscaped(w, p.caption);
            try w.writeAll("</caption>");
        }
        try w.writeAll("<thead><tr>");
        for (p.head, 0..) |h, i| {
            const attrs: []const u8 = if (p.sort_col != i) " scope=\"col\"" else if (p.sort_desc) " scope=\"col\" aria-sort=\"descending\"" else " scope=\"col\" aria-sort=\"ascending\"";
            try cell(w, "th", attrs, p.alignOf(i), h, false);
        }
        try w.writeAll("</tr></thead><tbody>");
        for (p.rows, 0..) |row, r| {
            try w.writeAll(if (p.selected == r) "<tr aria-current=\"true\">" else "<tr>");
            for (row, 0..) |c, i| {
                if (i == 0 and p.row_header) try cell(w, "th", " scope=\"row\"", p.alignOf(i), c, p.isHtml(i)) else try cell(w, "td", "", p.alignOf(i), c, p.isHtml(i));
            }
            try w.writeAll("</tr>");
        }
        if (p.rows.len == 0 and p.empty.len > 0) {
            try w.print("<tr><td class=\"zw-table-empty\" colspan=\"{d}\">", .{@max(p.head.len, 1)});
            try writeEscaped(w, p.empty);
            try w.writeAll("</td></tr>");
        }
        try w.writeAll("</tbody>");
        if (p.foot.len > 0) {
            try w.writeAll("<tfoot><tr>");
            for (p.foot, 0..) |c, i| {
                if (i == 0) try cell(w, "th", " scope=\"row\"", p.alignOf(i), c, false) else try cell(w, "td", "", p.alignOf(i), c, false);
            }
            try w.writeAll("</tr></tfoot>");
        }
        try w.writeAll("</table></div>");
    }
};

fn alignClass(a: Align) []const u8 {
    return switch (a) {
        .left => "",
        .center => " class=\"zw-ta-center\"",
        .right => " class=\"zw-ta-right\"",
    };
}

fn cell(w: *Writer, tag: []const u8, attrs: []const u8, a: Align, text: []const u8, raw: bool) Writer.Error!void {
    try w.print("<{s}{s}{s}>", .{ tag, attrs, alignClass(a) });
    if (raw) try w.writeAll(text) else try writeEscaped(w, text);
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

test "id, html columns, footer, sort and selection" {
    var buf: [2048]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try table(.{
        .head = &.{ "Item", "State", "Amount" },
        .rows = &.{ &.{ "a", "<b>ok</b>", "1" }, &.{ "b", "<i>", "2" } },
        .aligns = &.{ .left, .left, .right },
        .id = "t1",
        .html = &.{ false, true },
        .foot = &.{ "Total", "", "3<" },
        .sort_col = 2,
        .sort_desc = true,
        .selected = 1,
    }).render(&w);
    const s = w.buffered();
    try std.testing.expect(std.mem.startsWith(u8, s, "<div class=\"zw-table-wrap\" id=\"t1\" tabindex=\"0\">"));
    try std.testing.expect(std.mem.find(u8, s, "<th scope=\"col\" aria-sort=\"descending\" class=\"zw-ta-right\">Amount</th>") != null);
    try std.testing.expect(std.mem.find(u8, s, "<td><b>ok</b></td>") != null);
    try std.testing.expect(std.mem.find(u8, s, "<tr aria-current=\"true\"><td>b</td><td><i></td>") != null);
    try std.testing.expect(std.mem.find(u8, s, "<td>a</td>") != null and std.mem.count(u8, s, "aria-current") == 1);
    try std.testing.expect(std.mem.find(u8, s, "<tfoot><tr><th scope=\"row\">Total</th><td></td><td class=\"zw-ta-right\">3&lt;</td></tr></tfoot>") != null);
}
