# Markdown

`zw.markdown(src)` renders a Markdown subset straight into the response. It is safe for user input: raw HTML is escaped and links only allow `http(s)`, `mailto`, relative paths and anchors. This site's pages are Markdown files embedded with `@embedFile`.

```zig
const page = @embedFile("pages/intro.md");

fn intro(c: *zw.Ctx) !void {
    try c.page(ui.layout(.{ .title = "Intro", .body = zw.markdown(page) }));
}
```

## Supported syntax

| Block | Syntax |
|---|---|
| Headings | `#` to `####`, each gets an `id` anchor |
| Lists | `- item` and `1. item` |
| Code | three backticks and a language; `zig` is highlighted |
| Callouts | `> [!NOTE]`, `> [!TIP]`, `> [!WARNING]` |
| Tables | pipes with a `|---|` separator row |
| Rules | `---` |

Inline: backtick code, `**bold**`, `*emphasis*` and `[links](/path)`.

> [!NOTE]
> Lists do not nest, and there is no inline HTML. That keeps the renderer small and the output safe.

## Highlighting

Zig code is highlighted on the server with the compiler's own tokenizer, so the browser downloads no highlighter. `zw.highlight(w, "zig", src)` is available on its own.

## Custom fences

`zw.markdownWith(src, fences)` lets a fence render anything. This site turns `demo` fences into live components:

```zig
pub const Fences = struct {
    pub fn fence(_: Fences, w: *Writer, lang: []const u8, body: []const u8) Writer.Error!bool {
        if (!std.mem.eql(u8, lang, "demo")) return false; // fall back to a code block
        try renderDemo(w, body);
        return true;
    }
};
```
