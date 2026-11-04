//! Live demos for docs/pages/components/callout.md (```demo callout``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "callout", true, callout },
    .{ "callout-kinds", true, kinds },
    .{ "callout-options", true, options },
    .{ "callout-playground", true, playground },
    .{ "callout-rename", true, rename },
    .{ "callout-update", true, update },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-callout-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,240px),1fr));gap:16px}
    \\.demo-callout-cell{display:flex;flex-direction:column;gap:6px;min-width:0}
    \\.demo-callout-cell>code{align-self:flex-start;max-width:100%;overflow-wrap:anywhere}
    \\.demo-callout-code{margin:8px 0 0;color:var(--secondary);font:var(--callout);overflow-wrap:anywhere}
    \\.demo-callout-actions{display:flex;flex-wrap:wrap;justify-content:flex-end;gap:8px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/callout/x", handler }`.
pub const routes = .{
    .{ "GET /demo/callout/preview", previewDemo },
    .{ "POST /demo/callout/name", nameDemo },
    .{ "POST /demo/callout/rename", renameDemo },
    .{ "POST /demo/callout/update", updateDemo },
};

/// The `Kind` enum of `ui.callout` (it is not exported by name).
const Kind = ui.CalloutKind;

// Hero: a Settings pane. The callout explains why the controls below matter.
fn callout(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "iCloud Drive",
        .subtitle = "Macintosh HD · 256 GB",
        .body = zw.view("<div class=\"zw-stack\">{note}{bar}<div>{a}{b}</div></div>", .{
            .note = ui.callout(.{ .kind = .warning, .title = "Storage almost full.", .body = "Only 4.2 GB is left. Optimize Mac Storage keeps recent files here and moves the rest to iCloud." }),
            .bar = ui.progress(.{ .value = 98, .label = "Storage used", .text = "251.8 GB of 256 GB", .tone = .warning }),
            .a = ui.toggle(.{ .name = "optimize", .label = "Optimize Mac Storage", .description = "Older files move to iCloud when space is low.", .z = d.save }),
            .b = ui.toggle(.{ .name = "trash", .label = "Empty Trash Automatically", .description = "Items are deleted after 30 days.", .on = true, .z = d.save }),
        }),
        .footer = zw.view("{a}{b}", .{
            .a = ui.button(.{ .label = "Manage…", .variant = .plain }),
            .b = ui.button(.{ .label = "Optimize Now", .variant = .primary, .z = d.save }),
        }),
    }).render(w);
}

// One cell of a grid: the props in use, then the result.
const cell_src = "<div class=\"demo-callout-cell\"><code>{prop}</code>{c}</div>";

fn cell(prop: []const u8, c: anytype) zw.View(cell_src, struct { prop: []const u8, c: @TypeOf(c) }) {
    return .{ .data = .{ .prop = prop, .c = c } };
}

fn kinds(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-callout-grid\">{a}{b}{c}{d}{e}</div>", .{
        .a = cell(".kind = .note", ui.callout(.{ .title = "Note", .body = "Time Machine backs up every hour." })),
        .b = cell(".kind = .tip", ui.callout(.{ .kind = .tip, .title = "Tip", .body = "Press ⌘K to search from anywhere." })),
        .c = cell(".kind = .warning", ui.callout(.{ .kind = .warning, .title = "Warning", .body = "This disk is almost full." })),
        .d = cell(".kind = .important", ui.callout(.{ .kind = .important, .title = "Important", .body = "Updates restart your Mac." })),
        .e = cell(".kind = .caution", ui.callout(.{ .kind = .caution, .title = "Caution", .body = "Erasing a disk can't be undone." })),
    }).render(w);
}

fn options(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-callout-grid\">{a}{b}{c}{d}{e}{f}</div>", .{
        .a = cell(".title = \"Heads up.\"", ui.callout(.{ .kind = .tip, .title = "Heads up.", .body = "The title is a bold lead-in before the body." })),
        .b = cell("no .title", ui.callout(.{ .kind = .tip, .body = "Without a title the body stands on its own." })),
        .c = cell(".icon = false", ui.callout(.{ .title = "Plain note.", .body = "The colored bar still shows the kind.", .icon = false })),
        .d = cell(".compact = true", ui.callout(.{ .kind = .warning, .body = "Compact: tighter, no bar.", .compact = true })),
        .e = cell(".compact = true, .icon = false", ui.callout(.{ .body = "Just a line of quiet text.", .compact = true, .icon = false })),
        .f = cell(".body = view with a component", ui.callout(.{
            .kind = .tip,
            .title = "Hidden files.",
            .body = zw.view("Press {k} in Finder to show them.", .{ .k = ui.kbd(.{ .keys = "⌘ ⇧ ." }) }),
        })),
    }).render(w);
}

// Playground: a form with change events asks the server for a callout built from the form.
const Preview = struct {
    kind: Kind = .tip,
    title: []const u8 = "Tip",
    body: []const u8 = "Press ⌘K to search from anywhere.",
    icon: bool = true,
    compact: bool = false,

    pub fn render(p: Preview, w: *Writer) Writer.Error!void {
        try ui.callout(.{ .kind = p.kind, .title = p.title, .body = p.body, .icon = p.icon, .compact = p.compact }).render(w);
        try w.print("<p class=\"demo-callout-code\"><code>.kind = .{s}", .{@tagName(p.kind)});
        if (!p.icon) try w.writeAll(", .icon = false");
        if (p.compact) try w.writeAll(", .compact = true");
        try w.writeAll("</code></p>");
    }
};

fn previewDemo(c: *zw.Ctx) !void {
    try c.page(Preview{
        .kind = std.meta.stringToEnum(Kind, c.query("kind") orelse "") orelse .note,
        .title = c.query("title") orelse "",
        .body = c.query("body") orelse "",
        // A switch that is off sends nothing.
        .icon = c.query("icon") != null,
        .compact = c.query("compact") != null,
    });
}

fn playground(w: *Writer) Writer.Error!void {
    try zw.view(
        "<div class=\"zw-stack\"><form class=\"zw-stack\"{z}>{kind}{title}{body}<div>{icon}{compact}</div></form>" ++
            "<div id=\"demo-callout-preview\" aria-live=\"polite\">{preview}</div></div>",
        .{
            .z = ui.Z{ .get = "/demo/callout/preview", .trigger = "input", .target = "#demo-callout-preview", .swap = .inner },
            .kind = ui.picker(.{ .id = "demo-callout-kind", .name = "kind", .label = "Kind", .options = &.{
                .{ .value = "note", .label = "Note" },
                .{ .value = "tip", .label = "Tip", .selected = true },
                .{ .value = "warning", .label = "Warning" },
                .{ .value = "important", .label = "Important" },
                .{ .value = "caution", .label = "Caution" },
            } }),
            .title = ui.field(.{ .name = "title", .label = "Title", .placeholder = "Title (optional)", .value = "Tip", .maxlength = 40 }),
            .body = ui.field(.{ .name = "body", .label = "Body", .placeholder = "Body", .value = "Press ⌘K to search from anywhere.", .maxlength = 120 }),
            .icon = ui.toggle(.{ .name = "icon", .label = "Icon", .on = true }),
            .compact = ui.toggle(.{ .name = "compact", .label = "Compact" }),
            .preview = Preview{},
        },
    ).render(w);
}

// Rename: the callout is live feedback under a field. The field asks the server on every
// keystroke (debounced by z.js), and the answer replaces the status area.
const Verdict = struct { kind: Kind, title: []const u8, body: []const u8 };

fn verdict(name: []const u8) Verdict {
    if (name.len == 0) return .{ .kind = .note, .title = "Name required.", .body = "Type a name for the file." };
    for (name) |ch| if (ch == '/' or ch == ':') return .{ .kind = .caution, .title = "Not allowed.", .body = "Names can't contain “/” or “:”." };
    if (name[0] == '.') return .{ .kind = .warning, .title = "Hidden file.", .body = "Finder hides names that start with a dot." };
    if (name.len > 30) return .{ .kind = .important, .title = "Long name.", .body = "Lists shorten names after about 30 characters." };
    const has_ext = for (name[1..]) |ch| {
        if (ch == '.') break true;
    } else false;
    if (!has_ext) return .{ .kind = .tip, .title = "No extension.", .body = "Add one, such as .pdf, so apps know how to open it." };
    return .{ .kind = .tip, .title = "Looks good.", .body = "Press Return to rename." };
}

const Status = struct {
    name: []const u8,

    pub fn render(s: Status, w: *Writer) Writer.Error!void {
        const v = verdict(s.name);
        try ui.callout(.{ .kind = v.kind, .title = v.title, .body = v.body }).render(w);
    }
};

fn nameDemo(c: *zw.Ctx) !void {
    try c.page(Status{ .name = std.mem.trim(u8, c.form("name") orelse "", " ") });
}

fn renameDemo(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("name") orelse "", " ");
    const v = verdict(name);
    if (name.len == 0 or v.kind == .caution) return c.page(ui.toast(.{ .text = "Can't rename: fix the name first", .kind = .@"error" }));
    try c.page(ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Renamed to “{s}”", .{name}), .kind = .success }));
}

fn rename(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Rename",
        .body = zw.view(
            "<form class=\"zw-stack\"{z}>{name}<div id=\"demo-callout-name-status\" aria-live=\"polite\">{status}</div>" ++
                "<div class=\"demo-callout-actions\">{cancel}{ok}</div></form>",
            .{
                .z = ui.Z{ .post = "/demo/callout/rename", .swap = .none, .keep = true },
                .name = ui.field(.{
                    .name = "name",
                    .label = "File name",
                    .value = "Quarterly report",
                    .maxlength = 60,
                    .z = .{ .post = "/demo/callout/name", .trigger = "input", .target = "#demo-callout-name-status", .swap = .inner },
                }),
                .status = Status{ .name = "Quarterly report" },
                .cancel = ui.button(.{ .label = "Cancel", .variant = .plain }),
                .ok = ui.button(.{ .label = "Rename", .variant = .primary, .type = .submit }),
            },
        ),
    }).render(w);
}

// Update: the step is in the URL, so every click asks for the next panel and the server keeps nothing.
const Update = struct {
    step: u8 = 0,

    const panel = "<div id=\"demo-callout-update\" class=\"zw-stack\">{note}{bar}<div class=\"demo-callout-actions\">{a}{b}</div></div>";

    pub fn render(u: Update, w: *Writer) Writer.Error!void {
        switch (u.step) {
            1 => try zw.view(panel, .{
                .note = ui.callout(.{ .kind = .tip, .title = "Installed.", .body = "Restart to finish the update." }),
                .bar = ui.progress(.{ .value = 100, .label = "Update installed", .text = "macOS 26.1", .tone = .success }),
                .a = ui.button(.{ .label = "Start Over", .variant = .plain, .z = .{ .post = "/demo/callout/update?step=0", .target = "#demo-callout-update", .swap = .outer } }),
                .b = ui.button(.{ .label = "Restart Now", .variant = .primary, .z = .{ .post = "/demo/callout/update?step=2", .target = "#demo-callout-update", .swap = .outer } }),
            }).render(w),
            2 => try zw.view(panel, .{
                .note = ui.callout(.{ .title = "Restarting…", .body = "Your Mac restarts in a moment. This demo changes nothing." }),
                .bar = ui.progress(.{ .value = null, .label = "Restarting", .text = "Restarting" }),
                .a = ui.button(.{ .label = "Start Over", .variant = .plain, .z = .{ .post = "/demo/callout/update?step=0", .target = "#demo-callout-update", .swap = .outer } }),
                .b = ui.button(.{ .label = "Restarting", .variant = .primary, .loading = true }),
            }).render(w),
            else => try zw.view(panel, .{
                .note = ui.callout(.{ .kind = .important, .title = "Update available.", .body = "Installing restarts your Mac. Save your work first." }),
                .bar = ui.progress(.{ .value = 0, .label = "Update size", .text = "macOS 26.1 · 1.4 GB" }),
                .a = ui.button(.{ .label = "Later", .variant = .plain }),
                .b = ui.button(.{ .label = "Install Now", .variant = .primary, .z = .{ .post = "/demo/callout/update?step=1", .target = "#demo-callout-update", .swap = .outer } }),
            }).render(w),
        }
    }
};

fn updateDemo(c: *zw.Ctx) !void {
    const step = std.fmt.parseInt(u8, c.query("step") orelse "0", 10) catch 0;
    try c.page(Update{ .step = step });
}

fn update(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Software Update", .body = Update{} }).render(w);
}
