//! Code block with a language label and a Copy button. Zig is highlighted on the server.
const std = @import("std");
const Writer = std.Io.Writer;
const writeEscaped = @import("../view.zig").writeEscaped;
const highlight = @import("../highlight.zig");

pub const css =
    \\.zw-code{margin:0;border-radius:var(--radius-control);background:var(--code-bg);box-shadow:inset 0 0 0 .5px var(--separator);overflow:hidden}
    \\.zw-code figcaption{display:flex;align-items:center;justify-content:space-between;height:30px;padding:0 6px 0 12px;font:var(--callout);color:var(--secondary);border-bottom:1px solid var(--separator)}
    \\.zw-code pre{margin:0;padding:12px 14px;overflow-x:auto;font:12px/18px var(--mono);color:var(--label);tab-size:4}
    \\.zw-copy{appearance:none;border:0;background:transparent;color:var(--secondary);font:var(--callout);font-weight:500;height:22px;padding:0 8px;border-radius:5px;cursor:default}
    \\.zw-copy:hover{background:var(--fill);color:var(--label)}
    \\.tok-keyword{color:var(--tok-keyword)}.tok-string{color:var(--tok-string)}.tok-number{color:var(--tok-number)}
    \\.tok-comment{color:var(--tok-comment);font-style:italic}.tok-type{color:var(--tok-type)}.tok-builtin,.tok-fn{color:var(--tok-fn)}
    \\
;

/// Writes the full block. Used by `code(...)` and by markdown fences.
pub fn writeBlock(w: *Writer, lang: []const u8, src: []const u8) Writer.Error!void {
    try w.writeAll("<figure class=\"zw-code\"><figcaption><span>");
    try writeEscaped(w, if (lang.len > 0) lang else "text");
    try w.writeAll("</span><button type=\"button\" class=\"zw-copy\" data-copy aria-label=\"Copy code\">Copy</button></figcaption><pre><code>");
    try highlight.write(w, lang, src);
    try w.writeAll("</code></pre></figure>");
}

pub const Props = struct {
    /// "zig" is highlighted; anything else is shown as plain text with this label.
    lang: []const u8 = "zig",
    src: []const u8,
};

pub const Code = struct {
    p: Props,
    pub fn render(self: Code, w: *Writer) Writer.Error!void {
        try writeBlock(w, self.p.lang, self.p.src);
    }
};

pub fn code(p: Props) Code {
    return .{ .p = p };
}
