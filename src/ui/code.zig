//! Code block with a language label and a Copy button. Zig is highlighted on the server.
//! Optional file name, line numbers, highlighted lines and soft wrapping.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;
const highlight = @import("../highlight.zig");

pub const css =
    \\.zw-code{--lh:18px;border-radius:var(--radius-control);background:var(--code-bg);box-shadow:inset 0 0 0 .5px var(--separator);overflow:hidden;
    \\  & figcaption{display:flex;align-items:center;justify-content:space-between;gap:8px;min-height:30px;padding:0 6px 0 12px;font:var(--callout);color:var(--secondary);border-bottom:1px solid var(--separator);
    \\    @media (pointer:coarse){min-height:44px}}
    \\  & pre{padding:12px 14px;overflow-x:auto;font:12px/var(--lh) var(--mono);color:var(--label);tab-size:4}
    \\  & .zw-code-gutter{flex:none;overflow:hidden;padding:12px 10px 12px 14px;text-align:right;color:var(--tertiary);user-select:none;border-right:1px solid var(--separator)}}
    \\.zw-code-title{color:var(--label);font-weight:500}
    \\.zw-code-lang{margin-left:6px}
    \\.zw-code-body{position:relative;display:flex;
    \\  &>pre{position:relative;flex:1;min-width:0}}
    \\.zw-code-hl{position:absolute;inset:calc(12px + var(--l) * var(--lh)) 0 auto;height:calc(var(--n) * var(--lh));pointer-events:none;
    \\background:color-mix(in srgb,var(--accent) 14%,transparent);box-shadow:inset 2px 0 0 var(--accent)}
    \\.zw-code--wrap pre{overflow-x:visible;white-space:pre-wrap;overflow-wrap:anywhere}
    \\.zw-copy{appearance:none;border:0;background:transparent;color:var(--secondary);font:var(--callout);font-weight:500;height:22px;padding:0 8px;border-radius:5px;cursor:default;
    \\  &:hover{background:var(--fill);color:var(--label)}
    \\  &.zw-copied{color:var(--green)}
    \\  @media (pointer:coarse){height:34px;padding:0 12px}}
    \\.tok-keyword{color:var(--tok-keyword)}
    \\.tok-string{color:var(--tok-string)}
    \\.tok-number{color:var(--tok-number)}
    \\.tok-comment{color:var(--tok-comment);font-style:italic}
    \\.tok-type{color:var(--tok-type)}
    \\.tok-builtin,.tok-fn{color:var(--tok-fn)}
    \\
;

pub const Props = struct {
    /// "zig" is highlighted; anything else is shown as plain text with this label.
    lang: []const u8 = "zig",
    src: []const u8,
    /// File name shown in the caption, such as "src/main.zig"; the language moves beside it.
    title: []const u8 = "",
    /// Line numbers in a gutter (ignored with `wrap`).
    numbers: bool = false,
    /// Number of the first line, for excerpts.
    start: u32 = 1,
    /// Lines to highlight, by number: "3" or "2,5-7" (ignored with `wrap`).
    highlight: []const u8 = "",
    /// Wrap long lines instead of scrolling sideways.
    wrap: bool = false,
    /// Show the Copy button.
    copy: bool = true,
};

/// Writes the full block. Used by markdown fences.
pub fn writeBlock(w: *Writer, lang: []const u8, src: []const u8) Writer.Error!void {
    try writeProps(w, .{ .lang = lang, .src = src });
}

pub fn writeProps(w: *Writer, p: Props) Writer.Error!void {
    const lines = lineCount(p.src);
    try w.writeAll(if (p.wrap) "<figure class=\"zw-code zw-code--wrap\"><figcaption><span>" else "<figure class=\"zw-code\"><figcaption><span>");
    if (p.title.len > 0) {
        try w.writeAll("<span class=\"zw-code-title\">");
        try writeEscaped(w, p.title);
        try w.writeAll("</span>");
        if (p.lang.len > 0) {
            try w.writeAll("<span class=\"zw-code-lang\">");
            try writeEscaped(w, p.lang);
            try w.writeAll("</span>");
        }
    } else try writeEscaped(w, if (p.lang.len > 0) p.lang else "text");
    try w.writeAll("</span>");
    if (p.copy) try w.writeAll("<button type=\"button\" class=\"zw-copy\" data-copy aria-label=\"Copy code\">Copy</button>");
    try w.writeAll("</figcaption>");
    const plain = !p.wrap and (p.numbers or p.highlight.len > 0);
    if (plain) {
        try w.writeAll("<div class=\"zw-code-body\">");
        try writeBands(w, p.highlight, p.start);
        if (p.numbers) {
            try w.writeAll("<pre class=\"zw-code-gutter\" aria-hidden=\"true\">");
            for (0..lines) |i| {
                if (i > 0) try w.writeByte('\n');
                try w.print("{d}", .{@as(usize, p.start) + i});
            }
            try w.writeAll("</pre>");
        }
    }
    try w.writeAll("<pre tabindex=\"0\"><code>");
    try highlight.write(w, p.lang, p.src);
    try w.writeAll("</code></pre>");
    if (plain) try w.writeAll("</div>");
    try w.writeAll("</figure>");
}

/// Number of lines, not counting a final newline.
fn lineCount(src: []const u8) usize {
    var n: usize = 1;
    for (src, 0..) |c, i| {
        if (c == '\n' and i + 1 < src.len) n += 1;
    }
    return n;
}

/// One band per range in "2,5-7" (numbers relative to `start`); bad parts are skipped.
fn writeBands(w: *Writer, spec: []const u8, start: u32) Writer.Error!void {
    var it = std.mem.tokenizeScalar(u8, spec, ',');
    while (it.next()) |part| {
        const t = std.mem.trim(u8, part, " ");
        const a_s, const b_s = std.mem.cutScalar(u8, t, '-') orelse .{ t, t };
        const a = std.fmt.parseInt(u32, std.mem.trim(u8, a_s, " "), 10) catch continue;
        const b = std.fmt.parseInt(u32, std.mem.trim(u8, b_s, " "), 10) catch continue;
        if (b < a or a < start) continue;
        try w.print("<span class=\"zw-code-hl\" aria-hidden=\"true\" style=\"--l:{d};--n:{d}\"></span>", .{ a - start, b - a + 1 });
    }
}

pub const Code = struct {
    p: Props,
    pub fn render(self: Code, w: *Writer) Writer.Error!void {
        try writeProps(w, self.p);
    }
};

pub fn code(p: Props) Code {
    return .{ .p = p };
}

fn expectHas(p: Props, needle: []const u8) !void {
    var buf: [4096]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try code(p).render(&w);
    try std.testing.expect(std.mem.find(u8, w.buffered(), needle) != null);
}

test "caption, numbers, highlighted lines, wrap" {
    try expectHas(.{ .lang = "sh", .src = "ls" }, "<figure class=\"zw-code\"><figcaption><span>sh</span>");
    try expectHas(.{ .src = "a", .title = "main.zig" }, "<span class=\"zw-code-title\">main.zig</span><span class=\"zw-code-lang\">zig</span>");
    try expectHas(.{ .lang = "sh", .src = "a\nb\n", .numbers = true, .start = 5 }, "<pre class=\"zw-code-gutter\" aria-hidden=\"true\">5\n6</pre>");
    try expectHas(.{ .lang = "sh", .src = "a\nb\nc", .highlight = "2-3, x" }, "--l:1;--n:2");
    try expectHas(.{ .lang = "sh", .src = "a", .wrap = true, .numbers = true }, "zw-code--wrap");
    try expectHas(.{ .lang = "sh", .src = "a", .copy = false }, "</span></figcaption>");
}
