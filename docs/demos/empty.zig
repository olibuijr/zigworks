//! Live demos for docs/pages/components/empty.md (```demo empty``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "empty", true, empty },
    .{ "empty-sizes", true, sizes },
    .{ "empty-parts", true, parts },
    .{ "empty-places", true, places },
    .{ "empty-search", true, search },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-empty-sub{display:block;font:var(--callout);color:var(--secondary)}
    \\.demo-empty-bar{justify-content:space-between;padding-top:12px;border-top:1px solid var(--separator)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/empty/x", handler }`.
pub const routes = .{
    .{ "POST /demo/empty/reminders", remindersRoute },
    .{ "GET /demo/empty/place", placeRoute },
    .{ "GET /demo/empty/files", filesRoute },
};

// Sample files for the places and search demos.
const File = struct { name: []const u8, kind: []const u8 };
const files = [_]File{
    .{ .name = "Quarterly Report.pdf", .kind = "PDF document" },
    .{ .name = "Budget 2026.csv", .kind = "Spreadsheet" },
    .{ .name = "Meeting Notes.md", .kind = "Markdown" },
    .{ .name = "Logo.svg", .kind = "Vector image" },
    .{ .name = "Invoice 0042.pdf", .kind = "PDF document" },
};

const file_rows = "{#each items as f}<li><span class=\"zw-grow\">{f.name}<small class=\"demo-empty-sub\">{f.kind}</small></span></li>{/each}";

/// A flat list of files; an empty slice shows the list's own `empty` text.
const FileList = struct {
    id: []const u8,
    items: []const File,
    pub fn render(s: FileList, w: *Writer) Writer.Error!void {
        try ui.list(.{
            .id = s.id,
            .empty = "No files",
            .inset = false,
            .body = zw.view(file_rows, .{ .items = s.items }),
        }).render(w);
    }
};

// Hero: a Reminders card. The state is a bitmask `m` of which reminders exist, carried in the
// request URLs, so the server keeps nothing and every visitor starts empty.
const titles = [_][]const u8{ "Buy oat milk", "Call the dentist", "Book train tickets", "Water the plants", "Pay the electric bill" };

const Reminders = struct {
    m: u8,
    /// Also send the count badge as an out-of-band update.
    oob: bool = false,

    pub fn render(r: Reminders, w: *Writer) Writer.Error!void {
        if (r.m == 0) {
            try ui.empty(.{
                .icon = "✓",
                .title = "No Reminders",
                .text = "Reminders you add show up here.",
                .action = ui.button(.{ .label = "New Reminder", .variant = .primary, .z = .{ .post = "/demo/empty/reminders?m=1", .target = "#demo-empty-reminders" } }),
                .secondary = ui.button(.{ .label = "Import…", .variant = .plain, .z = d.save }),
            }).render(w);
        } else {
            try ui.list(.{ .id = "demo-empty-list", .inset = false, .reveal = true, .body = Rows{ .m = r.m } }).render(w);
            var buf: [48]u8 = undefined;
            const more = std.fmt.bufPrint(&buf, "/demo/empty/reminders?m={d}", .{r.m | (r.m +% 1)}) catch unreachable;
            try zw.view("<div class=\"zw-row demo-empty-bar\">{add}{clear}</div>", .{
                .add = ui.button(.{ .label = "New Reminder", .disabled = r.m == 31, .z = .{ .post = more, .target = "#demo-empty-reminders" } }),
                .clear = ui.button(.{ .label = "Clear All", .variant = .destructive, .z = .{ .post = "/demo/empty/reminders?m=0", .target = "#demo-empty-reminders" } }),
            }).render(w);
        }
        if (r.oob) try countBadge(r.m, true).render(w);
    }
};

const Rows = struct {
    m: u8,
    pub fn render(r: Rows, w: *Writer) Writer.Error!void {
        for (titles, 0..) |title, i| {
            const bit = @as(u8, 1) << @intCast(i);
            if (r.m & bit == 0) continue;
            var buf: [48]u8 = undefined;
            const without = std.fmt.bufPrint(&buf, "/demo/empty/reminders?m={d}", .{r.m & ~bit}) catch unreachable;
            try zw.view("<li>{check}<span class=\"zw-grow\">{title}</span>{del}</li>", .{
                .check = ui.check(.{ .on = false, .label = title }),
                .title = title,
                .del = ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{ .post = without, .target = "#demo-empty-reminders" } }),
            }).render(w);
        }
    }
};

fn countBadge(m: u8, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-empty-count", .oob = oob, .count = @popCount(m), .hide_zero = true, .tone = .accent });
}

fn remindersRoute(c: *zw.Ctx) !void {
    const m = (std.fmt.parseInt(u8, c.query("m") orelse "0", 10) catch 0) & 31;
    try c.page(Reminders{ .m = m, .oob = true });
}

fn empty(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .id = "demo-empty-hero",
        .title = "Reminders",
        .accessory = countBadge(0, false),
        .body = zw.view("<div id=\"demo-empty-reminders\">{r}</div>", .{ .r = Reminders{ .m = 0 } }),
    }).render(w);
}

// Sizes: each empty state sits in a card labelled with the prop value.
fn sizes(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\">{a}{b}{c}</div>", .{
        .a = ui.card(.{
            .variant = .inset,
            .title = ".compact",
            .subtitle = "A popover or a small card",
            .body = ui.empty(.{ .icon = "🔍", .title = "No Recent Searches", .size = .compact }),
        }),
        .b = ui.card(.{
            .variant = .inset,
            .title = ".regular (default)",
            .subtitle = "A section of a window",
            .body = ui.empty(.{
                .icon = "📝",
                .title = "No Notes",
                .text = "Create a note to start writing.",
                .action = ui.button(.{ .label = "New Note", .variant = .primary, .z = d.save }),
            }),
        }),
        .c = ui.card(.{
            .variant = .inset,
            .title = ".large",
            .subtitle = "A whole page or window",
            .body = ui.empty(.{
                .icon = "🖼",
                .title = "No Photos or Videos",
                .text = "You can import photos and videos from a camera or a disk.",
                .size = .large,
                .action = ui.button(.{ .label = "Import…", .variant = .primary, .z = d.save }),
            }),
        }),
    }).render(w);
}

// Parts: add the props one at a time, ending with a loading and a disabled button.
fn parts(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"zw-stack\">{a}{b}{c}{d}</div>", .{
        .a = ui.card(.{
            .variant = .inset,
            .title = "title, text",
            .body = ui.empty(.{ .title = "No Attachments", .text = "Files attached to this message show up here." }),
        }),
        .b = ui.card(.{
            .variant = .inset,
            .title = "icon, title, text",
            .body = ui.empty(.{ .icon = "📝", .title = "No Notes", .text = "Create a note to start writing." }),
        }),
        .c = ui.card(.{
            .variant = .inset,
            .title = "action, secondary",
            .body = ui.empty(.{
                .icon = "⚠️",
                .title = "Can’t Load Calendar",
                .text = "Check your connection and try again.",
                .action = ui.button(.{ .label = "Try Again", .variant = .primary, .z = d.save }),
                .secondary = ui.button(.{ .label = "Open Settings", .variant = .plain, .z = d.save }),
            }),
        }),
        .d = ui.card(.{
            .variant = .inset,
            .title = "loading and disabled buttons",
            .body = ui.empty(.{
                .icon = "☁️",
                .title = "Syncing Notes",
                .text = "This can take a moment.",
                .action = ui.button(.{ .label = "Syncing", .loading = true }),
                .secondary = ui.button(.{ .label = "Pause", .variant = .plain, .disabled = true }),
            }),
        }),
    }).render(w);
}

// Places: a Finder-like switcher. Each place is a different state of the same pane.
const Place = struct {
    name: []const u8,
    pub fn render(p: Place, w: *Writer) Writer.Error!void {
        if (std.mem.eql(u8, p.name, "shared")) {
            try ui.empty(.{
                .icon = "👥",
                .title = "Nothing Shared",
                .text = "Files that other people share with you appear here.",
                .action = ui.button(.{ .label = "Invite People", .variant = .primary, .z = d.save }),
            }).render(w);
        } else if (std.mem.eql(u8, p.name, "trash")) {
            try ui.empty(.{ .icon = "🗑", .title = "Trash is Empty", .text = "Items you delete stay here for 30 days." }).render(w);
        } else {
            try (FileList{ .id = "demo-empty-recents", .items = files[0..4] }).render(w);
        }
    }
};

fn placeRoute(c: *zw.Ctx) !void {
    try c.page(Place{ .name = c.query("place") orelse "recents" });
}

fn places(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "iCloud Drive",
        .body = zw.view("<div class=\"zw-stack\">{seg}<div id=\"demo-empty-place\">{pane}</div></div>", .{
            .seg = ui.segmented(.{
                .name = "place",
                .label = "Place",
                .size = .small,
                .full = true,
                .z = .{ .get = "/demo/empty/place", .target = "#demo-empty-place" },
                .options = &.{
                    .{ .value = "recents", .label = "Recents", .selected = true },
                    .{ .value = "shared", .label = "Shared" },
                    .{ .value = "trash", .label = "Trash" },
                },
            }),
            .pane = Place{ .name = "recents" },
        }),
    }).render(w);
}

// Search: no matches shows a compact empty state in place of the list.
fn contains(name: []const u8, q: []const u8) bool {
    if (q.len > name.len) return false;
    for (0..name.len - q.len + 1) |i| if (std.ascii.startsWithIgnoreCase(name[i..], q)) return true;
    return false;
}

fn filesRoute(c: *zw.Ctx) !void {
    const q = std.mem.trim(u8, c.query("q") orelse "", " ");
    var hits: [files.len]File = undefined;
    var n: usize = 0;
    for (files) |f| if (contains(f.name, q)) {
        hits[n] = f;
        n += 1;
    };
    if (n > 0) return c.page(FileList{ .id = "demo-empty-files", .items = hits[0..n] });
    const title = try std.fmt.allocPrint(c.arena, "No Results for “{s}”", .{q});
    try c.page(ui.empty(.{ .icon = "🔍", .title = title, .text = "Check the spelling or try a new search.", .size = .compact }));
}

fn search(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Documents",
        .body = zw.view("<div class=\"zw-stack\">{field}<div id=\"demo-empty-results\">{list}</div></div>", .{
            .field = ui.field(.{
                .name = "q",
                .label = "Filter files",
                .placeholder = "Try “report”, then “xyz”",
                .type = "search",
                .z = .{ .get = "/demo/empty/files", .trigger = "input", .target = "#demo-empty-results" },
            }),
            .list = FileList{ .id = "demo-empty-files", .items = &files },
        }),
    }).render(w);
}
