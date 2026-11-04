//! Live component demos for ```demo <name>``` fences. Each demo renders real components;
//! controls post to /demo, which logs and answers 204.
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;

pub const css =
    \\.zw-demo{display:flex;flex-wrap:wrap;align-items:center;gap:12px;padding:28px;border-radius:var(--radius);background:var(--window);box-shadow:inset 0 0 0 .5px var(--separator);font:var(--body);letter-spacing:-.08px}
    \\.zw-demo--block{display:block}
    \\.zw-demo--block>*+*{margin-top:12px}
    \\.zw-demo .zw-sidebar{display:block;position:static;height:auto;width:240px;inset:auto;border:0;border-radius:var(--radius-control);box-shadow:var(--shadow);background:var(--content)}
    \\.zw-demo .zw-card,.zw-demo .zw-list{flex:1}
    \\.zw-demo .is-done{color:var(--secondary);text-decoration:line-through}
    \\@media (hover:hover){#hero-list .zw-btn--destructive{opacity:0;transition:opacity var(--speed)}#hero-list li:hover .zw-btn--destructive,#hero-list li:focus-within .zw-btn--destructive{opacity:1}}
    \\
;

const save: ui.Z = .{ .post = "/demo", .swap = .none };

const Demo = struct { []const u8, bool, *const fn (*Writer) Writer.Error!void };

const demos = [_]Demo{
    .{ "hero", true, hero },
    .{ "layout", true, layout },
    .{ "sidebar", false, sidebar },
    .{ "card", true, card },
    .{ "list", true, list },
    .{ "setting", true, setting },
    .{ "sheet", false, sheet },
    .{ "button", false, button },
    .{ "field", true, field },
    .{ "search", false, search },
    .{ "check", false, check },
    .{ "toggle", true, toggle },
    .{ "segmented", false, segmented },
    .{ "slider", true, slider },
    .{ "picker", false, picker },
    .{ "menu", false, menu },
    .{ "badge", false, badge },
    .{ "progress", true, progress },
    .{ "callout", true, callout },
    .{ "code", true, code },
    .{ "table", true, table },
    .{ "island", true, island },
};

/// Markdown fence hook: ```demo name``` renders a live demo; other fences fall through.
pub const Fences = struct {
    pub fn fence(_: Fences, w: *Writer, lang: []const u8, body: []const u8) Writer.Error!bool {
        if (!std.mem.eql(u8, lang, "demo")) return false;
        for (demos) |d| if (std.mem.eql(u8, d[0], std.mem.trim(u8, body, " \n"))) {
            try w.writeAll(if (d[1]) "<div class=\"zw-demo zw-demo--block\">" else "<div class=\"zw-demo\">");
            try d[2](w);
            try w.writeAll("</div>");
            return true;
        };
        try w.writeAll("<p><strong>Missing demo:</strong> ");
        try zw.writeEscaped(w, body);
        try w.writeAll("</p>");
        return true;
    }
};

fn row(done: bool, title: []const u8) zw.View("<li>{c}<span class=\"zw-grow\">{t}</span></li>", struct { c: ui.Check, t: []const u8 }) {
    return .{ .data = .{ .c = ui.check(.{ .on = done, .label = title }), .t = title } };
}

// The home page todo works for real: rows are rendered by the server (POST /demo/todos,
// /demo/toggle, DELETE /demo/todo in main.zig). State lives in the page, not on the server,
// so every visitor gets a fresh list; the toggle URL carries the row's title and state.
pub const TodoRow = zw.View(
    \\<li>{check}<span class="zw-grow{#if done} is-done{/if}">{title}</span>{del}</li>
, struct { check: ui.Check, title: []const u8, done: bool, del: ui.Button });

pub fn todoRow(arena: std.mem.Allocator, done: bool, title: []const u8) !TodoRow {
    const t = try encode(arena, title);
    return .{ .data = .{
        .check = ui.check(.{ .on = done, .label = title, .z = .{
            .post = try std.fmt.allocPrint(arena, "/demo/toggle?d={d}&t={s}", .{ @intFromBool(done), t }),
            .target = "closest li",
            .swap = .outer,
        } }),
        .title = title,
        .done = done,
        .del = ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{ .delete = "/demo/todo", .target = "closest li", .swap = .delete } }),
    } };
}

/// Percent-encodes a query value.
fn encode(arena: std.mem.Allocator, s: []const u8) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    for (s) |ch| switch (ch) {
        'a'...'z', 'A'...'Z', '0'...'9', '-', '.', '_', '~' => try out.append(arena, ch),
        else => try out.print(arena, "%{X:0>2}", .{ch}),
    };
    return out.items;
}

fn hero(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const a = fba.allocator();
    const rows = .{
        todoRow(a, true, "Read the docs") catch unreachable,
        todoRow(a, false, "zig build run") catch unreachable,
        todoRow(a, false, "Ship it") catch unreachable,
    };
    try zw.view("<form class=\"zw-row\" style=\"margin-bottom:12px\"{z}>{f}{b}</form>{l}", .{
        .z = ui.Z{ .post = "/demo/todos", .target = "#hero-list", .swap = .beforeend },
        .f = ui.field(.{ .name = "title", .label = "New todo", .placeholder = "New todo", .required = true }),
        .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
        .l = ui.list(.{ .id = "hero-list", .empty = "All done. Add another.", .body = zw.view("{a}{b}{c}", .{ .a = rows[0], .b = rows[1], .c = rows[2] }) }),
    }).render(w);
}

fn layout(w: *Writer) Writer.Error!void {
    try zw.markdown("The page you are reading is a `ui.layout` with a sidebar, a toolbar (search and badge) and a Markdown body.").render(w);
}

fn sidebar(w: *Writer) Writer.Error!void {
    try ui.sidebar(.{ .current = "#inbox", .sections = &.{
        .{ .title = "Mail", .links = &.{ .{ .label = "Inbox", .href = "#inbox" }, .{ .label = "Drafts", .href = "#drafts" }, .{ .label = "Sent", .href = "#sent" } } },
        .{ .title = "Smart Mailboxes", .links = &.{.{ .label = "Today", .href = "#today" }} },
    } }).render(w);
}

fn card(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Storage", .body = zw.view("<p style=\"margin-bottom:10px\">41.2 GB of 64 GB used</p>{p}", .{ .p = ui.progress(.{ .value = 64, .label = "Storage used" }) }) }).render(w);
}

fn list(w: *Writer) Writer.Error!void {
    try ui.list(.{ .id = "demo-list", .body = zw.view("{a}{b}{c}", .{ .a = row(true, "Renew domain"), .b = row(false, "Write release notes"), .c = row(false, "Tag v0.2.0") }) }).render(w);
}

fn setting(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}", .{
        .a = ui.setting(.{ .label = "Appearance", .control = ui.segmented(.{ .name = "look", .label = "Appearance", .z = save, .options = &.{ .{ .value = "light", .label = "Light" }, .{ .value = "dark", .label = "Dark" }, .{ .value = "auto", .label = "Auto", .selected = true } } }) }),
        .b = ui.toggle(.{ .name = "sounds", .label = "Play sounds", .on = true, .z = save }),
    }) }).render(w);
}

fn sheet(w: *Writer) Writer.Error!void {
    try zw.view("{open}{sheet}", .{
        .open = ui.button(.{ .label = "Rename…", .opens = "demo-sheet" }),
        .sheet = ui.sheet(.{ .id = "demo-sheet", .title = "Rename Project", .body = zw.view("<form{z}>{f}<div class=\"zw-sheet-actions\">{c}{ok}</div></form>", .{
            .z = save,
            .f = ui.field(.{ .name = "name", .label = "Project name", .value = "zigworks" }),
            .c = ui.button(.{ .label = "Cancel", .opens = "demo-sheet" }),
            .ok = ui.button(.{ .label = "Rename", .variant = .primary, .type = .submit }),
        }) }),
    }).render(w);
}

fn button(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}{d}{e}", .{
        .a = ui.button(.{ .label = "Save", .variant = .primary }),
        .b = ui.button(.{ .label = "Cancel" }),
        .c = ui.button(.{ .label = "Learn More", .variant = .plain }),
        .d = ui.button(.{ .label = "Delete", .variant = .destructive }),
        .e = ui.button(.{ .label = "Disabled", .disabled = true }),
    }).render(w);
}

fn field(w: *Writer) Writer.Error!void {
    try ui.field(.{ .name = "email", .label = "Email", .placeholder = "name@example.com", .type = "email" }).render(w);
}

fn search(w: *Writer) Writer.Error!void {
    try ui.search(.{ .action = "/search", .id = "demo-results", .label = "Search docs", .placeholder = "Try “button”" }).render(w);
}

fn check(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}", .{ .a = ui.check(.{ .on = false, .label = "Not done" }), .b = ui.check(.{ .on = true, .label = "Done" }) }).render(w);
}

fn toggle(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}", .{ .a = ui.toggle(.{ .name = "wifi", .label = "Wi-Fi", .on = true, .z = save }), .b = ui.toggle(.{ .name = "bt", .label = "Bluetooth", .z = save }) }).render(w);
}

fn segmented(w: *Writer) Writer.Error!void {
    try ui.segmented(.{ .name = "view", .label = "View", .z = save, .options = &.{ .{ .value = "icons", .label = "Icons", .selected = true }, .{ .value = "list", .label = "List" }, .{ .value = "columns", .label = "Columns" } } }).render(w);
}

fn slider(w: *Writer) Writer.Error!void {
    try ui.setting(.{ .label = "Volume", .control = ui.slider(.{ .name = "volume", .label = "Volume", .value = 70, .z = save }) }).render(w);
}

fn picker(w: *Writer) Writer.Error!void {
    try ui.picker(.{ .id = "demo-picker", .name = "sort", .label = "Sort by", .z = save, .options = &.{ .{ .value = "name", .label = "Name", .selected = true }, .{ .value = "date", .label = "Date Modified" }, .{ .value = "size", .label = "Size" } } }).render(w);
}

fn menu(w: *Writer) Writer.Error!void {
    try zw.view("{b}{m}", .{
        .b = ui.button(.{ .label = "Actions", .opens = "demo-menu" }),
        .m = ui.menu(.{ .id = "demo-menu", .items = &.{ .{ .label = "Duplicate", .z = save }, .{ .label = "Share…", .z = save }, .{ .label = "Move to Trash", .z = save, .destructive = true, .separated = true } } }),
    }).render(w);
}

fn badge(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}", .{ .a = ui.badge(.{ .text = "3" }), .b = ui.badge(.{ .text = "12 left" }) }).render(w);
}

fn progress(w: *Writer) Writer.Error!void {
    try zw.view("{a}<p class=\"zw-row\" style=\"margin-top:14px\">{b}<span class=\"zw-secondary\">Indexing…</span></p>", .{
        .a = ui.progress(.{ .value = 42, .label = "Download" }),
        .b = ui.progress(.{ .value = null, .label = "Indexing" }),
    }).render(w);
}

fn callout(w: *Writer) Writer.Error!void {
    try zw.view("{a}{b}{c}", .{
        .a = ui.callout(.{ .title = "Note", .body = "Routes are matched in order." }),
        .b = ui.callout(.{ .kind = .tip, .title = "Tip", .body = "Run zig build e2e before you ship." }),
        .c = ui.callout(.{ .kind = .warning, .title = "Warning", .body = "No idle timeout yet: use a reverse proxy." }),
    }).render(w);
}

fn code(w: *Writer) Writer.Error!void {
    try ui.code(.{ .src = "fn index(c: *zw.Ctx) !void {\n    try c.html(\"<h1>Hello, {name}</h1>\", .{ .name = \"Zig\" });\n}" }).render(w);
}

fn table(w: *Writer) Writer.Error!void {
    try ui.table(.{ .head = &.{ "Method", "Path", "Handler" }, .rows = &.{
        &.{ "GET", "/", "index" },
        &.{ "POST", "/todos", "create" },
        &.{ "DELETE", "/todos/:id", "remove" },
    } }).render(w);
}

fn island(w: *Writer) Writer.Error!void {
    try ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":5}", .height = "220px", .label = "Animated orbit drawn on a canvas" }).render(w);
}
