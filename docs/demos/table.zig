//! Live demos for docs/pages/components/table.md (```demo table``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "table", true, hero },
    .{ "table-variants", true, variants },
    .{ "table-states", true, states },
    .{ "table-live", true, live },
    .{ "table-files", true, filesDemo },
    .{ "table-rich", true, rich },
    .{ "table-invoice", true, invoice },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-table-label{margin:0 0 6px;font:var(--callout);color:var(--secondary)}
    \\.demo-table-narrow{max-width:360px}
    \\.demo-table-bar{display:flex;flex-wrap:wrap;align-items:center;gap:8px}
    \\.demo-table-actions{display:flex;flex-wrap:wrap;gap:8px;margin-top:10px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/table/x", handler }`.
pub const routes = .{
    .{ "GET /demo/table/log", logRoute },
    .{ "GET /demo/table/files", filesRoute },
    .{ "POST /demo/table/pay", payRoute },
    .{ "POST /demo/table/remind", remindRoute },
};

// Hero: a Finder-style list view.
fn hero(w: *Writer) Writer.Error!void {
    try ui.table(.{
        .caption = "Documents",
        .head = &.{ "Name", "Modified", "Size" },
        .aligns = &.{ .left, .left, .right },
        .rows = &.{
            &.{ "Budget.numbers", "Today", "1.2 MB" },
            &.{ "Meeting notes.txt", "Yesterday", "12 KB" },
            &.{ "Poster.pdf", "Oct 28", "5.2 MB" },
            &.{ "Resume.pages", "Oct 14", "340 KB" },
            &.{ "Trip photos", "Sep 30", "--" },
        },
        .striped = true,
        .row_header = true,
    }).render(w);
}

const plan_head: []const []const u8 = &.{ "Plan", "Seats", "Price" };
const plans: []const []const []const u8 = &.{
    &.{ "Free", "1", "$0" },
    &.{ "Team", "10", "$12" },
    &.{ "Business", "50", "$40" },
};

fn variants(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-table-item"><p class="demo-table-label">Default</p>{a}</div>
        \\<div class="demo-table-item"><p class="demo-table-label"><code>.striped</code></p>{b}</div>
        \\<div class="demo-table-item"><p class="demo-table-label"><code>.compact</code></p>{c}</div>
        \\<div class="demo-table-item"><p class="demo-table-label"><code>.row_header</code></p>{d}</div>
        \\<div class="demo-table-item"><p class="demo-table-label"><code>.aligns</code> (left, center, right) and <code>.caption</code></p>{e}</div>
    , .{
        .a = ui.table(.{ .head = plan_head, .rows = plans }),
        .b = ui.table(.{ .head = plan_head, .rows = plans, .striped = true }),
        .c = ui.table(.{ .head = plan_head, .rows = plans, .compact = true }),
        .d = ui.table(.{ .head = plan_head, .rows = plans, .row_header = true }),
        .e = ui.table(.{
            .caption = "Service status",
            .head = &.{ "Region", "Status", "Latency" },
            .aligns = &.{ .left, .center, .right },
            .rows = &.{
                &.{ "Iceland", "Online", "12 ms" },
                &.{ "Frankfurt", "Online", "48 ms" },
                &.{ "Virginia", "Degraded", "131 ms" },
            },
        }),
    }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-table-item"><p class="demo-table-label">Empty: <code>.empty</code> spans the table when there are no rows</p>{a}</div>
        \\<div class="demo-table-item demo-table-narrow"><p class="demo-table-label">Overflow: the frame scrolls sideways and takes focus</p>{b}</div>
    , .{
        .a = ui.table(.{ .caption = "Team", .head = &.{ "Name", "Role" }, .rows = &.{}, .empty = "No members yet" }),
        .b = ui.table(.{
            .head = &.{ "Target", "Optimize", "Compile time", "Binary size", "Tests passed", "Warnings" },
            .aligns = &.{ .left, .left, .right, .right, .right, .right },
            .rows = &.{
                &.{ "x86_64-linux", "ReleaseSmall", "4.1 s", "212 KB", "148 / 148", "0" },
                &.{ "aarch64-macos", "ReleaseFast", "5.3 s", "388 KB", "148 / 148", "0" },
                &.{ "wasm32-wasi", "Debug", "2.7 s", "1.9 MB", "141 / 148", "3" },
            },
            .row_header = true,
        }),
    }).render(w);
}

// Live: the server returns the table for the requested number of readings. The count lives in
// the URL of the buttons, so nothing is stored on the server.
const readings: [6][]const []const u8 = .{
    &.{ "09:00", "18.2 °C" },
    &.{ "09:05", "18.4 °C" },
    &.{ "09:10", "18.9 °C" },
    &.{ "09:15", "19.1 °C" },
    &.{ "09:20", "19.0 °C" },
    &.{ "09:25", "19.6 °C" },
};

const Log = struct {
    n: usize,

    pub fn render(l: Log, w: *Writer) Writer.Error!void {
        var more: [40]u8 = undefined;
        const add_url = std.fmt.bufPrint(&more, "/demo/table/log?n={d}", .{l.n + 1}) catch unreachable;
        try zw.view("{t}<div class=\"demo-table-actions\">{add}{clear}</div>", .{
            .t = ui.table(.{
                .caption = "Sensor log",
                .head = &.{ "Time", "Temperature" },
                .aligns = &.{ .left, .right },
                .rows = readings[0..l.n],
                .empty = "No readings yet. Add one to start.",
                .compact = true,
            }),
            .add = ui.button(.{
                .label = "Add Reading",
                .variant = .primary,
                .disabled = l.n >= readings.len,
                .z = .{ .get = add_url, .target = "#demo-table-log", .swap = .inner },
            }),
            .clear = ui.button(.{
                .label = "Clear",
                .variant = .plain,
                .disabled = l.n == 0,
                .z = .{ .get = "/demo/table/log?n=0", .target = "#demo-table-log", .swap = .inner },
            }),
        }).render(w);
    }
};

fn live(w: *Writer) Writer.Error!void {
    try w.writeAll("<div id=\"demo-table-log\">");
    try (Log{ .n = 0 }).render(w);
    try w.writeAll("</div>");
}

fn logRoute(c: *zw.Ctx) !void {
    const n = std.fmt.parseInt(usize, c.query("n") orelse "0", 10) catch 0;
    try c.page(Log{ .n = @min(n, readings.len) });
}

// Files: two segmented controls pick the sort and the filter; the form asks the server for the
// matching table and swaps it in (the table's own `id` is the target). Cells are plain strings, so
// the server formats sizes and dates; `sort_col` marks the sorted header for assistive tech.
const File = struct { name: []const u8, kind: []const u8, kb: u32, days: u8 };
const files = [_]File{
    .{ .name = "Budget.numbers", .kind = "document", .kb = 1240, .days = 0 },
    .{ .name = "Notes.txt", .kind = "document", .kb = 12, .days = 1 },
    .{ .name = "Poster.pdf", .kind = "document", .kb = 5320, .days = 3 },
    .{ .name = "Beach.jpg", .kind = "image", .kb = 3480, .days = 2 },
    .{ .name = "Sunset.png", .kind = "image", .kb = 8120, .days = 6 },
    .{ .name = "Portrait.heic", .kind = "image", .kb = 2210, .days = 14 },
};
const Order = enum { name, size, modified };

fn before(order: Order, a: File, b: File) bool {
    return switch (order) {
        .name => std.ascii.lessThanIgnoreCase(a.name, b.name),
        .size => a.kb > b.kb,
        .modified => a.days < b.days,
    };
}

fn filesTable(a: std.mem.Allocator, order: Order, kind: []const u8) !ui.Table {
    var shown: [files.len]File = undefined;
    var n: usize = 0;
    for (files) |f| {
        if (std.mem.eql(u8, kind, "all") or std.mem.eql(u8, kind, f.kind)) {
            shown[n] = f;
            n += 1;
        }
    }
    std.mem.sort(File, shown[0..n], order, before);
    const rows = try a.alloc([]const []const u8, n);
    for (shown[0..n], rows) |f, *row| {
        const cells = try a.alloc([]const u8, 3);
        cells[0] = f.name;
        cells[1] = if (f.kb < 1024)
            try std.fmt.allocPrint(a, "{d} KB", .{f.kb})
        else
            try std.fmt.allocPrint(a, "{d}.{d} MB", .{ f.kb * 10 / 1024 / 10, f.kb * 10 / 1024 % 10 });
        cells[2] = switch (f.days) {
            0 => "Today",
            1 => "Yesterday",
            else => try std.fmt.allocPrint(a, "{d} days ago", .{f.days}),
        };
        row.* = cells;
    }
    return ui.table(.{
        .id = "demo-table-files",
        .caption = try std.fmt.allocPrint(a, "{d} items", .{n}),
        .sort_col = @backingInt(order),
        .sort_desc = order != .name,
        .head = &.{ "Name", "Size", "Modified" },
        .aligns = &.{ .left, .right, .left },
        .rows = rows,
        .empty = "No matching files.",
        .row_header = true,
        .compact = true,
    });
}

fn filesDemo(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const t = filesTable(fba.allocator(), .name, "all") catch return error.WriteFailed;
    try zw.view("<form class=\"demo-table-bar\"{z}>{sort}{kind}</form>{t}", .{
        .z = ui.Z{ .get = "/demo/table/files", .trigger = "change", .target = "#demo-table-files", .swap = .outer },
        .sort = ui.segmented(.{ .name = "sort", .label = "Sort by", .size = .small, .options = &.{
            .{ .value = "name", .label = "Name", .selected = true },
            .{ .value = "size", .label = "Size" },
            .{ .value = "modified", .label = "Modified" },
        } }),
        .kind = ui.segmented(.{ .name = "kind", .label = "Kind", .size = .small, .options = &.{
            .{ .value = "all", .label = "All", .selected = true },
            .{ .value = "image", .label = "Images" },
            .{ .value = "document", .label = "Documents" },
            .{ .value = "archive", .label = "Archives" },
        } }),
        .t = t,
    }).render(w);
}

fn filesRoute(c: *zw.Ctx) !void {
    const order = std.meta.stringToEnum(Order, c.query("sort") orelse "") orelse .name;
    try c.page(try filesTable(c.arena, order, c.query("kind") orelse "all"));
}

// Invoice: a table inside a card. The primary action answers with an out-of-band badge and a toast.
fn invoice(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Invoice 1042",
        .subtitle = "Due Nov 15",
        .accessory = ui.badge(.{ .id = "demo-table-status", .text = "Due", .tone = .orange }),
        .body = ui.table(.{
            .caption = "Line items",
            .head = &.{ "Item", "Qty", "Amount" },
            .aligns = &.{ .left, .right, .right },
            .rows = &.{
                &.{ "Hosting, annual", "1", "$120.00" },
                &.{ "Domain renewal", "2", "$24.00" },
                &.{ "Support plan", "1", "$60.00" },
            },
            .foot = &.{ "Total", "", "$204.00" },
            .row_header = true,
        }),
        .footer = zw.view("{a}{b}", .{
            .a = ui.button(.{ .label = "Download PDF", .z = d.save }),
            .b = ui.button(.{ .label = "Mark as Paid", .variant = .primary, .z = .{ .post = "/demo/table/pay", .swap = .none } }),
        }),
    }).render(w);
}

fn payRoute(c: *zw.Ctx) !void {
    try c.html("{b}{t}", .{
        .b = ui.badge(.{ .id = "demo-table-status", .oob = true, .text = "Paid", .tone = .green }),
        .t = ui.toast(.{ .text = "Invoice 1042 marked as paid", .kind = .success }),
    });
}

// Rich cells: columns marked in `.html` take trusted markup, so rows can hold a badge and a button.
// Here the markup is rendered into one stack buffer; a route would use `std.Io.Writer.Allocating`.
fn grab(out: *Writer, comp: anytype) Writer.Error![]const u8 {
    const start = out.end;
    try comp.render(out);
    return out.buffered()[start..];
}

fn rich(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var out: Writer = .fixed(&buf);
    const r0 = [_][]const u8{ "Ada Lovelace", try grab(&out, ui.badge(.{ .text = "Active", .tone = .green })), try grab(&out, remind("ada")) };
    const r1 = [_][]const u8{ "Grace Hopper", try grab(&out, ui.badge(.{ .text = "Away", .tone = .orange })), try grab(&out, remind("grace")) };
    const r2 = [_][]const u8{ "Alan Turing", try grab(&out, ui.badge(.{ .text = "Offline" })), try grab(&out, remind("alan")) };
    try ui.table(.{
        .caption = "Team",
        .head = &.{ "Name", "Status", "Actions" },
        .rows = &.{ &r0, &r1, &r2 },
        .html = &.{ false, true, true },
        .aligns = &.{ .left, .left, .right },
        .row_header = true,
        .selected = 1,
    }).render(w);
}

fn remind(comptime who: []const u8) ui.Button {
    return ui.button(.{
        .label = "Remind",
        .variant = .plain,
        .size = .small,
        .z = .{ .post = "/demo/table/remind?name=" ++ who, .swap = .none },
    });
}

fn remindRoute(c: *zw.Ctx) !void {
    const text = try std.fmt.allocPrint(c.arena, "Reminder sent to {s}", .{c.query("name") orelse "everyone"});
    try c.html("{t}", .{ .t = ui.toast(.{ .text = text, .kind = .success }) });
}
