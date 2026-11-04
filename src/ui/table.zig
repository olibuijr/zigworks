//! Data table: text cells, header row, zebra-free hairlines (macOS). Scrolls sideways on narrow screens.
//! Markdown tables render the same markup.
const zv = @import("../view.zig");

pub const css =
    \\.zw-table-wrap{overflow-x:auto;border-radius:var(--radius-control);box-shadow:inset 0 0 0 .5px var(--separator)}
    \\.zw-table{width:100%;border-collapse:collapse;font:var(--body)}
    \\.zw-table th{font:var(--callout);font-weight:600;color:var(--secondary);text-align:left;background:var(--fill)}
    \\.zw-table th,.zw-table td{padding:7px 12px;border-bottom:1px solid var(--separator);vertical-align:top}
    \\.zw-table tr:last-child td{border-bottom:0}
    \\.zw-table code{white-space:nowrap}
    \\
;

pub const Props = struct {
    head: []const []const u8,
    rows: []const []const []const u8,
};

const src = "<div class=\"zw-table-wrap\"><table class=\"zw-table\"><thead><tr>{#each head as h}<th>{h}</th>{/each}</tr></thead>" ++
    "<tbody>{#each rows as r}<tr>{#each r as cell}<td>{cell}</td>{/each}</tr>{/each}</tbody></table></div>";

pub const Table = zv.View(src, Props);

pub fn table(p: Props) Table {
    return .{ .data = p };
}
