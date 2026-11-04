//! Live demos for docs/pages/components/progress.md (```demo progress``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "progress", true, progress },
    .{ "progress-variants", true, variants },
    .{ "progress-states", true, states },
    .{ "progress-live", true, live },
    .{ "progress-queue", true, queue },
    .{ "progress-composition", true, composition },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-progress-grid{display:grid;grid-template-columns:minmax(0,12rem) minmax(0,1fr);gap:18px 20px;align-items:center;
    \\  &>span{font:var(--callout);color:var(--secondary)}
    \\  &>div{display:flex;flex-wrap:wrap;align-items:center;gap:12px 24px;min-width:0;
    \\    &.demo-progress-col{flex-direction:column;align-items:stretch;gap:14px}
    \\  }
    \\}
    \\@media (max-width:599px){
    \\  .demo-progress-grid{grid-template-columns:minmax(0,1fr);gap:6px;&>div{margin-bottom:12px}}
    \\}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/progress/x", handler }`.
pub const routes = .{
    .{ "GET /demo/progress/storage", storageUsed },
    .{ "POST /demo/progress/add", queueAdd },
    .{ "POST /demo/progress/advance", queueAdvance },
    .{ "DELETE /demo/progress/row", queueRemove },
};

// Hero: the Software Update and Storage panes of a Settings app.
fn progress(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\">{update}{storage}</div>", .{
        .update = ui.card(.{
            .title = "Software Update",
            .subtitle = "macOS 26.1 · 3.4 GB",
            .accessory = ui.badge(.{ .text = "Downloading", .tone = .accent }),
            .body = ui.progress(.{ .value = 36, .label = "Software update download", .text = "1.2 GB of 3.4 GB", .show_value = true }),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Cancel", .variant = .plain, .z = d.save }),
                .b = ui.button(.{ .label = "Pause", .z = d.save }),
            }),
        }),
        .storage = ui.card(.{ .title = "Storage", .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "Macintosh HD", .description = "41.2 GB of 64 GB used", .control = ui.progress(.{ .value = 64, .label = "Macintosh HD used", .ring = true, .show_value = true }) }),
            .b = ui.setting(.{ .label = "Time Machine", .description = "Backing up to Backup Disk", .control = ui.progress(.{ .value = null, .label = "Backup in progress", .text = "Backing up…" }) }),
            .c = ui.setting(.{ .label = "iCloud Drive", .description = "Everything is up to date", .control = ui.progress(.{ .value = 100, .label = "iCloud Drive synced", .ring = true, .size = .small, .tone = .success }) }),
        }) }),
    }).render(w);
}

// Every prop, mapped to its row.
fn variants(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-progress-grid">
        \\<span><code>size</code> on a bar</span><div class="demo-progress-col">{bs}{br}{bl}</div>
        \\<span><code>tone</code></span><div class="demo-progress-col">{ta}{ts}{tw}{te}</div>
        \\<span><code>text</code> and <code>show_value</code></span><div class="demo-progress-col">{c0}{c1}{c2}{c3}</div>
        \\<span><code>ring</code> with <code>size</code> and <code>text</code></span><div>{rs}{rr}{rl}</div>
        \\<span><code>ring</code> with <code>tone</code></span><div>{ra}{rsu}{rw}{re}</div>
        \\<span><code>value = null</code> with <code>size</code></span><div>{ss}{sr}{sl}</div>
        \\<span><code>value = null</code> with <code>tone</code></span><div>{sa}{ssu}{sw}{se}</div>
        \\</div>
    , .{
        .bs = ui.progress(.{ .value = 60, .label = "Small bar", .text = ".small", .show_value = true, .size = .small }),
        .br = ui.progress(.{ .value = 60, .label = "Regular bar", .text = ".regular", .show_value = true }),
        .bl = ui.progress(.{ .value = 60, .label = "Large bar", .text = ".large", .show_value = true, .size = .large }),
        .ta = ui.progress(.{ .value = 70, .label = "Accent bar", .text = ".accent", .show_value = true }),
        .ts = ui.progress(.{ .value = 70, .label = "Success bar", .text = ".success", .show_value = true, .tone = .success }),
        .tw = ui.progress(.{ .value = 70, .label = "Warning bar", .text = ".warning", .show_value = true, .tone = .warning }),
        .te = ui.progress(.{ .value = 70, .label = "Error bar", .text = ".@\"error\"", .show_value = true, .tone = .@"error" }),
        .c0 = ui.progress(.{ .value = 45, .label = "Bar without caption" }),
        .c1 = ui.progress(.{ .value = 45, .label = "Bar with text", .text = "Copying photos" }),
        .c2 = ui.progress(.{ .value = 45, .label = "Bar with percentage", .show_value = true }),
        .c3 = ui.progress(.{ .value = 45, .label = "Bar with text and percentage", .text = "Copying photos", .show_value = true }),
        .rs = ui.progress(.{ .value = 64, .label = "Small ring", .ring = true, .size = .small, .text = ".small" }),
        .rr = ui.progress(.{ .value = 64, .label = "Regular ring", .ring = true, .show_value = true, .text = ".regular" }),
        .rl = ui.progress(.{ .value = 64, .label = "Large ring", .ring = true, .show_value = true, .size = .large, .text = ".large" }),
        .ra = ui.progress(.{ .value = 80, .label = "Accent ring", .ring = true, .show_value = true }),
        .rsu = ui.progress(.{ .value = 80, .label = "Success ring", .ring = true, .show_value = true, .tone = .success }),
        .rw = ui.progress(.{ .value = 80, .label = "Warning ring", .ring = true, .show_value = true, .tone = .warning }),
        .re = ui.progress(.{ .value = 80, .label = "Error ring", .ring = true, .show_value = true, .tone = .@"error" }),
        .ss = ui.progress(.{ .value = null, .label = "Small spinner", .size = .small, .text = ".small" }),
        .sr = ui.progress(.{ .value = null, .label = "Regular spinner", .text = ".regular" }),
        .sl = ui.progress(.{ .value = null, .label = "Large spinner", .size = .large, .text = ".large" }),
        .sa = ui.progress(.{ .value = null, .label = "Gray spinner", .text = ".accent" }),
        .ssu = ui.progress(.{ .value = null, .label = "Green spinner", .tone = .success, .text = ".success" }),
        .sw = ui.progress(.{ .value = null, .label = "Orange spinner", .tone = .warning, .text = ".warning" }),
        .se = ui.progress(.{ .value = null, .label = "Red spinner", .tone = .@"error", .text = ".@\"error\"" }),
    }).render(w);
}

// There is no disabled state: a progress bar is read-only. These are the states it does have.
fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-progress-grid">
        \\<span>Not started (0)</span><div class="demo-progress-col">{e0}{e1}</div>
        \\<span>Complete (100)</span><div class="demo-progress-col">{c0}{c1}</div>
        \\<span>Nearly full</span><div class="demo-progress-col">{w0}</div>
        \\<span>Failed</span><div class="demo-progress-col">{f0}{f1}</div>
        \\<span>Unknown length (null)</span><div>{i0}{i1}</div>
        \\<span>Over 100 is clamped</span><div class="demo-progress-col">{o0}</div>
        \\<span>Name only, no caption</span><div class="demo-progress-col">{n0}</div>
        \\</div>
    , .{
        .e0 = ui.progress(.{ .value = 0, .label = "Waiting to start", .text = "Waiting to start", .show_value = true }),
        .e1 = ui.progress(.{ .value = 0, .label = "Ring not started", .ring = true, .show_value = true }),
        .c0 = ui.progress(.{ .value = 100, .label = "Backup complete", .text = "Backup complete", .show_value = true, .tone = .success }),
        .c1 = ui.progress(.{ .value = 100, .label = "Restore complete", .ring = true, .show_value = true, .tone = .success, .text = "Restore complete" }),
        .w0 = ui.progress(.{ .value = 92, .label = "Disk space", .text = "Disk almost full", .show_value = true, .tone = .warning }),
        .f0 = ui.progress(.{ .value = 30, .label = "Upload failed", .text = "Upload failed: no connection", .show_value = true, .tone = .@"error" }),
        .f1 = ui.progress(.{ .value = 30, .label = "Sync failed", .ring = true, .show_value = true, .tone = .@"error", .text = "Sync failed" }),
        .i0 = ui.progress(.{ .value = null, .label = "Indexing", .text = "Indexing…" }),
        .i1 = ui.progress(.{ .value = null, .label = "Searching", .size = .small, .text = "Searching…" }),
        .o0 = ui.progress(.{ .value = 140, .label = "Clamped value", .text = "value = 140", .show_value = true }),
        .n0 = ui.progress(.{ .value = 55, .label = "Importing library" }),
    }).render(w);
}

// ---- Live: a slider drives a ring, a bar and a badge ----

const Meter = zw.View("<div class=\"zw-row\">{ring}<div class=\"zw-grow\">{bar}</div></div>", struct { ring: ui.Progress, bar: ui.Progress });

fn meterPart(v: u8, as_ring: bool) ui.Progress {
    return ui.progress(.{
        .value = v,
        .label = "Used space",
        .ring = as_ring,
        .size = if (as_ring) .large else .regular,
        .text = if (as_ring) "" else "Macintosh HD",
        .show_value = true,
        .tone = if (v >= 90) .@"error" else if (v >= 75) .warning else .accent,
    });
}

fn meter(v: u8) Meter {
    return .{ .data = .{ .ring = meterPart(v, true), .bar = meterPart(v, false) } };
}

fn status(v: u8, oob: bool) ui.Badge {
    return ui.badge(.{
        .id = "demo-progress-status",
        .oob = oob,
        .text = if (v >= 90) "Almost full" else if (v >= 75) "Getting full" else "Healthy",
        .tone = if (v >= 90) .red else if (v >= 75) .orange else .green,
    });
}

fn live(w: *Writer) Writer.Error!void {
    try zw.view("{card}{slider}", .{
        .card = ui.card(.{
            .title = "Storage",
            .accessory = status(62, false),
            .body = zw.view("<div id=\"demo-progress-meter\">{m}</div>", .{ .m = meter(62) }),
        }),
        .slider = ui.setting(.{ .label = "Used space", .description = "Drag to change it; the server redraws the meter.", .control = ui.slider(.{
            .name = "v",
            .label = "Used space",
            .value = 62,
            .show_value = true,
            .unit = "%",
            .z = .{ .get = "/demo/progress/storage", .target = "#demo-progress-meter", .swap = .inner, .trigger = "input" },
        }) }),
    }).render(w);
}

/// The new meter replaces the old one; the badge in the card header is swapped out of band.
fn storageUsed(c: *zw.Ctx) !void {
    const v = @min(std.fmt.parseInt(u8, c.query("v") orelse "", 10) catch 50, 100);
    try c.html("{meter}{status}", .{ .meter = meter(v), .status = status(v, true) });
}

// ---- Queue: add files, advance them, remove them ----

const Row = zw.View("<li><div class=\"zw-grow\">{bar}</div>{btn}</li>", struct { bar: ui.Progress, btn: ui.Button });

/// One upload. The Advance URL carries the file name and progress, so the page holds all state.
fn row(arena: std.mem.Allocator, name: []const u8, v: u8) !Row {
    const done = v >= 100;
    return .{ .data = .{
        .bar = ui.progress(.{ .value = v, .label = name, .text = name, .show_value = true, .tone = if (done) .success else .accent }),
        .btn = if (done)
            ui.button(.{ .label = "Remove", .variant = .destructive, .size = .small, .z = .{ .delete = "/demo/progress/row", .target = "closest li", .swap = .delete } })
        else
            ui.button(.{ .label = "Advance", .size = .small, .z = .{
                .post = try std.fmt.allocPrint(arena, "/demo/progress/advance?n={f}&v={d}", .{ std.fmt.alt(std.Uri.Component{ .raw = name }, .formatEscaped), v }),
                .target = "closest li",
                .swap = .outer,
            } }),
    } };
}

fn queueAdd(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("file") orelse "", " ");
    if (name.len == 0 or name.len > 60) return c.send(.no_content, "text/plain", "");
    try c.page(try row(c.arena, name, 0));
}

/// Each Advance stands in for a progress event: +30%, and a toast when the file is done.
fn queueAdvance(c: *zw.Ctx) !void {
    const name = c.query("n") orelse return c.send(.bad_request, "text/plain", "missing n");
    const v = std.fmt.parseInt(u8, c.query("v") orelse "0", 10) catch 0;
    const next: u8 = @intCast(@min(@as(u16, v) + 30, 100));
    const r = try row(c.arena, name, next);
    if (next < 100) return c.page(r);
    const text = try std.fmt.allocPrint(c.arena, "{s} uploaded", .{name});
    try c.html("{row}{toast}", .{ .row = r, .toast = ui.toast(.{ .text = text, .kind = .success }) });
}

fn queueRemove(c: *zw.Ctx) !void {
    // An empty 200 lets z.js remove the row (204 would mean "change nothing").
    try c.send(.ok, "text/html; charset=utf-8", "");
}

fn queue(w: *Writer) Writer.Error!void {
    var buf: [2048]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const a = fba.allocator();
    try zw.view("<form class=\"zw-row\"{z}><div class=\"zw-grow\">{f}</div>{b}</form>{l}", .{
        .z = ui.Z{ .post = "/demo/progress/add", .target = "#demo-progress-queue", .swap = .beforeend },
        .f = ui.field(.{ .name = "file", .label = "File name", .placeholder = "File name", .required = true }),
        .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
        .l = ui.list(.{
            .id = "demo-progress-queue",
            .empty = "Nothing to upload. Add a file.",
            .header = "Uploads",
            .footer = "Advance moves a file forward by 30%. At 100% it turns green and posts a toast.",
            .body = zw.view("{a}{b}", .{
                .a = row(a, "Quarterly report.pdf", 40) catch return error.WriteFailed,
                .b = row(a, "Holiday video.mov", 85) catch return error.WriteFailed,
            }),
        }),
    }).render(w);
}

// ---- Composition ----

fn composition(w: *Writer) Writer.Error!void {
    try zw.view("{copy}{accounts}<div class=\"zw-row\">{b1}{b2}</div>", .{
        .copy = ui.card(.{
            .title = "Copying 3 items",
            .accessory = ui.button(.{ .label = "Stop", .variant = .plain, .z = d.save }),
            .body = ui.progress(.{ .value = 72, .label = "Copying files", .text = "Taxes 2025.pdf", .show_value = true }),
            .footer = "About 2 minutes remaining",
        }),
        .accounts = ui.list(.{
            .id = "demo-progress-accounts",
            .header = "Mail accounts",
            .footer = "A badge, a ring or a spinner says where each account is.",
            .body = zw.view("<li><span class=\"zw-grow\">iCloud</span>{a}</li><li><span class=\"zw-grow\">Work</span>{b}</li><li><span class=\"zw-grow\">Archive</span>{c}</li>", .{
                .a = ui.badge(.{ .text = "Up to date", .tone = .green }),
                .b = ui.progress(.{ .value = null, .label = "Work account fetching", .size = .small, .text = "Fetching…" }),
                .c = ui.progress(.{ .value = 64, .label = "Archive downloaded", .ring = true, .size = .small, .text = "6,400 of 10,000" }),
            }),
        }),
        .b1 = ui.button(.{ .label = "Checking…", .loading = true }),
        .b2 = ui.button(.{ .label = "Install", .variant = .primary, .disabled = true }),
    }).render(w);
}
