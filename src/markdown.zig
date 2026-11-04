//! Markdown subset -> HTML, rendered straight into a Writer. Safe for untrusted input:
//! raw HTML is escaped and links only allow http(s), mailto, relative paths and #anchors.
//!
//! Blocks: # headings (with id anchors), paragraphs, - and 1. lists, ``` fences (lang), > quotes
//! (`> [!NOTE]` / `[!TIP]` / `[!WARNING]` / `[!IMPORTANT]` / `[!CAUTION]` pick the callout kind), | tables |, --- rules.
//! Inline: `code`, **bold**, *em*, [text](url).
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("view.zig").writeEscaped;
const code = @import("ui/code.zig");

/// A markdown document as a component. `fences` may override fenced blocks:
/// a value with `fn fence(self, w: *Writer, lang: []const u8, body: []const u8) Writer.Error!bool`
/// (return true when handled). Pass `{}` for the default (highlighted code blocks).
pub fn Markdown(comptime Fences: type) type {
    return struct {
        src: []const u8,
        fences: Fences,
        pub fn render(self: @This(), w: *Writer) Writer.Error!void {
            try w.writeAll("<div class=\"zw-prose\">");
            try renderBlocks(w, self.src, self.fences);
            try w.writeAll("</div>");
        }
    };
}

pub fn markdown(src: []const u8) Markdown(void) {
    return .{ .src = src, .fences = {} };
}

pub fn markdownWith(src: []const u8, fences: anytype) Markdown(@TypeOf(fences)) {
    return .{ .src = src, .fences = fences };
}

pub fn renderBlocks(w: *Writer, src: []const u8, fences: anytype) Writer.Error!void {
    var lines = std.mem.splitScalar(u8, src, '\n');
    var pending: ?[]const u8 = null;
    while (pending orelse lines.next()) |raw| {
        pending = null;
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (line.len == 0) continue;

        if (std.mem.startsWith(u8, line, "```")) {
            const lang = std.mem.trim(u8, line[3..], " ");
            const start = lines.index orelse src.len;
            var end = start;
            while (lines.next()) |l| {
                if (std.mem.startsWith(u8, std.mem.trimStart(u8, l, " "), "```")) break;
                end = lines.index orelse src.len;
            }
            const body = std.mem.trimEnd(u8, src[start..@max(start, end)], "\n\r");
            if (@TypeOf(fences) == void or !(try fences.fence(w, lang, body))) try code.writeBlock(w, lang, body);
        } else if (heading(line)) |h| {
            try w.print("<h{d} id=\"", .{h.level});
            try slug(w, h.text);
            try w.writeAll("\">");
            try inline_(w, h.text);
            try w.print("</h{d}>", .{h.level});
        } else if (std.mem.eql(u8, line, "---")) {
            try w.writeAll("<hr>");
        } else if (line[0] == '>') {
            const first = std.mem.trim(u8, line[1..], " ");
            const kind = calloutKind(first);
            try w.print("<aside class=\"zw-callout zw-callout--{s}\"><p>", .{kind orelse "note"});
            if (kind == null) try inline_(w, first);
            var sep = kind == null;
            while (lines.next()) |q| {
                const t = std.mem.trimEnd(u8, q, " \r");
                if (t.len == 0 or t[0] != '>') {
                    pending = q;
                    break;
                }
                if (sep) try w.writeByte(' ');
                sep = true;
                try inline_(w, std.mem.trim(u8, t[1..], " "));
            }
            try w.writeAll("</p></aside>");
        } else if (listItem(line)) |item| {
            const tag: []const u8 = if (item.ordered) "ol" else "ul";
            try w.print("<{s}>", .{tag});
            var l: ?[]const u8 = line;
            while (l) |li| : (l = lines.next()) {
                const it = listItem(std.mem.trimEnd(u8, li, " \r")) orelse {
                    pending = li;
                    break;
                };
                if (it.ordered != item.ordered) {
                    pending = li;
                    break;
                }
                try w.writeAll("<li>");
                try inline_(w, it.text);
                try w.writeAll("</li>");
            }
            try w.print("</{s}>", .{tag});
        } else if (line[0] == '|') {
            try w.writeAll("<div class=\"zw-table-wrap\"><table class=\"zw-table\">");
            var row: usize = 0;
            var l: ?[]const u8 = line;
            while (l) |tl| : (l = lines.next()) {
                const t = std.mem.trim(u8, tl, " \r");
                if (t.len == 0 or t[0] != '|') {
                    pending = tl;
                    break;
                }
                defer row += 1;
                if (row == 1 and isSeparator(t)) continue;
                const cell: []const u8 = if (row == 0) "th" else "td";
                try w.writeAll(if (row == 0) "<thead><tr>" else "<tr>");
                var cells = std.mem.splitScalar(u8, std.mem.trim(u8, t, "|"), '|');
                while (cells.next()) |c| {
                    try w.print("<{s}>", .{cell});
                    try inline_(w, std.mem.trim(u8, c, " "));
                    try w.print("</{s}>", .{cell});
                }
                try w.writeAll(if (row == 0) "</tr></thead><tbody>" else "</tr>");
            }
            try w.writeAll("</tbody></table></div>");
        } else {
            try w.writeAll("<p>");
            try inline_(w, line);
            while (lines.next()) |pl| {
                const t = std.mem.trimEnd(u8, pl, " \r");
                if (t.len == 0 or startsBlock(t)) {
                    pending = pl;
                    break;
                }
                try w.writeByte(' ');
                try inline_(w, t);
            }
            try w.writeAll("</p>");
        }
    }
}

fn startsBlock(l: []const u8) bool {
    return heading(l) != null or listItem(l) != null or l[0] == '>' or l[0] == '|' or
        std.mem.startsWith(u8, l, "```") or std.mem.eql(u8, l, "---");
}

const Heading = struct { level: usize, text: []const u8 };

fn heading(l: []const u8) ?Heading {
    var n: usize = 0;
    while (n < l.len and l[n] == '#') n += 1;
    if (n == 0 or n > 4 or n >= l.len or l[n] != ' ') return null;
    return .{ .level = n, .text = std.mem.trim(u8, l[n..], " ") };
}

const Item = struct { ordered: bool, text: []const u8 };

fn listItem(l: []const u8) ?Item {
    if (std.mem.startsWith(u8, l, "- ") or std.mem.startsWith(u8, l, "* ")) return .{ .ordered = false, .text = l[2..] };
    var i: usize = 0;
    while (i < l.len and std.ascii.isDigit(l[i])) i += 1;
    if (i > 0 and i + 1 < l.len and l[i] == '.' and l[i + 1] == ' ') return .{ .ordered = true, .text = l[i + 2 ..] };
    return null;
}

fn isSeparator(l: []const u8) bool {
    for (l) |c| if (c != '|' and c != '-' and c != ':' and c != ' ') return false;
    return true;
}

fn calloutKind(text: []const u8) ?[]const u8 {
    const kinds = [_][2][]const u8{ .{ "[!NOTE]", "note" }, .{ "[!TIP]", "tip" }, .{ "[!WARNING]", "warning" }, .{ "[!IMPORTANT]", "important" }, .{ "[!CAUTION]", "caution" } };
    for (kinds) |k| if (std.ascii.eqlIgnoreCase(text, k[0])) return k[1];
    return null;
}

/// Heading text -> anchor id: lowercase letters and digits, other runs become '-'.
pub fn slug(w: *Writer, text: []const u8) Writer.Error!void {
    var dash = false;
    var wrote = false;
    for (text) |c| {
        if (std.ascii.isAlphanumeric(c)) {
            if (dash and wrote) try w.writeByte('-');
            try w.writeByte(std.ascii.toLower(c));
            dash = false;
            wrote = true;
        } else dash = true;
    }
}

fn inline_(w: *Writer, s: []const u8) Writer.Error!void {
    var i: usize = 0;
    var start: usize = 0;
    while (i < s.len) {
        const c = s[i];
        const span: ?Span = switch (c) {
            '`' => wrap(s, i, "`", "code"),
            '*' => if (i + 1 < s.len and s[i + 1] == '*') wrap(s, i, "**", "strong") else wrap(s, i, "*", "em"),
            '[' => link(s, i),
            else => null,
        };
        if (span) |sp| {
            try writeEscaped(w, s[start..i]);
            if (sp.href) |href| {
                try w.writeAll("<a href=\"");
                try writeEscaped(w, href);
                try w.writeAll("\">");
                try inline_(w, sp.inner);
                try w.writeAll("</a>");
            } else {
                try w.print("<{s}>", .{sp.tag});
                if (std.mem.eql(u8, sp.tag, "code")) try writeEscaped(w, sp.inner) else try inline_(w, sp.inner);
                try w.print("</{s}>", .{sp.tag});
            }
            i = sp.end;
            start = i;
        } else i += 1;
    }
    try writeEscaped(w, s[start..]);
}

const Span = struct { tag: []const u8 = "", inner: []const u8, end: usize, href: ?[]const u8 = null };

fn wrap(s: []const u8, i: usize, mark: []const u8, tag: []const u8) ?Span {
    const from = i + mark.len;
    const close = std.mem.findPos(u8, s, from, mark) orelse return null;
    // Markers must hug their text: `2 * 3` is not emphasis.
    if (close == from or s[from] == ' ' or s[close - 1] == ' ') return null;
    return .{ .tag = tag, .inner = s[from..close], .end = close + mark.len };
}

fn link(s: []const u8, i: usize) ?Span {
    const close = std.mem.findScalarPos(u8, s, i, ']') orelse return null;
    if (close + 1 >= s.len or s[close + 1] != '(') return null;
    const end = std.mem.findScalarPos(u8, s, close, ')') orelse return null;
    const href = s[close + 2 .. end];
    if (!safeHref(href)) return null;
    return .{ .inner = s[i + 1 .. close], .end = end + 1, .href = href };
}

fn safeHref(h: []const u8) bool {
    if (h.len == 0) return false;
    if (h[0] == '/' or h[0] == '#' or h[0] == '.') return true;
    for ([_][]const u8{ "https://", "http://", "mailto:" }) |p| if (std.ascii.startsWithIgnoreCase(h, p)) return true;
    // Relative path without a scheme: no ':' before the first '/'.
    const colon = std.mem.findScalar(u8, h, ':') orelse return true;
    const slash = std.mem.findScalar(u8, h, '/') orelse h.len;
    return slash < colon;
}

fn expectMd(expected: []const u8, src: []const u8) !void {
    var buf: [4096]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try renderBlocks(&w, src, {});
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test "blocks" {
    try expectMd("<h2 id=\"hello-world\">Hello, <code>world</code></h2><p>one two</p>", "## Hello, `world`\n\none\ntwo\n");
    try expectMd("<ul><li>a</li><li><strong>b</strong></li></ul><ol><li>c</li></ol>", "- a\n- **b**\n1. c\n");
    try expectMd("<aside class=\"zw-callout zw-callout--tip\"><p>Use <em>this</em>.</p></aside><p>after</p>", "> [!TIP]\n> Use *this*.\nafter\n");
    try expectMd(
        "<div class=\"zw-table-wrap\"><table class=\"zw-table\"><thead><tr><th>A</th><th>B</th></tr></thead><tbody><tr><td><code>x</code></td><td>y</td></tr></tbody></table></div>",
        "| A | B |\n|---|---|\n| `x` | y |\n",
    );
    try expectMd("<hr><p>x</p>", "---\nx");
}

test "quotes stream every line" {
    try expectMd("<aside class=\"zw-callout zw-callout--important\"><p>Read <strong>this</strong> first.</p></aside>", "> [!IMPORTANT]\n> Read **this**\n> first.\n");
    var src_buf: [1024]u8 = undefined;
    var src: Writer = .fixed(&src_buf);
    var want_buf: [1024]u8 = undefined;
    var want: Writer = .fixed(&want_buf);
    try want.writeAll("<aside class=\"zw-callout zw-callout--note\"><p>");
    for (0..70) |i| {
        try src.print("> l{d}\n", .{i});
        try want.print("{s}l{d}", .{ if (i > 0) " " else "", i });
    }
    try want.writeAll("</p></aside>");
    try expectMd(want.buffered(), src.buffered());
}

test "inline safety" {
    try expectMd("<p>&lt;script&gt; <a href=\"/docs\">docs</a> [bad](javascript:alert(1)) <code>&lt;b&gt;</code></p>", "<script> [docs](/docs) [bad](javascript:alert(1)) `<b>`");
    try expectMd("<p>2 * 3 and a ** b</p>", "2 * 3 and a ** b");
}

test "fences use the hook, then default code blocks" {
    const Hook = struct {
        fn fence(_: @This(), w: *Writer, lang: []const u8, body: []const u8) Writer.Error!bool {
            if (!std.mem.eql(u8, lang, "demo")) return false;
            try w.print("[demo:{s}]", .{body});
            return true;
        }
    };
    var buf: [2048]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try renderBlocks(&w, "```demo\nbutton\n```\n```sh\nzig build\n```", Hook{});
    const out = w.buffered();
    try std.testing.expect(std.mem.startsWith(u8, out, "[demo:button]<figure class=\"zw-code\""));
    try std.testing.expect(std.mem.find(u8, out, "zig build</code>") != null);
}
