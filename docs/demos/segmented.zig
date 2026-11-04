//! Live demos for docs/pages/components/segmented.md (```demo segmented``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "segmented", true, hero },
    .{ "segmented-variants", true, variants },
    .{ "segmented-states", true, states },
    .{ "segmented-billing", true, billing },
    .{ "segmented-mail", true, mail },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-segmented-bar{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:10px 16px;margin-bottom:12px}
    \\.demo-segmented-tiles{display:grid;grid-template-columns:repeat(auto-fill,minmax(96px,1fr));gap:8px}
    \\.demo-segmented-tile{display:flex;flex-direction:column;align-items:center;gap:6px;min-width:0;padding:12px 6px;border-radius:var(--radius);background:var(--fill);font:var(--callout);text-align:center;overflow-wrap:anywhere}
    \\.demo-segmented-glyph{font-size:32px;line-height:1}
    \\.demo-segmented-meta{flex:none;font:var(--callout);color:var(--secondary)}
    \\.demo-segmented-cases{display:grid;gap:14px;width:100%}
    \\.demo-segmented-case{display:flex;flex-wrap:wrap;align-items:center;gap:6px 16px;min-width:0;
    \\  &>code{flex:0 0 12em}
    \\  @media (max-width:599px){&>code{flex-basis:100%}}}
    \\.demo-segmented-narrow{width:100%;max-width:240px}
    \\.demo-segmented-filter{margin-bottom:12px}
    \\.demo-segmented-price{margin-top:14px;color:var(--secondary)}
    \\.demo-segmented-amount{font:var(--title2);color:var(--label)}
    \\.demo-segmented-dot{flex:none;display:inline-flex;width:10px}
    \\.demo-segmented-msg{display:flex;flex-direction:column;min-width:0;
    \\  &>span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--secondary);font:var(--callout)}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/segmented/x", handler }`.
pub const routes = .{
    .{ "GET /demo/segmented/files", filesRoute },
    .{ "GET /demo/segmented/plan", planRoute },
    .{ "GET /demo/segmented/mail", mailRoute },
};

const grid = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 2h5v5H2zm7 0h5v5H9zM2 9h5v5H2zm7 0h5v5H9z\"/></svg>";
const rows = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 3h12v2H2zm0 4h12v2H2zm0 4h12v2H2z\"/></svg>";
const details = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 3h2v2H2zm4 0h8v2H6zM2 7h2v2H2zm4 0h8v2H6zm-4 4h2v2H2zm4 0h8v2H6z\"/></svg>";

/// One caption (the prop it shows) and a control.
fn row(w: *Writer, comptime caption: []const u8, control: anytype) Writer.Error!void {
    try zw.view("<div class=\"demo-segmented-case\"><code>" ++ caption ++ "</code>{c}</div>", .{ .c = control }).render(w);
}

// ---- Hero: a Finder-like window. The view and sort controls re-render the file area. ----

const File = struct { name: []const u8, kind: []const u8, size: []const u8, glyph: []const u8 };

const files = [_]File{
    .{ .name = "Budget 2026.xlsx", .kind = "Spreadsheet", .size = "84 KB", .glyph = "📊" },
    .{ .name = "Cover letter.pdf", .kind = "PDF", .size = "212 KB", .glyph = "📄" },
    .{ .name = "Holiday.mov", .kind = "Movie", .size = "1.4 GB", .glyph = "🎬" },
    .{ .name = "Notes.txt", .kind = "Text", .size = "4 KB", .glyph = "📝" },
    .{ .name = "Photos", .kind = "Folder", .size = "2.3 GB", .glyph = "📁" },
    .{ .name = "Slides.key", .kind = "Presentation", .size = "18 MB", .glyph = "📽️" },
};

/// Indexes into `files`, sorted by name (the array order), kind or size.
fn order(sort: []const u8) []const u8 {
    if (std.mem.eql(u8, sort, "kind")) return &.{ 4, 2, 1, 5, 0, 3 };
    if (std.mem.eql(u8, sort, "size")) return &.{ 3, 0, 1, 5, 2, 4 };
    return &.{ 0, 1, 2, 3, 4, 5 };
}

/// `<li>` rows of the list and details views.
const FileRows = struct {
    sort: []const u8,
    details: bool,

    pub fn render(r: FileRows, w: *Writer) Writer.Error!void {
        for (order(r.sort)) |i| {
            const f = files[i];
            try zw.view("<li><span aria-hidden=\"true\">{g}</span><span class=\"zw-grow\">{n}</span>{#if details}{k}{/if}<span class=\"demo-segmented-meta\">{s}</span></li>", .{
                .g = f.glyph,
                .n = f.name,
                .details = r.details,
                .k = ui.badge(.{ .text = f.kind, .size = .small }),
                .s = f.size,
            }).render(w);
        }
    }
};

/// The file area for a view (`icons`, `list`, `details`) and a sort (`name`, `kind`, `size`).
const Files = struct {
    view: []const u8,
    sort: []const u8,

    pub fn render(f: Files, w: *Writer) Writer.Error!void {
        if (std.mem.eql(u8, f.view, "icons")) {
            try w.writeAll("<div class=\"demo-segmented-tiles\">");
            for (order(f.sort)) |i| {
                try zw.view("<div class=\"demo-segmented-tile\"><span class=\"demo-segmented-glyph\" aria-hidden=\"true\">{g}</span><span>{n}</span></div>", .{
                    .g = files[i].glyph,
                    .n = files[i].name,
                }).render(w);
            }
            try w.writeAll("</div>");
        } else {
            try ui.list(.{ .id = "demo-segmented-list", .inset = false, .body = FileRows{ .sort = f.sort, .details = std.mem.eql(u8, f.view, "details") } }).render(w);
        }
    }
};

fn filesRoute(c: *zw.Ctx) !void {
    try c.page(Files{ .view = c.query("demo-segmented-view") orelse "icons", .sort = c.query("demo-segmented-sort") orelse "name" });
}

fn hero(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Documents", .subtitle = "6 items", .body = zw.view(
        "<form class=\"demo-segmented-bar\"{z}>{view}<span class=\"zw-inline\"><span aria-hidden=\"true\">Sort by</span>{sort}</span></form><div id=\"demo-segmented-files\">{files}</div>",
        .{
            .z = ui.Z{ .get = "/demo/segmented/files", .target = "#demo-segmented-files", .swap = .inner, .trigger = "change" },
            .view = ui.segmented(.{ .name = "demo-segmented-view", .label = "View", .icons_only = true, .options = &.{
                .{ .value = "icons", .label = "Icons", .icon = grid, .selected = true },
                .{ .value = "list", .label = "List", .icon = rows },
                .{ .value = "details", .label = "Details", .icon = details },
            } }),
            .sort = ui.segmented(.{ .name = "demo-segmented-sort", .label = "Sort by", .size = .small, .options = &.{
                .{ .value = "name", .label = "Name", .selected = true },
                .{ .value = "kind", .label = "Kind" },
                .{ .value = "size", .label = "Size" },
            } }),
            .files = Files{ .view = "icons", .sort = "name" },
        },
    ) }).render(w);
}

// ---- Variants and sizes: each row names the prop it shows. ----

const range: []const ui.SegmentedOption = &.{
    .{ .value = "day", .label = "Day" },
    .{ .value = "week", .label = "Week", .selected = true },
    .{ .value = "month", .label = "Month" },
};

fn variants(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-segmented-cases\">");
    try row(w, ".size = .small", ui.segmented(.{ .name = "demo-segmented-small", .label = "Range, small", .size = .small, .z = d.save, .options = range }));
    try row(w, ".size = .regular", ui.segmented(.{ .name = "demo-segmented-regular", .label = "Range, regular", .z = d.save, .options = range }));
    try row(w, ".size = .large", ui.segmented(.{ .name = "demo-segmented-large", .label = "Range, large", .size = .large, .z = d.save, .options = range }));
    try row(w, ".full = true", ui.segmented(.{ .name = "demo-segmented-full", .label = "Range, full width", .full = true, .z = d.save, .options = range }));
    try row(w, "option .icon", ui.segmented(.{ .name = "demo-segmented-icon", .label = "Layout, icon and text", .z = d.save, .options = &.{
        .{ .value = "grid", .label = "Grid", .icon = grid, .selected = true },
        .{ .value = "list", .label = "List", .icon = rows },
        .{ .value = "details", .label = "Details", .icon = details },
    } }));
    try row(w, ".icons_only = true", ui.segmented(.{ .name = "demo-segmented-icons", .label = "Layout, icons only", .icons_only = true, .z = d.save, .options = &.{
        .{ .value = "grid", .label = "Grid", .icon = grid, .selected = true },
        .{ .value = "list", .label = "List", .icon = rows },
        .{ .value = "details", .label = "Details", .icon = details },
    } }));
    try w.writeAll("</div>");
}

// ---- States ----

fn states(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-segmented-cases\">");
    try row(w, "option .selected", ui.segmented(.{ .name = "demo-segmented-selected", .label = "Appearance", .z = d.save, .options = &.{
        .{ .value = "light", .label = "Light" },
        .{ .value = "dark", .label = "Dark", .selected = true },
        .{ .value = "auto", .label = "Auto" },
    } }));
    try row(w, "none selected", ui.segmented(.{ .name = "demo-segmented-none", .label = "Appearance, nothing chosen", .z = d.save, .options = &.{
        .{ .value = "light", .label = "Light" },
        .{ .value = "dark", .label = "Dark" },
        .{ .value = "auto", .label = "Auto" },
    } }));
    try row(w, "option .disabled", ui.segmented(.{ .name = "demo-segmented-option-off", .label = "Billing period", .z = d.save, .options = &.{
        .{ .value = "month", .label = "Monthly", .selected = true },
        .{ .value = "year", .label = "Yearly" },
        .{ .value = "decade", .label = "Decade", .disabled = true },
    } }));
    try row(w, ".disabled = true", ui.segmented(.{ .name = "demo-segmented-off", .label = "Appearance, locked", .disabled = true, .z = d.save, .options = &.{
        .{ .value = "light", .label = "Light" },
        .{ .value = "dark", .label = "Dark", .selected = true },
        .{ .value = "auto", .label = "Auto" },
    } }));
    try row(w, ".help", ui.segmented(.{ .name = "demo-segmented-help", .label = "Sync", .help = "Applies to every device.", .z = d.save, .options = &.{
        .{ .value = "auto", .label = "Automatic", .selected = true },
        .{ .value = "manual", .label = "Manual" },
    } }));
    try row(w, ".invalid", ui.segmented(.{ .name = "demo-segmented-invalid", .label = "Delivery", .help = "Choose how to ship.", .invalid = "Choose a delivery method.", .z = d.save, .options = &.{
        .{ .value = "post", .label = "Post" },
        .{ .value = "pickup", .label = "Pickup" },
    } }));
    try row(w, "long labels", zw.view("<div class=\"demo-segmented-narrow\">{c}</div>", .{
        .c = ui.segmented(.{ .name = "demo-segmented-long", .label = "Backup frequency", .full = true, .z = d.save, .options = &.{
            .{ .value = "hourly", .label = "Every hour while plugged in", .selected = true },
            .{ .value = "daily", .label = "Once a day when the lid is closed" },
        } }),
    }));
    try row(w, "seven options", ui.segmented(.{ .name = "demo-segmented-days", .label = "Repeat on", .size = .small, .z = d.save, .options = &.{
        .{ .value = "mo", .label = "Mo", .selected = true },
        .{ .value = "tu", .label = "Tu" },
        .{ .value = "we", .label = "We" },
        .{ .value = "th", .label = "Th" },
        .{ .value = "fr", .label = "Fr" },
        .{ .value = "sa", .label = "Sa" },
        .{ .value = "su", .label = "Su" },
    } }));
    try w.writeAll("</div>");
}

// ---- Billing: the choice changes the price, a badge elsewhere and shows a toast. ----

const Price = struct {
    yearly: bool,

    pub fn render(p: Price, w: *Writer) Writer.Error!void {
        try w.writeAll(if (p.yearly)
            "<strong class=\"demo-segmented-amount\">$8</strong> per month, billed $96 a year"
        else
            "<strong class=\"demo-segmented-amount\">$10</strong> per month, billed monthly");
    }
};

fn saveBadge(yearly: bool, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-segmented-save", .oob = oob, .text = if (yearly) "Save 20%" else "Billed monthly", .tone = if (yearly) .green else .gray });
}

fn planRoute(c: *zw.Ctx) !void {
    const yearly = std.mem.eql(u8, c.query("demo-segmented-billing") orelse "", "year");
    try c.page(zw.view("{price}{badge}{toast}", .{
        .price = Price{ .yearly = yearly },
        .badge = saveBadge(yearly, true),
        .toast = ui.toast(.{ .text = if (yearly) "Switched to yearly billing" else "Switched to monthly billing", .kind = .success }),
    }));
}

fn billing(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Pro plan",
        .subtitle = "Sync, backups and priority support.",
        .accessory = saveBadge(false, false),
        .footer = "Cancel any time.",
        .body = zw.view("{seg}<p class=\"demo-segmented-price\" id=\"demo-segmented-price\">{price}</p>", .{
            .seg = ui.segmented(.{
                .name = "demo-segmented-billing",
                .label = "Billing period",
                .full = true,
                .z = .{ .get = "/demo/segmented/plan", .target = "#demo-segmented-price", .swap = .inner },
                .options = &.{
                    .{ .value = "month", .label = "Monthly", .selected = true },
                    .{ .value = "year", .label = "Yearly" },
                },
            }),
            .price = Price{ .yearly = false },
        }),
    }).render(w);
}

// ---- Mail: a segmented filter above a list, with a count badge and an empty state. ----

const Message = struct { from: []const u8, subject: []const u8, unread: bool, flagged: bool };

const messages = [_]Message{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine", .unread = true, .flagged = true },
    .{ .from = "Grace Hopper", .subject = "Compiler draft for review", .unread = true, .flagged = false },
    .{ .from = "Alan Turing", .subject = "Re: The halting problem", .unread = false, .flagged = true },
    .{ .from = "Katherine Johnson", .subject = "Trajectory numbers", .unread = true, .flagged = false },
    .{ .from = "Edsger Dijkstra", .subject = "A question about semaphores", .unread = false, .flagged = false },
};

fn shown(filter: []const u8, m: Message) bool {
    if (std.mem.eql(u8, filter, "unread")) return m.unread;
    if (std.mem.eql(u8, filter, "flagged")) return m.flagged;
    if (std.mem.eql(u8, filter, "drafts")) return false;
    return true;
}

fn emptyText(filter: []const u8) []const u8 {
    if (std.mem.eql(u8, filter, "unread")) return "You're all caught up";
    if (std.mem.eql(u8, filter, "flagged")) return "No flagged messages";
    if (std.mem.eql(u8, filter, "drafts")) return "No drafts";
    return "The inbox is empty";
}

const MessageRows = struct {
    filter: []const u8,

    pub fn render(r: MessageRows, w: *Writer) Writer.Error!void {
        for (messages) |m| {
            if (!shown(r.filter, m)) continue;
            try zw.view("<li><span class=\"demo-segmented-dot\">{#if m.unread}{dot}{/if}</span><span class=\"zw-grow demo-segmented-msg\"><strong>{m.from}</strong><span>{m.subject}</span></span>{#if m.flagged}<span role=\"img\" aria-label=\"Flagged\">🚩</span>{/if}</li>", .{
                .m = m,
                .dot = ui.badge(.{ .dot = true, .tone = .accent, .text = "Unread" }),
            }).render(w);
        }
    }
};

fn messageList(filter: []const u8) ui.List(MessageRows) {
    return ui.list(.{ .id = "demo-segmented-mail", .empty = emptyText(filter), .inset = false, .body = MessageRows{ .filter = filter } });
}

fn countBadge(filter: []const u8, oob: bool) ui.Badge {
    var n: u32 = 0;
    for (messages) |m| {
        if (shown(filter, m)) n += 1;
    }
    return ui.badge(.{ .id = "demo-segmented-count", .oob = oob, .count = n, .hide_zero = true });
}

fn mailRoute(c: *zw.Ctx) !void {
    const filter = c.query("demo-segmented-filter") orelse "all";
    try c.page(zw.view("{list}{count}", .{ .list = messageList(filter), .count = countBadge(filter, true) }));
}

fn mail(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Inbox",
        .accessory = countBadge("all", false),
        .body = zw.view("<div class=\"demo-segmented-filter\">{seg}</div>{list}", .{
            .seg = ui.segmented(.{
                .name = "demo-segmented-filter",
                .label = "Show",
                .full = true,
                .z = .{ .get = "/demo/segmented/mail", .target = "#demo-segmented-mail", .swap = .outer },
                .options = &.{
                    .{ .value = "all", .label = "All", .selected = true },
                    .{ .value = "unread", .label = "Unread" },
                    .{ .value = "flagged", .label = "Flagged" },
                    .{ .value = "drafts", .label = "Drafts" },
                },
            }),
            .list = messageList("all"),
        }),
    }).render(w);
}
