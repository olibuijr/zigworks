//! Live demos for docs/pages/components/code.md (```demo code``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "code", true, code },
    .{ "code-options", true, options },
    .{ "code-states", true, states },
    .{ "code-playground", true, playground },
    .{ "code-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-code-label{margin-bottom:6px;font:var(--callout);color:var(--secondary)}
    \\.demo-code-status{display:flex;flex-wrap:wrap;align-items:center;gap:8px;font:var(--callout);color:var(--secondary)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/code/x", handler }`.
pub const routes = .{
    .{ "POST /demo/code/preview", preview },
};

/// A caption (trusted markup) above one block.
const item = "<div><p class=\"demo-code-label\">{@html label}</p>{block}</div>";

fn code(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Add a route",
        .subtitle = "Handlers take a Ctx and return an error union",
        .accessory = ui.badge(.{ .text = "Zig", .tone = .accent }),
        .footer = "Lines 4 and 9-10 are new.",
        .body = zw.view("<div class=\"zw-stack\">{a}<p>Run the server, then open the page:</p>{b}</div>", .{
            .a = ui.code(.{
                .title = "src/main.zig",
                .numbers = true,
                .highlight = "4,9-10",
                .src =
                \\const app = .{
                \\    .routes = .{
                \\        .{ "GET /", index },
                \\        .{ "GET /hello", hello },
                \\    },
                \\};
                \\
                \\fn hello(c: *zw.Ctx) !void {
                \\    const name = c.query("name") orelse "world";
                \\    try c.html("<h1>Hello, {name}</h1>", .{ .name = name });
                \\}
                ,
            }),
            .b = ui.code(.{
                .lang = "sh",
                .src =
                \\zig build run
                \\curl 'localhost:8080/hello?name=Ada'
                ,
            }),
        }),
    }).render(w);
}

fn options(w: *Writer) Writer.Error!void {
    const excerpt =
        \\    var it = std.mem.tokenizeScalar(u8, spec, ',');
        \\    while (it.next()) |part| {
        \\        const t = std.mem.trim(u8, part, " ");
        \\        try writeBand(w, t);
        \\    }
    ;
    try zw.view(item, .{ .label = "<code>lang</code> and <code>src</code>: the label, and highlighting for <code>zig</code> only", .block = ui.code(.{ .lang = "sh", .src = "zig build test --summary all" }) }).render(w);
    try zw.view(item, .{ .label = "<code>title</code>: a file name; the language moves beside it", .block = ui.code(.{ .title = "build.zig", .src = "pub fn build(b: *std.Build) void {\n    _ = b;\n}" }) }).render(w);
    try zw.view(item, .{ .label = "<code>numbers</code>, <code>start</code> and <code>highlight</code>: an excerpt from line 120, lines 120 and 122-123 marked", .block = ui.code(.{
        .title = "src/ui/code.zig",
        .numbers = true,
        .start = 120,
        .highlight = "120,122-123",
        .src = excerpt,
    }) }).render(w);
    try zw.view(item, .{ .label = "<code>copy = false</code>: no Copy button", .block = ui.code(.{ .lang = "text", .copy = false, .src = "Read-only output, nothing to copy." }) }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    const long = "const url = \"https://example.com/api/v1/projects/zigworks/releases/latest/download/zigworks-x86_64-linux.tar.xz\";";
    try zw.view(item, .{ .label = "Default: a long line scrolls sideways", .block = ui.code(.{ .title = "download.zig", .src = long }) }).render(w);
    try zw.view(item, .{ .label = "<code>wrap = true</code>: the line wraps. <code>numbers</code> and <code>highlight</code> are set here but ignored", .block = ui.code(.{
        .title = "download.zig",
        .wrap = true,
        .numbers = true,
        .highlight = "1",
        .src = long,
    }) }).render(w);
    try zw.view(item, .{ .label = "Another <code>lang</code>: shown as plain text with its label", .block = ui.code(.{
        .lang = "log",
        .src = "12:01:07 GET /hello 200 1.2ms\n12:01:09 GET /missing 404 0.3ms",
    }) }).render(w);
    try zw.view(item, .{ .label = "Empty <code>lang</code>: just the file name", .block = ui.code(.{ .lang = "", .title = "Dockerfile", .src = "FROM scratch\nCOPY zig-out/bin/app /app\nENTRYPOINT [\"/app\"]" }) }).render(w);
    try zw.view(item, .{ .label = "Empty <code>src</code>", .block = ui.code(.{ .lang = "sh", .src = "", .copy = false }) }).render(w);
    try zw.view(item, .{ .label = "Bad <code>highlight</code> parts are skipped: <code>2,x,4-3</code> marks line 2 only", .block = ui.code(.{
        .lang = "sh",
        .numbers = true,
        .highlight = "2,x,4-3",
        .src = "zig build\nzig build test\nzig build run",
    }) }).render(w);
}

// Playground: the form posts on every change and the server renders the block again.
// All state is in the request.

const Play = struct {
    sample: []const u8 = "zig",
    title: bool = true,
    numbers: bool = true,
    wrap: bool = false,
    copy: bool = true,
    hl: []const u8 = "2",
};

const Sample = struct { lang: []const u8, file: []const u8, src: []const u8 };

const samples = [_]Sample{
    .{ .lang = "zig", .file = "hello.zig", .src =
    \\const std = @import("std");
    \\
    \\pub fn main() !void {
    \\    const name = "zigworks";
    \\    std.debug.print("Hello, {s}!\n", .{name});
    \\}
    },
    .{ .lang = "sh", .file = "release.sh", .src =
    \\set -e
    \\zig build -Doptimize=ReleaseSafe
    \\zig build test --summary all
    \\cp zig-out/bin/app /usr/local/bin/app
    },
    .{ .lang = "json", .file = "package.json", .src =
    \\{
    \\  "name": "zigworks",
    \\  "version": "0.2.0",
    \\  "private": true
    \\}
    },
};

fn sampleFor(key: []const u8) Sample {
    for (samples) |s| if (std.mem.eql(u8, s.lang, key)) return s;
    return samples[0];
}

fn playBlock(p: Play) ui.Code {
    const s = sampleFor(p.sample);
    return ui.code(.{ .lang = s.lang, .title = if (p.title) s.file else "", .src = s.src, .numbers = p.numbers, .highlight = p.hl, .wrap = p.wrap, .copy = p.copy });
}

fn playStatus(p: Play, oob: bool) ui.Badge {
    const ignored = p.wrap and (p.numbers or p.hl.len > 0);
    return ui.badge(.{
        .id = "demo-code-status",
        .oob = oob,
        .text = if (ignored) "Wrap turns off numbers and highlight" else if (p.wrap) "Long lines wrap" else "Long lines scroll",
        .tone = if (ignored) .orange else .green,
    });
}

fn preview(c: *zw.Ctx) !void {
    const hl = c.form("hl") orelse "";
    const p: Play = .{
        .sample = c.form("sample") orelse "zig",
        .title = c.form("title") != null,
        .numbers = c.form("numbers") != null,
        .wrap = c.form("wrap") != null,
        .copy = c.form("copy") != null,
        .hl = if (std.mem.eql(u8, hl, "none")) "" else hl,
    };
    try c.html("{a}{b}", .{ .a = playBlock(p), .b = playStatus(p, true) });
}

fn playground(w: *Writer) Writer.Error!void {
    const p: Play = .{};
    try zw.view("<form class=\"zw-stack\"{z}>{sample}{hl}{toggles}</form><div id=\"demo-code-out\">{block}</div><div class=\"demo-code-status\">Result: {status}</div>", .{
        .z = ui.Z{ .post = "/demo/code/preview", .trigger = "change", .target = "#demo-code-out", .swap = .inner, .keep = true },
        .sample = ui.segmented(.{ .name = "sample", .label = "Sample", .full = true, .options = &.{
            .{ .value = "zig", .label = "Zig", .selected = true },
            .{ .value = "sh", .label = "Shell" },
            .{ .value = "json", .label = "JSON" },
        } }),
        .hl = ui.segmented(.{ .name = "hl", .label = "Highlight", .full = true, .size = .small, .options = &.{
            .{ .value = "none", .label = "No highlight" },
            .{ .value = "2", .label = "Line 2", .selected = true },
            .{ .value = "3-4", .label = "Lines 3-4" },
        } }),
        .toggles = ui.card(.{ .variant = .inset, .body = zw.view("{a}{b}{c}{d}", .{
            .a = ui.toggle(.{ .name = "title", .label = "File name", .on = p.title }),
            .b = ui.toggle(.{ .name = "numbers", .label = "Line numbers", .on = p.numbers }),
            .c = ui.toggle(.{ .name = "wrap", .label = "Wrap long lines", .on = p.wrap }),
            .d = ui.toggle(.{ .name = "copy", .label = "Copy button", .on = p.copy }),
        }) }),
        .block = playBlock(p),
        .status = playStatus(p, false),
    }).render(w);
}

fn compose(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Install",
        .subtitle = "Add zigworks to a project",
        .body = zw.view("<div class=\"zw-stack\">{tabs}{note}</div>", .{
            .tabs = ui.tabs(.{ .id = "demo-code-install", .labels = &.{ "Fetch", "build.zig.zon", "build.zig" }, .panels = .{
                ui.code(.{ .lang = "sh", .src = "zig fetch --save git+https://example.com/zigworks.git" }),
                ui.code(.{
                    .lang = "zon",
                    .title = "build.zig.zon",
                    .numbers = true,
                    .highlight = "4-7",
                    .src =
                    \\.{
                    \\    .name = .app,
                    \\    .dependencies = .{
                    \\        .zigworks = .{
                    \\            .url = "git+https://example.com/zigworks.git",
                    \\            .hash = "...",
                    \\        },
                    \\    },
                    \\}
                    ,
                }),
                ui.code(.{
                    .title = "build.zig",
                    .numbers = true,
                    .start = 12,
                    .src =
                    \\const zw = b.dependency("zigworks", .{});
                    \\exe.root_module.addImport("zigworks", zw.module("zigworks"));
                    ,
                }),
            } }),
            .note = ui.callout(.{ .kind = .tip, .compact = true, .title = "Tip", .body = "The Copy button copies the code only, never the line numbers." }),
        }),
    }).render(w);
    try ui.disclosure(.{
        .title = "Show the hash",
        .style = .card,
        .detail = "build.zig.zon",
        .body = ui.code(.{ .lang = "sh", .wrap = true, .src = "zig fetch git+https://example.com/zigworks.git  # prints the hash to paste into .hash" }),
    }).render(w);
}
