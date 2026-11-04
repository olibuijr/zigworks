//! Server-side syntax highlighting. Zig uses the compiler's own tokenizer (std.zig.Tokenizer);
//! other languages are escaped as plain text. Emits <span class="tok-..."> wrapped tokens.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("view.zig").writeEscaped;

/// Writes `code` as highlighted HTML (no surrounding <pre>).
pub fn write(w: *Writer, lang: []const u8, code: []const u8) Writer.Error!void {
    if (std.mem.eql(u8, lang, "zig")) return zig(w, code);
    try writeEscaped(w, code);
}

fn zig(w: *Writer, code: []const u8) Writer.Error!void {
    // ponytail: the tokenizer needs a 0-terminated copy; longer snippets fall back to plain text.
    var buf: [32 * 1024]u8 = undefined;
    if (code.len >= buf.len) return writeEscaped(w, code);
    @memcpy(buf[0..code.len], code);
    buf[code.len] = 0;
    const src: [:0]const u8 = buf[0..code.len :0];

    var tokenizer: std.zig.Tokenizer = .init(src);
    var at: usize = 0;
    while (true) {
        const tok = tokenizer.next();
        if (tok.tag == .eof) break;
        try gap(w, src[at..tok.loc.start]);
        const text = src[tok.loc.start..tok.loc.end];
        if (class(tok.tag, text, src[tok.loc.end..])) |cls| {
            try w.print("<span class=\"tok-{s}\">", .{cls});
            try writeEscaped(w, text);
            try w.writeAll("</span>");
        } else try writeEscaped(w, text);
        at = tok.loc.end;
    }
    try gap(w, src[at..]);
}

/// Text between tokens: whitespace and `//` comments (the tokenizer skips both).
fn gap(w: *Writer, text: []const u8) Writer.Error!void {
    var rest = text;
    while (std.mem.find(u8, rest, "//")) |i| {
        try writeEscaped(w, rest[0..i]);
        const end = std.mem.findScalarPos(u8, rest, i, '\n') orelse rest.len;
        try w.writeAll("<span class=\"tok-comment\">");
        try writeEscaped(w, rest[i..end]);
        try w.writeAll("</span>");
        rest = rest[end..];
    }
    try writeEscaped(w, rest);
}

fn class(tag: std.zig.Token.Tag, text: []const u8, after: []const u8) ?[]const u8 {
    return switch (tag) {
        .string_literal, .multiline_string_literal_line, .char_literal => "string",
        .number_literal => "number",
        .builtin => "builtin",
        .doc_comment, .container_doc_comment => "comment",
        .identifier => if (std.ascii.isUpper(text[0]) or isPrimitive(text))
            "type"
        else if (std.mem.trimStart(u8, after, " ").len > 0 and std.mem.trimStart(u8, after, " ")[0] == '(')
            "fn"
        else
            null,
        else => if (std.mem.startsWith(u8, @tagName(tag), "keyword_")) "keyword" else null,
    };
}

fn isPrimitive(s: []const u8) bool {
    const names = [_][]const u8{ "void", "bool", "type", "anyerror", "noreturn", "usize", "isize", "comptime_int", "comptime_float", "f16", "f32", "f64", "f128", "true", "false", "null", "undefined" };
    for (names) |n| if (std.mem.eql(u8, s, n)) return true;
    if (s.len >= 2 and (s[0] == 'u' or s[0] == 'i')) {
        for (s[1..]) |c| if (!std.ascii.isDigit(c)) return false;
        return true;
    }
    return false;
}

test "zig highlighting" {
    var buf: [1024]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try write(&w, "zig", "const x: u8 = @intCast(f(1)); // hi <b>\n");
    try std.testing.expectEqualStrings(
        "<span class=\"tok-keyword\">const</span> x: <span class=\"tok-type\">u8</span> = <span class=\"tok-builtin\">@intCast</span>(<span class=\"tok-fn\">f</span>(<span class=\"tok-number\">1</span>)); <span class=\"tok-comment\">// hi &lt;b&gt;</span>\n",
        w.buffered(),
    );
}

test "plain languages are escaped" {
    var buf: [64]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try write(&w, "sh", "echo <x>");
    try std.testing.expectEqualStrings("echo &lt;x&gt;", w.buffered());
}
