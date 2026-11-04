//! Live demos for docs/pages/components/tag.md (```demo tag``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "tag", true, hero },
    .{ "tag-variants", true, variants },
    .{ "tag-states", true, states },
    .{ "tag-filter", true, filter },
    .{ "tag-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-tag-add{margin-top:12px}
    \\.demo-tag-rows{display:grid;grid-template-columns:max-content 1fr;gap:14px 16px;align-items:center;margin:0}
    \\.demo-tag-rows>dt{font:var(--callout);color:var(--secondary)}
    \\.demo-tag-rows>dd{margin:0}
    \\@media (max-width:599px){.demo-tag-rows{grid-template-columns:1fr;gap:6px}.demo-tag-rows>dd{margin-bottom:8px}}
    \\.demo-tag-filter{margin-bottom:12px}
    \\.demo-tag-star{color:var(--orange)}
    \\.demo-tag-issues>li{padding-block:10px}
    \\.demo-tag-issue{display:flex;flex-direction:column;align-items:flex-start;gap:4px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/tag/x", handler }`.
pub const routes = .{
    .{ "POST /demo/tag/add", add },
    .{ "DELETE /demo/tag/remove", remove },
    .{ "GET /demo/tag/files", files },
};

// ---- Hero: a note with removable tags and an "add tag" form ----

fn hero(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Weekend in Lisbon",
        .subtitle = "Notes · Edited today",
        .footer = "Tags help you find this note again.",
        .body = zw.view(
            \\<div class="zw-tags" id="demo-tag-note">{a}{b}{c}</div>
            \\<form class="zw-row demo-tag-add"{z}>{field}{button}</form>
        , .{
            .a = ui.tag(.{ .text = "Travel", .icon = "✈", .remove = .{ .delete = "/demo/tag/remove?t=Travel" } }),
            .b = ui.tag(.{ .text = "Restaurants", .tone = .orange, .remove = .{ .delete = "/demo/tag/remove?t=Restaurants" } }),
            .c = ui.tag(.{ .text = "Photos", .tone = .green, .remove = .{ .delete = "/demo/tag/remove?t=Photos" } }),
            .z = ui.Z{ .post = "/demo/tag/add", .target = "#demo-tag-note", .swap = .beforeend },
            .field = ui.field(.{ .name = "demo-tag-new", .label = "New tag", .placeholder = "Add a tag", .required = true }),
            .button = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
        }),
    }).render(w);
}

/// POST /demo/tag/add: answers with a new removable tag; the page appends it.
fn add(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("demo-tag-new") orelse "", " ");
    if (name.len == 0 or name.len > 24) return c.send(.no_content, "text/plain", "");
    const url = try std.fmt.allocPrint(c.arena, "/demo/tag/remove?t={f}", .{std.fmt.alt(std.Uri.Component{ .raw = name }, .formatEscaped)});
    try c.page(ui.tag(.{ .text = name, .remove = .{ .delete = url } }));
}

/// DELETE /demo/tag/remove?t=...: the toast goes out of band; z.js then deletes the tag (an empty 204 would not).
fn remove(c: *zw.Ctx) !void {
    const name = c.query("t") orelse "tag";
    try c.page(ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Removed “{s}”", .{name}) }));
}

// ---- Variants and sizes, one row per prop ----

fn variants(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<dl class="demo-tag-rows">
        \\<dt><code>tone</code></dt><dd class="zw-tags">{t1}{t2}{t3}{t4}{t5}</dd>
        \\<dt><code>size</code></dt><dd class="zw-tags">{s1}{s2}{s3}</dd>
        \\<dt><code>icon</code></dt><dd class="zw-tags">{i1}{i2}{i3}</dd>
        \\<dt><code>href</code></dt><dd class="zw-tags">{h1}{h2}</dd>
        \\<dt><code>remove</code></dt><dd class="zw-tags">{r1}{r2}{r3}</dd>
        \\<dt><code>text</code></dt><dd class="zw-tags">{x1}</dd>
        \\</dl>
    , .{
        .t1 = ui.tag(.{ .text = "accent" }),
        .t2 = ui.tag(.{ .text = "gray", .tone = .gray }),
        .t3 = ui.tag(.{ .text = "red", .tone = .red }),
        .t4 = ui.tag(.{ .text = "green", .tone = .green }),
        .t5 = ui.tag(.{ .text = "orange", .tone = .orange }),
        .s1 = ui.tag(.{ .text = "small", .size = .small }),
        .s2 = ui.tag(.{ .text = "regular" }),
        .s3 = ui.tag(.{ .text = "large", .size = .large }),
        .i1 = ui.tag(.{ .text = "Starred", .tone = .orange, .icon = "★" }),
        .i2 = ui.tag(.{ .text = "Done", .tone = .green, .icon = "✓" }),
        .i3 = ui.tag(.{ .text = "Flagged", .tone = .red, .icon = "⚑" }),
        .h1 = ui.tag(.{ .text = "Release notes", .href = "#demo-tag-variants" }),
        .h2 = ui.tag(.{ .text = "API reference", .tone = .gray, .href = "#demo-tag-variants", .icon = "↗" }),
        .r1 = ui.tag(.{ .text = "Draft", .size = .small, .tone = .gray, .remove = .{ .delete = "/demo/tag/remove?t=Draft" } }),
        .r2 = ui.tag(.{ .text = "Review", .remove = .{ .delete = "/demo/tag/remove?t=Review" } }),
        .r3 = ui.tag(.{ .text = "Shipped", .size = .large, .tone = .green, .remove = .{ .delete = "/demo/tag/remove?t=Shipped" } }),
        .x1 = ui.tag(.{ .text = "A very long tag that does not fit on a phone and ends in an ellipsis instead of overflowing", .tone = .gray, .remove = .{ .delete = "/demo/tag/remove?t=Long" } }),
    }).render(w);
}

// ---- States ----

fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<dl class="demo-tag-rows">
        \\<dt><code>default</code></dt><dd class="zw-tags">{a}</dd>
        \\<dt><code>selected</code></dt><dd class="zw-tags">{b}{c}</dd>
        \\<dt><code>name</code></dt><dd class="zw-tags">{d}{e}{f}</dd>
        \\<dt><code>disabled</code></dt><dd class="zw-tags">{g}{h}{i}{j}{k}</dd>
        \\</dl>
    , .{
        .a = ui.tag(.{ .text = "Draft", .tone = .gray }),
        .b = ui.tag(.{ .text = "In review", .selected = true }),
        .c = ui.tag(.{ .text = "Inbox", .href = "#demo-tag-states", .selected = true }),
        .d = ui.tag(.{ .text = "Unread", .name = "demo-tag-state-unread" }),
        .e = ui.tag(.{ .text = "Flagged", .tone = .orange, .name = "demo-tag-state-flagged", .selected = true }),
        .f = ui.tag(.{ .text = "Mine", .tone = .green, .name = "demo-tag-state-mine", .value = "me", .icon = "●" }),
        .g = ui.tag(.{ .text = "Archived", .tone = .gray, .disabled = true }),
        .h = ui.tag(.{ .text = "Trash", .href = "#demo-tag-states", .disabled = true }),
        .i = ui.tag(.{ .text = "Locked", .name = "demo-tag-state-locked", .disabled = true }),
        .j = ui.tag(.{ .text = "Pinned", .name = "demo-tag-state-pinned", .selected = true, .disabled = true }),
        .k = ui.tag(.{ .text = "Team", .tone = .green, .disabled = true, .remove = .{ .delete = "/demo/tag/remove?t=Team" } }),
    }).render(w);
}

// ---- Interactive: filter chips that reload a file list ----

const Kind = enum { doc, image, code };
const File = struct { name: []const u8, kind: Kind, starred: bool = false };
const all_files = [_]File{
    .{ .name = "Quarterly report.pdf", .kind = .doc, .starred = true },
    .{ .name = "Meeting notes.md", .kind = .doc },
    .{ .name = "Beach.heic", .kind = .image },
    .{ .name = "Logo.svg", .kind = .image, .starred = true },
    .{ .name = "main.zig", .kind = .code },
    .{ .name = "build.zig", .kind = .code, .starred = true },
    .{ .name = "Invoice 0142.pdf", .kind = .doc },
};

/// True when the query string holds exactly this `name=value` pair.
fn has(query: []const u8, comptime pair: []const u8) bool {
    var it = std.mem.splitScalar(u8, query, '&');
    while (it.next()) |p| if (std.mem.eql(u8, p, pair)) return true;
    return false;
}

fn row(f: File) zw.View(
    \\<li><span class="zw-grow">{name}</span>{#if starred}<span class="demo-tag-star" role="img" aria-label="Starred">★</span>{/if}{kind}</li>
, struct { name: []const u8, starred: bool, kind: ui.Tag }) {
    return .{ .data = .{
        .name = f.name,
        .starred = f.starred,
        .kind = switch (f.kind) {
            .doc => ui.tag(.{ .text = "Document", .size = .small, .tone = .gray, .icon = "📄" }),
            .image => ui.tag(.{ .text = "Image", .size = .small, .tone = .gray, .icon = "🖼" }),
            .code => ui.tag(.{ .text = "Code", .size = .small, .tone = .gray, .icon = "⌨" }),
        },
    } };
}

/// The files that match the chips in a query string; no kind chip selected means every kind.
const Rows = struct {
    query: []const u8,

    fn shown(self: Rows, f: File) bool {
        const q = self.query;
        const any_kind = has(q, "demo-tag-kind=doc") or has(q, "demo-tag-kind=image") or has(q, "demo-tag-kind=code");
        const kind_ok = !any_kind or switch (f.kind) {
            .doc => has(q, "demo-tag-kind=doc"),
            .image => has(q, "demo-tag-kind=image"),
            .code => has(q, "demo-tag-kind=code"),
        };
        return kind_ok and (f.starred or !has(q, "demo-tag-starred=1"));
    }

    fn count(self: Rows) u32 {
        var n: u32 = 0;
        for (all_files) |f| n += @intFromBool(self.shown(f));
        return n;
    }

    pub fn render(self: Rows, w: *Writer) Writer.Error!void {
        for (all_files) |f| if (self.shown(f)) try row(f).render(w);
    }
};

fn filter(w: *Writer) Writer.Error!void {
    const all: Rows = .{ .query = "" };
    try ui.card(.{
        .title = "Downloads",
        .subtitle = "Pick chips to narrow the list",
        .accessory = ui.badge(.{ .id = "demo-tag-count", .count = all.count(), .tone = .gray }),
        .body = zw.view(
            \\<form class="zw-tags demo-tag-filter"{z}>{a}{b}{c}{star}</form>{list}
        , .{
            .z = ui.Z{ .get = "/demo/tag/files", .trigger = "change", .target = "#demo-tag-files", .swap = .inner },
            .a = ui.tag(.{ .text = "Documents", .icon = "📄", .name = "demo-tag-kind", .value = "doc" }),
            .b = ui.tag(.{ .text = "Images", .icon = "🖼", .name = "demo-tag-kind", .value = "image" }),
            .c = ui.tag(.{ .text = "Code", .icon = "⌨", .name = "demo-tag-kind", .value = "code" }),
            .star = ui.tag(.{ .text = "Starred", .icon = "★", .tone = .orange, .name = "demo-tag-starred", .value = "1" }),
            .list = ui.list(.{ .id = "demo-tag-files", .inset = false, .empty = "No files match these chips.", .body = all }),
        }),
    }).render(w);
}

/// GET /demo/tag/files?demo-tag-kind=doc&...: the matching rows, plus the count badge out of band.
fn files(c: *zw.Ctx) !void {
    const rows: Rows = .{ .query = c.raw_query };
    var out: Writer.Allocating = .init(c.arena);
    try rows.render(&out.writer);
    try ui.badge(.{ .id = "demo-tag-count", .oob = true, .count = rows.count(), .tone = .gray }).render(&out.writer);
    try c.send(.ok, "text/html; charset=utf-8", out.written());
}

// ---- Composition: tags inside list rows, chips that save ----

fn compose(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-tag-issues",
        .header = "Open issues",
        .body = zw.view(
            \\<li>{a1}<div class="zw-grow demo-tag-issue"><span>Sidebar collapses on iPad</span><span class="zw-tags">{t1}{t2}</span></div>{n1}</li>
            \\<li>{a2}<div class="zw-grow demo-tag-issue"><span>Add keyboard shortcuts</span><span class="zw-tags">{t3}{t4}</span></div>{n2}</li>
            \\<li>{a3}<div class="zw-grow demo-tag-issue"><span>Update the docs for 0.2</span><span class="zw-tags">{t5}</span></div>{n3}</li>
        , .{
            .a1 = ui.avatar(.{ .name = "Ada Lovelace", .size = 28 }),
            .t1 = ui.tag(.{ .text = "Bug", .size = .small, .tone = .red }),
            .t2 = ui.tag(.{ .text = "UI", .size = .small, .tone = .gray }),
            .n1 = ui.badge(.{ .count = 4 }),
            .a2 = ui.avatar(.{ .name = "Grace Hopper", .size = 28 }),
            .t3 = ui.tag(.{ .text = "Feature", .size = .small, .tone = .green }),
            .t4 = ui.tag(.{ .text = "Needs design", .size = .small, .tone = .orange, .icon = "!" }),
            .n2 = ui.badge(.{ .count = 2 }),
            .a3 = ui.avatar(.{ .name = "Alan Turing", .size = 28 }),
            .t5 = ui.tag(.{ .text = "Docs", .size = .small, .href = "#demo-tag-compose" }),
            .n3 = ui.badge(.{ .count = 1 }),
        }),
    }).render(w);
    try ui.card(.{
        .title = "Notify me about",
        .footer = "Changes save as you tap.",
        .body = zw.view("<div class=\"zw-tags\">{a}{b}{c}</div>", .{
            .a = ui.tag(.{ .text = "Mentions", .tone = .green, .name = "demo-tag-notify", .value = "mentions", .selected = true, .z = d.save }),
            .b = ui.tag(.{ .text = "Replies", .tone = .green, .name = "demo-tag-notify", .value = "replies", .selected = true, .z = d.save }),
            .c = ui.tag(.{ .text = "Reactions", .tone = .green, .name = "demo-tag-notify", .value = "reactions", .z = d.save }),
        }),
    }).render(w);
}
